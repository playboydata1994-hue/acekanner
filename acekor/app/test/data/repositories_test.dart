import 'package:acekor/data/db/app_database.dart';
import 'package:acekor/data/errors.dart';
import 'package:acekor/data/repositories/activities_repository.dart';
import 'package:acekor/data/repositories/roster_repository.dart';
import 'package:acekor/data/repositories/scores_repository.dart';
import 'package:acekor/data/repositories/subjects_repository.dart';
import 'package:acekor/domain/categories.dart';
import 'package:acekor/domain/scoring/percent.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late RosterRepository roster;
  late SubjectsRepository subjects;
  late ActivitiesRepository activities;
  late ScoresRepository scores;

  setUp(() {
    db = newTestDatabase();
    roster = RosterRepository(db);
    subjects = SubjectsRepository(db);
    activities = ActivitiesRepository(db);
    scores = ScoresRepository(db);
  });
  tearDown(() => db.close());

  Future<({String subject, String section, List<String> students})> seedClass() async {
    final section = await roster.createSection(const SectionInput(name: 'BSIT 1-A', program: 'BSIT', yearLevel: 1));
    final subject = await subjects.createSubject(const SubjectInput(code: 'IT 101', title: 'Intro to Computing'));
    final ids = <String>[];
    for (final n in [('Juan', 'Dela Cruz', '2021-001'), ('Ana', 'Reyes', '2021-002'), ('Ben', 'Santos', '2021-003')]) {
      ids.add(
        await roster.addStudent(StudentInput(firstName: n.$1, lastName: n.$2, studentNo: n.$3, sectionId: section)),
      );
    }
    expect(await subjects.enrolSection(subject, section), 3);
    return (subject: subject, section: section, students: ids);
  }

  test('seed: built-in categories, default scale, profile', () async {
    final cats = await subjects.categories();
    expect(cats.map((c) => c.id), containsAll(['quiz', 'recitation', 'midterm', 'final', 'practical']));
    final scales = await subjects.scales();
    expect(scales.single.items.first.grade, '1.00');
    expect((await roster.profile()).id, 1);
  });

  test('new subject gets the default weights totalling 100%', () async {
    final id = await subjects.createSubject(const SubjectInput(code: 'IT 102'));
    final w = await subjects.weights(id);
    expect(w.fold(0, (s, v) => s + v.weightBp), 10000);
    expect((await subjects.subject(id))!.gradingActive, isTrue);
    expect(await subjects.saveWeights(id, {'quiz': 5000, 'recitation': 4000}), isFalse);
    expect((await subjects.subject(id))!.gradingActive, isFalse);
    expect(await subjects.saveWeights(id, {'quiz': 6000, 'recitation': 4000}), isTrue);
  });

  test('duplicate student IDs are refused (ignoring dashes and case)', () async {
    await roster.addStudent(const StudentInput(firstName: 'Juan', lastName: 'Dela Cruz', studentNo: '2021-00123'));
    expect(
      () => roster.addStudent(const StudentInput(firstName: 'Other', lastName: 'Person', studentNo: '202100123')),
      throwsA(isA<DuplicateStudentNoError>()),
    );
    // Students without an ID are fine.
    await roster.addStudent(const StudentInput(firstName: 'A', lastName: 'B'));
    await roster.addStudent(const StudentInput(firstName: 'C', lastName: 'D'));
    expect((await roster.students()).length, 3);
  });

  test('editing a student keeps their scores; delete and restore', () async {
    final c = await seedClass();
    final quiz = await activities.createActivity(
      ActivityInput(subjectId: c.subject, categoryId: 'quiz', number: 1, maxPoints: 50),
    );
    await scores.save(quiz, c.students[0], 42);
    await roster.updateStudent(
      c.students[0],
      const StudentInput(firstName: 'Juan Miguel', lastName: 'Dela Cruz', studentNo: '2021-001'),
    );
    expect((await scores.score(quiz, c.students[0]))!.points, 42);
    await roster.deleteStudent(c.students[0]);
    expect((await roster.students()).length, 2);
    expect((await roster.students(deleted: true)).single.id, c.students[0]);
    await roster.restoreStudent(c.students[0]);
    expect((await scores.score(quiz, c.students[0]))!.points, 42);
  });

  test('import: duplicates in file and on phone, enrolment', () async {
    final subject = await subjects.createSubject(const SubjectInput(code: 'IT 103'));
    await roster.addStudent(const StudentInput(firstName: 'Juan', lastName: 'Dela Cruz', studentNo: '1'));
    final r = await roster.importStudents([
      const StudentInput(firstName: 'Juan', lastName: 'Dela Cruz', studentNo: '1'),
      const StudentInput(firstName: 'Ana', lastName: 'Reyes', studentNo: '2'),
      const StudentInput(firstName: 'Ana2', lastName: 'Reyes', studentNo: '2'),
      const StudentInput(firstName: '', lastName: 'NoFirst'),
    ], subjectId: subject);
    expect(r.added, 1);
    expect(r.skipped, 3);
    expect(r.problems.length, 3);
    expect((await roster.students(subjectId: subject)).length, 2); // existing one enrolled too
  });

  test('activity numbering and labels', () async {
    final c = await seedClass();
    expect(await activities.nextNumber(c.subject, 'quiz'), 1);
    await activities.createActivity(ActivityInput(subjectId: c.subject, categoryId: 'quiz', number: 1, maxPoints: 50));
    expect(await activities.nextNumber(c.subject, 'quiz'), 2);
    expect(
      () =>
          activities.createActivity(ActivityInput(subjectId: c.subject, categoryId: 'quiz', number: 1, maxPoints: 20)),
      throwsA(isA<DataError>()),
    );
    final mid = await activities.createActivity(
      ActivityInput(subjectId: c.subject, categoryId: 'midterm', maxPoints: 100),
    );
    expect((await activities.activity(mid))!.heading, 'MIDTERM EXAMINATION');
    final list = await activities.activities(c.subject);
    expect(list.first.heading, 'QUIZ 1');
  });

  test('scores: save, replace, history, maximum enforced by the database', () async {
    final c = await seedClass();
    final quiz = await activities.createActivity(
      ActivityInput(subjectId: c.subject, categoryId: 'quiz', number: 1, maxPoints: 50),
    );
    final first = await scores.save(quiz, c.students[0], 40);
    expect(first.previous, isNull);
    final second = await scores.save(quiz, c.students[0], 42);
    expect(second.previous, 40);
    expect(second.scoreId, first.scoreId);
    expect(() => scores.save(quiz, c.students[0], 51), throwsA(isA<DataError>()));
    // Lowering the maximum below a recorded score is refused by a trigger.
    expect(
      () => activities.updateActivity(
        quiz,
        ActivityInput(subjectId: c.subject, categoryId: 'quiz', number: 1, maxPoints: 40),
      ),
      throwsA(isA<DataError>()),
    );
    await scores.deleteScore(first.scoreId);
    final h = await scores.history(activityId: quiz);
    expect(h.map((e) => e.row.change), ['delete', 'update', 'create']);
    expect(h[1].row.oldPoints, 40);
    expect(h[1].row.newPoints, 42);
    expect(h.first.studentName, 'Juan Dela Cruz');
    expect(h.first.activityLabel, 'Quiz 1');
  });

  test('continuous entry: next student without a score', () async {
    final c = await seedClass(); // alphabetical: Dela Cruz, Reyes, Santos
    final quiz = await activities.createActivity(
      ActivityInput(subjectId: c.subject, categoryId: 'quiz', number: 1, maxPoints: 50),
    );
    await scores.save(quiz, c.students[0], 42);
    var next = await scores.nextWithoutScore(quiz, c.subject, afterStudentId: c.students[0]);
    expect(next!.row.lastName, 'Reyes');
    await scores.save(quiz, c.students[1], 30);
    next = await scores.nextWithoutScore(quiz, c.subject, afterStudentId: c.students[1]);
    expect(next!.row.lastName, 'Santos');
    await scores.save(quiz, c.students[2], 30);
    expect(await scores.nextWithoutScore(quiz, c.subject, afterStudentId: c.students[2]), isNull);
  });

  test('gradebook: weighted grade and class statistics', () async {
    final c = await seedClass();
    await subjects.saveWeights(c.subject, {'quiz': 6000, 'recitation': 4000});
    final q1 = await activities.createActivity(
      ActivityInput(subjectId: c.subject, categoryId: 'quiz', number: 1, maxPoints: 10),
    );
    final q2 = await activities.createActivity(
      ActivityInput(subjectId: c.subject, categoryId: 'quiz', number: 2, maxPoints: 50),
    );
    final r1 = await activities.createActivity(
      ActivityInput(subjectId: c.subject, categoryId: 'recitation', number: 1, maxPoints: 10),
    );
    await scores.save(q1, c.students[0], 8);
    await scores.save(q2, c.students[0], 45);
    await scores.save(r1, c.students[0], 8);
    await scores.save(q1, c.students[1], 10);
    final book = (await GradebookService(db).build(c.subject))!;
    final g = book.grades[c.students[0]]!;
    // quiz 53/60 = 88.33% × 60% = 53.00; recitation 80% × 40% = 32 → 85
    expect(formatPercent(g.percent!), '85%');
    expect(g.equivalent!.grade, '2.00');
    final s = book.stats(book.activities.firstWhere((a) => a.id == q1));
    expect(s.recorded, 2);
    expect(s.total, 3);
    expect(formatPercent(s.average!), '90%');
    expect(s.highest, 10);
    expect(book.grades[c.students[2]]!.missingCount, 3);
    final quizOnly = (await GradebookService(db).build(c.subject, kinds: {CategoryKind.quiz}))!;
    expect(quizOnly.activities.length, 2);
  });

  test('integrity check is clean', () async {
    await seedClass();
    expect(await db.integrityProblems(), isEmpty);
  });
}
