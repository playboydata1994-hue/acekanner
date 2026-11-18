import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../../core/util/ids.dart';
import '../../core/util/text.dart';
import '../../domain/names.dart';
import '../../domain/search/student_search.dart';
import '../db/app_database.dart';
import '../errors.dart';
import '../live_query.dart';

/// A section with its student count.
class SectionSummary {
  const SectionSummary(this.section, this.studentCount);
  final SectionRow section;
  final int studentCount;

  String get id => section.id;
  String get name => section.name;

  /// "BSIT 1-A · 2026-2027 · 1st Semester"
  String get subtitle => [
    if (section.program.isNotEmpty) section.program,
    if (section.yearLevel != null) 'Year ${section.yearLevel}',
    if (section.academicYear.isNotEmpty) section.academicYear,
    if (section.semester.isNotEmpty) section.semester,
  ].join(' · ');
}

/// A student with the name of their section.
class StudentView {
  const StudentView(this.row, this.sectionName);
  final StudentRow row;
  final String? sectionName;

  String get id => row.id;
  String get natural => Names.natural(row.firstName, row.lastName, suffix: row.suffix);
  String get formal => Names.formal(row.firstName, row.lastName, middle: row.middleName, suffix: row.suffix);
  String get complete => Names.complete(row.firstName, row.lastName, middle: row.middleName, suffix: row.suffix);

  SearchableStudent get searchable => SearchableStudent(
    id: row.id,
    firstName: row.firstName,
    middleName: row.middleName,
    lastName: row.lastName,
    suffix: row.suffix,
    studentNo: row.studentNo,
    sectionName: sectionName,
  );
}

class StudentInput {
  const StudentInput({
    required this.firstName,
    required this.lastName,
    this.studentNo,
    this.middleName = '',
    this.suffix = '',
    this.program = '',
    this.yearLevel,
    this.sectionId,
    this.academicYear = '',
    this.semester = '',
  });

  final String? studentNo;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String program;
  final int? yearLevel;
  final String? sectionId;
  final String academicYear;
  final String semester;

  StudentInput normalized() => StudentInput(
    studentNo: blankToNull(studentNo),
    firstName: cleanSpaces(firstName),
    middleName: cleanSpaces(middleName),
    lastName: cleanSpaces(lastName),
    suffix: cleanSpaces(suffix),
    program: cleanSpaces(program),
    yearLevel: yearLevel,
    sectionId: sectionId,
    academicYear: cleanSpaces(academicYear),
    semester: cleanSpaces(semester),
  );

  /// User-facing problems; empty when valid.
  List<String> problems() {
    final n = normalized();
    return [
      if (n.firstName.isEmpty) 'Enter the first name.',
      if (n.lastName.isEmpty) 'Enter the last name.',
      if (n.firstName.length > 80 || n.lastName.length > 80 || n.middleName.length > 80)
        'A name is too long (80 letters at most).',
      if (n.suffix.length > 10) 'The suffix is too long.',
      if ((n.studentNo ?? '').length > 30) 'The student ID is too long (30 characters at most).',
      if (n.studentNo != null && studentNoKey(n.studentNo) == null) 'The student ID needs letters or digits.',
      if (n.yearLevel != null && (n.yearLevel! < 1 || n.yearLevel! > 6)) 'Year level must be 1 to 6.',
    ];
  }
}

class SectionInput {
  const SectionInput({
    required this.name,
    this.program = '',
    this.yearLevel,
    this.academicYear = '',
    this.semester = '',
  });
  final String name;
  final String program;
  final int? yearLevel;
  final String academicYear;
  final String semester;
}

/// Result of importing a class list.
class ImportResult {
  const ImportResult({required this.added, required this.updated, required this.skipped, required this.problems});
  final int added;
  final int updated;
  final int skipped;

  /// "Row 7: duplicate student ID 2021-00123 (already Juan Dela Cruz)".
  final List<String> problems;
}

enum DuplicatePolicy {
  /// Keep the existing student; skip the row.
  skip,

  /// Update the existing student's details (scores are kept).
  update,
}

/// Instructor profile, sections and students.
class RosterRepository {
  RosterRepository(this._db, {this.clock = const Clock()});

  final AppDatabase _db;
  final Clock clock;

  // ------------------------------------------------------------ profile

  Stream<ProfileRow> watchProfile() => (_db.select(_db.instructorProfile)..where((t) => t.id.equals(1))).watchSingle();

  Future<ProfileRow> profile() => (_db.select(_db.instructorProfile)..where((t) => t.id.equals(1))).getSingle();

  Future<void> saveProfile({
    required String instructorName,
    required String schoolName,
    required String schoolAddress,
    required String department,
  }) async {
    await (_db.update(_db.instructorProfile)..where((t) => t.id.equals(1))).write(
      InstructorProfileCompanion(
        instructorName: Value(cleanSpaces(instructorName)),
        schoolName: Value(cleanSpaces(schoolName)),
        schoolAddress: Value(cleanSpaces(schoolAddress)),
        department: Value(cleanSpaces(department)),
        updatedAt: Value(clock.now()),
      ),
    );
  }

  // ------------------------------------------------------------ sections

  Future<List<SectionSummary>> sections() async {
    final count = _db.students.id.count();
    final q =
        _db.select(_db.sections).join([
            leftOuterJoin(
              _db.students,
              _db.students.sectionId.equalsExp(_db.sections.id) & _db.students.deletedAt.isNull(),
              useColumns: false,
            ),
          ])
          ..addColumns([count])
          ..groupBy([_db.sections.id])
          ..orderBy([OrderingTerm.asc(_db.sections.name.collate(Collate.noCase))]);
    final rows = await q.get();
    return [for (final r in rows) SectionSummary(r.readTable(_db.sections), r.read(count) ?? 0)];
  }

  Stream<List<SectionSummary>> watchSections() => liveQuery(_db, [_db.sections, _db.students], sections);

  Future<String> createSection(SectionInput input) async {
    final name = cleanSpaces(input.name);
    if (name.isEmpty) throw const DataError('Enter the section name.');
    final id = newId();
    final now = clock.now();
    try {
      await _db
          .into(_db.sections)
          .insert(
            SectionsCompanion.insert(
              id: id,
              name: name,
              program: Value(cleanSpaces(input.program)),
              yearLevel: Value(input.yearLevel),
              academicYear: Value(cleanSpaces(input.academicYear)),
              semester: Value(cleanSpaces(input.semester)),
              createdAt: now,
              updatedAt: now,
            ),
          );
    } on Exception catch (e) {
      throw DataError.fromDatabase(e, unique: 'A section named "$name" already exists for that term.');
    }
    return id;
  }

  Future<void> updateSection(String id, SectionInput input) async {
    final name = cleanSpaces(input.name);
    if (name.isEmpty) throw const DataError('Enter the section name.');
    try {
      await (_db.update(_db.sections)..where((t) => t.id.equals(id))).write(
        SectionsCompanion(
          name: Value(name),
          program: Value(cleanSpaces(input.program)),
          yearLevel: Value(input.yearLevel),
          academicYear: Value(cleanSpaces(input.academicYear)),
          semester: Value(cleanSpaces(input.semester)),
          updatedAt: Value(clock.now()),
        ),
      );
    } on Exception catch (e) {
      throw DataError.fromDatabase(e, unique: 'A section named "$name" already exists for that term.');
    }
  }

  /// Deletes the section. Its students stay (without a section) with all scores.
  Future<void> deleteSection(String id) => (_db.delete(_db.sections)..where((t) => t.id.equals(id))).go();

  // ------------------------------------------------------------ students

  Future<List<StudentView>> students({String? sectionId, bool deleted = false, String? subjectId}) async {
    final q =
        _db.select(_db.students).join([
            leftOuterJoin(_db.sections, _db.sections.id.equalsExp(_db.students.sectionId)),
            if (subjectId != null)
              innerJoin(
                _db.subjectStudents,
                _db.subjectStudents.studentId.equalsExp(_db.students.id) &
                    _db.subjectStudents.subjectId.equals(subjectId),
                useColumns: false,
              ),
          ])
          ..where(deleted ? _db.students.deletedAt.isNotNull() : _db.students.deletedAt.isNull())
          ..orderBy([
            OrderingTerm.asc(_db.students.lastName.collate(Collate.noCase)),
            OrderingTerm.asc(_db.students.firstName.collate(Collate.noCase)),
          ]);
    if (sectionId != null) q.where(_db.students.sectionId.equals(sectionId));
    final rows = await q.get();
    return [for (final r in rows) StudentView(r.readTable(_db.students), r.readTableOrNull(_db.sections)?.name)];
  }

  Stream<List<StudentView>> watchStudents({String? sectionId, bool deleted = false, String? subjectId}) => liveQuery(
    _db,
    [_db.students, _db.sections, _db.subjectStudents],
    () => students(sectionId: sectionId, deleted: deleted, subjectId: subjectId),
  );

  Future<StudentView?> student(String id) async {
    final q = _db.select(_db.students).join([
      leftOuterJoin(_db.sections, _db.sections.id.equalsExp(_db.students.sectionId)),
    ])..where(_db.students.id.equals(id));
    final r = await q.getSingleOrNull();
    return r == null ? null : StudentView(r.readTable(_db.students), r.readTableOrNull(_db.sections)?.name);
  }

  Stream<StudentView?> watchStudent(String id) => liveQuery(_db, [_db.students, _db.sections], () => student(id));

  /// The active student who already uses [studentNo] (other than [exceptId]).
  Future<StudentRow?> findByStudentNo(String? studentNo, {String? exceptId}) async {
    final key = studentNoKey(studentNo);
    if (key == null) return null;
    final q = _db.select(_db.students)..where((t) => t.studentNoKey.equals(key) & t.deletedAt.isNull());
    if (exceptId != null) q.where((t) => t.id.equals(exceptId).not());
    return (await q.get()).firstOrNull;
  }

  StudentsCompanion _companion(StudentInput n) => StudentsCompanion(
    studentNo: Value(n.studentNo),
    studentNoKey: Value(studentNoKey(n.studentNo)),
    firstName: Value(n.firstName),
    middleName: Value(n.middleName),
    lastName: Value(n.lastName),
    suffix: Value(n.suffix),
    program: Value(n.program),
    yearLevel: Value(n.yearLevel),
    sectionId: Value(n.sectionId),
    academicYear: Value(n.academicYear),
    semester: Value(n.semester),
  );

  Future<void> _checkInput(StudentInput input, {String? exceptId}) async {
    final problems = input.problems();
    if (problems.isNotEmpty) throw DataError(problems.first);
    final dup = await findByStudentNo(input.normalized().studentNo, exceptId: exceptId);
    if (dup != null) {
      throw DuplicateStudentNoError(
        'Student ID ${input.normalized().studentNo} is already used by '
        '${Names.natural(dup.firstName, dup.lastName, suffix: dup.suffix)}.',
        existingId: dup.id,
      );
    }
  }

  /// Adds a student; [subjectIds] enrols them at once.
  Future<String> addStudent(StudentInput input, {List<String> subjectIds = const []}) async {
    await _checkInput(input);
    final id = newId();
    final now = clock.now();
    await _db.transaction(() async {
      await _db
          .into(_db.students)
          .insert(_companion(input.normalized()).copyWith(id: Value(id), createdAt: Value(now), updatedAt: Value(now)));
      for (final s in subjectIds) {
        await _db
            .into(_db.subjectStudents)
            .insert(
              SubjectStudentsCompanion.insert(subjectId: s, studentId: id, enrolledAt: now),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
    return id;
  }

  /// Edits the profile. Scores, enrolments and history are never touched.
  Future<void> updateStudent(String id, StudentInput input) async {
    await _checkInput(input, exceptId: id);
    await (_db.update(
      _db.students,
    )..where((t) => t.id.equals(id))).write(_companion(input.normalized()).copyWith(updatedAt: Value(clock.now())));
  }

  /// Moves students to [sectionId] (null = no section). Scores are kept.
  Future<void> moveToSection(List<String> ids, String? sectionId) async {
    await (_db.update(_db.students)..where((t) => t.id.isIn(ids))).write(
      StudentsCompanion(sectionId: Value(sectionId), updatedAt: Value(clock.now())),
    );
  }

  /// To "Recently deleted": hidden everywhere, scores kept, can be restored.
  Future<void> deleteStudent(String id) async {
    await (_db.update(
      _db.students,
    )..where((t) => t.id.equals(id))).write(StudentsCompanion(deletedAt: Value(clock.now())));
  }

  Future<void> restoreStudent(String id) async {
    final row = await (_db.select(_db.students)..where((t) => t.id.equals(id))).getSingle();
    final dup = await findByStudentNo(row.studentNo, exceptId: id);
    if (dup != null) {
      throw DuplicateStudentNoError(
        'Cannot restore: student ID ${row.studentNo} is now used by '
        '${Names.natural(dup.firstName, dup.lastName)}.',
        existingId: dup.id,
      );
    }
    await (_db.update(_db.students)..where((t) => t.id.equals(id))).write(
      StudentsCompanion(deletedAt: const Value(null), updatedAt: Value(clock.now())),
    );
  }

  /// Permanently removes a deleted student and their scores.
  Future<void> purgeStudent(String id) =>
      (_db.delete(_db.students)..where((t) => t.id.equals(id) & t.deletedAt.isNotNull())).go();

  /// Imports a class list. Rows with a student ID already on the phone (or
  /// repeated in the file) are skipped or update the existing student,
  /// following [policy]. Optionally places everyone in [sectionId] and
  /// enrols them in [subjectId].
  Future<ImportResult> importStudents(
    List<StudentInput> rows, {
    String? sectionId,
    String? subjectId,
    DuplicatePolicy policy = DuplicatePolicy.skip,
    int firstRowNumber = 2,
  }) async {
    var added = 0, updated = 0, skipped = 0;
    final problems = <String>[];
    final now = clock.now();
    await _db.transaction(() async {
      final seen = <String, int>{};
      for (var i = 0; i < rows.length; i++) {
        final rowNo = i + firstRowNumber;
        final raw = rows[i];
        final input = StudentInput(
          studentNo: raw.studentNo,
          firstName: raw.firstName,
          middleName: raw.middleName,
          lastName: raw.lastName,
          suffix: raw.suffix,
          program: raw.program,
          yearLevel: raw.yearLevel,
          sectionId: sectionId ?? raw.sectionId,
          academicYear: raw.academicYear,
          semester: raw.semester,
        ).normalized();
        final issues = input.problems();
        if (issues.isNotEmpty) {
          skipped++;
          problems.add('Row $rowNo: ${issues.first}');
          continue;
        }
        final key = studentNoKey(input.studentNo);
        if (key != null && seen.containsKey(key)) {
          skipped++;
          problems.add('Row $rowNo: student ID ${input.studentNo} is repeated (first on row ${seen[key]}).');
          continue;
        }
        if (key != null) seen[key] = rowNo;
        final existing = await findByStudentNo(input.studentNo);
        String id;
        if (existing != null) {
          id = existing.id;
          if (policy == DuplicatePolicy.update) {
            await (_db.update(
              _db.students,
            )..where((t) => t.id.equals(id))).write(_companion(input).copyWith(updatedAt: Value(now)));
            updated++;
          } else {
            skipped++;
            problems.add(
              'Row $rowNo: student ID ${input.studentNo} is already '
              '${Names.natural(existing.firstName, existing.lastName)} (kept).',
            );
          }
        } else {
          id = newId();
          await _db
              .into(_db.students)
              .insert(_companion(input).copyWith(id: Value(id), createdAt: Value(now), updatedAt: Value(now)));
          added++;
        }
        if (subjectId != null) {
          await _db
              .into(_db.subjectStudents)
              .insert(
                SubjectStudentsCompanion.insert(subjectId: subjectId, studentId: id, enrolledAt: now),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
    });
    return ImportResult(added: added, updated: updated, skipped: skipped, problems: problems);
  }
}
