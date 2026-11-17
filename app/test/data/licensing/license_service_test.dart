import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/licensing/auth_service.dart';
import 'package:acekanner/data/licensing/license_api.dart';
import 'package:acekanner/data/licensing/license_repository.dart';
import 'package:acekanner/data/licensing/license_service.dart';
import 'package:acekanner/data/licensing/scan_ledger.dart';
import 'package:acekanner/data/secure/secret_store.dart';
import 'package:acekanner/data/settings/settings_repository.dart';
import 'package:acekanner/domain/licensing/entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/licensing_fakes.dart';
import '../../support/test_db.dart';

/// Computed with PostgreSQL for '11111111-1111-1111-1111-111111111111'
/// (supabase/tests/sql uses the same expression).
const String playRefFromPostgres = 'dd2995ba2ef89e4627c14afc3fd95160d548a616df13edc0b04e86ff09eb4aea';

void main() {
  late AppDatabase db;
  late TestIssuer issuer;
  late FakeLicenseApi api;
  late FakeAuth auth;
  late ScanLedgerStore ledger;
  late LicenseRepository repo;
  late LicenseService service;
  final clock = FixedClock(t0);

  setUp(() async {
    db = openTestDatabase();
    issuer = await TestIssuer.create();
    api = FakeLicenseApi(issuer, now: () => t0);
    auth = FakeAuth();
    ledger = ScanLedgerStore(db, MemorySecretStore(), clock: clock);
    final verifier = EntitlementVerifier(issuer.config.entitlementKeys);
    repo = LicenseRepository(db, ledger, SettingsRepository(db, clock: clock), configured: true, verifier: verifier, clock: clock);
    service = LicenseService(
      repository: repo,
      api: api,
      auth: auth,
      verifier: verifier,
      installId: () async => testInstall,
      appVersion: () async => '0.6.0',
      clock: clock,
    );
  });

  tearDown(() => db.close());

  test('sign-in claims the free lease on this phone and stores the plan', () async {
    await service.signIn();
    expect(auth.signIns, 1);
    expect(api.claims, [true]);
    final s = await repo.status();
    expect(s.signedIn, isTrue);
    expect(s.freeRemaining, 100);
  });

  test('check-in uploads only hashes of unsynced scans, in batches, then marks them synced', () async {
    await service.signIn();
    for (var i = 0; i < 520; i++) {
      await ledger.append(submissionKey: hex64(i + 1), tier: 'free');
    }
    await service.checkin();
    expect(api.uploads.skip(1).map((u) => u.length), [500, 20]);
    expect(api.claims.skip(1), [false, false], reason: 'only sign-in claims the lease');
    final uploaded = api.uploads.skip(1).expand((u) => u).toList();
    expect(uploaded.first.keyHash, ScanLedgerStore.chargeHash(hex64(1)));
    expect(uploaded.every((c) => c.keyHash != hex64(1)), isTrue, reason: 'raw submission keys never leave the phone');
    expect(await ledger.unsynced(), isEmpty);
    final s = await repo.status();
    expect(s.freeUsed, 100);
    expect(s.freeRemaining, 0);

    // Nothing new: an empty upload.
    await service.checkin();
    expect(api.uploads.last, isEmpty);
  });

  test('a token for another account or phone is refused and not stored', () async {
    await service.signIn();
    api.tokenAccount = '22222222-2222-2222-2222-222222222222';
    await expectLater(service.checkin(), throwsA(isA<LicenseApiException>().having((e) => e.code, 'code', 'invalid_token')));
    expect((await repo.current())!.accountId, testAccount);
  });

  test('offline: check-in fails, the stored plan keeps working, refreshIfDue stays quiet', () async {
    await service.signIn();
    await ledger.append(submissionKey: hex64(7), tier: 'free');
    api.failWith = const LicenseApiException('offline', 'No internet');
    await expectLater(service.checkin(), throwsA(isA<LicenseApiException>()));
    await service.refreshIfDue();
    final s = await repo.status();
    expect(s.signedIn, isTrue);
    expect(s.freeRemaining, 99);
    expect((await ledger.unsynced()).length, 1);
  });

  test('purchase: Premium only after the server confirms it', () async {
    await service.signIn();
    expect(await service.verifyPurchase('valid-token-123'), PurchaseOutcome.granted);
    expect((await repo.status()).premiumActive, isTrue);
  });

  test('pending payment grants nothing', () async {
    await service.signIn();
    api.pendingPurchase = true;
    expect(await service.verifyPurchase('valid-token-123'), PurchaseOutcome.pending);
    expect((await repo.status()).premiumActive, isFalse);
  });

  test('sign-out and account deletion keep local papers and the ledger', () async {
    await service.signIn();
    await ledger.append(submissionKey: hex64(9), tier: 'free');
    await service.deleteAccount();
    expect(api.deletes, 1);
    expect(auth.current, isNull);
    expect(await repo.current(), isNull);
    expect(await ledger.countFree(), 1);
  });

  test('without a server (test build) online actions explain themselves', () async {
    final offline = LicenseService(
      repository: repo,
      api: null,
      auth: const DisabledAuthService(),
      verifier: EntitlementVerifier(issuer.config.entitlementKeys),
      installId: () async => testInstall,
      appVersion: () async => '0.6.0',
    );
    expect(offline.available, isFalse);
    await expectLater(offline.checkin(), throwsA(isA<LicenseApiException>()));
    await offline.refreshIfDue();
  });

  test('play account ref matches the server (SHA-256 of the account id)', () {
    // Same value as the SQL: encode(sha256('acekanner-account|v1|' || id), 'hex').
    expect(LicenseService.playAccountRef(testAccount), playRefFromPostgres);
  });
}
