import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/text.dart';
import '../../domain/categories.dart';
import '../db/app_database.dart';
import '../errors.dart';
import '../live_query.dart';

/// An activity with its category and how many scores are recorded.
class ActivityView {
  const ActivityView(this.row, this.category, {this.recorded = 0});
  final ActivityRow row;
  final CategoryRow category;
  final int recorded;

  String get id => row.id;
  int get maxPoints => row.maxPoints;
  CategoryKind get kind => CategoryKind.parse(category.kind);
  Period get period => Period.parse(row.period);

  /// "Quiz 1", "Recitation 2", "Midterm Examination", or the custom title.
  String get label => activityLabel(category.name, row.number, row.title);

  /// "QUIZ 1" as shown on the calculator.
  String get heading => label.toUpperCase();
}

String activityLabel(String categoryName, int? number, String title) {
  if (number != null) return '$categoryName $number';
  final t = title.trim();
  return t.isEmpty ? categoryName : t;
}

class ActivityInput {
  const ActivityInput({
    required this.subjectId,
    required this.categoryId,
    required this.maxPoints,
    this.number,
    this.title = '',
    this.date,
    this.period = Period.none,
    this.remarks = '',
  });

  final String subjectId;
  final String categoryId;
  final int? number;
  final String title;
  final int maxPoints;

  /// 'YYYY-MM-DD'
  final String? date;
  final Period period;
  final String remarks;
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Quizzes, recitations and examinations of each subject.
class ActivitiesRepository {
  ActivitiesRepository(this._db, {this.clock = const Clock()});

  final AppDatabase _db;
  final Clock clock;

  Future<List<ActivityView>> activities(String subjectId, {bool deleted = false, CategoryKind? kind}) async {
    final count = _db.scores.id.count();
    final q =
        _db.select(_db.activities).join([
            innerJoin(_db.categories, _db.categories.id.equalsExp(_db.activities.categoryId)),
            leftOuterJoin(_db.scores, _db.scores.activityId.equalsExp(_db.activities.id), useColumns: false),
          ])
          ..addColumns([count])
          ..where(
            _db.activities.subjectId.equals(subjectId) &
                (deleted ? _db.activities.deletedAt.isNotNull() : _db.activities.deletedAt.isNull()),
          )
          ..groupBy([_db.activities.id])
          ..orderBy([
            OrderingTerm.asc(_db.categories.sortOrder),
            OrderingTerm.asc(_db.categories.name),
            OrderingTerm.asc(_db.activities.number),
            OrderingTerm.asc(_db.activities.createdAt),
          ]);
    if (kind != null) q.where(_db.categories.kind.equals(kind.name));
    final rows = await q.get();
    return [
      for (final r in rows)
        ActivityView(r.readTable(_db.activities), r.readTable(_db.categories), recorded: r.read(count) ?? 0),
    ];
  }

  Stream<List<ActivityView>> watchActivities(String subjectId, {bool deleted = false, CategoryKind? kind}) => liveQuery(
    _db,
    [_db.activities, _db.categories, _db.scores],
    () => activities(subjectId, deleted: deleted, kind: kind),
  );

  Future<ActivityView?> activity(String id) async {
    final q = _db.select(_db.activities).join([
      innerJoin(_db.categories, _db.categories.id.equalsExp(_db.activities.categoryId)),
    ])..where(_db.activities.id.equals(id));
    final r = await q.getSingleOrNull();
    if (r == null) return null;
    final recorded =
        await (_db.selectOnly(_db.scores)
              ..addColumns([_db.scores.id.count()])
              ..where(_db.scores.activityId.equals(id)))
            .map((e) => e.read(_db.scores.id.count()) ?? 0)
            .getSingle();
    return ActivityView(r.readTable(_db.activities), r.readTable(_db.categories), recorded: recorded);
  }

  Stream<ActivityView?> watchActivity(String id) =>
      liveQuery(_db, [_db.activities, _db.categories, _db.scores], () => activity(id));

  /// The next free number for a category in a subject (Quiz 3 after Quiz 2).
  Future<int> nextNumber(String subjectId, String categoryId, {int first = 1}) async {
    final max = _db.activities.number.max();
    final v =
        await (_db.selectOnly(_db.activities)
              ..addColumns([max])
              ..where(
                _db.activities.subjectId.equals(subjectId) &
                    _db.activities.categoryId.equals(categoryId) &
                    _db.activities.deletedAt.isNull(),
              ))
            .map((r) => r.read(max))
            .getSingle();
    final next = (v ?? 0) + 1;
    return next < first ? first : next;
  }

  void _validate(ActivityInput input) {
    if (input.maxPoints < 1 || input.maxPoints > 1000) {
      throw const DataError('Maximum points must be 1 to 1000.');
    }
    if (input.number != null && (input.number! < 1 || input.number! > 999)) {
      throw const DataError('The number must be 1 to 999.');
    }
    if (cleanSpaces(input.title).length > 80) throw const DataError('The title is too long (80 letters at most).');
  }

  Future<String> createActivity(ActivityInput input) async {
    _validate(input);
    final id = newId();
    final now = clock.now();
    try {
      await _db
          .into(_db.activities)
          .insert(
            ActivitiesCompanion.insert(
              id: id,
              subjectId: input.subjectId,
              categoryId: input.categoryId,
              number: Value(input.number),
              title: Value(cleanSpaces(input.title)),
              maxPoints: input.maxPoints,
              activityDate: Value(input.date ?? isoDate(now)),
              period: Value(input.period.code),
              remarks: Value(input.remarks.trim()),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } on Exception catch (e) {
      throw DataError.fromDatabase(e, unique: 'That number is already used. Choose another number.');
    }
    return id;
  }

  /// Edits an activity. The maximum cannot go below a recorded score.
  Future<void> updateActivity(String id, ActivityInput input) async {
    _validate(input);
    try {
      await (_db.update(_db.activities)..where((t) => t.id.equals(id))).write(
        ActivitiesCompanion(
          categoryId: Value(input.categoryId),
          number: Value(input.number),
          title: Value(cleanSpaces(input.title)),
          maxPoints: Value(input.maxPoints),
          activityDate: Value(input.date),
          period: Value(input.period.code),
          remarks: Value(input.remarks.trim()),
          updatedAt: Value(clock.now()),
        ),
      );
    } on Exception catch (e) {
      throw DataError.fromDatabase(e, unique: 'That number is already used. Choose another number.');
    }
  }

  /// To "Recently deleted"; its scores are kept until it is removed for good.
  Future<void> deleteActivity(String id) => (_db.update(
    _db.activities,
  )..where((t) => t.id.equals(id))).write(ActivitiesCompanion(deletedAt: Value(clock.now())));

  Future<void> restoreActivity(String id) async {
    try {
      await (_db.update(_db.activities)..where((t) => t.id.equals(id))).write(
        ActivitiesCompanion(deletedAt: const Value(null), updatedAt: Value(clock.now())),
      );
    } on Exception catch (e) {
      throw DataError.fromDatabase(e, unique: 'Another activity now has the same number. Renumber it first.');
    }
  }

  Future<void> purgeActivity(String id) =>
      (_db.delete(_db.activities)..where((t) => t.id.equals(id) & t.deletedAt.isNotNull())).go();
}
