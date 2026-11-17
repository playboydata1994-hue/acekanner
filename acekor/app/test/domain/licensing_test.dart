import 'dart:convert';

import 'package:acekor/domain/categories.dart';
import 'package:acekor/domain/licensing/entitlement.dart';
import 'package:acekor/domain/licensing/plan_status.dart';
import 'package:acekor/domain/licensing/reminder_schedule.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

/// Signs claims the way the server does (EdDSA compact JWS).
Future<String> sign(
  SimpleKeyPair kp,
  Map<String, Object?> claims, {
  String typ = 'ACEKOR-ENT+JWS',
  String kid = 'k1',
}) async {
  String b64(List<int> b) => base64Url.encode(b).replaceAll('=', '');
  final h = b64(utf8.encode(jsonEncode({'alg': 'EdDSA', 'typ': typ, 'kid': kid})));
  final p = b64(utf8.encode(jsonEncode(claims)));
  final sig = await Ed25519().sign(utf8.encode('$h.$p'), keyPair: kp);
  return '$h.$p.${b64(sig.bytes)}';
}

int secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

void main() {
  late SimpleKeyPair kp;
  late EntitlementVerifier verifier;
  final now = DateTime.utc(2027, 12, 1, 8);

  setUpAll(() async {
    kp = await Ed25519().newKeyPairFromSeed(List.filled(32, 7));
    verifier = EntitlementVerifier({'k1': (await kp.extractPublicKey()).bytes});
  });

  Map<String, Object?> claims({
    String paid = 'none',
    DateTime? paidUntil,
    bool autoRenew = false,
    DateTime? trialStart,
    DateTime? verified,
  }) {
    final v = verified ?? now;
    return {
      'v': 1,
      'app': 'acekor',
      'sub': 'acct',
      'dev': 'install-0000000000000001',
      'paid': paid,
      'paid_until': paidUntil == null ? null : secs(paidUntil),
      'auto_renew': autoRenew,
      'trial_started': trialStart == null ? null : secs(trialStart),
      'trial_until': trialStart == null ? null : secs(trialStart.add(const Duration(days: 7))),
      'verified_at': secs(v),
      'offline_until': secs(v.add(const Duration(days: 30))),
      'iat': secs(v),
      'jti': 'j',
    };
  }

  test('a valid token verifies; forged, other-app or other-phone tokens do not', () async {
    final t = await sign(kp, claims(paid: 'max', paidUntil: DateTime.utc(2027, 12, 31)));
    final e = await verifier.verify(t, accountId: 'acct', installId: 'install-0000000000000001');
    expect(e.paid, Tier.max);
    final parts = t.split('.');
    final tampered =
        '${parts[0]}.${base64Url.encode(utf8.encode(jsonEncode({...claims(paid: 'max'), 'paid_until': 9999999999}))).replaceAll('=', '')}.${parts[2]}';
    expect(() => verifier.verify(tampered), throwsA(isA<EntitlementException>()));
    expect(() => verifier.verify(t, installId: 'other-phone-000000000'), throwsA(isA<EntitlementException>()));
    final other = await sign(kp, {...claims(), 'app': 'acekanner'});
    expect(() => verifier.verify(other), throwsA(isA<EntitlementException>()));
    final wrongTyp = await sign(kp, claims(), typ: 'ACEK-ENT+JWS');
    expect(() => verifier.verify(wrongTyp), throwsA(isA<EntitlementException>()));
  });

  Future<PlanStatus> status(Map<String, Object?> c, DateTime at) async =>
      PlanStatus(configured: true, now: at, entitlement: await verifier.verify(await sign(kp, c)));

  test('gates: no plan, trial (everything), PRO (no exams), MAX', () async {
    final none = await status(claims(), now);
    expect(none.block(CategoryKind.quiz), PlanBlock.noPlan);
    final trial = await status(claims(trialStart: now.subtract(const Duration(days: 2))), now);
    expect(trial.tier, Tier.max);
    expect(trial.trialDaysLeft, 5);
    expect(trial.canSave(CategoryKind.exam), isTrue);
    final trialOver = await status(claims(trialStart: now.subtract(const Duration(days: 8))), now);
    expect(trialOver.block(CategoryKind.quiz), PlanBlock.trialEnded);
    final pro = await status(claims(paid: 'pro', paidUntil: DateTime.utc(2028, 1, 1)), now);
    expect(pro.canSave(CategoryKind.quiz), isTrue);
    expect(pro.canSave(CategoryKind.recitation), isTrue);
    expect(pro.block(CategoryKind.exam), PlanBlock.needsMax);
    final max = await status(claims(paid: 'max', paidUntil: DateTime.utc(2028, 1, 1)), now);
    expect(max.canSave(CategoryKind.exam), isTrue);
  });

  test('offline policy: expiry, renewal grace, 30-day check, turned-back clock', () async {
    final c = claims(paid: 'pro', paidUntil: DateTime.utc(2027, 12, 10), autoRenew: false);
    expect((await status(c, DateTime.utc(2027, 12, 9))).paidActive, isTrue);
    expect((await status(c, DateTime.utc(2027, 12, 11))).block(CategoryKind.quiz), PlanBlock.expired);
    final renewing = claims(paid: 'pro', paidUntil: DateTime.utc(2027, 12, 10), autoRenew: true);
    expect((await status(renewing, DateTime.utc(2027, 12, 15))).paidActive, isTrue);
    expect((await status(renewing, DateTime.utc(2027, 12, 18))).paidActive, isFalse);
    final longPaid = claims(paid: 'max', paidUntil: DateTime.utc(2029, 1, 1));
    expect(
      (await status(longPaid, now.add(const Duration(days: 31)))).block(CategoryKind.quiz),
      PlanBlock.checkInRequired,
    );
    expect((await status(longPaid, now.subtract(const Duration(days: 3)))).needsCheckIn, isTrue);
  });

  test('test build: phone-only trial', () {
    final s = PlanStatus(configured: false, now: now, localTrialStarted: now.subtract(const Duration(days: 1)));
    expect(s.tier, Tier.max);
    final ended = PlanStatus(configured: false, now: now, localTrialStarted: now.subtract(const Duration(days: 7)));
    expect(ended.block(CategoryKind.quiz), PlanBlock.trialEnded);
  });

  test('reminders: owner example — expires Dec 31, 2027 → notify Dec 26, 2027', () async {
    final s = await status(claims(paid: 'max', paidUntil: DateTime(2027, 12, 31, 12).toUtc()), now);
    final r = ReminderSchedule.build(s, oneDayBefore: true, nowLocal: DateTime(2027, 12, 1));
    final five = r.firstWhere((x) => x.id == ReminderSchedule.fiveDayId);
    expect(five.at, DateTime(2027, 12, 26, 9));
    expect(five.title, 'ACEKOR CALCULATOR');
    expect(five.body, contains('will expire in 5 days (December 31, 2027)'));
    expect(five.body, contains('Renew your subscription to continue enjoying premium academic scoring features.'));
    final one = r.firstWhere((x) => x.id == ReminderSchedule.oneDayId);
    expect(one.at, DateTime(2027, 12, 30, 9));
    expect(ReminderSchedule.build(s, oneDayBefore: false, nowLocal: DateTime(2027, 12, 1)).length, 1);
  });

  test('reminders: auto-renew wording, past dates skipped, renewal moves them', () async {
    final renewing = await status(
      claims(paid: 'pro', paidUntil: DateTime(2027, 12, 31, 12).toUtc(), autoRenew: true),
      now,
    );
    final r = ReminderSchedule.build(renewing, oneDayBefore: true, nowLocal: DateTime(2027, 12, 1));
    expect(r.first.body, contains('renews in 5 days, on December 31, 2027'));
    expect(ReminderSchedule.build(renewing, oneDayBefore: true, nowLocal: DateTime(2027, 12, 27)).map((x) => x.id), [
      ReminderSchedule.oneDayId,
    ]);
    final renewed = await status(
      claims(paid: 'pro', paidUntil: DateTime(2028, 12, 31, 12).toUtc(), autoRenew: true),
      now,
    );
    final after = ReminderSchedule.build(renewed, oneDayBefore: true, nowLocal: DateTime(2027, 12, 1));
    expect(after.first.at, DateTime(2028, 12, 26, 9));
    // Same fixed IDs: rescheduling replaces, never duplicates.
    expect(after.map((x) => x.id).toSet(), {ReminderSchedule.fiveDayId, ReminderSchedule.oneDayId});
  });

  test('trial reminder one day before the trial ends', () async {
    final s = await status(claims(trialStart: now), now);
    final r = ReminderSchedule.build(s, oneDayBefore: true, nowLocal: now.toLocal());
    expect(r.single.id, ReminderSchedule.trialId);
    expect(r.single.at, now.add(const Duration(days: 6)).toLocal());
  });
}
