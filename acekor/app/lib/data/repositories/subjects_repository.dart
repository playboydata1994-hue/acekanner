import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/text.dart';
import '../../domain/categories.dart';
import '../../domain/grading/default_scale.dart';
import '../../domain/grading/grade_scale.dart';
import '../db/app_database.dart';
import '../errors.dart';
import '../live_query.dart';

class SubjectSummary {
  const SubjectSummary(this.subject, {required this.students, required this.activities, required this.weightTotalBp});
  final SubjectRow subject;
  final int students;
  final int activities;
  final int weightTotalBp;

  String get id => subject.id;

  /// "IT 101 · Introduction to Computing"
  String get label => subject.title.isEmpty ? subject.code : '${subject.code} · ${subject.title}';
  String get term => [
    if (subject.academicYear.isNotEmpty) subject.academicYear,
    if (subject.semester.isNotEmpty) subject.semester,
  ].join(' · ');
}

class SubjectInput {
  const SubjectInput({required this.code, this.title = '', this.academicYear = '', this.semester = ''});
  final String code;
  final String title;
  final String academicYear;
  final String semester;
}

/// A category with its weight in one subject.
class WeightView {
  const WeightView(this.category, this.weightBp);
  final CategoryRow category;
  final int weightBp;
  CategoryKind get kind => CategoryKind.parse(category.kind);
}

/// A grade scale with its rows.
class ScaleView {
  const ScaleView(this.row, this.items);
  final GradeScaleRow row;
  final List<ScaleItem> items;

  GradeScale toScale() => GradeScale(
    id: row.id,
    name: row.name,
    items: items,
    passingBp: row.passingBp,
    roundBeforeLookup: row.roundBeforeLookup,
  );
}

/// Subjects, enrolment, assessment categories, weights and grade scales.
class SubjectsRepository {
  SubjectsRepository(this._db, {this.clock = const Clock()});

  final AppDatabase _db;
  final Clock clock;

  // ------------------------------------------------------------ subjects

  Future<List<SubjectSummary>> subjects({bool deleted = false}) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT s.*,
        (SELECT count(*) FROM subject_students e JOIN students st ON st.id = e.student_id
           WHERE e.subject_id = s.id AND st.deleted_at IS NULL) AS n_students,
        (SELECT count(*) FROM activities a WHERE a.subject_id = s.id AND a.deleted_at IS NULL) AS n_activities,
        (SELECT ifnull(sum(w.weight_bp), 0) FROM subject_weights w JOIN categories c ON c.id = w.category_id
           WHERE w.subject_id = s.id AND c.deleted_at IS NULL) AS weight_total
      FROM subjects s
      WHERE ${deleted ? 's.deleted_at IS NOT NULL' : 's.deleted_at IS NULL'}
      ORDER BY s.code COLLATE NOCASE, s.academic_year DESC, s.semester
      ''',
          readsFrom: {
            _db.subjects,
            _db.subjectStudents,
            _db.activities,
            _db.subjectWeights,
            _db.students,
            _db.categories,
          },
        )
        .get();
    return [
      for (final r in rows)
        SubjectSummary(
          _db.subjects.map(r.data),
          students: r.read<int>('n_students'),
          activities: r.read<int>('n_activities'),
          weightTotalBp: r.read<int>('weight_total'),
        ),
    ];
  }

  Stream<List<SubjectSummary>> watchSubjects({bool deleted = false}) => liveQuery(_db, [
    _db.subjects,
    _db.subjectStudents,
    _db.activities,
    _db.subjectWeights,
    _db.students,
    _db.categories,
  ], () => subjects(deleted: deleted));

  Future<SubjectRow?> subject(String id) => (_db.select(_db.subjects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<SubjectRow?> watchSubject(String id) =>
      (_db.select(_db.subjects)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Creates a subject with the default weights (Quizzes 30 %, Recitation 20 %,
  /// Midterm 20 %, Final 20 %, Practical 10 %) and the default 1.00-5.00 scale.
  Future<String> createSubject(SubjectInput input) async {
    final code = cleanSpaces(input.code);
    if (code.isEmpty) throw const DataError('Enter the subject code, e.g. IT 101.');
    final id = newId();
    final now = clock.now();
    try {
      await _db.transaction(() async {
        await _db
            .into(_db.subjects)
            .insert(
              SubjectsCompanion.insert(
                id: id,
                code: code,
                title: Value(cleanSpaces(input.title)),
                academicYear: Value(cleanSpaces(input.academicYear)),
                semester: Value(cleanSpaces(input.semester)),
                gradeScaleId: const Value(DefaultScale.id),
                gradingActive: const Value(true),
                createdAt: now,
                updatedAt: now,
              ),
            );
        for (final e in CategoryCatalog.defaultWeightsBp.entries) {
          await _db
              .into(_db.subjectWeights)
              .insert(SubjectWeightsCompanion.insert(subjectId: id, categoryId: e.key, weightBp: e.value));
        }
      });
    } on Exception catch (e) {
      throw DataError.fromDatabase(e, unique: 'Subject $code already exists for that term.');
    }
    return id;
  }

  Future<void> updateSubject(String id, SubjectInput input) async {
    final code = cleanSpaces(input.code);
    if (code.isEmpty) throw const DataError('Enter the subject code.');
    try {
      await (_db.update(_db.subjects)..where((t) => t.id.equals(id))).write(
        SubjectsCompanion(
          code: Value(code),
          title: Value(cleanSpaces(input.title)),
          academicYear: Value(cleanSpaces(input.academicYear)),
          semester: Value(cleanSpaces(input.semester)),
          updatedAt: Value(clock.now()),
        ),
      );
    } on Exception catch (e) {
      throw DataError.fromDatabase(e, unique: 'Subject $code already exists for that term.');
    }
  }

  Future<void> setCombineMethod(String id, String code) => (_db.update(
    _db.subjects,
  )..where((t) => t.id.equals(id))).write(SubjectsCompanion(combineMethod: Value(code), updatedAt: Value(clock.now())));

  Future<void> setScale(String subjectId, String? scaleId) =>
      (_db.update(_db.subjects)..where((t) => t.id.equals(subjectId))).write(
        SubjectsCompanion(gradeScaleId: Value(scaleId), updatedAt: Value(clock.now())),
      );

  Future<void> deleteSubject(String id) =>
      (_db.update(_db.subjects)..where((t) => t.id.equals(id))).write(SubjectsCompanion(deletedAt: Value(clock.now())));

  Future<void> restoreSubject(String id) async {
    try {
      await (_db.update(_db.subjects)..where((t) => t.id.equals(id))).write(
        SubjectsCompanion(deletedAt: const Value(null), updatedAt: Value(clock.now())),
      );
    } on Exception catch (e) {
      throw DataError.fromDatabase(e, unique: 'Another subject with this code now exists for that term.');
    }
  }

  /// Permanently removes a deleted subject with its activities and scores.
  Future<void> purgeSubject(String id) =>
      (_db.delete(_db.subjects)..where((t) => t.id.equals(id) & t.deletedAt.isNotNull())).go();

  // ------------------------------------------------------------ enrolment

  /// Enrols every active student of [sectionId]; returns how many were added.
  Future<int> enrolSection(String subjectId, String sectionId) async {
    final ids =
        await (_db.selectOnly(_db.students)
              ..addColumns([_db.students.id])
              ..where(_db.students.sectionId.equals(sectionId) & _db.students.deletedAt.isNull()))
            .map((r) => r.read(_db.students.id)!)
            .get();
    return enrolStudents(subjectId, ids);
  }

  Future<int> enrolStudents(String subjectId, List<String> studentIds) async {
    final now = clock.now();
    var added = 0;
    await _db.transaction(() async {
      for (final s in studentIds) {
        added +=
            await _db
                    .into(_db.subjectStudents)
                    .insert(
                      SubjectStudentsCompanion.insert(subjectId: subjectId, studentId: s, enrolledAt: now),
                      mode: InsertMode.insertOrIgnore,
                    ) >
                0
            ? 1
            : 0;
      }
    });
    return added;
  }

  /// Removes the student from the subject's class list. Their scores stay in
  /// the database and come back if they are enrolled again.
  Future<void> unenrol(String subjectId, String studentId) => (_db.delete(
    _db.subjectStudents,
  )..where((t) => t.subjectId.equals(subjectId) & t.studentId.equals(studentId))).go();

  Future<List<String>> subjectIdsOf(String studentId) async => (await (_db.select(
    _db.subjectStudents,
  )..where((t) => t.studentId.equals(studentId))).get()).map((e) => e.subjectId).toList();

  // ------------------------------------------------------------ categories

  Future<List<CategoryRow>> categories({bool includeDeleted = false}) {
    final q = _db.select(_db.categories)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)]);
    if (!includeDeleted) q.where((t) => t.deletedAt.isNull());
    return q.get();
  }

  Stream<List<CategoryRow>> watchCategories() =>
      (_db.select(_db.categories)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)]))
          .watch();

  /// A custom examination category (MAX), e.g. "Oral Examination".
  Future<String> createCategory(String name, int defaultMax) async {
    final n = cleanSpaces(name);
    if (n.isEmpty) throw const DataError('Enter the category name.');
    if (defaultMax < 1 || defaultMax > 1000) throw const DataError('Points must be 1 to 1000.');
    final id = newId();
    try {
      await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: id,
              name: n,
              kind: CategoryKind.exam.name,
              defaultMaxPoints: defaultMax,
              sortOrder: const Value(200),
              createdAt: clock.now(),
            ),
          );
    } on Exception catch (e) {
      throw DataError.fromDatabase(e, unique: 'A category named "$n" already exists.');
    }
    return id;
  }

  Future<void> updateCategory(String id, {String? name, int? defaultMax}) async {
    if (defaultMax != null && (defaultMax < 1 || defaultMax > 1000)) {
      throw const DataError('Points must be 1 to 1000.');
    }
    try {
      await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(
          name: name == null ? const Value.absent() : Value(cleanSpaces(name)),
          defaultMaxPoints: defaultMax == null ? const Value.absent() : Value(defaultMax),
        ),
      );
    } on Exception catch (e) {
      throw DataError.fromDatabase(e, unique: 'A category with that name already exists.');
    }
  }

  /// Custom categories only; refused while activities use it.
  Future<void> deleteCategory(String id) async {
    final row = await (_db.select(_db.categories)..where((t) => t.id.equals(id))).getSingle();
    if (row.builtIn) throw const DataError('Built-in categories cannot be deleted.');
    final used =
        await (_db.select(_db.activities)
              ..where((t) => t.categoryId.equals(id) & t.deletedAt.isNull())
              ..limit(1))
            .get();
    if (used.isNotEmpty) throw const DataError('Activities still use this category. Delete them first.');
    await _db.transaction(() async {
      await (_db.delete(_db.subjectWeights)..where((t) => t.categoryId.equals(id))).go();
      await (_db.update(
        _db.categories,
      )..where((t) => t.id.equals(id))).write(CategoriesCompanion(deletedAt: Value(clock.now())));
    });
  }

  // ------------------------------------------------------------ weights

  /// Every active category with its weight in [subjectId] (0 when unset).
  Future<List<WeightView>> weights(String subjectId) async {
    final cats = await categories();
    final rows = await (_db.select(_db.subjectWeights)..where((t) => t.subjectId.equals(subjectId))).get();
    final byCat = {for (final r in rows) r.categoryId: r.weightBp};
    return [for (final c in cats) WeightView(c, byCat[c.id] ?? 0)];
  }

  Stream<List<WeightView>> watchWeights(String subjectId) =>
      liveQuery(_db, [_db.categories, _db.subjectWeights], () => weights(subjectId));

  /// Saves the weights. Grading is activated only when they total exactly
  /// 100 %; otherwise they are kept as a draft and grading stays off.
  /// Returns true when grading is active.
  Future<bool> saveWeights(String subjectId, Map<String, int> weightsBp) async {
    if (weightsBp.values.any((w) => w < 0 || w > 10000)) throw const DataError('Each weight must be 0 to 100%.');
    final total = weightsBp.values.fold(0, (s, w) => s + w);
    final active = total == 10000;
    await _db.transaction(() async {
      await (_db.delete(_db.subjectWeights)..where((t) => t.subjectId.equals(subjectId))).go();
      for (final e in weightsBp.entries) {
        if (e.value == 0) continue;
        await _db
            .into(_db.subjectWeights)
            .insert(SubjectWeightsCompanion.insert(subjectId: subjectId, categoryId: e.key, weightBp: e.value));
      }
      await (_db.update(_db.subjects)..where((t) => t.id.equals(subjectId))).write(
        SubjectsCompanion(gradingActive: Value(active), updatedAt: Value(clock.now())),
      );
    });
    return active;
  }

  // ------------------------------------------------------------ grade scales

  Future<List<ScaleView>> scales() async {
    final rows = await (_db.select(
      _db.gradeScales,
    )..orderBy([(t) => OrderingTerm.desc(t.builtIn), (t) => OrderingTerm.asc(t.name)])).get();
    final items = await _db.select(_db.gradeScaleRows).get();
    return [
      for (final r in rows)
        ScaleView(
          r,
          [for (final i in items.where((i) => i.scaleId == r.id)) ScaleItem(i.minBp, i.grade, i.remark)]
            ..sort((a, b) => b.minBp.compareTo(a.minBp)),
        ),
    ];
  }

  Stream<List<ScaleView>> watchScales() => liveQuery(_db, [_db.gradeScales, _db.gradeScaleRows], scales);

  Future<ScaleView?> scale(String? id) async {
    if (id == null) return null;
    return (await scales()).where((s) => s.row.id == id).firstOrNull;
  }

  /// Creates ([id] null) or replaces a scale. Built-in scales are copied, never changed.
  Future<String> saveScale({
    String? id,
    required String name,
    required int passingBp,
    required bool roundBeforeLookup,
    required List<ScaleItem> items,
  }) async {
    final n = cleanSpaces(name);
    if (n.isEmpty) throw const DataError('Enter a name for the scale.');
    final problems = GradeScale.validate(items);
    if (problems.isNotEmpty) throw DataError(problems.first);
    final now = clock.now();
    final existing = id == null
        ? null
        : await (_db.select(_db.gradeScales)..where((t) => t.id.equals(id))).getSingleOrNull();
    final targetId = (existing == null || existing.builtIn) ? newId() : existing.id;
    await _db.transaction(() async {
      if (targetId == existing?.id) {
        await (_db.update(_db.gradeScales)..where((t) => t.id.equals(targetId))).write(
          GradeScalesCompanion(
            name: Value(n),
            passingBp: Value(passingBp),
            roundBeforeLookup: Value(roundBeforeLookup),
            updatedAt: Value(now),
          ),
        );
        await (_db.delete(_db.gradeScaleRows)..where((t) => t.scaleId.equals(targetId))).go();
      } else {
        await _db
            .into(_db.gradeScales)
            .insert(
              GradeScalesCompanion.insert(
                id: targetId,
                name: n,
                passingBp: Value(passingBp),
                roundBeforeLookup: Value(roundBeforeLookup),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
      for (final i in items) {
        await _db
            .into(_db.gradeScaleRows)
            .insert(
              GradeScaleRowsCompanion.insert(
                scaleId: targetId,
                minBp: i.minBp,
                grade: cleanSpaces(i.grade),
                remark: Value(cleanSpaces(i.remark)),
              ),
            );
      }
    });
    return targetId;
  }

  /// Deletes a custom scale; subjects using it switch to the default scale.
  Future<void> deleteScale(String id) async {
    if (id == DefaultScale.id) throw const DataError('The default scale cannot be deleted.');
    await _db.transaction(() async {
      await (_db.update(
        _db.subjects,
      )..where((t) => t.gradeScaleId.equals(id))).write(const SubjectsCompanion(gradeScaleId: Value(DefaultScale.id)));
      await (_db.delete(_db.gradeScales)..where((t) => t.id.equals(id) & t.builtIn.equals(false))).go();
    });
  }
}
