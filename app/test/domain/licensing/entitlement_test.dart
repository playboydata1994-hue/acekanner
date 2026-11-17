import 'dart:convert';
import 'dart:io';

import 'package:acekanner/app/app_config.dart';
import 'package:acekanner/domain/licensing/entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/licensing_fakes.dart';

void main() {
  // Tokens signed by the real server code (supabase/tests/deno/vectors_test.ts).
  final vectors = jsonDecode(File('test/fixtures/entitlement_vectors.json').readAsStringSync()) as Map<String, dynamic>;
  final verifier = EntitlementVerifier({vectors['keyId'] as String: base64.decode(vectors['publicKey'] as String)});

  test('accepts tokens signed by the server code', () async {
    final free = await verifier.verify(vectors['free']['token'] as String);
    expect(free.premiumPlan, isFalse);
    expect(free.lease, 63);
    expect(free.freeUsed, 37);
    expect(free.offlineUntil.difference(free.verifiedAt), const Duration(days: 30));

    final premium = await verifier.verify(vectors['premium']['token'] as String);
    expect(premium.premiumPlan, isTrue);
    expect(premium.premiumUntil, DateTime.utc(2027, 11, 17));
    expect(premium.accountId, '11111111-1111-1111-1111-111111111111');
    expect(premium.installId, 'install-phone-aaaa-0001');
  });

  test('rejects edited tokens, other keys, unknown key IDs and wrong bindings', () async {
    final token = vectors['free']['token'] as String;
    final parts = token.split('.');
    final claims = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
    claims['lease'] = 100;
    final edited = '${parts[0]}.${base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '')}.${parts[2]}';

    Future<String> reason(Future<Object?> f) async {
      try {
        await f;
        return 'accepted';
      } on EntitlementException catch (e) {
        return e.reason;
      }
    }

    expect(await reason(verifier.verify(edited)), 'bad signature');
    expect(await reason(verifier.verify(vectors['otherKey'] as String)), 'bad signature');
    expect(await reason(EntitlementVerifier({'k9': base64.decode(vectors['publicKey'] as String)}).verify(token)), 'unknown key');
    expect(await reason(verifier.verify(token, accountId: 'someone-else')), 'other account');
    expect(await reason(verifier.verify(token, installId: 'install-other-phone-01')), 'other phone');
    expect(await reason(verifier.verify('not.a.token')), 'malformed');
    expect(await reason(verifier.verify('abc')), 'malformed');
  });

  test('a token signed by a test issuer verifies only with its key', () async {
    final issuer = await TestIssuer.create();
    final t = await issuer.token(now: DateTime.utc(2026, 11, 17));
    expect((await EntitlementVerifier(issuer.config.entitlementKeys).verify(t)).lease, 100);
    await expectLater(verifier.verify(t), throwsA(isA<EntitlementException>()));
  });

  test('licensing config: keys parsed, configured only when complete', () {
    final key = base64.encode(List<int>.filled(32, 1));
    expect(LicensingConfig.parseKeys('k1:$key, bad, k2:short, k3:${base64.encode([1, 2])}').keys, ['k1']);
    expect(LicensingConfig.none.configured, isFalse);
    final ok = LicensingConfig(
      supabaseUrl: 'https://abc.supabase.co',
      supabaseKey: 'sb_publishable_x',
      googleWebClientId: '123.apps.googleusercontent.com',
      entitlementKeys: {'k1': base64.decode(key)},
    );
    expect(ok.configured, isTrue);
    expect(
      LicensingConfig(supabaseUrl: 'http://insecure', supabaseKey: 'x', googleWebClientId: ok.googleWebClientId, entitlementKeys: ok.entitlementKeys).configured,
      isFalse,
    );
  });
}
