import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:acekanner/data/db/app_database.dart';

import '../support/app_harness.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = newTestAppDatabase());

  testWidgets('create an examination, fill its key with quick entry, and it becomes complete',
      (tester) async {
    await pumpApp(tester, db);

    await tester.tap(find.text('Create examination'));
    await tester.pumpAndSettle();
    expect(find.text('New examination'), findsOneWidget);
    // The date is optional and starts empty; the class-list upload box is offered.
    expect(find.text('Examination date (optional)'), findsOneWidget);
    expect(find.text('Not set · tap to choose'), findsOneWidget);
    expect(find.text('Upload class list'), findsOneWidget);

    // "?" next to it shows a sample class list.
    await tester.scrollUntilVisible(find.byTooltip('Sample class list'), 100, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sample class list'));
    await tester.pumpAndSettle();
    expect(find.text('Sample class list'), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Sample spreadsheet: Student No, Last Name, First Name, Middle Name; 2021-00123, Dela Cruz')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Got it'),
      200,
      scrollable: find.descendant(of: find.byType(DraggableScrollableSheet), matching: find.byType(Scrollable)).first,
    );
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsNothing);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();

    // Saving without a title shows the validation message.
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the examination title'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Examination title'), 'Prelim Exam');
    await tester.tap(find.text('75'));
    await tester.tap(find.text('A–B'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    // Detail screen of the new examination.
    expect(find.text('Prelim Exam'), findsOneWidget);
    expect(find.text('KEY INCOMPLETE'), findsOneWidget);
    expect(find.text('Set A'), findsOneWidget);
    expect(find.text('Set B'), findsOneWidget);
    expect(find.text('0 of 75 answers set'), findsNWidgets(2));

    // Open set A and fill all 75 answers with quick entry.
    await tester.tap(find.text('Set A'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 75 answers set'), findsOneWidget);
    await tester.tap(find.text('Quick entry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'ABCDE' * 15);
    await tester.tap(find.text('Fill in'));
    await tester.pumpAndSettle();
    expect(find.text('75 of 75 answers set'), findsOneWidget);

    // Tapping a selected bubble clears it; the count follows.
    await tester.tap(find.bySemanticsLabel('Question 1, choice A'));
    await tester.pumpAndSettle();
    expect(find.text('74 of 75 answers set'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Question 1, choice C'));
    await tester.pumpAndSettle();
    expect(find.text('75 of 75 answers set'), findsOneWidget);

    await tester.tap(find.text('Save key'));
    await tester.pumpAndSettle();
    expect(find.text('Answer key saved'), findsOneWidget);

    final items = await (db.select(db.answerKeyItems)).get();
    final setA = items.where((i) => i.correctMask != 0).toList();
    expect(setA, hasLength(75));
    expect(setA.firstWhere((i) => i.questionNo == 1).correctMask, 4); // C
    expect(setA.firstWhere((i) => i.questionNo == 2).correctMask, 2); // B

    // Back on the detail screen: set A complete, set B still empty.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('75 of 75 answers set'), findsOneWidget);
    expect(find.text('0 of 75 answers set'), findsOneWidget);
    expect(find.text('KEY INCOMPLETE'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('leaving the key editor with unsaved changes asks first', (tester) async {
    await pumpApp(tester, db);
    await tester.tap(find.text('Create examination'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Examination title'), 'Quiz');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set A'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Question 1, choice B'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('0 of 50 answers set'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('delete moves an examination to Recently deleted, and it can be restored',
      (tester) async {
    await pumpApp(tester, db);
    await tester.tap(find.text('Create examination'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Examination title'), 'Finals');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('No examinations yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Recently deleted'));
    await tester.pumpAndSettle();
    expect(find.text('Finals'), findsOneWidget);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('answer key, exam form and detail fit a small 320 dp phone', (tester) async {
    await pumpApp(tester, db);
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpAndSettle();

    await tapTab(tester, 'Exams');
    expect(tester.takeException(), isNull, reason: 'exams list');
    await tester.tap(find.text('New examination'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'exam form');
    await tester.enterText(find.widgetWithText(TextFormField, 'Examination title'), 'Small screen');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'exam detail');
    await tester.tap(find.text('Set A'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'answer key');
    await tester.tap(find.bySemanticsLabel('Question 1, choice E'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 50 answers set'), findsOneWidget);
    // Layout overflows would have failed the test with a rendering exception.
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Save key'));
    await tester.pumpAndSettle();
    await disposeApp(tester);
  });
}
