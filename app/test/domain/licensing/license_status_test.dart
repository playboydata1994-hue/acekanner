import 'package:acekanner/domain/licensing/entitlement.dart';
import 'package:acekanner/domain/licensing/license_status.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime now = DateTime.utc(2026, 11, 17, 8);

Entitlement ent({int used = 0, int? lease, DateTime? premiumUntil, int offlineDays = 30, DateTime? issued}) {
  final at = issued ?? now.subtract(const Duration(days: 1));
  return Entitlement(
    token: 't',
    tokenId: 'j',
    accountId: 'a',
    installId: 'i',
    premiumPlan: premiumUntil != null,
    freeLimit: 100,
    freeUsed: used,
    lease: lease ?? 100 - used,
    premiumUntil: premiumUntil,
    verifiedAt: at,
    offlineUntil: at.add(Duration(days: offlineDays)),
    issuedAt: at,
  );
}

LicenseStatus status({Entitlement? e, int unsynced = 0, int local = 0, bool configured = true, bool tampered = false, DateTime? at}) =>
    LicenseStatus(
      configured: configured,
      entitlement: e,
      unsyncedFree: unsynced,
      localFreeUsed: local,
      now: at ?? now,
      clockTampered: tampered,
    );

void main() {
  test('test build without licensing: 100 scans counted on this phone, never Premium', () {
    expect(status(configured: false, local: 37).freeRemaining, 63);
    expect(status(configured: false, local: 37).block, isNull);
    expect(status(configured: false, local: 100).block, ScanBlock.freeUsedUp);
    expect(status(configured: false, e: ent(premiumUntil: now.add(const Duration(days: 9)))).premiumActive, isFalse);
  });

  test('signed out: sign in first', () {
    expect(status().block, ScanBlock.signInRequired);
    expect(status().chargeTier, isNull);
  });

  test('free plan: the lease minus scans not yet reported', () {
    final s = status(e: ent(used: 37), unsynced: 5);
    expect(s.freeRemaining, 58);
    expect(s.freeUsed, 42);
    expect(s.chargeTier, 'free');
    expect(status(e: ent(used: 37), unsynced: 63).block, ScanBlock.freeUsedUp);
  });

  test('lease held by another phone', () {
    expect(status(e: ent(used: 10, lease: 0)).block, ScanBlock.leaseOnOtherPhone);
  });

  test('premium: unlimited until expiry, then the free lease again', () {
    final until = now.add(const Duration(days: 200));
    final p = status(e: ent(used: 100, premiumUntil: until), unsynced: 3);
    expect(p.premiumActive, isTrue);
    expect(p.block, isNull);
    expect(p.chargeTier, 'premium');
    final after = status(
      e: ent(used: 40, premiumUntil: until, issued: until.subtract(const Duration(days: 1))),
      at: until.add(const Duration(minutes: 1)),
    );
    expect(after.premiumActive, isFalse);
    expect(after.chargeTier, 'free', reason: 'falls back to the remaining free scans');
  });

  test('offline window: 30 days, warning in the last 7, then scanning pauses', () {
    final fresh = status(e: ent(issued: now.subtract(const Duration(days: 10)), premiumUntil: now.add(const Duration(days: 300))));
    expect(fresh.checkDueSoon, isFalse);
    final soon = status(e: ent(issued: now.subtract(const Duration(days: 25)), premiumUntil: now.add(const Duration(days: 300))));
    expect(soon.checkDueSoon, isTrue);
    expect(soon.premiumActive, isTrue);
    final overdue = status(e: ent(issued: now.subtract(const Duration(days: 31)), premiumUntil: now.add(const Duration(days: 300))));
    expect(overdue.premiumActive, isFalse);
    expect(overdue.block, ScanBlock.checkInRequired);
  });

  test('premium never outlives its expiry, even inside the offline window', () {
    final s = status(e: ent(premiumUntil: now.add(const Duration(days: 3))));
    expect(s.checkDueBy, now.add(const Duration(days: 3)));
  });

  test('a clock turned back counts as an overdue check', () {
    final s = status(e: ent(premiumUntil: now.add(const Duration(days: 300))), tampered: true);
    expect(s.premiumActive, isFalse);
    expect(s.block, ScanBlock.checkInRequired);
  });

  test('every block has a plain-language message', () {
    for (final b in ScanBlock.values) {
      expect(scanBlockMessage(b), isNotEmpty);
    }
    expect(const ScanLimitException(ScanBlock.freeUsedUp).message, contains('Premium'));
  });
}
