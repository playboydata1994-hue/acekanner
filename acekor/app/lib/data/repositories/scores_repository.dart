import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../domain/categories.dart';
import '../../domain/grading/grade_scale.dart';
import '../../domain/grading/grading_engine.dart';
import '../../domain/scoring/ratio.dart';
import '../db/app_database.dart';
import '../errors.dart';
import '../live_query.dart';
import 'activities_repository.dart';
import 'roster_repository.dart';
import 'subjects_repository.dart';

class SaveOutcome {
  const SaveOutcome({required this.scoreId, required this.previous});
  final String scoreId;

  /// The score it replaced, or null for a new score.
  final int? previous;
}

/// One student's line on an activity sheet.
class ActivityScoreLine {
  const ActivityScoreLine(this.student, this.score);
  final StudentView student;
  final ScoreRow? score;
}

/// A recorded change, for the change history.
class HistoryView {
  const HistoryView(this.row, {this.studentName, this.activityLabel, this.subjectCode});
  final ScoreHistoryRow row;
  final String? studentName;
  final String? activityLabel;
  final String? subjectCode;
}

/// One score of a student, with its activity and subject.
class StudentScoreLine {
  const StudentScoreLine(this.score, this.activity, this.subject);
  final ScoreRow score;
  final ActivityView activity;
  final SubjectRow subject;
}

/// Saving, editing and reading scores.
class ScoresRepository {
  ScoresRepository(this._db, {this.clock = const Clock()});

  final AppDatabase _db;
  final Clock clock;

  Future<ScoreRow?> score(String activityId, String studentId) => (_db.select(
    _db.scores,
  )..where((t) => t.activityId.equals(activityId) & t.studentId.equals(studentId))).getSingleOrNull();

  Stream<ScoreRow?> watchScore(String activityId, String studentId) => (_db.select(
    _db.scores,
  )..where((t) => t.activityId.equals(activityId) & t.studentId.equals(studentId))).watchSingleOrNull();

  /// Saves (or replaces) the score of a student in an activity. Committed to
  /// disk before it returns (WAL + synchronous=FULL).
  Future<SaveOutcome> save(String activityId, String studentId, int points, {String? remarks}) async {
    if (points < 0) throw const DataError('A score cannot be negative.');
    try {
      return await _db.transaction(() async {
        final activity = await (_db.select(_db.activities)..where((t) => t.id.equals(activityId))).getSingle();
        if (points > activity.maxPoints) {
          throw DataError('The score is above the maximum of ${activity.maxPoints} points.');
        }
        final now = clock.now();
        final existing = await score(activityId, studentId);
        if (existing == null) {
          final id = newId();
          await _db
              .into(_db.scores)
              .insert(
                ScoresCompanion.insert(
                  id: id,
                  activityId: activityId,
                  studentId: studentId,
                  points: points,
                  remarks: Value(remarks?.trim() ?? ''),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
          return SaveOutcome(scoreId: id, previous: null);
        }
        await (_db.update(_db.scores)..where((t) => t.id.equals(existing.id))).write(
          ScoresCompanion(
            points: Value(points),
            remarks: remarks == null ? const Value.absent() : Value(remarks.trim()),
            updatedAt: Value(now),
          ),
        );
        return SaveOutcome(scoreId: existing.id, previous: existing.points);
      });
    } on DataError {
      rethrow;
    } on Exception catch (e) {
      throw DataError.fromDatabase(e);
    }
  }

  Future<void> updateScore(String scoreId, int points, {String? remarks}) async {
    try {
      await (_db.update(_db.scores)..where((t) => t.id.equals(scoreId))).write(
        ScoresCompanion(
          points: Value(points),
          remarks: remarks == null ? const Value.absent() : Value(remarks.trim()),
          updatedAt: Value(clock.now()),
        ),
      );
    } on Exception catch (e) {
      throw DataError.fromDatabase(e);
    }
  }

  /// Deletes a score (the change history keeps a record of it).
  Future<void> deleteScore(String scoreId) => (_db.delete(_db.scores)..where((t) => t.id.equals(scoreId))).go();

  /// Students of the subject (optionally one section) with their score.
  /// Students who have a score but are no longer enrolled are listed too.
  Future<List<ActivityScoreLine>> activitySheet(String activityId, String subjectId, {String? sectionId}) async {
    final roster = RosterRepository(_db, clock: clock);
    final enrolled = await roster.students(subjectId: subjectId, sectionId: sectionId);
    final scores = await (_db.select(_db.scores)..where((t) => t.activityId.equals(activityId))).get();
    final byStudent = {for (final s in scores) s.studentId: s};
    final lines = [for (final s in enrolled) ActivityScoreLine(s, byStudent.remove(s.id))];
    for (final orphan in byStudent.values) {
      final s = await roster.student(orphan.studentId);
      if (s == null || s.row.deletedAt != null) continue;
      if (sectionId != null && s.row.sectionId != sectionId) continue;
      lines.add(ActivityScoreLine(s, orphan));
    }
    return lines;
  }

  Stream<List<ActivityScoreLine>> watchActivitySheet(String activityId, String subjectId, {String? sectionId}) =>
      liveQuery(_db, [
        _db.scores,
        _db.students,
        _db.subjectStudents,
        _db.sections,
      ], () => activitySheet(activityId, subjectId, sectionId: sectionId));

  /// For continuous entry: the next student (alphabetical, after [afterStudentId])
  /// in the class list who has no score yet in [activityId]; wraps around.
  Future<StudentView?> nextWithoutScore(
    String activityId,
    String subjectId, {
    String? sectionId,
    String? afterStudentId,
  }) async {
    final sheet = await activitySheet(activityId, subjectId, sectionId: sectionId);
    final all = sheet.map((l) => l.student.id).toList();
    final pos = afterStudentId == null ? -1 : all.indexOf(afterStudentId);
    final without = [
      for (final l in sheet)
        if (l.score == null && l.student.id != afterStudentId) l.student,
    ];
    if (without.isEmpty) return null;
    return without.firstWhere((s) => all.indexOf(s.id) > pos, orElse: () => without.first);
  }

  /// Change history, newest first.
  Future<List<HistoryView>> history({String? activityId, String? studentId, int limit = 200}) async {
    final where = <String>[];
    final vars = <Variable<Object>>[];
    if (activityId != null) {
      where.add('h.activity_id = ?');
      vars.add(Variable.withString(activityId));
    }
    if (studentId != null) {
      where.add('h.student_id = ?');
      vars.add(Variable.withString(studentId));
    }
    final rows = await _db
        .customSelect(
          '''
      SELECT h.*, st.first_name, st.last_name, st.suffix,
             a.number AS a_number, a.title AS a_title, c.name AS c_name, s.code AS s_code
      FROM score_history h
      LEFT JOIN students st ON st.id = h.student_id
      LEFT JOIN activities a ON a.id = h.activity_id
      LEFT JOIN categories c ON c.id = a.category_id
      LEFT JOIN subjects s ON s.id = a.subject_id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY h.at DESC, h.id DESC
      LIMIT $limit
      ''',
          variables: vars,
          readsFrom: {_db.scoreHistory, _db.students, _db.activities, _db.categories, _db.subjects},
        )
        .get();
    return [
      for (final r in rows)
        HistoryView(
          _db.scoreHistory.map(r.data),
          studentName: r.readNullable<String>('first_name') == null
              ? null
              : '${r.read<String>('first_name')} ${r.read<String>('last_name')}',
          activityLabel: r.readNullable<String>('c_name') == null
              ? null
              : activityLabel(r.read<String>('c_name'), r.readNullable<int>('a_number'), r.read<String>('a_title')),
          subjectCode: r.readNullable<String>('s_code'),
        ),
    ];
  }

  Stream<List<HistoryView>> watchHistory({String? activityId, String? studentId}) => liveQuery(_db, [
    _db.scoreHistory,
    _db.students,
    _db.activities,
  ], () => history(activityId: activityId, studentId: studentId));

  /// Every score of a student, across subjects.
  Future<List<StudentScoreLine>> studentScores(String studentId) async {
    final q =
        _db.select(_db.scores).join([
            innerJoin(_db.activities, _db.activities.id.equalsExp(_db.scores.activityId)),
            innerJoin(_db.categories, _db.categories.id.equalsExp(_db.activities.categoryId)),
            innerJoin(_db.subjects, _db.subjects.id.equalsExp(_db.activities.subjectId)),
          ])
          ..where(
            _db.scores.studentId.equals(studentId) &
                _db.activities.deletedAt.isNull() &
                _db.subjects.deletedAt.isNull(),
          )
          ..orderBy([
            OrderingTerm.asc(_db.subjects.code),
            OrderingTerm.asc(_db.categories.sortOrder),
            OrderingTerm.asc(_db.activities.number),
          ]);
    return [
      for (final r in await q.get())
        StudentScoreLine(
          r.readTable(_db.scores),
          ActivityView(r.readTable(_db.activities), r.readTable(_db.categories)),
          r.readTable(_db.subjects),
        ),
    ];
  }

  Stream<List<StudentScoreLine>> watchStudentScores(String studentId) =>
      liveQuery(_db, [_db.scores, _db.activities, _db.subjects], () => studentScores(studentId));
}

// ---------------------------------------------------------------- gradebook

/// Class statistics of one activity.
class ActivityStats {
  const ActivityStats({
    required this.recorded,
    required this.total,
    this.average,
    this.highest,
    this.lowest,
    this.passed,
  });
  final int recorded;
  final int total;

  /// Mean of the recorded percentages (missing scores excluded).
  final Ratio? average;
  final int? highest;
  final int? lowest;

  /// Recorded scores at or above the passing percentage.
  final int? passed;
}

/// Everything needed to show or export one subject's grades.
class Gradebook {
  Gradebook({
    required this.subject,
    required this.weights,
    required this.scale,
    required this.activities,
    required this.students,
    required this.scores,
    required this.engine,
  });

  final SubjectRow subject;
  final List<WeightView> weights;
  final GradeScale? scale;
  final List<ActivityView> activities;
  final List<StudentView> students;

  /// student id → activity id → points.
  final Map<String, Map<String, int>> scores;
  final GradingEngine engine;

  late final Map<String, StudentGrade> grades = {
    for (final s in students)
      s.id: engine.grade([
        for (final a in activities) GradeActivity(id: a.id, categoryId: a.row.categoryId, maxPoints: a.maxPoints),
      ], scores[s.id] ?? const {}),
  };

  int? scoreOf(String studentId, String activityId) => scores[studentId]?[activityId];

  ActivityStats stats(ActivityView a) {
    final values = [for (final s in students) scoreOf(s.id, a.id)].whereType<int>().toList();
    if (values.isEmpty) return ActivityStats(recorded: 0, total: students.length);
    final avg = Ratio.of(values.fold(0, (s, v) => s + v) * 100, values.length * a.maxPoints);
    final passing = scale?.passingBp ?? 7500;
    return ActivityStats(
      recorded: values.length,
      total: students.length,
      average: avg,
      highest: values.reduce((x, y) => x > y ? x : y),
      lowest: values.reduce((x, y) => x < y ? x : y),
      passed: values.where((v) => v * 10000 >= passing * a.maxPoints).length,
    );
  }

  /// Mean of the students' weighted grades (students without a grade excluded).
  Ratio? get classAverage {
    final list = grades.values.map((g) => g.percent).whereType<Ratio>().toList();
    if (list.isEmpty) return null;
    return list.fold(Ratio.zero, (s, r) => s + r) / Ratio.of(list.length);
  }
}

/// Builds gradebooks for records and reports.
class GradebookService {
  GradebookService(this._db, {this.clock = const Clock()});

  final AppDatabase _db;
  final Clock clock;

  Future<Gradebook?> build(
    String subjectId, {
    String? sectionId,
    Period? period,
    Set<String>? activityIds,
    Set<CategoryKind>? kinds,
    Set<String>? studentIds,
  }) async {
    final subjects = SubjectsRepository(_db, clock: clock);
    final subject = await subjects.subject(subjectId);
    if (subject == null) return null;
    final weights = await subjects.weights(subjectId);
    final scale = (await subjects.scale(subject.gradeScaleId))?.toScale();
    var activities = await ActivitiesRepository(_db, clock: clock).activities(subjectId);
    if (period != null && period != Period.none) activities = activities.where((a) => a.period == period).toList();
    if (activityIds != null) activities = activities.where((a) => activityIds.contains(a.id)).toList();
    if (kinds != null) activities = activities.where((a) => kinds.contains(a.kind)).toList();
    var students = await RosterRepository(_db, clock: clock).students(subjectId: subjectId, sectionId: sectionId);
    if (studentIds != null) students = students.where((s) => studentIds.contains(s.id)).toList();

    final ids = activities.map((a) => a.id).toList();
    final rows = ids.isEmpty
        ? <ScoreRow>[]
        : await (_db.select(_db.scores)..where((t) => t.activityId.isIn(ids))).get();
    final scores = <String, Map<String, int>>{};
    for (final r in rows) {
      scores.putIfAbsent(r.studentId, () => {})[r.activityId] = r.points;
    }
    final engine = GradingEngine(
      categories: [
        for (final w in weights)
          if (w.weightBp > 0)
            GradeCategory(id: w.category.id, name: w.category.name, kind: w.kind, weightBp: w.weightBp),
      ],
      method: CombineMethod.parse(subject.combineMethod),
      scale: scale,
    );
    return Gradebook(
      subject: subject,
      weights: weights,
      scale: scale,
      activities: activities,
      students: students,
      scores: scores,
      engine: engine,
    );
  }

  Stream<Gradebook?> watch(String subjectId, {String? sectionId}) => liveQuery(_db, [
    _db.subjects,
    _db.subjectWeights,
    _db.activities,
    _db.scores,
    _db.students,
    _db.subjectStudents,
    _db.gradeScales,
    _db.gradeScaleRows,
    _db.categories,
  ], () => build(subjectId, sectionId: sectionId));
}
