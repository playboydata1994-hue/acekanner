import 'package:acekanner/app/licensing_providers.dart';
import 'package:acekanner/app/providers.dart';
import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/licensing/billing.dart';
import 'package:acekanner/data/licensing/license_api.dart';
import 'package:acekanner/data/secure/secret_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../support/licensing_fakes.dart';
import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late TestIssuer issuer;
  late FakeLicenseApi api;
  late FakeAuth auth;
  late FakeBillingGateway gateway;
  late ProviderContainer c;

  setUp(() async {
    db = openTestDatabase();
    issuer = await TestIssuer.create();
    api = FakeLicenseApi(issuer, now: () => t0);
    auth = FakeAuth();
    gateway = FakeBillingGateway();
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(FixedClock(t0)),
      licensingConfigProvider.overrideWithValue(issuer.config),
      secretStoreProvider.overrideWithValue(MemorySecretStore()..values['acekanner.install_id.v1'] = testInstall),
      authServiceProvider.overrideWithValue(auth),
      licenseApiProvider.overrideWithValue(api),
      billingGatewayProvider.overrideWithValue(gateway),
    ]);
    await c.read(licenseServiceProvider).signIn();
    c.read(billingControllerProvider); // starts listening to Play
  });

  tearDown(() async {
    c.dispose();
    await db.close();
  });

  Future<bool> premium() async => (await c.read(licenseRepositoryProvider).status()).premiumActive;
  BillingState state() => c.read(billingControllerProvider);

  test('loads the price from Play; purchase is tied to the account', () async {
    final billing = c.read(billingControllerProvider.notifier);
    await billing.load();
    expect(state().available, isTrue);
    expect(state().price, '₱399.00');
    await billing.buy();
    expect(gateway.buyRefs.single, hasLength(64));
    expect(state().phase, BillingPhase.purchasing);
  });

  test('a purchase verified by the server unlocks Premium, then Play is told it is complete', () async {
    await c.read(billingControllerProvider.notifier).handle([purchase('valid-token-1', PurchaseStatus.purchased)]);
    expect(state().phase, BillingPhase.success);
    expect(await premium(), isTrue);
    expect(gateway.completed, hasLength(1));
  });

  test("Play's purchase message alone never activates Premium", () async {
    // The server does not confirm this token.
    await c.read(billingControllerProvider.notifier).handle([purchase('forged-token-1', PurchaseStatus.purchased)]);
    expect(await premium(), isFalse);
    expect(gateway.completed, isEmpty);
    expect(state().phase, BillingPhase.idle);
  });

  test('server unreachable: purchase kept for retry, not completed, no Premium', () async {
    api.failWith = const LicenseApiException('offline', 'No internet');
    await c.read(billingControllerProvider.notifier).handle([purchase('valid-token-1', PurchaseStatus.purchased)]);
    expect(state().phase, BillingPhase.error);
    expect(state().message, contains('Restore purchase'));
    expect(gateway.completed, isEmpty);
    expect(await premium(), isFalse);
  });

  test('purchase from another ACEkanner account is refused with its reason', () async {
    api.failWith = const LicenseApiException('other_account', 'This purchase belongs to another ACEkanner account.');
    await c.read(billingControllerProvider.notifier).handle([purchase('valid-token-1', PurchaseStatus.purchased)]);
    expect(state().message, contains('another ACEkanner account'));
    expect(gateway.completed, isEmpty);
  });

  test('pending payment shows pending and grants nothing', () async {
    await c.read(billingControllerProvider.notifier).handle([purchase('valid-token-1', PurchaseStatus.pending)]);
    expect(state().phase, BillingPhase.pending);
    expect(await premium(), isFalse);
  });

  test('cancel and error leave the plan unchanged; other products are ignored', () async {
    final b = c.read(billingControllerProvider.notifier);
    await b.handle([purchase('t', PurchaseStatus.canceled)]);
    expect(state().phase, BillingPhase.idle);
    await b.handle([purchase('t', PurchaseStatus.error)]);
    expect(state().message, contains('not charged'));
    await b.handle([purchase('valid-token-2', PurchaseStatus.purchased, product: 'something_else')]);
    expect(await premium(), isFalse);
  });

  test('restore re-verifies owned subscriptions', () async {
    final b = c.read(billingControllerProvider.notifier);
    final restoring = b.restore();
    expect(gateway.restores, 1);
    await b.handle([purchase('valid-token-1', PurchaseStatus.restored)]);
    await restoring;
    expect(await premium(), isTrue);
  });
}
