import 'dart:async';
import 'dart:convert';

import 'package:acekanner/app/app_config.dart';
import 'package:acekanner/data/licensing/auth_service.dart';
import 'package:acekanner/data/licensing/billing.dart';
import 'package:acekanner/data/licensing/license_api.dart';
import 'package:cryptography/cryptography.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const String testAccount = '11111111-1111-1111-1111-111111111111';
const String testInstall = 'install-phone-aaaa-0001';

/// Signs entitlement tokens exactly like the server (Ed25519 compact JWS).
class TestIssuer {
  TestIssuer._(this._pair, this.publicKey);

  static Future<TestIssuer> create({int seedByte = 3}) async {
    final pair = await Ed25519().newKeyPairFromSeed(List<int>.filled(32, seedByte));
    final pub = await pair.extractPublicKey();
    return TestIssuer._(pair, pub.bytes);
  }

  final SimpleKeyPair _pair;
  final List<int> publicKey;
  int _n = 0;

  LicensingConfig get config => LicensingConfig(
        supabaseUrl: 'https://test.supabase.co',
        supabaseKey: 'sb_publishable_test',
        googleWebClientId: 'test.apps.googleusercontent.com',
        entitlementKeys: {'k1': publicKey},
      );

  Future<String> sign(Map<String, Object?> claims, {String kid = 'k1'}) async {
    String enc(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
    final input = '${enc({'alg': 'EdDSA', 'typ': 'ACEK-ENT+JWS', 'kid': kid})}.${enc(claims)}';
    final sig = await Ed25519().sign(utf8.encode(input), keyPair: _pair);
    return '$input.${base64Url.encode(sig.bytes).replaceAll('=', '')}';
  }

  Future<String> token({
    String account = testAccount,
    String install = testInstall,
    int freeUsed = 0,
    int? lease,
    DateTime? premiumUntil,
    required DateTime now,
    int offlineDays = 30,
  }) {
    final s = now.millisecondsSinceEpoch ~/ 1000;
    final premium = premiumUntil != null && premiumUntil.isAfter(now);
    return sign({
      'v': 1,
      'sub': account,
      'dev': install,
      'plan': premium ? 'premium' : 'free',
      'free_limit': 100,
      'free_used': freeUsed,
      'lease': lease ?? (100 - freeUsed).clamp(0, 100),
      'premium_until': premium ? premiumUntil.millisecondsSinceEpoch ~/ 1000 : null,
      'verified_at': s,
      'offline_until': s + offlineDays * 86400,
      'iat': s,
      'jti': 'jti-${_n++}',
    });
  }
}

class FakeAuth implements AuthService {
  FakeAuth({this.current});

  @override
  AuthAccount? current;
  final _changes = StreamController<AuthAccount?>.broadcast();
  int signIns = 0;
  AuthFailure? failWith;

  @override
  Stream<AuthAccount?> get changes => _changes.stream;

  @override
  Future<AuthAccount> signIn() async {
    if (failWith != null) throw failWith!;
    signIns++;
    current = const AuthAccount(id: testAccount, email: 'maria@example.com');
    _changes.add(current);
    return current!;
  }

  @override
  Future<void> signOut() async {
    current = null;
    _changes.add(null);
  }
}

/// Simulates the `license` function: counts unique uploaded scans.
class FakeLicenseApi implements LicenseApi {
  FakeLicenseApi(this.issuer, {required this.now});

  final TestIssuer issuer;
  DateTime Function() now;
  final Set<String> counted = {};
  final List<List<ChargeUpload>> uploads = [];
  final List<bool> claims = [];
  DateTime? premiumUntil;
  bool pendingPurchase = false;
  LicenseApiException? failWith;
  String? tokenAccount;
  int deletes = 0;

  Future<String> _token() => issuer.token(
        account: tokenAccount ?? testAccount,
        freeUsed: counted.length,
        premiumUntil: premiumUntil,
        now: now(),
      );

  @override
  Future<String> checkin({
    required String deviceId,
    required bool claim,
    required String appVersion,
    required List<ChargeUpload> charges,
  }) async {
    if (failWith != null) throw failWith!;
    uploads.add(charges);
    claims.add(claim);
    for (final c in charges) {
      if (c.tier == 'free') counted.add(c.keyHash);
    }
    return _token();
  }

  @override
  Future<PurchaseVerification> verifyPurchase({
    required String deviceId,
    required String purchaseToken,
    required String productId,
  }) async {
    if (failWith != null) throw failWith!;
    if (!pendingPurchase && purchaseToken.startsWith('valid')) {
      premiumUntil = now().add(const Duration(days: 365));
    }
    final granted = premiumUntil != null;
    return PurchaseVerification(token: await _token(), granted: granted, pending: pendingPurchase);
  }

  @override
  Future<void> deleteAccount() async {
    if (failWith != null) throw failWith!;
    deletes++;
  }
}

class FakeBillingGateway implements BillingGateway {
  final purchases = StreamController<List<PurchaseDetails>>.broadcast();
  final List<PurchaseDetails> completed = [];
  final List<String> buyRefs = [];
  bool available = true;
  bool hasProduct = true;
  int restores = 0;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchases.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetails?> premiumProduct() async => hasProduct
      ? ProductDetails(
          id: 'acekanner_premium_yearly',
          title: 'ACEkanner Premium',
          description: 'Unlimited scans',
          price: '₱399.00',
          rawPrice: 399,
          currencyCode: 'PHP',
        )
      : null;

  @override
  Future<bool> buy(ProductDetails product, {required String accountRef}) async {
    buyRefs.add(accountRef);
    return true;
  }

  @override
  Future<void> restore({required String accountRef}) async => restores++;

  @override
  Future<void> complete(PurchaseDetails purchase) async => completed.add(purchase);
}

PurchaseDetails purchase(String token, PurchaseStatus status, {String product = 'acekanner_premium_yearly'}) =>
    PurchaseDetails(
      productID: product,
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: token,
        source: 'google_play',
      ),
      transactionDate: '1763337600000',
      status: status,
    )..pendingCompletePurchase = status == PurchaseStatus.purchased;
