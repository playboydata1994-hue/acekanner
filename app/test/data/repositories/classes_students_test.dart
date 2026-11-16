import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/audit/audit_logger.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/errors.dart';
import 'package:acekanner/data/repositories/classes_repository.dart';
import 'package:acekanner/data/repositories/students_repository.dart';
import 'package:acekanner/domain/roster_csv.dart';

import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late ClassesRepository classes;
  late StudentsRepository students;

  setUp(() {
    db = openTestDatabase();
    final clock = FixedClock(t0);
    classes = ClassesRepository(db, clock: clock);
    students = StudentsRepository(db, AuditLogger(db, clock: clock), clock: clock);
  });
  tearDown(() => db.close());

  group('subjects and courses', () {
    test('codes are upper-cased and unique (case-insensitive)', () async {
      final id = await classes.createSubject(const SubjectInput(code: ' cs101 ', title: 'Programming 1'));
      final rows = await classes.watchSubjects().first;
      expect(rows.single.code, 'CS101');
      await expectLater(
        classes.createSubject(const SubjectInput(code: 'Cs101', title: 'Other')),
        throwsA(isA<DuplicateValueException>()),
      );
      // Editing a subject may keep its own code.
      await classes.updateSubject(id, const SubjectInput(code: 'CS101', title: 'Computer Programming 1'));
      expect((await classes.subject(id))!.title, 'Computer Programming 1');
    });

    test('a deleted subject frees its code', () async {
      final id = await classes.createSubject(const SubjectInput(code: 'IT1', title: 'A'));
      await classes.deleteSubject(id);
      expect(await classes.watchSubjects().first, isEmpty);
      await classes.createSubject(const SubjectInput(code: 'IT1', title: 'B'));
    });

    test('course codes are unique', () async {
      await classes.createCourse(const CourseInput(code: 'BSIT', name: 'BS Information Technology'));
      await expectLater(
        classes.createCourse(const CourseInput(code: 'bsit', name: 'x')),
        throwsA(isA<DuplicateValueException>()),
      );
    });
  });

  group('sections and rosters', () {
    late String sectionId;

    setUp(() async {
      final course = await classes.createCourse(const CourseInput(code: 'BSIT', name: 'BSIT'));
      sectionId = await classes.createSection(
        SectionInput(name: 'BSIT 2-A', courseId: course, schoolYear: '2026 - 2027', term: '1st Semester'),
      );
    });

    test('section names are unique per school year and term', () async {
      await expectLater(
        classes.createSection(
          const SectionInput(name: 'bsit 2-a', schoolYear: '2026-2027', term: '1st Semester'),
        ),
        throwsA(isA<DuplicateValueException>()),
      );
      await classes.createSection(
        const SectionInput(name: 'BSIT 2-A', schoolYear: '2026-2027', term: '2nd Semester'),
      );
    });

    test('summary shows course code, period and student count', () async {
      await students.addToSection(
        sectionId,
        const StudentInput(studentNo: '2021-00123', lastName: 'Dela Cruz', firstName: 'Juan'),
      );
      final summary = (await classes.watchSections().first).single;
      expect(summary.courseCode, 'BSIT');
      expect(summary.period, '2026-2027 · 1st Semester');
      expect(summary.studentCount, 1);
    });

    test('adding an existing number enrolls that student instead of duplicating', () async {
      final other = await classes.createSection(const SectionInput(name: 'BSIT 2-B'));
      const juan = StudentInput(studentNo: '2021-00123', lastName: 'Dela Cruz', firstName: 'Juan');
      final first = await students.addToSection(sectionId, juan);
      expect(first.outcome, AddStudentOutcome.added);

      final again = await students.addToSection(sectionId, juan);
      expect(again.outcome, AddStudentOutcome.alreadyInSection);

      final linked = await students.addToSection(
        other,
        const StudentInput(studentNo: '202100123', lastName: 'X', firstName: 'Y'),
      );
      expect(linked.outcome, AddStudentOutcome.linkedExisting);
      expect(linked.student.lastName, 'Dela Cruz', reason: 'names are not overwritten');
      expect(await db.select(db.students).get(), hasLength(1));
    });

    test('updating a student to a number already in use is refused', () async {
      final a = await students.addToSection(
        sectionId,
        const StudentInput(studentNo: '1001', lastName: 'A', firstName: 'A'),
      );
      await students.addToSection(
        sectionId,
        const StudentInput(studentNo: '1002', lastName: 'B', firstName: 'B'),
      );
      await expectLater(
        students.updateStudent(
          a.student.id,
          const StudentInput(studentNo: '1002', lastName: 'A', firstName: 'A'),
        ),
        throwsA(isA<DuplicateValueException>()),
      );
    });

    test('roster is sorted by last name and removal keeps the record', () async {
      await students.addToSection(
        sectionId,
        const StudentInput(studentNo: '2', lastName: 'santos', firstName: 'Ana'),
      );
      final b = await students.addToSection(
        sectionId,
        const StudentInput(studentNo: '1', lastName: 'Abad', firstName: 'Ben'),
      );
      final roster = await students.watchRoster(sectionId).first;
      expect(roster.map((s) => s.lastName), ['Abad', 'santos']);
      expect(studentDisplayName(roster.first), 'Abad, Ben');

      await students.removeFromSection(sectionId, b.student.id);
      expect(await students.watchRoster(sectionId).first, hasLength(1));
      expect(await db.select(db.students).get(), hasLength(2));
    });

    test('roster import adds, updates, enrolls and keeps emails', () async {
      await students.addToSection(
        sectionId,
        const StudentInput(
          studentNo: '1001',
          lastName: 'Old',
          firstName: 'Name',
          email: 'keep@school.edu.ph',
        ),
      );
      final other = await classes.createSection(const SectionInput(name: 'BSIT 2-B'));
      await students.addToSection(
        other,
        const StudentInput(studentNo: '1003', lastName: 'Reyes', firstName: 'Lea'),
      );

      final parsed = parseRosterCsv(
        'Student No,Last Name,First Name\n'
        '1001,New,Name\n' // existing in section: names updated
        '1002,Garcia,Mark\n' // new
        '1003,Reyes,Lea\n', // existing elsewhere: enrolled
      );
      final summary = await students.importRoster(sectionId, parsed.rows);
      expect(
        [summary.added, summary.updated, summary.enrolled, summary.unchanged],
        [1, 1, 1, 0],
      );
      final updated = await students.findByNumber('1001');
      expect(updated!.lastName, 'New');
      expect(updated.email, 'keep@school.edu.ph');

      final rerun = await students.importRoster(sectionId, parsed.rows);
      expect(rerun.unchanged, 3);
      expect(await students.watchRoster(sectionId).first, hasLength(3));

      final audit = await db.select(db.auditLogs).get();
      expect(audit.where((a) => a.event == 'roster.imported'), hasLength(2));
    });
  });
}
