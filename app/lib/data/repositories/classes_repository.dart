import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/text.dart';
import '../db/app_database.dart';
import '../errors.dart';

class SubjectInput {
  const SubjectInput({required this.code, required this.title, this.description, this.units});

  final String code;
  final String title;
  final String? description;
  final double? units;
}

class CourseInput {
  const CourseInput({required this.code, required this.name});

  final String code;
  final String name;
}

class SectionInput {
  const SectionInput({
    required this.name,
    this.courseId,
    this.yearLevel,
    this.schoolYear,
    this.term,
  });

  final String name;
  final String? courseId;
  final int? yearLevel;
  final String? schoolYear;
  final String? term;
}

/// A section with its course code and number of enrolled students.
class SectionSummary {
  const SectionSummary(this.section, {this.courseCode, required this.studentCount});

  final SectionRow section;
  final String? courseCode;
  final int studentCount;

  /// "2026-2027 · 1st Semester" (empty when neither is set).
  String get period => [section.schoolYear, section.term].whereType<String>().join(' · ');
}

/// Subjects, courses (degree programs) and sections (class blocks).
class ClassesRepository {
  ClassesRepository(this._db, {this.clock = const Clock()});

  final AppDatabase _db;
  final Clock clock;

  // ---------------------------------------------------------------- subjects

  Stream<List<SubjectRow>> watchSubjects() => (_db.select(_db.subjects)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.code)]))
      .watch();

  Future<SubjectRow?> subject(String id) =>
      (_db.select(_db.subjects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<String> createSubject(SubjectInput input) => _saveSubject(null, input);

  Future<void> updateSubject(String id, SubjectInput input) => _saveSubject(id, input);

  Future<String> _saveSubject(String? id, SubjectInput input) {
    final code = cleanSpaces(input.code).toUpperCase();
    return _guardUnique('A subject with code $code already exists.', () {
      return _db.transaction(() async {
        final clash = await _db
            .customSelect(
              'SELECT id FROM subjects WHERE deleted_at IS NULL AND code = ? COLLATE NOCASE',
              variables: [Variable(code)],
            )
            .get();
        if (clash.any((r) => r.read<String>('id') != id)) {
          throw DuplicateValueException('A subject with code $code already exists.');
        }
        final now = clock.now();
        final values = SubjectsCompanion(
          code: Value(code),
          title: Value(cleanSpaces(input.title)),
          description: Value(blankToNull(input.description)),
          units: Value(input.units),
          updatedAt: Value(now),
        );
        if (id == null) {
          final newIdValue = newId();
          await _db.into(_db.subjects).insert(
                values.copyWith(id: Value(newIdValue), createdAt: Value(now)),
              );
          return newIdValue;
        }
        await (_db.update(_db.subjects)..where((t) => t.id.equals(id))).write(values);
        return id;
      });
    });
  }

  /// Hides the subject. Examinations that use it keep showing it.
  Future<void> deleteSubject(String id) => (_db.update(_db.subjects)
        ..where((t) => t.id.equals(id)))
      .write(SubjectsCompanion(deletedAt: Value(clock.now())));

  // ----------------------------------------------------------------- courses

  Stream<List<CourseRow>> watchCourses() => (_db.select(_db.courses)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.code)]))
      .watch();

  Future<String> createCourse(CourseInput input) => _saveCourse(null, input);

  Future<void> updateCourse(String id, CourseInput input) => _saveCourse(id, input);

  Future<String> _saveCourse(String? id, CourseInput input) {
    final code = cleanSpaces(input.code).toUpperCase();
    return _guardUnique('A course with code $code already exists.', () {
      return _db.transaction(() async {
        final clash = await _db
            .customSelect(
              'SELECT id FROM courses WHERE deleted_at IS NULL AND code = ? COLLATE NOCASE',
              variables: [Variable(code)],
            )
            .get();
        if (clash.any((r) => r.read<String>('id') != id)) {
          throw DuplicateValueException('A course with code $code already exists.');
        }
        final now = clock.now();
        final values = CoursesCompanion(
          code: Value(code),
          name: Value(cleanSpaces(input.name)),
          updatedAt: Value(now),
        );
        if (id == null) {
          final newIdValue = newId();
          await _db.into(_db.courses).insert(
                values.copyWith(id: Value(newIdValue), createdAt: Value(now)),
              );
          return newIdValue;
        }
        await (_db.update(_db.courses)..where((t) => t.id.equals(id))).write(values);
        return id;
      });
    });
  }

  Future<void> deleteCourse(String id) => (_db.update(_db.courses)
        ..where((t) => t.id.equals(id)))
      .write(CoursesCompanion(deletedAt: Value(clock.now())));

  // ---------------------------------------------------------------- sections

  Stream<List<SectionSummary>> watchSections() => _db.sectionSummaries().watch().map(
        (rows) => [
          for (final r in rows)
            SectionSummary(r.s, courseCode: r.courseCode, studentCount: r.studentCount),
        ],
      );

  Stream<SectionSummary?> watchSection(String id) => watchSections().map(
        (all) => all.where((s) => s.section.id == id).firstOrNull,
      );

  Future<String> createSection(SectionInput input) => _saveSection(null, input);

  Future<void> updateSection(String id, SectionInput input) => _saveSection(id, input);

  Future<String> _saveSection(String? id, SectionInput input) {
    final name = cleanSpaces(input.name);
    final schoolYear = blankToNull(input.schoolYear)?.replaceAll(' ', '');
    final term = blankToNull(input.term);
    const message = 'A section with this name already exists for the same school year and term.';
    return _guardUnique(message, () {
      return _db.transaction(() async {
        final clash = await _db
            .customSelect(
              'SELECT id FROM sections WHERE deleted_at IS NULL '
              'AND name = ? COLLATE NOCASE '
              "AND ifnull(school_year, '') = ? AND ifnull(term, '') = ?",
              variables: [Variable(name), Variable(schoolYear ?? ''), Variable(term ?? '')],
            )
            .get();
        if (clash.any((r) => r.read<String>('id') != id)) {
          throw const DuplicateValueException(message);
        }
        final now = clock.now();
        final values = SectionsCompanion(
          name: Value(name),
          courseId: Value(input.courseId),
          yearLevel: Value(input.yearLevel),
          schoolYear: Value(schoolYear),
          term: Value(term),
          updatedAt: Value(now),
        );
        if (id == null) {
          final newIdValue = newId();
          await _db.into(_db.sections).insert(
                values.copyWith(id: Value(newIdValue), createdAt: Value(now)),
              );
          return newIdValue;
        }
        await (_db.update(_db.sections)..where((t) => t.id.equals(id))).write(values);
        return id;
      });
    });
  }

  /// Hides the section. Its students and past examinations are kept.
  Future<void> deleteSection(String id) => (_db.update(_db.sections)
        ..where((t) => t.id.equals(id)))
      .write(SectionsCompanion(deletedAt: Value(clock.now())));

  static Future<T> _guardUnique<T>(String message, Future<T> Function() body) async {
    try {
      return await body();
    } catch (e) {
      if (isUniqueViolation(e)) throw DuplicateValueException(message);
      rethrow;
    }
  }
}
