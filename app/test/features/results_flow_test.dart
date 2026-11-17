import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/audit/audit_logger.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/repositories/answer_key_repository.dart';
import 'package:acekanner/data/repositories/classes_repository.dart';
import 'package:acekanner/data/repositories/exams_repository.dart';
import 'package:acekanner/data/repositories/grading_repository.dart';
import 'package:acekanner/data/repositories/scan_repository.dart';
import 'package:acekanner/data/repositories/students_repository.dart';

import '../support/app_harness.dart';
import '../support/omr_fixtures.dart';
import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late Directory tmp;

  int keyMask(int q) => 1 << ((q - 1) % 5);

  /// Exam "Finals" (50 items, pass 75 %) with three graded papers: 100 %, 80 %, 60 %.
  /// With [unassigned], also a fourth student (Dina) and a paper saved without a
  /// student (44 of 50 correct).
  Future<void> seed({bool unassigned = false}) async {
    final clock = FixedClock(t0);
    final audit = AuditLogger(db, clock: clock);
    final grading = GradingRepository(db, audit, clock: clock);
    final exams = ExamsRepository(db, audit, grading: grading, clock: clock);
    final keys = AnswerKeyRepository(db, audit, exams, grading: grading, clock: clock);
    final scans = ScanRepository(db, audit, scansDirectory: () async => tmp, grading: grading, clock: clock);
    final students = StudentsRepository(db, audit, clock: clock);
    final section = await ClassesRepository(db, clock: clock).createSection(const SectionInput(name: 'BSIT 2-A'));
    final examId = await exams.create(ExamInput(title: 'Finals', itemCount: 50, sectionIds: [section]));
    final versionId = (await exams.loadDetail(examId))!.versions.single.version.id;
    final items = (await keys.load(versionId)).items;
    await keys.save(versionId, [for (final i in items) i.copyWith(mask: keyMask(i.questionNo))]);
    final names = ['Ana', 'Ben', 'Carla'];
    final correct = [50, 40, 30];
    for (var s = 0; s < 3; s++) {
      final student = (await students.addToSection(
        section,
        StudentInput(studentNo: '100$s', lastName: 'Reyes', firstName: names[s]),
      ))
          .student;
      final masks = [for (var q = 1; q <= 50; q++) q <= correct[s] ? keyMask(q) : (keyMask(q) << 1) % 31];
      final image = File('${tmp.path}/r$s.jpg')..writeAsBytesSync([1, 2, 3]);
      await scans.save(ReviewedSheet(
        examId: examId,
        versionId: versionId,
        reading: reading(masks: masks),
        finalMasks: {for (var q = 1; q <= 50; q++) q: masks[q - 1]},
        overridden: const {},
        rectifiedImage: image,
        studentId: student.id,
      ));
    }
    if (unassigned) {
      await students.addToSection(section, const StudentInput(studentNo: '1003', lastName: 'Reyes', firstName: 'Dina'));
      final masks = [for (var q = 1; q <= 50; q++) q <= 44 ? keyMask(q) : (keyMask(q) << 1) % 31];
      final image = File('${tmp.path}/u.jpg')..writeAsBytesSync([1, 2, 3]);
      await scans.save(ReviewedSheet(
        examId: examId,
        versionId: versionId,
        reading: reading(masks: masks, studentNumber: '1003'),
        finalMasks: {for (var q = 1; q <= 50; q++) q: masks[q - 1]},
        overridden: const {},
        rectifiedImage: image,
      ));
    }
  }

  setUp(() {
    db = newTestAppDatabase();
    tmp = Directory.systemTemp.createTempSync('acek_results_');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  testWidgets('papers show scores; a paper can be inspected and corrected', (tester) async {
    await tester.runAsync(seed);
    await pumpApp(tester, db);
    await tapTab(tester, 'Exams');
    await tester.tap(find.text('Finals'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Reyes, Carla'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('40 / 50 · 80%'), findsOneWidget);
    expect(find.text('30 / 50 · 60%'), findsOneWidget);
    expect(find.text('FAILED'), findsOneWidget);
    expect(find.text('PASSED'), findsNWidgets(2));

    await tester.tap(find.text('Reyes, Carla'));
    await tester.pumpAndSettle();
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('30 / 50 points'), findsOneWidget);
    expect(find.text('FAILED'), findsOneWidget);

    await tester.tap(find.text('Not correct'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('31'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('31'));
    await tester.pumpAndSettle();
    expect(find.text('Correct question 31'), findsOneWidget);
    // Q31 key is A; Carla shaded B. Set A.
    await tester.tap(find.bySemanticsLabel('Choice B'));
    await tester.tap(find.bySemanticsLabel('Choice A'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('62%'), -200, scrollable: find.byType(Scrollable).first);
    expect(find.text('62%'), findsOneWidget);
    expect(find.text('31 / 50 points'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('a paper saved without a student is listed first and can be given to a student', (tester) async {
    await tester.runAsync(() => seed(unassigned: true));
    await pumpApp(tester, db);
    await tapTab(tester, 'Exams');
    await tester.tap(find.text('Finals'));
    await tester.pumpAndSettle();

    final banner = find.textContaining('1 paper has no student yet');
    await tester.scrollUntilVisible(banner, 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('shaded 1003 · tap to choose the student'), findsOneWidget);
    await tester.tap(find.text('No student yet'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Shaded number 1003'), findsOneWidget);

    await tester.tap(find.text('Choose the student'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('1000 · has a paper'), findsOneWidget);
    expect(find.text('Shaded on the paper: 1003'), findsOneWidget);
    await tester.tap(find.text('Reyes, Dina'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    expect(find.text('Paper given to Reyes, Dina'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
    expect(find.text('44 / 50 points'), findsOneWidget);
    expect(find.text('Choose the student'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(banner, findsNothing);
    await disposeApp(tester);
  });

  testWidgets('class results: statistics, distribution and most-missed questions', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.runAsync(seed);
    await pumpApp(tester, db);
    await tapTab(tester, 'Exams');
    await tester.tap(find.text('Finals'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Class results and question analysis'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Class results and question analysis'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Papers: 3'), findsOneWidget);
    expect(find.bySemanticsLabel('Average: 80%'), findsOneWidget);
    expect(find.bySemanticsLabel('Highest: 100%'), findsOneWidget);
    expect(find.bySemanticsLabel('Lowest: 60%'), findsOneWidget);
    expect(find.bySemanticsLabel('Passed: 2 · 66.7%'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Score distribution of 3 papers')), findsOneWidget);

    await tester.tap(find.text('Show table'));
    await tester.pumpAndSettle();
    expect(find.text('90–100%'), findsOneWidget);

    // Questions 41-50 were answered correctly only by the 100 % paper.
    await tester.scrollUntilVisible(find.text('Q41'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('33% correct'), findsWidgets);
    await disposeApp(tester);
    semantics.dispose();
  });
}
