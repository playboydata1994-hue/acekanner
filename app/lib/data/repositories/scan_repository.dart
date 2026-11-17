import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../domain/answer_mask.dart';
import '../../domain/omr_reading.dart';
import '../../domain/personal_sheet_code.dart';
import '../../domain/sheet_layout.dart';
import '../../domain/sheet_qr.dart';
import '../audit/audit_logger.dart';
import '../db/app_database.dart';
import '../licensing/license_repository.dart';
import '../errors.dart';
import 'grading_repository.dart';

/// How the student on a paper was identified.
enum IdentifiedBy { qrCode, studentNumber, instructor, none }

class StudentMatch {
  const StudentMatch({required this.student, required this.by, this.detectedNumber});

  final StudentRow? student;
  final IdentifiedBy by;

  /// Digits read from the grid (may contain '?').
  final String? detectedNumber;
}

/// Everything the scanner needs about an examination.
class ScanContext {
  const ScanContext({
    required this.exam,
    required this.versions,
    required this.layout,
    required this.roster,
  });

  final ExaminationRow exam;
  final List<ExaminationVersionRow> versions;
  final SheetLayout layout;

  /// Students in the sections assigned to the examination.
  final List<StudentRow> roster;
}

/// A paper ready to be saved after the instructor's review.
class ReviewedSheet {
  const ReviewedSheet({
    required this.examId,
    required this.versionId,
    required this.reading,
    required this.finalMasks,
    required this.overridden,
    required this.rectifiedImage,
    this.studentId,
    this.sessionId,
    this.replaceSheetId,
  });

  final String examId;
  final String versionId;
  final OmrSheetReading reading;

  /// Answer used for grading per question (1-based); null is not allowed.
  final Map<int, int> finalMasks;

  /// Questions whose answer the instructor set or changed.
  final Set<int> overridden;
  final File rectifiedImage;
  final String? studentId;
  final String? sessionId;

  /// An earlier paper of the same student this one replaces.
  final String? replaceSheetId;
}

/// A saved paper, for lists.
class ScannedPaper {
  const ScannedPaper({required this.sheet, this.student, required this.versionLabel, this.result});

  final AnswerSheetRow sheet;
  final StudentRow? student;
  final String? versionLabel;

  /// Current score; null while the paper waits for grading.
  final ExaminationResultRow? result;
}

/// Scan sessions, student identification and saving reviewed papers.
class ScanRepository {
  ScanRepository(
    this._db,
    this._audit, {
    required this.scansDirectory,
    this.grading,
    this.charger,
    this.clock = const Clock(),
  });

  final AppDatabase _db;
  final AuditLogger _audit;

  /// Grades a saved paper immediately when the examination's key is complete.
  final GradingRepository? grading;

  /// Charges each newly saved paper against the plan (Phase 6). A refused
  /// charge rolls the whole save back.
  final ScanCharger? charger;
  final Clock clock;

  /// App-private folder for corrected sheet images.
  final Future<Directory> Function() scansDirectory;

  Future<ScanContext> context(String examId) async {
    final exam = await (_db.select(_db.examinations)..where((t) => t.id.equals(examId))).getSingleOrNull();
    if (exam == null || exam.deletedAt != null) {
      throw const DataException('This examination no longer exists.');
    }
    final versions = await (_db.select(_db.examinationVersions)
          ..where((t) => t.examinationId.equals(examId))
          ..orderBy([(t) => OrderingTerm.asc(t.label)]))
        .get();
    final roster = await _db.customSelect(
      'SELECT DISTINCT st.* FROM students st '
      'INNER JOIN section_students ss ON ss.student_id = st.id '
      'INNER JOIN examination_sections es ON es.section_id = ss.section_id '
      'WHERE es.examination_id = ? AND st.deleted_at IS NULL '
      'ORDER BY st.last_name COLLATE NOCASE, st.first_name COLLATE NOCASE',
      variables: [Variable(examId)],
      readsFrom: {_db.students, _db.sectionStudents, _db.examinationSections},
    ).asyncMap((r) => _db.students.mapFromRow(r)).get();
    return ScanContext(
      exam: exam,
      versions: versions,
      layout: SheetLayout(itemCount: exam.itemCount, idDigits: exam.studentIdDigits, setCount: versions.length),
      roster: roster,
    );
  }

  /// Returns an explanation when the sheet's QR code belongs to another
  /// examination or layout; null when it matches or has no readable QR.
  String? sheetMismatch(ScanContext ctx, OmrSheetReading reading) {
    if (SheetQr.isOlderDesign(reading.qr)) {
      return 'This is an older ACEkanner answer sheet design that this version no longer reads. '
          'Print new sheets for this examination.';
    }
    final qr = SheetQr.tryParse(reading.qr);
    if (qr == null) return null;
    if (qr.examCode != ctx.exam.shortCode) {
      return 'This answer sheet was printed for another examination (code ${qr.examCode}). '
          'This examination’s code is ${ctx.exam.shortCode}.';
    }
    if (qr.idDigits != ctx.exam.studentIdDigits || qr.setCount != ctx.versions.length) {
      return 'This sheet was printed before the examination’s settings changed. Print new sheets.';
    }
    return null;
  }

  /// Personalized QR first; otherwise the shaded number, matched against the
  /// examination's sections and then against all saved students.
  Future<StudentMatch> identify(ScanContext ctx, OmrSheetReading reading) async {
    final qr = SheetQr.tryParse(reading.qr);
    if (qr?.sheetCode != null) {
      for (final s in ctx.roster) {
        if (personalSheetCode(ctx.exam.id, s.id) == qr!.sheetCode) {
          return StudentMatch(student: s, by: IdentifiedBy.qrCode, detectedNumber: reading.studentNumber);
        }
      }
    }
    if (reading.studentNumberClear) {
      final key = reading.studentNumber;
      final inRoster = ctx.roster.where((s) => s.studentNoKey == key).toList();
      if (inRoster.length == 1) {
        return StudentMatch(student: inRoster.single, by: IdentifiedBy.studentNumber, detectedNumber: key);
      }
      final anywhere = await (_db.select(_db.students)
            ..where((t) => t.studentNoKey.equals(key) & t.deletedAt.isNull()))
          .getSingleOrNull();
      if (anywhere != null) {
        return StudentMatch(student: anywhere, by: IdentifiedBy.studentNumber, detectedNumber: key);
      }
    }
    return StudentMatch(student: null, by: IdentifiedBy.none, detectedNumber: reading.studentNumber);
  }

  /// The student's current paper for this examination, if any.
  Future<AnswerSheetRow?> existingPaper(String examId, String studentId) =>
      (_db.select(_db.answerSheets)
            ..where((t) =>
                t.examinationId.equals(examId) &
                t.studentId.equals(studentId) &
                t.status.isIn(const ['needs_review', 'finalized']))
            ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<String> startSession(String examId, String mode, {String? deviceModel, String? appVersion}) async {
    final id = newId();
    await _db.into(_db.scanSessions).insert(
          ScanSessionsCompanion.insert(
            id: id,
            examinationId: examId,
            mode: mode,
            startedAt: clock.now(),
            deviceModel: Value(deviceModel),
            appVersion: Value(appVersion),
          ),
        );
    return id;
  }

  Future<void> recordCapture(String sessionId, {required bool rejected}) => _db.customStatement(
        'UPDATE scan_sessions SET captures_attempted = captures_attempted + 1, '
        'captures_rejected = captures_rejected + ? WHERE id = ?',
        [rejected ? 1 : 0, sessionId],
      );

  Future<void> endSession(String sessionId) => (_db.update(_db.scanSessions)
        ..where((t) => t.id.equals(sessionId)))
      .write(ScanSessionsCompanion(endedAt: Value(clock.now())));

  /// Saves a reviewed paper: its answers, the corrected image and an audit
  /// entry, in one transaction. A replaced earlier paper is kept as
  /// `superseded`. Grading happens when the paper is finalized.
  ///
  /// A paper may be saved without a student; it is then neither graded nor
  /// charged against the plan until the instructor assigns it to a student
  /// ([assignStudent]).
  Future<String> save(ReviewedSheet s) async {
    final reading = s.reading;
    if (s.finalMasks.length != reading.questions.length) {
      throw const DataException('Every question needs a final answer before saving.');
    }
    if (s.finalMasks.values.any((m) => !AnswerMask.isValidAnswer(m))) {
      throw const DataException('Invalid answer.');
    }
    final sheetId = newId();
    final dir = Directory(p.join((await scansDirectory()).path, s.examId));
    await dir.create(recursive: true);
    final imagePath = p.join(dir.path, '$sheetId.jpg');
    await s.rectifiedImage.copy(imagePath);

    try {
      await _db.transaction(() async {
        final now = clock.now();
        if (s.replaceSheetId != null) {
          await (_db.update(_db.answerSheets)..where((t) => t.id.equals(s.replaceSheetId!)))
              .write(AnswerSheetsCompanion(status: const Value('superseded'), updatedAt: Value(now)));
        }
        await _db.into(_db.answerSheets).insert(
              AnswerSheetsCompanion.insert(
                id: sheetId,
                examinationId: s.examId,
                examinationVersionId: Value(s.versionId),
                scanSessionId: Value(s.sessionId),
                studentId: Value(s.studentId),
                detectedStudentNo: Value(reading.studentNumber.isEmpty ? null : reading.studentNumber),
                status: 'needs_review',
                rectifiedImagePath: Value(imagePath),
                omrEngineVersion: Value(reading.engineVersion),
                omrPayload: Value(reading.raw),
                qualityScore: Value(reading.quality.score.clamp(0.0, 1.0)),
                flaggedCount: Value(reading.flaggedCount),
                capturedAt: now,
                updatedAt: now,
              ),
            );
        if (s.studentId != null) {
          await charger?.charge(examId: s.examId, studentId: s.studentId, sheetId: sheetId);
        }
        await _db.batch((b) {
          b.insertAll(_db.studentAnswers, [
            for (var i = 0; i < reading.questions.length; i++)
              StudentAnswersCompanion.insert(
                answerSheetId: sheetId,
                questionNo: i + 1,
                detectedState: reading.questions[i].state.name,
                detectedMask: Value(reading.questions[i].mask),
                bubbleScores: jsonEncode(reading.questions[i].scores),
                confidence: reading.questions[i].confidence.clamp(0.0, 1.0),
                finalMask: Value(s.finalMasks[i + 1]),
                resolvedBy: Value(s.overridden.contains(i + 1) ? 'instructor' : 'engine'),
              ),
          ]);
        });
        if (s.sessionId != null) {
          await _db.customStatement(
            'UPDATE scan_sessions SET sheets_finalized = sheets_finalized + 1 WHERE id = ?',
            [s.sessionId],
          );
        }
        await _audit.record(
          event: s.replaceSheetId == null ? 'answer_sheet.scanned' : 'answer_sheet.rescanned',
          entityType: 'answer_sheet',
          entityId: sheetId,
          examinationId: s.examId,
          details: {
            'flagged': reading.flaggedCount,
            'overridden': s.overridden.toList()..sort(),
            if (s.replaceSheetId != null) 'replaces': s.replaceSheetId,
          },
        );
        final exam = await (_db.select(_db.examinations)..where((t) => t.id.equals(s.examId))).getSingle();
        if (grading != null && exam.status == 'ready' && s.studentId != null) {
          await grading!.finalize(sheetId);
        }
      });
    } catch (_) {
      await File(imagePath).delete().catchError((_) => File(imagePath));
      rethrow;
    }
    return sheetId;
  }

  /// Gives a paper that was saved without a student to [studentId]. The scan
  /// is counted against the plan now (free when this student's paper was
  /// already counted); a refused charge changes nothing. An earlier paper of
  /// the same student is replaced (kept as `superseded`). The paper is graded
  /// right away when the examination's answer keys are complete.
  Future<void> assignStudent(String sheetId, String studentId) {
    return _db.transaction(() async {
      final sheet = await (_db.select(_db.answerSheets)..where((t) => t.id.equals(sheetId))).getSingleOrNull();
      if (sheet == null) throw const DataException('This paper no longer exists.');
      if (sheet.status != 'needs_review') throw const DataException('This paper was replaced or removed.');
      if (sheet.studentId != null) throw const DataException('This paper already has a student.');
      final student = await (_db.select(_db.students)..where((t) => t.id.equals(studentId))).getSingleOrNull();
      if (student == null || student.deletedAt != null) {
        throw const DataException('Choose a student from your class lists.');
      }
      await charger?.charge(examId: sheet.examinationId, studentId: studentId, sheetId: sheetId);
      final now = clock.now();
      final replaced = await (_db.update(_db.answerSheets)
            ..where((t) =>
                t.examinationId.equals(sheet.examinationId) &
                t.studentId.equals(studentId) &
                t.status.isIn(const ['needs_review', 'finalized'])))
          .write(AnswerSheetsCompanion(status: const Value('superseded'), updatedAt: Value(now)));
      await (_db.update(_db.answerSheets)..where((t) => t.id.equals(sheetId)))
          .write(AnswerSheetsCompanion(studentId: Value(studentId), updatedAt: Value(now)));
      await _audit.record(
        event: 'answer_sheet.assigned',
        entityType: 'answer_sheet',
        entityId: sheetId,
        examinationId: sheet.examinationId,
        details: {'student': studentId, 'replacedPapers': replaced},
      );
      final exam = await (_db.select(_db.examinations)..where((t) => t.id.equals(sheet.examinationId))).getSingle();
      if (grading != null && exam.status == 'ready') {
        await grading!.finalize(sheetId);
      }
    });
  }

  /// Current papers (not superseded) of an examination, newest first.
  Stream<List<ScannedPaper>> watchPapers(String examId) {
    final query = _db.select(_db.answerSheets).join([
      leftOuterJoin(_db.students, _db.students.id.equalsExp(_db.answerSheets.studentId)),
      leftOuterJoin(
        _db.examinationVersions,
        _db.examinationVersions.id.equalsExp(_db.answerSheets.examinationVersionId),
      ),
      leftOuterJoin(
        _db.examinationResults,
        _db.examinationResults.answerSheetId.equalsExp(_db.answerSheets.id) &
            _db.examinationResults.isCurrent.equals(true),
      ),
    ])
      ..where(_db.answerSheets.examinationId.equals(examId) &
          _db.answerSheets.status.isIn(const ['needs_review', 'finalized']))
      ..orderBy([OrderingTerm.desc(_db.answerSheets.capturedAt)]);
    return query.watch().map(
          (rows) => [
            for (final r in rows)
              ScannedPaper(
                sheet: r.readTable(_db.answerSheets),
                student: r.readTableOrNull(_db.students),
                versionLabel: r.readTableOrNull(_db.examinationVersions)?.label,
                result: r.readTableOrNull(_db.examinationResults),
              ),
          ],
        );
  }
}

/// Default scans folder: `<app support>/scans`.
Future<Directory> Function() scansDirectoryIn(Future<Directory> Function() base) =>
    () async => Directory(p.join((await base()).path, 'scans'));
