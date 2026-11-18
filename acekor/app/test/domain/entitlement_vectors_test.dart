import 'dart:convert';
import 'dart:io';

import 'package:acekor/domain/licensing/entitlement.dart';
import 'package:acekor/domain/licensing/plan_status.dart';
import 'package:acekor/domain/categories.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tokens signed by the real server code (supabase/tests/deno/acekor_vectors_test.ts).
void main() {
  final v =
      jsonDecode(File('test/fixtures/acekor_entitlement_vectors.json').readAsStringSync()) as Map<String, dynamic>;
  final verifier = EntitlementVerifier({v['keyId'] as String: base64.decode(v['publicKey'] as String)});

  test('server trial token', () async {
    final e = await verifier.verify(v['trial']['token'] as String, installId: 'install-acekor-0000-0001');
    expect(e.paid, Tier.none);
    final s = PlanStatus(configured: true, now: DateTime.utc(2027, 12, 2), entitlement: e);
    expect(s.trialActive, isTrue);
    expect(s.canSave(CategoryKind.exam), isTrue);
  });

  test('server MAX token', () async {
    final e = await verifier.verify(v['max']['token'] as String);
    expect(e.paid, Tier.max);
    expect(e.paidUntil, DateTime.utc(2027, 12, 31, 12));
    expect(e.autoRenew, isFalse);
    expect(e.offlineUntil, DateTime.utc(2027, 12, 31));
  });

  test("an ACEkanner-typed token is refused", () async {
    await expectLater(verifier.verify(v['acekannerTyped'] as String), throwsA(isA<EntitlementException>()));
  });
}
