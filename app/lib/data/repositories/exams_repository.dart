import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/text.dart';
import '../../domain/short_code.dart';
import '../audit/audit_logger.dart';
import '../db/app_database.dart';
import '../errors.dart';
import '../live_query.dart';
import 'grading_repository.dart';

/// Version (set) labels in order.
const List<String> versionLabels = ['A', 'B', 'C', 'D', 'E'];

abstract final class ExamStatus {
  static const String draft = 'draft';
  static const String ready = 'ready';
  static const String closed = 'closed';
}

abstract final class MultipleMarkPolicy {
  /// Counts as a wrong answer (negative marking applies).
  static const String incorrect = 'incorrect';

  /// Scores zero (no negative marking).
  static const String zero = 'zero';
}

class ExamInput {
  const ExamInput({
    required this.title,
    required this.itemCount,
    this.subjectId,
    this.examDate,
    this.versionCount = 1,
    this.sectionIds = const [],
    this.passingPercentage = 75,
    this.pointsPerItem = 1,
    this.negativePoints = 0,
    this.multipleMarkPolicy = MultipleMarkPolicy.incorrect,
    this.allowNegativeTotal = false,
    this.studentIdDigits = 10,
  });

  final String title;
  final int itemCount;
  final String? subjectId;
  final DateTime? examDate;
  final int versionCount;
  final List<String> sectionIds;
  final double passingPercentage;

  /// Points and penalty given to every item when the exam is created (and to
  /// items added later). Individual items can be changed in the answer key.
  final double pointsPerItem;
  final double negativePoints;
  final String multipleMarkPolicy;
  final bool allowNegativeTotal;
  final int studentIdDigits;

  void validate() {
    if (cleanSpaces(title).isEmpty) throw const DataException('Enter the examination title.');
    if (!AppConstants.itemCounts.contains(itemCount)) {
      throw const DataException('Choose 50, 75 or 100 items.');
    }
    if (versionCount < 1 || versionCount > versionLabels.length) {
      throw const DataException('Choose 1 to 4 exam sets.');
    }
    if (passingPercentage < 0 || passingPercentage > 100) {
      throw const DataException('Passing percentage must be 0 to 100.');
    }
    if (pointsPerItem < 0 || pointsPerItem > 100 || negativePoints < 0 || negativePoints > 100) {
      throw const DataException('Points must be 0 to 100.');
    }
    if (studentIdDigits < 4 || studentIdDigits > 12) {
      throw const DataException('Student numbers must have 4 to 12 digits.');
    }
  }
}

class ExamListItem {
  const ExamListItem({
    required this.exam,
    this.subjectCode,
    this.subjectTitle,
    required this.versionCount,
    required this.paperCount,
  });

  final ExaminationRow exam;
  final String? subjectCode;
  final String? subjectTitle;
  final int versionCount;
  final int paperCount;
}

class VersionKeyStatus {
  const VersionKeyStatus({
    required this.version,
    required this.keyId,
    required this.revision,
    required this.completeCount,
    required this.itemTotal,
  });

  final ExaminationVersionRow version;
  final String keyId;
  final int revision;
  final int completeCount;
  final int itemTotal;

  bool get isComplete => itemTotal > 0 && completeCount == itemTotal;
}

class ExamDetail {
  const ExamDetail({
    required this.exam,
    required this.subject,
    required this.sections,
    required this.versions,
    required this.paperCount,
    required this.structureLocked,
  });

  final ExaminationRow exam;
  final SubjectRow? subject;
  final List<SectionRow> sections;
  final List<VersionKeyStatus> versions;
  final int paperCount;

  /// True once sheets were printed or scanned: item count and sets are fixed.
  final bool structureLocked;

  bool get keysComplete => versions.isNotEmpty && versions.every((v) => v.isComplete);
}

/// Examinations, their sets (versions) and section assignments.
class ExamsRepository {
  ExamsRepository(this._db, this._audit, {this.grading, this.scansDirectory, this.clock = const Clock()});

  final AppDatabase _db;
  final AuditLogger _audit;

  /// Folder holding the corrected sheet images (`<scans>/<exam id>/`), removed
  /// when an examination is deleted permanently.
  final Future<Directory> Function()? scansDirectory;

  /// Re-scores papers when scoring rules change.
  final GradingRepository? grading;
  final Clock clock;

  Stream<List<ExamListItem>> watchActive() => _db.activeExaminationList().watch().map(
        (rows) => [
          for (final r in rows)
            ExamListItem(
              exam: r.e,
              subjectCode: r.subjectCode,
              subjectTitle: r.subjectTitle,
              versionCount: r.versionCount,
              paperCount: r.paperCount,
            ),
        ],
      );

  Stream<List<ExamListItem>> watchDeleted() => _db.deletedExaminationList().watch().map(
        (rows) => [
          for (final r in rows)
            ExamListItem(
              exam: r.e,
              subjectCode: r.subjectCode,
              subjectTitle: r.subjectTitle,
              versionCount: r.versionCount,
              paperCount: r.paperCount,
            ),
        ],
      );

  /// Re-emits whenever anything shown on the examination screen changes.
  Stream<ExamDetail?> watchDetail(String id) => liveQuery(
        _db,
        [
          _db.examinations,
          _db.examinationVersions,
          _db.answerKeys,
          _db.answerKeyItems,
          _db.examinationSections,
          _db.sections,
          _db.subjects,
          _db.answerSheets,
          _db.printedSheets,
        ],
        () => loadDetail(id),
      );

  Future<ExamDetail?> loadDetail(String id) async {
    final exam = await _exam(id);
    if (exam == null) return null;
    final subject = exam.subjectId == null
        ? null
        : await (_db.select(_db.subjects)..where((t) => t.id.equals(exam.subjectId!)))
            .getSingleOrNull();
    final sections = await _db.examinationSectionList(examinationId: id).get();
    final versions = await _db.versionKeyStatus(examinationId: id).get();
    final papers = await _count(
      "SELECT COUNT(*) AS c FROM answer_sheets WHERE examination_id = ? AND status IN ('needs_review', 'finalized')",
      id,
    );
    return ExamDetail(
      exam: exam,
      subject: subject,
      sections: sections,
      versions: [
        for (final v in versions)
          VersionKeyStatus(
            version: v.v,
            keyId: v.keyId,
            revision: v.revision,
            completeCount: v.completeCount,
            itemTotal: v.itemTotal,
          ),
      ],
      paperCount: papers,
      structureLocked: await isStructureLocked(id),
    );
  }

  Future<bool> isStructureLocked(String examId) async {
    final printed =
        await _count('SELECT COUNT(*) AS c FROM printed_sheets WHERE examination_id = ?', examId);
    final scanned =
        await _count('SELECT COUNT(*) AS c FROM answer_sheets WHERE examination_id = ?', examId);
    return printed > 0 || scanned > 0;
  }

  Future<String> create(ExamInput input) {
    input.validate();
    return _db.transaction(() async {
      final now = clock.now();
      final id = newId();
      await _db.into(_db.examinations).insert(
            ExaminationsCompanion.insert(
              id: id,
              shortCode: await _uniqueShortCode(),
              title: cleanSpaces(input.title),
              subjectId: Value(input.subjectId),
              examDate: Value(input.examDate),
              itemCount: input.itemCount,
              passingPercentage: Value(input.passingPercentage),
              multipleMarkPolicy: Value(input.multipleMarkPolicy),
              allowNegativeTotal: Value(input.allowNegativeTotal),
              studentIdDigits: Value(input.studentIdDigits),
              createdAt: now,
              updatedAt: now,
            ),
          );
      for (var v = 0; v < input.versionCount; v++) {
        await _addVersion(
          examId: id,
          label: versionLabels[v],
          itemCount: input.itemCount,
          points: input.pointsPerItem,
          negative: input.negativePoints,
        );
      }
      await _setSections(id, input.sectionIds);
      await _audit.record(
        event: 'examination.created',
        entityType: 'examination',
        entityId: id,
        examinationId: id,
        details: {'items': input.itemCount, 'sets': input.versionCount},
      );
      return id;
    });
  }

  /// Saves edits. The item count and number of sets can change only while no
  /// sheets have been printed or scanned for this examination.
  Future<void> update(String id, ExamInput input) {
    input.validate();
    return _db.transaction(() async {
      final exam = await _exam(id);
      if (exam == null) throw const DataException('This examination no longer exists.');
      final versions = await (_db.select(_db.examinationVersions)
            ..where((t) => t.examinationId.equals(id))
            ..orderBy([(t) => OrderingTerm.asc(t.label)]))
          .get();
      final structureChanged =
          exam.itemCount != input.itemCount || versions.length != input.versionCount;
      if (structureChanged && await isStructureLocked(id)) {
        throw const LockedException(
          'Answer sheets for this examination were already printed or scanned, so '
          'the number of items and sets can no longer change.',
        );
      }

      await (_db.update(_db.examinations)..where((t) => t.id.equals(id))).write(
            ExaminationsCompanion(
              title: Value(cleanSpaces(input.title)),
              subjectId: Value(input.subjectId),
              examDate: Value(input.examDate),
              itemCount: Value(input.itemCount),
              questionsUsed: Value(
                exam.questionsUsed != null && exam.questionsUsed! < input.itemCount ? exam.questionsUsed : null,
              ),
              passingPercentage: Value(input.passingPercentage),
              multipleMarkPolicy: Value(input.multipleMarkPolicy),
              allowNegativeTotal: Value(input.allowNegativeTotal),
              studentIdDigits: Value(input.studentIdDigits),
              updatedAt: Value(clock.now()),
            ),
          );

      if (exam.itemCount != input.itemCount) {
        for (final v in versions) {
          await _resizeKey(v.id, input.itemCount, input.pointsPerItem, input.negativePoints);
        }
      }
      if (versions.length < input.versionCount) {
        for (var i = versions.length; i < input.versionCount; i++) {
          await _addVersion(
            examId: id,
            label: versionLabels[i],
            itemCount: input.itemCount,
            points: input.pointsPerItem,
            negative: input.negativePoints,
          );
        }
      } else if (versions.length > input.versionCount) {
        final removed = versions.sublist(input.versionCount).map((v) => v.id).toList();
        await (_db.delete(_db.examinationVersions)..where((t) => t.id.isIn(removed))).go();
      }
      await _setSections(id, input.sectionIds);
      await refreshStatus(id);
      final rulesChanged = exam.passingPercentage != input.passingPercentage ||
          exam.multipleMarkPolicy != input.multipleMarkPolicy ||
          exam.allowNegativeTotal != input.allowNegativeTotal;
      if (rulesChanged) await grading?.regrade(id, reason: 'examination.rules_changed');
      await _audit.record(
        event: 'examination.updated',
        entityType: 'examination',
        entityId: id,
        examinationId: id,
        details: {
          'items': input.itemCount,
          'sets': input.versionCount,
          'structureChanged': structureChanged,
        },
      );
    });
  }

  /// How many questions of the sheet are used: questions 1..[used] are in the
  /// answer key and graded; later ones are ignored (e.g. 90 on a 100-item
  /// sheet). Null or the full item count means all. Graded papers are
  /// re-scored and waiting papers graded when the key becomes complete.
  Future<void> setQuestionsUsed(String examId, int? used) async {
    await _db.transaction(() async {
      final exam = await _exam(examId);
      if (exam == null) throw const DataException('This examination no longer exists.');
      if (used != null && (used < 1 || used > exam.itemCount)) {
        throw DataException('Choose 1 to ${exam.itemCount} questions.');
      }
      final value = used == null || used == exam.itemCount ? null : used;
      if (value == exam.questionsUsed) return;
      await (_db.update(_db.examinations)..where((t) => t.id.equals(examId)))
          .write(ExaminationsCompanion(questionsUsed: Value(value), updatedAt: Value(clock.now())));
      await _audit.record(
        event: 'examination.questions_used',
        entityType: 'examination',
        entityId: examId,
        examinationId: examId,
        details: {'from': exam.scoredItems, 'to': value ?? exam.itemCount},
      );
      await refreshStatus(examId);
      // Re-score only with a complete key; otherwise papers are re-scored when
      // the key is finished.
      if ((await _exam(examId))?.status == ExamStatus.ready) {
        await grading?.regrade(examId, reason: 'examination.questions_used');
        await grading?.gradePending(examId);
      }
    });
  }

  /// Sets status to ready when every item of every set's current key is
  /// complete, otherwise draft. A closed examination stays closed.
  Future<void> refreshStatus(String examId) async {
    final exam = await _exam(examId);
    if (exam == null || exam.status == ExamStatus.closed) return;
    final incomplete = await _db.incompleteKeyItemCount(examinationId: examId).getSingle();
    final status = incomplete == 0 ? ExamStatus.ready : ExamStatus.draft;
    if (status != exam.status) {
      await (_db.update(_db.examinations)..where((t) => t.id.equals(examId)))
          .write(ExaminationsCompanion(status: Value(status)));
    }
  }

  Future<void> moveToTrash(String id) => _db.transaction(() async {
        await (_db.update(_db.examinations)..where((t) => t.id.equals(id)))
            .write(ExaminationsCompanion(deletedAt: Value(clock.now())));
        await _audit.record(
          event: 'examination.trashed',
          entityType: 'examination',
          entityId: id,
          examinationId: id,
        );
      });

  Future<void> restore(String id) => _db.transaction(() async {
        await (_db.update(_db.examinations)..where((t) => t.id.equals(id)))
            .write(const ExaminationsCompanion(deletedAt: Value(null)));
        await _audit.record(
          event: 'examination.restored',
          entityType: 'examination',
          entityId: id,
          examinationId: id,
        );
      });

  /// Permanently deletes an examination in the trash, with all its sheets,
  /// answers, results and corrected sheet images. Scan charges in the ledger
  /// are kept.
  Future<void> deletePermanently(String id) async {
    await _purge(id);
    final base = scansDirectory;
    if (base == null) return;
    final dir = Directory(p.join((await base()).path, id));
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } on FileSystemException {
      // The rows are gone; a leftover image is retried on the next purge of this folder.
    }
  }

  Future<void> _purge(String id) => _db.transaction(() async {
        final exam = await _exam(id);
        if (exam == null) return;
        if (exam.deletedAt == null) {
          throw const DataException('Move the examination to the trash first.');
        }
        final papers = await _count(
          'SELECT COUNT(*) AS c FROM answer_sheets WHERE examination_id = ?',
          id,
        );
        await (_db.delete(_db.examinations)..where((t) => t.id.equals(id))).go();
        await _audit.record(
          event: 'examination.purged',
          entityType: 'examination',
          entityId: id,
          examinationId: id,
          details: {'papers': papers},
        );
      });

  // ----------------------------------------------------------------- helpers

  Future<ExaminationRow?> _exam(String id) =>
      (_db.select(_db.examinations)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> _count(String sql, String arg) async =>
      (await _db.customSelect(sql, variables: [Variable(arg)]).getSingle()).read<int>('c');

  Future<String> _uniqueShortCode() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final code = ShortCode.generate();
      final taken = await _count('SELECT COUNT(*) AS c FROM examinations WHERE short_code = ?', code);
      if (taken == 0) return code;
    }
    throw StateError('Could not generate a unique examination code.');
  }

  Future<void> _addVersion({
    required String examId,
    required String label,
    required int itemCount,
    required double points,
    required double negative,
  }) async {
    final now = clock.now();
    final versionId = newId();
    await _db.into(_db.examinationVersions).insert(
          ExaminationVersionsCompanion.insert(
            id: versionId,
            examinationId: examId,
            label: label,
            createdAt: now,
          ),
        );
    final keyId = newId();
    await _db.into(_db.answerKeys).insert(
          AnswerKeysCompanion.insert(
            id: keyId,
            examinationVersionId: versionId,
            revision: 1,
            createdAt: now,
          ),
        );
    await _db.batch((b) {
      b.insertAll(_db.answerKeyItems, [
        for (var q = 1; q <= itemCount; q++)
          AnswerKeyItemsCompanion.insert(
            answerKeyId: keyId,
            questionNo: q,
            points: Value(points),
            negativePoints: Value(negative),
          ),
      ]);
    });
  }

  Future<void> _resizeKey(String versionId, int itemCount, double points, double negative) async {
    final key = await (_db.select(_db.answerKeys)
          ..where((t) => t.examinationVersionId.equals(versionId) & t.isCurrent.equals(true)))
        .getSingle();
    await (_db.delete(_db.answerKeyItems)
          ..where((t) => t.answerKeyId.equals(key.id) & t.questionNo.isBiggerThanValue(itemCount)))
        .go();
    final existing = await _count(
      'SELECT COUNT(*) AS c FROM answer_key_items WHERE answer_key_id = ?',
      key.id,
    );
    await _db.batch((b) {
      b.insertAll(_db.answerKeyItems, [
        for (var q = existing + 1; q <= itemCount; q++)
          AnswerKeyItemsCompanion.insert(
            answerKeyId: key.id,
            questionNo: q,
            points: Value(points),
            negativePoints: Value(negative),
          ),
      ]);
    });
  }

  Future<void> _setSections(String examId, List<String> sectionIds) async {
    await (_db.delete(_db.examinationSections)..where((t) => t.examinationId.equals(examId))).go();
    if (sectionIds.isEmpty) return;
    await _db.batch((b) {
      b.insertAll(_db.examinationSections, [
        for (final s in sectionIds.toSet())
          ExaminationSectionsCompanion.insert(examinationId: examId, sectionId: s),
      ]);
    });
  }
}
