import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/settings/settings_repository.dart';

import '../support/app_harness.dart';
import '../support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = newTestAppDatabase());

  testWidgets('first launch: onboarding, then the dashboard', (tester) async {
    await pumpApp(tester, db, onboarded: false);

    expect(find.text('Scan, check and grade in seconds'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Works offline. Data stays on your phone.'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.textContaining('of 100 free scans left'), findsOneWidget);
    expect(find.text('Add your name and school'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('No examinations yet'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('No examinations yet'), findsOneWidget);
    expect(await SettingsRepository(db).getBool(SettingKeys.onboardingCompleted), isTrue);
    await disposeApp(tester);
  });

  testWidgets('dashboard shows live totals and recent examinations', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, db);
    await tester.scrollUntilVisible(find.text('No examinations yet'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('No examinations yet'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ACEkanner · Developed by NYE94'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('ACEkanner · Developed by NYE94'), findsOneWidget);

    await insertExam(db, id: 'e1', title: 'Prelim Examination', itemCount: 75);
    await insertSheet(db, id: 's1', examId: 'e1');
    await insertLedger(db, id: 'L1', submissionKey: hex64(9));
    await tester.pumpAndSettle();

    expect(find.text('Prelim Examination'), findsOneWidget);
    expect(find.text('75 items · 1 paper'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('free scans left'), -200, scrollable: find.byType(Scrollable).first);
    // The plan card is one merged accessibility node (read as a unit).
    expect(find.bySemanticsLabel(RegExp('99 of 100 free scans left')), findsOneWidget);
    expect(find.bySemanticsLabel('Examinations: 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Papers scanned: 1'), findsOneWidget);
    await disposeApp(tester);
    semantics.dispose();
  });

  testWidgets('Home: the round "Scan" button opens the quick check scanner', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, db);
    final scan = find.bySemanticsLabel('Scan an answer sheet');
    await tester.scrollUntilVisible(scan, 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Scan'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(scan);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    // No camera in tests: the scanner keeps waiting, so frames are pumped, not settled.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Quick check'), findsOneWidget);
    expect(find.text('0 checked'), findsOneWidget);
    await disposeApp(tester);
    semantics.dispose();
  });

  testWidgets('"Print blank answer sheets" from Home and from the Exams tab', (tester) async {
    await pumpApp(tester, db);
    final home = find.text('Print blank answer sheets');
    await tester.scrollUntilVisible(home, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(home);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Blank answer sheets'), findsOneWidget);
    await tester.pageBack();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tapTab(tester, 'Exams');
    expect(find.byTooltip('Print blank answer sheets'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('settings and about show storage and engine status', (tester) async {
    await pumpApp(tester, db);
    await tapTab(tester, 'Settings');
    expect(find.text('Profile and school'), findsOneWidget);
    expect(find.text('Plan and account'), findsOneWidget);
    expect(find.text('Free plan · 100 of 100 scans left'), findsOneWidget);

    final about = find.text('About ACEkanner');
    await tester.scrollUntilVisible(about, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(about);
    await tester.pumpAndSettle();
    expect(find.text('Not encrypted (development build)'), findsOneWidget);
    expect(find.textContaining('Android phones only'), findsOneWidget);
    expect(find.text('Version 5'), findsOneWidget);
    expect(find.text('Developed by NYE94'), findsOneWidget);
    expect(find.text('Version 0.2.0 (build 2)'), findsOneWidget);
    expect(find.text('com.acekanner.app'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('introduction can be replayed from settings', (tester) async {
    await pumpApp(tester, db);
    await tapTab(tester, 'Settings');
    await tester.tap(find.text('Introduction'));
    await tester.pumpAndSettle();

    expect(find.text('Scan, check and grade in seconds'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Profile and school'), findsOneWidget);
    await disposeApp(tester);
  });
}
