import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:acekanner/data/db/app_database.dart';

import '../support/app_harness.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = newTestAppDatabase());

  testWidgets('add a section and a student; the roster and counts update', (tester) async {
    await pumpApp(tester, db);
    await tapTab(tester, 'Classes');
    expect(find.text('No sections yet'), findsOneWidget);

    await tester.tap(find.text('Add section'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Section name'), 'BSIT 2-A');
    await tester.tap(find.widgetWithText(FilledButton, 'Add section'));
    await tester.pumpAndSettle();

    // Lands on the new section.
    expect(find.text('BSIT 2-A'), findsOneWidget);
    expect(find.text('No students yet'), findsOneWidget);

    await tester.tap(find.text('Add student'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Student number'), '2021-00123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Last name'), 'Dela Cruz');
    await tester.enterText(find.widgetWithText(TextFormField, 'First name'), 'Juan');
    await tester.tap(find.widgetWithText(FilledButton, 'Add student'));
    await tester.pumpAndSettle();

    expect(find.text('Dela Cruz, Juan'), findsOneWidget);
    expect(find.text('1 student'), findsOneWidget);
    expect(find.textContaining('added'), findsOneWidget);

    // Adding the same number again does not duplicate the student.
    await tester.tap(find.text('Add student'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Student number'), '202100123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Last name'), 'X');
    await tester.enterText(find.widgetWithText(TextFormField, 'First name'), 'Y');
    await tester.tap(find.widgetWithText(FilledButton, 'Add student'));
    await tester.pumpAndSettle();
    expect(find.textContaining('already in this section'), findsOneWidget);
    expect(await db.select(db.students).get(), hasLength(1));
    await disposeApp(tester);
  });

  testWidgets('subjects: add, then a duplicate code is refused inside the form', (tester) async {
    await pumpApp(tester, db);
    await tapTab(tester, 'Classes');
    await tester.tap(find.text('Subjects'));
    await tester.pumpAndSettle();

    Future<void> addSubject(String code, String title) async {
      await tester.tap(find.text('Add subject'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Subject code'), code);
      await tester.enterText(find.widgetWithText(TextFormField, 'Descriptive title'), title);
      await tester.tap(find.widgetWithText(FilledButton, 'Add subject'));
      await tester.pumpAndSettle();
    }

    await addSubject('cs101', 'Programming 1');
    expect(find.text('CS101'), findsOneWidget);

    await addSubject('CS101', 'Again');
    expect(find.text('A subject with code CS101 already exists.'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('profile and student number format are saved', (tester) async {
    await pumpApp(tester, db);
    await tester.tap(find.text('Add your name and school'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Maria Santos');
    await tester.enterText(find.widgetWithText(TextFormField, 'School name'), 'State University');
    await tester.enterText(find.widgetWithText(TextFormField, 'Student number format'), '####-#####');
    await tester.pumpAndSettle();
    expect(find.textContaining('Example: 2021-00123'), findsOneWidget);
    expect(find.text('School logo (optional)'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Add logo'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Save');
    final list = find.ancestor(of: find.text('School logo (optional)'), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(save, 200, scrollable: list);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.textContaining('Maria'), findsWidgets);
    expect(find.text('Add your name and school'), findsNothing);
    await tapTab(tester, 'Settings');
    expect(find.text('Maria Santos · State University'), findsOneWidget);
    expect(find.text('####-#####'), findsOneWidget);
    await disposeApp(tester);
  });
}
