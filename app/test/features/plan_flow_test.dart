import 'package:acekanner/app/licensing_providers.dart';
import 'package:acekanner/app/providers.dart' show licensingConfigProvider;
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/secure/secret_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';
import '../support/licensing_fakes.dart';
import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = newTestAppDatabase());
  tearDown(() => db.close());

  Future<void> openPlan(WidgetTester tester) async {
    await tapTab(tester, 'Settings');
    await tester.tap(find.text('Plan and account'));
    await tester.pumpAndSettle();
  }

  testWidgets('test build: explains that licensing is off and counts 100 scans locally', (tester) async {
    await pumpApp(tester, db);
    await openPlan(tester);
    expect(find.textContaining('test build without online licensing'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
    expect(find.text('Upgrade to Premium'), findsNothing);
    await disposeApp(tester);
  });

  group('licensing configured', () {
    late TestIssuer issuer;
    late FakeAuth auth;
    late FakeLicenseApi api;
    late FakeBillingGateway gateway;

    setUp(() async {
      issuer = await TestIssuer.create();
      auth = FakeAuth();
      api = FakeLicenseApi(issuer, now: () => DateTime.now().toUtc());
      gateway = FakeBillingGateway();
    });

    Future<void> pump(WidgetTester tester) => pumpApp(tester, db,
        secrets: MemorySecretStore()..values['acekanner.install_id.v1'] = testInstall,
        overrides: [
          licensingConfigProvider.overrideWithValue(issuer.config),
          authServiceProvider.overrideWithValue(auth),
          licenseApiProvider.overrideWithValue(api),
          billingGatewayProvider.overrideWithValue(gateway),
        ]);

    testWidgets('sign in, see the free scans, upgrade after server confirmation', (tester) async {
      await tester.runAsync(() async {
        await pump(tester);
        expect(find.text('Sign in once to start your 100 free scans.'), findsOneWidget);
        await openPlan(tester);
        expect(find.textContaining('Student names'), findsOneWidget, reason: 'privacy notice before sign-in');

        await tester.tap(find.text('Sign in with Google'));
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(find.text('maria@example.com'), findsOneWidget);
        expect(api.claims, [true]);
        expect(find.textContaining('₱399.00'), findsOneWidget);

        final upgrade = find.text('Upgrade to Premium');
        await tester.ensureVisible(upgrade);
        await tester.pumpAndSettle();
        await tester.tap(upgrade);
        await tester.pump(const Duration(milliseconds: 100));
        expect(gateway.buyRefs, hasLength(1));

        gateway.purchases.add([purchase('valid-token-1', PurchaseStatus.purchased)]);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(find.textContaining('Unlimited scans until'), findsOneWidget);
        expect(find.text('Manage subscription'), findsOneWidget);
        expect(gateway.completed, hasLength(1));
      });
      await disposeApp(tester);
    });

    testWidgets('signed out: Scan papers explains that sign-in is needed', (tester) async {
      await insertExam(db, id: 'exam1', title: 'Midterm');
      await pump(tester);
      await tapTab(tester, 'Exams');
      await tester.tap(find.text('Midterm'));
      await tester.pumpAndSettle();
      final scan = find.text('Scan papers');
      await tester.scrollUntilVisible(scan, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(scan);
      await tester.pumpAndSettle();
      expect(find.text('Sign in to scan'), findsOneWidget);
      await tester.tap(find.text('Plan and account'));
      await tester.pumpAndSettle();
      expect(find.text('Sign in with Google'), findsOneWidget);
      await disposeApp(tester);
    });
  });
}
