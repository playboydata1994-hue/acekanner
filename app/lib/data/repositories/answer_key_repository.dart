import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/text.dart';
import '../../domain/answer_mask.dart';
import '../audit/audit_logger.dart';
import '../db/app_database.dart';
import '../errors.dart';
import 'exams_repository.dart';

abstract final class KeyItemMode {
  static const String normal = 'normal';

  /// Everyone receives the points.
  static const String bonus = 'bonus';

  /// Excluded from scoring and from the total.
  static const String dropped = 'dropped';
}

/// One question of an answer key (immutable; edit with [copyWith]).
class KeyItem {
  const KeyItem({
    required this.questionNo,
    this.mask = 0,
    this.points = 1,
    this.negativePoints = 0,
    this.mode = KeyItemMode.normal,
  });

  final int questionNo;
  final int mask;
  final double points;
  final double negativePoints;
  final String mode;

  /// A normal item needs at least one accepted answer; bonus and dropped do not.
  bool get isComplete => mode != KeyItemMode.normal || mask != 0;

  KeyItem copyWith({int? mask, double? points, double? negativePoints, String? mode}) => KeyItem(
        questionNo: questionNo,
        mask: mask ?? this.mask,
        points: points ?? this.points,
        negativePoints: negativePoints ?? this.negativePoints,
        mode: mode ?? this.mode,
      );

  @override
  bool operator ==(Object other) =>
      other is KeyItem &&
      other.questionNo == questionNo &&
      other.mask == mask &&
      other.points == points &&
      other.negativePoints == negativePoints &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(questionNo, mask, points, negativePoints, mode);
}

class AnswerKeyData {
  const AnswerKeyData({
    required this.exam,
    required this.version,
    required this.key,
    required this.items,
    required this.hasFinalizedPapers,
  });

  final ExaminationRow exam;
  final ExaminationVersionRow version;
  final AnswerKeyRow key;
  final List<KeyItem> items;

  /// When true, saving creates a new key revision (with a reason) and the
  /// papers must be regraded.
  final bool hasFinalizedPapers;
}

class KeySaveResult {
  const KeySaveResult({required this.revision, required this.newRevision, required this.changed});

  final int revision;
  final bool newRevision;
  final List<int> changed;
}

/// Answer keys: loading, validation and saving with revision history.
class AnswerKeyRepository {
  AnswerKeyRepository(this._db, this._audit, this._exams, {this.clock = const Clock()});

  final AppDatabase _db;
  final AuditLogger _audit;
  final ExamsRepository _exams;
  final Clock clock;

  Future<AnswerKeyData> load(String versionId) async {
    final version = await (_db.select(_db.examinationVersions)..where((t) => t.id.equals(versionId)))
        .getSingleOrNull();
    if (version == null) throw const DataException('This exam set no longer exists.');
    final exam = await (_db.select(_db.examinations)
          ..where((t) => t.id.equals(version.examinationId)))
        .getSingle();
    final key = await _currentKey(versionId);
    final rows = await (_db.select(_db.answerKeyItems)
          ..where((t) => t.answerKeyId.equals(key.id))
          ..orderBy([(t) => OrderingTerm.asc(t.questionNo)]))
        .get();
    return AnswerKeyData(
      exam: exam,
      version: version,
      key: key,
      items: [for (final r in rows) _fromRow(r)],
      hasFinalizedPapers: await _hasFinalizedPapers(exam.id),
    );
  }

  /// Saves [items] as the key of [versionId].
  ///
  /// Before any paper is finalized the current revision is edited in place.
  /// Afterwards a new revision is created ([changeNote] required) so earlier
  /// results stay explainable; the audit log records which questions changed.
  Future<KeySaveResult> save(String versionId, List<KeyItem> items, {String? changeNote}) {
    return _db.transaction(() async {
      final current = await load(versionId);
      _validate(items, current.exam.itemCount);
      final before = {for (final i in current.items) i.questionNo: i};
      final changed = [
        for (final i in items)
          if (before[i.questionNo] != i) i.questionNo,
      ];
      if (changed.isEmpty) {
        return KeySaveResult(revision: current.key.revision, newRevision: false, changed: const []);
      }

      final examId = current.exam.id;
      if (current.hasFinalizedPapers) {
        final note = blankToNull(changeNote);
        if (note == null) {
          throw const DataException('Explain why the answer key is being changed.');
        }
        final revision = current.key.revision + 1;
        final keyId = newId();
        await (_db.update(_db.answerKeys)..where((t) => t.id.equals(current.key.id)))
            .write(const AnswerKeysCompanion(isCurrent: Value(false)));
        await _db.into(_db.answerKeys).insert(
              AnswerKeysCompanion.insert(
                id: keyId,
                examinationVersionId: versionId,
                revision: revision,
                changeNote: Value(note),
                createdAt: clock.now(),
              ),
            );
        await _db.batch((b) {
          b.insertAll(_db.answerKeyItems, [for (final i in items) _companion(keyId, i)]);
        });
        await _audit.record(
          event: 'answer_key.revised',
          entityType: 'answer_key',
          entityId: keyId,
          examinationId: examId,
          details: {
            'set': current.version.label,
            'from': current.key.revision,
            'to': revision,
            'questions': changed,
          },
        );
        await _touch(examId);
        await _exams.refreshStatus(examId);
        return KeySaveResult(revision: revision, newRevision: true, changed: changed);
      }

      for (final q in changed) {
        final item = items.firstWhere((i) => i.questionNo == q);
        await (_db.update(_db.answerKeyItems)
              ..where((t) => t.answerKeyId.equals(current.key.id) & t.questionNo.equals(q)))
            .write(_companion(current.key.id, item));
      }
      await _audit.record(
        event: 'answer_key.updated',
        entityType: 'answer_key',
        entityId: current.key.id,
        examinationId: examId,
        details: {'set': current.version.label, 'changed': changed.length},
      );
      await _touch(examId);
      await _exams.refreshStatus(examId);
      return KeySaveResult(revision: current.key.revision, newRevision: false, changed: changed);
    });
  }

  static void _validate(List<KeyItem> items, int itemCount) {
    if (items.length != itemCount) {
      throw DataException('The key must have exactly $itemCount items.');
    }
    final numbers = items.map((i) => i.questionNo).toSet();
    if (numbers.length != itemCount || numbers.any((q) => q < 1 || q > itemCount)) {
      throw DataException('Questions must be numbered 1 to $itemCount.');
    }
    for (final i in items) {
      if (!AnswerMask.isValid(i.mask)) {
        throw DataException('Question ${i.questionNo} has an invalid answer.');
      }
      if (i.points < 0 || i.points > 100 || i.negativePoints < 0 || i.negativePoints > 100) {
        throw DataException('Question ${i.questionNo}: points must be 0 to 100.');
      }
      if (![KeyItemMode.normal, KeyItemMode.bonus, KeyItemMode.dropped].contains(i.mode)) {
        throw DataException('Question ${i.questionNo} has an invalid mode.');
      }
    }
  }

  Future<AnswerKeyRow> _currentKey(String versionId) => (_db.select(_db.answerKeys)
        ..where((t) => t.examinationVersionId.equals(versionId) & t.isCurrent.equals(true)))
      .getSingle();

  Future<bool> _hasFinalizedPapers(String examId) async {
    final row = await _db.customSelect(
      "SELECT COUNT(*) AS c FROM answer_sheets WHERE examination_id = ? AND status = 'finalized'",
      variables: [Variable(examId)],
    ).getSingle();
    return row.read<int>('c') > 0;
  }

  Future<void> _touch(String examId) => (_db.update(_db.examinations)
        ..where((t) => t.id.equals(examId)))
      .write(ExaminationsCompanion(updatedAt: Value(clock.now())));

  static KeyItem _fromRow(AnswerKeyItemRow r) => KeyItem(
        questionNo: r.questionNo,
        mask: r.correctMask,
        points: r.points,
        negativePoints: r.negativePoints,
        mode: r.mode,
      );

  static AnswerKeyItemsCompanion _companion(String keyId, KeyItem i) => AnswerKeyItemsCompanion(
        answerKeyId: Value(keyId),
        questionNo: Value(i.questionNo),
        correctMask: Value(i.mask),
        points: Value(i.points),
        negativePoints: Value(i.negativePoints),
        mode: Value(i.mode),
      );
}
