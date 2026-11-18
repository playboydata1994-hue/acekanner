import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:acekanner/app/providers.dart';
import 'package:acekanner/core/theme/app_theme.dart';
import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/audit/audit_logger.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/repositories/answer_key_repository.dart';
import 'package:acekanner/data/repositories/classes_repository.dart';
import 'package:acekanner/data/repositories/exams_repository.dart';
import 'package:acekanner/data/repositories/grading_repository.dart';
import 'package:acekanner/data/repositories/scan_repository.dart';
import 'package:acekanner/data/repositories/students_repository.dart';
import 'package:acekanner/features/scanner/quick_check_card.dart';

import '../../support/omr_fixtures.dart';
import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late Directory tmp;
  late ScanRepository scans;
  late StudentsRepository students;
  late GradingRepository grading;
  late String examId;
  late StudentRow juan;

  int keyMask(int q) => 1 << ((q - 1) % 5);

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('acek_quick_');
    final clock = FixedClock(t0);
    final audit = AuditLogger(db, clock: clock);
    grading = GradingRepository(db, audit, clock: clock);
    final exams = ExamsRepository(db, audit, grading: grading, clock: clock);
    scans = ScanRepository(db, audit, scansDirectory: () async => tmp, grading: grading, clock: clock);
    students = StudentsRepository(db, audit, clock: clock);
    final section = await ClassesRepository(db, clock: clock).createSection(const SectionInput(name: 'BSIT 2-A'));
    juan = (await students.addToSection(
      section,
      const StudentInput(studentNo: '2021-00123', lastName: 'Dela Cruz', firstName: 'Juan'),
    ))
        .student;
    examId = await exams.create(ExamInput(title: 'Quiz', itemCount: 50, sectionIds: [section], studentIdDigits: 9));
    final keys = AnswerKeyRepository(db, audit, exams, grading: grading, clock: clock);
    final versionId = (await exams.loadDetail(examId))!.versions.single.version.id;
    final items = (await keys.load(versionId)).items;
    await keys.save(versionId, [for (final i in items) i.copyWith(mask: keyMask(i.questionNo))]);
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  testWidgets('quick check: examination, student, score and answers; nothing saved', (tester) async {
    final semantics = tester.ensureSemantics();
    final ctx = (await tester.runAsync(() => scans.context(examId)))!;
    final r = reading(
      masks: [for (var q = 1; q <= 50; q++) q <= 45 ? keyMask(q) : (keyMask(q) << 1) % 31],
      uncertain: {3},
      crossed: {2: 1},
    );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    var next = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanRepositoryProvider.overrideWithValue(scans),
          studentsRepositoryProvider.overrideWithValue(students),
          gradingRepositoryProvider.overrideWithValue(grading),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickCheckCard(scanContext: ctx, reading: r, onNext: () => next++),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();

    expect(find.text('QUICK CHECK · NOT SAVED'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Code ${ctx.exam.shortCode}'), findsOneWidget);
    expect(find.text(studentDisplayName(juan)), findsOneWidget);
    // 45 right, but question 3 is unclear and counts as no answer: 44 / 50.
    expect(find.text('88%'), findsOneWidget);
    expect(find.text('44 / 50'), findsOneWidget);
    expect(find.text('44 CORRECT'), findsOneWidget);
    expect(find.text('5 WRONG'), findsOneWidget);
    expect(find.text('1 UNCLEAR'), findsOneWidget);

    await tester.tap(find.text('Show answers'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Question 1: read A, key A'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 2: read B (A crossed out), key B'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 3: read ?, key C'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 46: read B, key A'), findsOneWidget);

    await tester.ensureVisible(find.text('Next sheet'));
    await tester.tap(find.text('Next sheet'));
    expect(next, 1);
    expect(await tester.runAsync(() => db.select(db.answerSheets).get()), isEmpty, reason: 'nothing is saved');
    semantics.dispose();
  });
}
