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
    expect(find.text('No examinations yet'), findsOneWidget);
    expect(find.text('Add your name and school'), findsOneWidget);
    expect(await SettingsRepository(db).getBool(SettingKeys.onboardingCompleted), isTrue);
    await disposeApp(tester);
  });

  testWidgets('dashboard shows live totals and recent examinations', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, db);
    expect(find.text('No examinations yet'), findsOneWidget);

    await insertExam(db, id: 'e1', title: 'Prelim Examination', itemCount: 75);
    await insertSheet(db, id: 's1', examId: 'e1');
    await insertLedger(db, id: 'L1', submissionKey: hex64(9));
    await tester.pumpAndSettle();

    expect(find.text('Prelim Examination'), findsOneWidget);
    expect(find.text('75 items · 1 paper'), findsOneWidget);
    // The plan card is one merged accessibility node (read as a unit).
    expect(find.bySemanticsLabel(RegExp('99 of 100 free scans left')), findsOneWidget);
    expect(find.bySemanticsLabel('Examinations: 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Papers scanned: 1'), findsOneWidget);
    await disposeApp(tester);
    semantics.dispose();
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
    expect(find.text('Version 1'), findsOneWidget);
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
