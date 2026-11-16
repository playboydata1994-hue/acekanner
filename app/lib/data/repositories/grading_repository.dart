import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../domain/analytics.dart';
import '../../domain/grading.dart';
import '../audit/audit_logger.dart';
import '../db/app_database.dart';
import '../errors.dart';
import '../live_query.dart';

/// A finalized (or waiting) paper with everything the result screen shows.
class PaperDetail {
  const PaperDetail({
    required this.exam,
    required this.sheet,
    required this.student,
    required this.version,
    required this.result,
    required this.keyRevision,
    required this.grade,
    required this.answers,
  });

  final ExaminationRow exam;
  final AnswerSheetRow sheet;
  final StudentRow? student;
  final ExaminationVersionRow? version;

  /// Current stored result; null while the paper waits for a complete key.
  final ExaminationResultRow? result;
  final int? keyRevision;

  /// Per-question breakdown recomputed from the stored answers and the key
  /// used for [result] (identical to what was stored).
  final GradeResult? grade;
  final List<StudentAnswerRow> answers;
}

/// One graded paper for class analytics.
class AnalyticsPaper {
  const AnalyticsPaper({
    required this.sheetId,
    required this.student,
    required this.versionId,
    required this.sectionIds,
    required this.grade,
  });

  final String sheetId;
  final StudentRow? student;
  final String versionId;
  final Set<String> sectionIds;
  final GradeResult grade;
}

class ExamAnalytics {
  const ExamAnalytics({
    required this.exam,
    required this.versions,
    required this.sections,
    required this.papers,
    required this.keys,
  });

  final ExaminationRow exam;
  final List<ExaminationVersionRow> versions;
  final List<SectionRow> sections;
  final List<AnalyticsPaper> papers;

  /// Current key items per version id.
  final Map<String, List<GradeKeyItem>> keys;

  List<AnalyticsPaper> filtered({String? sectionId, String? versionId}) => [
        for (final p in papers)
          if ((sectionId == null || p.sectionIds.contains(sectionId)) && (versionId == null || p.versionId == versionId)) p,
      ];

  ScoreStats stats({String? sectionId, String? versionId}) {
    final list = filtered(sectionId: sectionId, versionId: versionId);
    return scoreStats([for (final p in list) p.grade.percentage], passed: [for (final p in list) p.grade.passed]);
  }

  List<ItemStat> items(String versionId, {String? sectionId}) => itemAnalysis(
        [
          for (final p in filtered(sectionId: sectionId, versionId: versionId))
            GradedPaper(percentage: p.grade.percentage, questions: p.grade.questions),
        ],
        keys[versionId] ?? const [],
      );
}

/// Turns saved papers into scores, keeps them correct when the key or the
/// rules change, and records every change in the audit log.
class GradingRepository {
  GradingRepository(this._db, this._audit, {this.clock = const Clock()});

  final AppDatabase _db;
  final AuditLogger _audit;
  final Clock clock;

  /// One charge-free submission per student per examination: re-scanning or
  /// re-finalizing the same student's paper never creates a second one.
  static String submissionKey(String examId, String studentId) =>
      sha256.convert(utf8.encode('acekanner-submission|v1|$examId|$studentId')).toString();

  /// Grades a saved paper with the current key of its set and marks it
  /// finalized. Idempotent: returns the current result if already finalized.
  Future<ExaminationResultRow> finalize(String sheetId) {
    return _db.transaction(() async {
      final sheet = await _sheet(sheetId);
      if (sheet.status == 'finalized') {
        final current = await _currentResult(sheetId);
        if (current != null) return current;
      }
      if (sheet.status != 'needs_review' && sheet.status != 'finalized') {
        throw const DataException('This paper was replaced or rejected and cannot be graded.');
      }
      if (sheet.studentId == null) throw const DataException('Identify the student before grading.');
      if (sheet.examinationVersionId == null) throw const DataException('Choose the exam set before grading.');
      final exam = await _exam(sheet.examinationId);
      final (key, items) = await _currentKey(sheet.examinationVersionId!);
      if (items.any((i) => i.mode == 'normal' && i.correctMask == 0)) {
        throw const DataException('Finish the answer key before grading.');
      }
      final answers = await _answers(sheetId, exam.itemCount);
      final g = grade(key: items, answers: answers, rules: _rules(exam));

      final subKey = submissionKey(exam.id, sheet.studentId!);
      final now = clock.now();
      // A re-scan of the same student replaces the earlier paper.
      await (_db.update(_db.answerSheets)
            ..where((t) =>
                t.examinationId.equals(exam.id) &
                t.studentId.equals(sheet.studentId!) &
                t.id.equals(sheetId).not() &
                t.status.isIn(const ['needs_review', 'finalized'])))
          .write(AnswerSheetsCompanion(status: const Value('superseded'), updatedAt: Value(now)));
      await (_db.update(_db.answerSheets)..where((t) => t.id.equals(sheetId))).write(
            AnswerSheetsCompanion(
              status: const Value('finalized'),
              submissionKey: Value(subKey),
              finalizedAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      final row = await _insertResult(sheetId, key.id, g, now);
      await _audit.record(
        event: 'answer_sheet.finalized',
        entityType: 'answer_sheet',
        entityId: sheetId,
        examinationId: exam.id,
        details: {'percentage': g.percentage, 'earned': g.earned, 'possible': g.possible, 'keyRevision': key.revision},
      );
      return row;
    });
  }

  /// Grades every saved paper of the examination that is waiting (student
  /// and set known). Returns how many were graded.
  Future<int> gradePending(String examId) {
    return _db.transaction(() async {
      final waiting = await (_db.select(_db.answerSheets)
            ..where((t) =>
                t.examinationId.equals(examId) &
                t.status.equals('needs_review') &
                t.studentId.isNotNull() &
                t.examinationVersionId.isNotNull())
            ..orderBy([(t) => OrderingTerm.asc(t.capturedAt)]))
          .get();
      var graded = 0;
      for (final s in waiting) {
        // A later paper of the same student may already have replaced this one.
        final fresh = await _sheet(s.id);
        if (fresh.status != 'needs_review') continue;
        try {
          await finalize(s.id);
          graded++;
        } on DataException {
          // Not gradable yet (e.g. key incomplete); stays waiting.
        }
      }
      return graded;
    });
  }

  /// Re-scores finalized papers with the current key and rules. A new key
  /// revision adds a new result (the old one stays as history); a rule change
  /// updates the current result. Returns the number of papers whose score
  /// changed.
  Future<int> regrade(String examId, {String? versionId, required String reason}) {
    return _db.transaction(() async {
      final exam = await _exam(examId);
      final sheets = await (_db.select(_db.answerSheets)
            ..where((t) =>
                t.examinationId.equals(examId) &
                t.status.equals('finalized') &
                (versionId == null ? const Constant(true) : t.examinationVersionId.equals(versionId))))
          .get();
      final keys = <String, (AnswerKeyRow, List<GradeKeyItem>)>{};
      var changed = 0;
      final now = clock.now();
      for (final s in sheets) {
        final (key, items) = keys[s.examinationVersionId!] ??= await _currentKey(s.examinationVersionId!);
        final g = grade(key: items, answers: await _answers(s.id, exam.itemCount), rules: _rules(exam));
        final current = await _currentResult(s.id);
        if (current == null || current.answerKeyId != key.id) {
          if (current != null) {
            await (_db.update(_db.examinationResults)..where((t) => t.id.equals(current.id)))
                .write(const ExaminationResultsCompanion(isCurrent: Value(false)));
          }
          await _insertResult(s.id, key.id, g, now);
          if (current == null || _differs(current, g)) changed++;
        } else if (_differs(current, g)) {
          await (_db.update(_db.examinationResults)..where((t) => t.id.equals(current.id)))
              .write(_resultValues(g, now));
          changed++;
        }
      }
      if (sheets.isNotEmpty) {
        await _audit.record(
          event: 'results.regraded',
          entityType: 'examination',
          entityId: examId,
          examinationId: examId,
          details: {'reason': reason, 'papers': sheets.length, 'changed': changed, 'set': ?versionId},
        );
      }
      return changed;
    });
  }

  /// Instructor corrections of how answers were read (question → mask). A
  /// finalized paper is re-scored immediately.
  Future<void> correctAnswers(String sheetId, Map<int, int> changes) {
    if (changes.isEmpty) return Future.value();
    return _db.transaction(() async {
      final sheet = await _sheet(sheetId);
      for (final e in changes.entries) {
        if (e.value < 0 || e.value > 31) throw const DataException('Invalid answer.');
        await (_db.update(_db.studentAnswers)
              ..where((t) => t.answerSheetId.equals(sheetId) & t.questionNo.equals(e.key)))
            .write(StudentAnswersCompanion(finalMask: Value(e.value), resolvedBy: const Value('instructor')));
      }
      await (_db.update(_db.answerSheets)..where((t) => t.id.equals(sheetId)))
          .write(AnswerSheetsCompanion(updatedAt: Value(clock.now())));
      await _audit.record(
        event: 'answer.corrected',
        entityType: 'answer_sheet',
        entityId: sheetId,
        examinationId: sheet.examinationId,
        details: {'questions': changes.keys.toList()..sort()},
      );
      if (sheet.status == 'finalized') {
        final exam = await _exam(sheet.examinationId);
        final current = await _currentResult(sheetId);
        final (key, items) = await _currentKey(sheet.examinationVersionId!);
        final g = grade(key: items, answers: await _answers(sheetId, exam.itemCount), rules: _rules(exam));
        if (current != null && current.answerKeyId == key.id) {
          await (_db.update(_db.examinationResults)..where((t) => t.id.equals(current.id)))
              .write(_resultValues(g, clock.now()));
        } else {
          if (current != null) {
            await (_db.update(_db.examinationResults)..where((t) => t.id.equals(current.id)))
                .write(const ExaminationResultsCompanion(isCurrent: Value(false)));
          }
          await _insertResult(sheetId, key.id, g, clock.now());
        }
      }
    });
  }

  /// Everything the paper result screen shows.
  Future<PaperDetail?> paperDetail(String sheetId) async {
    final sheet = await (_db.select(_db.answerSheets)..where((t) => t.id.equals(sheetId))).getSingleOrNull();
    if (sheet == null) return null;
    final exam = await _exam(sheet.examinationId);
    final student = sheet.studentId == null
        ? null
        : await (_db.select(_db.students)..where((t) => t.id.equals(sheet.studentId!))).getSingleOrNull();
    final version = sheet.examinationVersionId == null
        ? null
        : await (_db.select(_db.examinationVersions)..where((t) => t.id.equals(sheet.examinationVersionId!)))
            .getSingleOrNull();
    final result = await _currentResult(sheetId);
    final answers = await (_db.select(_db.studentAnswers)
          ..where((t) => t.answerSheetId.equals(sheetId))
          ..orderBy([(t) => OrderingTerm.asc(t.questionNo)]))
        .get();
    GradeResult? g;
    int? revision;
    if (result != null) {
      final key = await (_db.select(_db.answerKeys)..where((t) => t.id.equals(result.answerKeyId))).getSingle();
      revision = key.revision;
      g = grade(key: await _items(key.id), answers: _toMap(answers, exam.itemCount), rules: _rules(exam));
    }
    return PaperDetail(
      exam: exam,
      sheet: sheet,
      student: student,
      version: version,
      result: result,
      keyRevision: revision,
      grade: g,
      answers: answers,
    );
  }

  /// Re-emits [paperDetail] whenever the paper, its answers or results change.
  Stream<PaperDetail?> watchPaper(String sheetId) => liveQuery(
        _db,
        [_db.answerSheets, _db.studentAnswers, _db.examinationResults, _db.students],
        () => paperDetail(sheetId),
      );

  /// Re-emits [analytics] whenever results change.
  Stream<ExamAnalytics> watchAnalytics(String examId) => liveQuery(
        _db,
        [_db.answerSheets, _db.examinationResults, _db.studentAnswers, _db.answerKeys, _db.sectionStudents],
        () => analytics(examId),
      );

  /// Graded papers of an examination with their sections, for analytics.
  Future<ExamAnalytics> analytics(String examId) async {
    final exam = await _exam(examId);
    final versions = await (_db.select(_db.examinationVersions)
          ..where((t) => t.examinationId.equals(examId))
          ..orderBy([(t) => OrderingTerm.asc(t.label)]))
        .get();
    final sections = await _db.examinationSectionList(examinationId: examId).get();
    final keys = <String, List<GradeKeyItem>>{
      for (final v in versions) v.id: (await _currentKey(v.id)).$2,
    };
    final sheets = await (_db.select(_db.answerSheets)
          ..where((t) => t.examinationId.equals(examId) & t.status.equals('finalized')))
        .get();
    final rules = _rules(exam);
    final papers = <AnalyticsPaper>[];
    for (final s in sheets) {
      final result = await _currentResult(s.id);
      if (result == null || s.examinationVersionId == null) continue;
      final items = await _items(result.answerKeyId);
      final student = s.studentId == null
          ? null
          : await (_db.select(_db.students)..where((t) => t.id.equals(s.studentId!))).getSingleOrNull();
      final memberships = s.studentId == null
          ? const <String>{}
          : (await (_db.select(_db.sectionStudents)..where((t) => t.studentId.equals(s.studentId!))).get())
              .map((m) => m.sectionId)
              .toSet();
      papers.add(AnalyticsPaper(
        sheetId: s.id,
        student: student,
        versionId: s.examinationVersionId!,
        sectionIds: memberships,
        grade: grade(key: items, answers: await _answers(s.id, exam.itemCount), rules: rules),
      ));
    }
    return ExamAnalytics(exam: exam, versions: versions, sections: sections, papers: papers, keys: keys);
  }

  // ------------------------------------------------------------------ helpers

  static GradingRules _rules(ExaminationRow e) => GradingRules(
        passingPercentage: e.passingPercentage,
        multipleMarkPolicy: e.multipleMarkPolicy,
        allowNegativeTotal: e.allowNegativeTotal,
      );

  Future<AnswerSheetRow> _sheet(String id) async {
    final s = await (_db.select(_db.answerSheets)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (s == null) throw const DataException('This paper no longer exists.');
    return s;
  }

  Future<ExaminationRow> _exam(String id) => (_db.select(_db.examinations)..where((t) => t.id.equals(id))).getSingle();

  Future<(AnswerKeyRow, List<GradeKeyItem>)> _currentKey(String versionId) async {
    final key = await (_db.select(_db.answerKeys)
          ..where((t) => t.examinationVersionId.equals(versionId) & t.isCurrent.equals(true)))
        .getSingle();
    return (key, await _items(key.id));
  }

  Future<List<GradeKeyItem>> _items(String keyId) async {
    final rows = await (_db.select(_db.answerKeyItems)
          ..where((t) => t.answerKeyId.equals(keyId))
          ..orderBy([(t) => OrderingTerm.asc(t.questionNo)]))
        .get();
    return [
      for (final r in rows)
        GradeKeyItem(
          questionNo: r.questionNo,
          correctMask: r.correctMask,
          points: r.points,
          negativePoints: r.negativePoints,
          mode: r.mode,
        ),
    ];
  }

  Future<Map<int, int>> _answers(String sheetId, int itemCount) async {
    final rows = await (_db.select(_db.studentAnswers)..where((t) => t.answerSheetId.equals(sheetId))).get();
    if (rows.length != itemCount || rows.any((r) => r.finalMask == null)) {
      throw const DataException('Decide every flagged answer before grading.');
    }
    return _toMap(rows, itemCount);
  }

  static Map<int, int> _toMap(List<StudentAnswerRow> rows, int itemCount) =>
      {for (final r in rows) r.questionNo: r.finalMask ?? 0};

  Future<ExaminationResultRow?> _currentResult(String sheetId) => (_db.select(_db.examinationResults)
        ..where((t) => t.answerSheetId.equals(sheetId) & t.isCurrent.equals(true)))
      .getSingleOrNull();

  Future<ExaminationResultRow> _insertResult(String sheetId, String keyId, GradeResult g, DateTime now) async {
    final id = newId();
    await _db.into(_db.examinationResults).insert(
          _resultValues(g, now).copyWith(
            id: Value(id),
            answerSheetId: Value(sheetId),
            answerKeyId: Value(keyId),
            isCurrent: const Value(true),
          ),
        );
    return (_db.select(_db.examinationResults)..where((t) => t.id.equals(id))).getSingle();
  }

  static ExaminationResultsCompanion _resultValues(GradeResult g, DateTime now) => ExaminationResultsCompanion(
        correctCount: Value(g.correct),
        incorrectCount: Value(g.incorrect),
        blankCount: Value(g.blank),
        multipleCount: Value(g.multiple),
        earnedPoints: Value(g.earned),
        possiblePoints: Value(g.possible),
        percentage: Value(g.percentage.clamp(-100000, 100).toDouble()),
        passed: Value(g.passed),
        gradedAt: Value(now),
      );

  static bool _differs(ExaminationResultRow r, GradeResult g) =>
      r.earnedPoints != g.earned ||
      r.possiblePoints != g.possible ||
      r.passed != g.passed ||
      r.correctCount != g.correct ||
      r.incorrectCount != g.incorrect ||
      r.blankCount != g.blank ||
      r.multipleCount != g.multiple;
}
