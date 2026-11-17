import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/features/classes/type_students_screen.dart';

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

    // Import screen: "?" and "See a sample class list" show the sample.
    await tester.scrollUntilVisible(find.text('Import class list (Excel or CSV)'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Import class list (Excel or CSV)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('See a sample class list'));
    await tester.pumpAndSettle();
    expect(find.text('Sample class list'), findsOneWidget);
    expect(find.text('Or one Name column'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20)); // close the sheet
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sample class list'));
    await tester.pumpAndSettle();
    expect(find.text('Sample class list'), findsWidgets);
    await disposeApp(tester);
  });

  testWidgets('type several students into a section; mistakes are shown before saving', (tester) async {
    await pumpApp(tester, db);
    await tapTab(tester, 'Classes');
    await tester.tap(find.text('Add section'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Section name'), 'BSIT 2-B');
    await tester.tap(find.widgetWithText(FilledButton, 'Add section'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BSIT 2-B'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Type several students'));
    await tester.pumpAndSettle();
    expect(find.text('Add to BSIT 2-B'), findsOneWidget);
    expect(find.text('Section name'), findsNothing, reason: 'the section is already known');
    expect(find.text('Save students'), findsOneWidget);

    Finder field(int card, String label) => find.descendant(
          of: find.byType(Card).at(card),
          matching: find.widgetWithText(TextFormField, label),
        );
    await tester.enterText(field(0, 'Student No'), '2021-00123');
    await tester.enterText(field(0, 'Last name'), 'Dela Cruz');
    await tester.enterText(field(0, 'First name'), 'Juan');
    await tester.enterText(field(1, 'Student No'), '202100123'); // same number, other spelling
    await tester.enterText(field(1, 'Last name'), 'Santos');
    await tester.pump();
    expect(find.text('Save 2 students'), findsOneWidget);

    await tester.tap(find.text('Save 2 students'));
    await tester.pumpAndSettle();
    expect(find.text('Same number as student 1'), findsOneWidget);
    expect(find.text('Enter the first name'), findsOneWidget);
    expect(await db.select(db.students).get(), isEmpty, reason: 'nothing saved while there are mistakes');
    await tester.pump(const Duration(seconds: 5)); // let the message go away
    await tester.pumpAndSettle();

    await tester.enterText(field(1, 'Student No'), '2021-00124');
    await tester.enterText(field(1, 'First name'), 'Maria');
    await tester.enterText(field(1, 'Middle name (optional)'), 'Lopez');
    final form = find.descendant(of: find.byType(TypeStudentsScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Add another student'), 200, scrollable: form);
    await tester.ensureVisible(find.text('Add another student'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add another student'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Student 4'), 200, scrollable: form);
    expect(find.text('Student 4'), findsOneWidget);
    await tester.tap(find.text('Save 2 students'));
    await tester.pumpAndSettle();

    expect(find.text('2 students saved (2 new, 0 already saved).'), findsOneWidget);
    expect(find.text('Dela Cruz, Juan'), findsOneWidget);
    expect(find.textContaining('Santos, Maria'), findsOneWidget);
    final saved = await db.select(db.students).get();
    expect(saved.map((s) => (s.studentNo, s.middleName)).toSet(), {('2021-00123', null), ('2021-00124', 'Lopez')});
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
    await tester.enterText(find.widgetWithText(TextFormField, 'Full name (optional)'), 'Maria Santos');
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

  testWidgets('profile can be saved without an instructor name or title', (tester) async {
    await pumpApp(tester, db);
    await tester.tap(find.text('Add your name and school'));
    await tester.pumpAndSettle();
    expect(find.text('Full name (optional)'), findsOneWidget);
    expect(find.text('Title (optional)'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'School name'), 'State University');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your name.'), findsNothing);
    expect(find.text('Add your name and school'), findsNothing, reason: 'saved and closed');
    await tapTab(tester, 'Settings');
    expect(find.text('State University'), findsOneWidget);
    await disposeApp(tester);
  });
}
