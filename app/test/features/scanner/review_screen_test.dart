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
import 'package:acekanner/data/repositories/classes_repository.dart';
import 'package:acekanner/data/repositories/exams_repository.dart';
import 'package:acekanner/data/repositories/scan_repository.dart';
import 'package:acekanner/data/repositories/students_repository.dart';
import 'package:acekanner/domain/answer_mask.dart';
import 'package:acekanner/features/scanner/review_screen.dart';

import '../../support/omr_fixtures.dart';
import '../../support/test_db.dart';

/// 1×1 transparent PNG.
const _png = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

void main() {
  late AppDatabase db;
  late Directory tmp;
  late ScanRepository scans;
  late StudentsRepository students;
  late String examId;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('acek_review_');
    final clock = FixedClock(t0);
    final audit = AuditLogger(db, clock: clock);
    scans = ScanRepository(db, audit, scansDirectory: () async => tmp, clock: clock);
    students = StudentsRepository(db, audit, clock: clock);
    final classes = ClassesRepository(db, clock: clock);
    final section = await classes.createSection(const SectionInput(name: 'BSIT 2-A'));
    await students.addToSection(
      section,
      const StudentInput(studentNo: '2021-00123', lastName: 'Dela Cruz', firstName: 'Juan'),
    );
    examId = await ExamsRepository(db, audit, clock: clock).create(
      ExamInput(title: 'Quiz', itemCount: 50, sectionIds: [section], studentIdDigits: 9),
    );
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Future<bool?> pumpReview(
    WidgetTester tester, {
    required Set<int> uncertain,
    Set<int> multiple = const {},
    String number = '202100123',
  }) async {
    final ctx = (await tester.runAsync(() => scans.context(examId)))!;
    final image = File('${tmp.path}/rect.png')..writeAsBytesSync(_png);
    final r = reading(
      masks: List.generate(50, (i) => multiple.contains(i + 1) ? 5 : 1 << (i % 5)),
      uncertain: uncertain,
      multiple: multiple,
      studentNumber: number,
    );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    bool? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanRepositoryProvider.overrideWithValue(scans),
          studentsRepositoryProvider.overrideWithValue(students),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ReviewScreen(context: ctx, reading: r, rectifiedImage: image),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  Future<void> tapLabel(WidgetTester tester, String label) async {
    final f = find.bySemanticsLabel(label);
    await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('identifies the student, requires flagged answers to be decided, then saves', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpReview(tester, uncertain: {3, 7});

    expect(find.text('Dela Cruz, Juan'), findsOneWidget);
    expect(find.textContaining('from the shaded number'), findsOneWidget);
    expect(find.text('2 TO DECIDE'), findsOneWidget);
    expect(find.text('Decide 2 flagged answers'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save paper')).onPressed, isNull);

    // Decide question 3 as D, question 7 as "no answer".
    await tapLabel(tester, 'Question 3: needs your decision');
    expect(find.text('Question 3'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Choice C')); // clear the suggestion
    await tester.tap(find.bySemanticsLabel('Choice D'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this answer'));
    await tester.pumpAndSettle();
    await tapLabel(tester, 'Question 7: needs your decision');
    await tester.tap(find.text('No answer'));
    await tester.pumpAndSettle();

    expect(find.text('ALL READ'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Save paper');
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

    await tester.runAsync(() async {
      await tester.tap(save);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget, reason: 'review closed after saving');

    final sheets = await tester.runAsync(() => db.select(db.answerSheets).get());
    expect(sheets, hasLength(1));
    final answers = (await tester.runAsync(() => db.select(db.studentAnswers).get()))!;
    expect(answers.firstWhere((a) => a.questionNo == 3).finalMask, 8);
    expect(answers.firstWhere((a) => a.questionNo == 3).resolvedBy, 'instructor');
    expect(answers.firstWhere((a) => a.questionNo == 7).finalMask, 0);
    expect(answers.firstWhere((a) => a.questionNo == 1).resolvedBy, 'engine');
    semantics.dispose();
  });

  testWidgets('one button marks flagged and double-shaded answers wrong; Undo restores them', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpReview(tester, uncertain: {3, 7}, multiple: {10});

    final bulk = find.text('Mark all as wrong (3)');
    await tester.scrollUntilVisible(bulk, 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(bulk, findsOneWidget);
    expect(find.text('2 flagged · 1 with 2 or more circles shaded'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 10: A/C'), findsOneWidget);

    await tester.ensureVisible(bulk);
    await tester.tap(bulk);
    await tester.pump();
    expect(find.text('3 answers marked wrong. Tap an answer to change it.'), findsOneWidget);
    for (final q in [3, 7, 10]) {
      expect(find.bySemanticsLabel('Question $q: marked wrong'), findsOneWidget);
    }
    expect(find.text('ALL READ'), findsOneWidget);
    expect(bulk, findsNothing, reason: 'nothing left to mark');

    // Undo puts everything back as it was.
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Question 3: needs your decision'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 7: needs your decision'), findsOneWidget);
    expect(find.text('Decide 2 flagged answers'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 10: A/C'), findsOneWidget);

    // Mark again and save: the paper keeps the readings, the answers are wrong.
    await tester.ensureVisible(bulk);
    await tester.tap(bulk);
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Save paper');
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    await tester.runAsync(() async {
      await tester.tap(save);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    final answers = (await tester.runAsync(() => db.select(db.studentAnswers).get()))!;
    for (final q in [3, 7, 10]) {
      final row = answers.firstWhere((a) => a.questionNo == q);
      expect(row.finalMask, AnswerMask.markedWrong);
      expect(row.resolvedBy, 'instructor');
    }
    expect(answers.firstWhere((a) => a.questionNo == 10).detectedMask, 5, reason: 'what was read is kept');
    semantics.dispose();
  });

  testWidgets('a single flagged answer can be marked wrong from its picker', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpReview(tester, uncertain: {4});
    await tapLabel(tester, 'Question 4: needs your decision');
    await tester.tap(find.text('Wrong'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Question 4: marked wrong'), findsOneWidget);
    expect(find.text('ALL READ'), findsOneWidget);

    // Opening it again starts from no letters, not from the "wrong" value.
    await tapLabel(tester, 'Question 4: marked wrong');
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Use this answer')).onPressed, isNull);
    semantics.dispose();
  });

  testWidgets('an unknown number must be matched to a student by hand', (tester) async {
    await pumpReview(tester, uncertain: const {}, number: '209999999');
    expect(find.text('Student not identified'), findsOneWidget);
    expect(find.textContaining('209999999'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save without student')).onPressed, isNotNull);

    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dela Cruz, Juan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('chosen by you'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save paper')).onPressed, isNotNull);
  });

  testWidgets('a paper can be saved without a student, to assign later', (tester) async {
    await pumpReview(tester, uncertain: const {}, number: '209999999');
    expect(find.textContaining('save without a student and choose the student later'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Save without student');
    await tester.runAsync(() async {
      await tester.tap(save);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget, reason: 'review closed after saving');
    final sheet = (await tester.runAsync(() => db.select(db.answerSheets).getSingle()))!;
    expect(sheet.studentId, isNull);
    expect(sheet.status, 'needs_review');
    expect(sheet.detectedStudentNo, '209999999');
  });

  testWidgets('discarding asks first and saves nothing', (tester) async {
    await pumpReview(tester, uncertain: const {});
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this scan?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Discard'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.answerSheets).get()), isEmpty);
  });
}
