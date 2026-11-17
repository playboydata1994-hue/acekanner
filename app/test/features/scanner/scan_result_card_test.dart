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
import 'package:acekanner/features/scanner/review_screen.dart';
import 'package:acekanner/features/scanner/scan_result_card.dart';

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
    tmp = Directory.systemTemp.createTempSync('acek_card_');
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

  /// 45 of 50 answers match the key.
  Future<List<bool>> pumpCard(WidgetTester tester, {Set<int> uncertain = const {}, String number = '202100123'}) async {
    final ctx = (await tester.runAsync(() => scans.context(examId)))!;
    final image = File('${tmp.path}/rect.png')..writeAsBytesSync([1, 2, 3]);
    final r = reading(
      masks: [for (var q = 1; q <= 50; q++) q <= 45 ? keyMask(q) : (keyMask(q) << 1) % 31],
      uncertain: uncertain,
      studentNumber: number,
    );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final finished = <bool>[];
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
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                child: ScanResultCard(key: UniqueKey(), scanContext: ctx, reading: r, rectifiedImage: image, onFinished: finished.add),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    return finished;
  }

  /// Taps and lets database work finish. After Confirm the card keeps its
  /// spinner (the scanner removes it), so frames are pumped, not settled.
  Future<void> tapAndWait(WidgetTester tester, Finder f) async {
    await tester.runAsync(() async {
      await tester.tap(f);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('a clean sheet: student, score and Confirm saves it', (tester) async {
    final finished = await pumpCard(tester);
    expect(find.text('Dela Cruz, Juan'), findsOneWidget);
    expect(find.text('2021-00123 · Set A'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('45 / 50'), findsOneWidget);
    expect(find.text('ALL ANSWERS READ'), findsOneWidget);
    expect(find.textContaining('Fix in Review'), findsNothing);

    await tapAndWait(tester, find.text('Confirm'));
    expect(finished, [true]);
    final sheet = (await tester.runAsync(() => db.select(db.answerSheets).getSingle()))!;
    expect(sheet.studentId, juan.id);
    expect(sheet.status, 'finalized', reason: 'graded right away');
  });

  testWidgets('flagged answers and an unknown number block Confirm; Review opens the review page', (tester) async {
    await pumpCard(tester, uncertain: {4, 9}, number: '209999999');
    expect(find.text('Student not identified'), findsOneWidget);
    expect(find.text('2 FLAGGED'), findsOneWidget);
    expect(find.text('Fix in Review before the next sheet:'), findsOneWidget);
    expect(find.text('Student number 209999999 is not in your class lists'), findsOneWidget);
    expect(find.text('2 flagged answers need your decision'), findsOneWidget);
    expect(find.text('Score: after the flagged answers are decided.'), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(find.ancestor(of: find.text('Confirm'), matching: find.bySubtype<ButtonStyleButton>())).onPressed, isNull);

    await tapAndWait(tester, find.text('Review'));
    expect(find.byType(ReviewScreen), findsOneWidget);
    expect(find.text('Check the scan'), findsOneWidget);
  });

  testWidgets('re-scanning a student asks before replacing the earlier paper', (tester) async {
    final finished = await pumpCard(tester);
    await tapAndWait(tester, find.text('Confirm'));
    expect(finished, [true]);

    final again = await pumpCard(tester);
    expect(find.text('This student already has a saved paper. Confirming replaces it.'), findsOneWidget);
    await tapAndWait(tester, find.text('Confirm'));
    expect(find.text('Replace the earlier paper?'), findsOneWidget);
    await tapAndWait(tester, find.text('Replace'));
    expect(again, [true]);
    final sheets = (await tester.runAsync(() => db.select(db.answerSheets).get()))!;
    expect(sheets.map((s) => s.status).toList()..sort(), ['finalized', 'superseded']);
  });

  testWidgets('discarding saves nothing', (tester) async {
    final finished = await pumpCard(tester);
    await tapAndWait(tester, find.text('Discard and scan again'));
    expect(finished, [false]);
    expect(await tester.runAsync(() => db.select(db.answerSheets).get()), isEmpty);
  });
}
