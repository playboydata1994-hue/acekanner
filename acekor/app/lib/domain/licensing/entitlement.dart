import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Paid plans.
enum Tier {
  none,
  pro,
  max;

  static Tier parse(Object? v) => switch (v) {
    'pro' => Tier.pro,
    'max' => Tier.max,
    _ => Tier.none,
  };

  String get label => switch (this) {
    Tier.none => 'No plan',
    Tier.pro => 'PRO',
    Tier.max => 'MAX',
  };
}

/// A plan grant from the licensing server: an Ed25519-signed compact JWS.
/// Every field comes from a token whose signature was verified with a public
/// key built into the app, so it cannot be forged or edited on the phone.
class Entitlement {
  const Entitlement({
    required this.token,
    required this.tokenId,
    required this.accountId,
    required this.installId,
    required this.paid,
    required this.paidUntil,
    required this.autoRenew,
    required this.trialStarted,
    required this.trialUntil,
    required this.verifiedAt,
    required this.offlineUntil,
    required this.issuedAt,
  });

  final String token;
  final String tokenId;
  final String accountId;
  final String installId;

  /// The paid plan Google Play reported when the token was issued.
  final Tier paid;
  final DateTime? paidUntil;

  /// Auto-renew was on (Play will renew at [paidUntil] unless cancelled).
  final bool autoRenew;
  final DateTime? trialStarted;
  final DateTime? trialUntil;
  final DateTime verifiedAt;

  /// After this the app must check in online again.
  final DateTime offlineUntil;
  final DateTime issuedAt;
}

class EntitlementException implements Exception {
  const EntitlementException(this.reason);
  final String reason;

  @override
  String toString() => 'EntitlementException: $reason';
}

/// Checks the server's signature and the token's binding to this app,
/// account and phone.
class EntitlementVerifier {
  EntitlementVerifier(this.publicKeys);

  static const String tokenType = 'ACEKOR-ENT+JWS';
  static const String appId = 'acekor';

  final Map<String, List<int>> publicKeys;
  final Ed25519 _ed25519 = Ed25519();

  Future<Entitlement> verify(String token, {String? accountId, String? installId}) async {
    final parts = token.split('.');
    if (parts.length != 3) throw const EntitlementException('malformed');
    final Map<String, dynamic> header;
    final Map<String, dynamic> c;
    final List<int> signature;
    try {
      header = jsonDecode(utf8.decode(_b64(parts[0]))) as Map<String, dynamic>;
      c = jsonDecode(utf8.decode(_b64(parts[1]))) as Map<String, dynamic>;
      signature = _b64(parts[2]);
    } on FormatException {
      throw const EntitlementException('malformed');
    } on TypeError {
      throw const EntitlementException('malformed');
    }
    if (header['alg'] != 'EdDSA' || header['typ'] != tokenType) {
      throw const EntitlementException('unexpected header');
    }
    final key = publicKeys[header['kid']];
    if (key == null) throw const EntitlementException('unknown key');
    final ok = await _ed25519.verify(
      utf8.encode('${parts[0]}.${parts[1]}'),
      signature: Signature(signature, publicKey: SimplePublicKey(key, type: KeyPairType.ed25519)),
    );
    if (!ok) throw const EntitlementException('bad signature');

    try {
      if (c['v'] != 1) throw const EntitlementException('unsupported version');
      if (c['app'] != appId) throw const EntitlementException('other app');
      final e = Entitlement(
        token: token,
        tokenId: c['jti'] as String,
        accountId: c['sub'] as String,
        installId: c['dev'] as String,
        paid: Tier.parse(c['paid']),
        paidUntil: _optTime(c['paid_until']),
        autoRenew: c['auto_renew'] == true,
        trialStarted: _optTime(c['trial_started']),
        trialUntil: _optTime(c['trial_until']),
        verifiedAt: _time(c['verified_at']),
        offlineUntil: _time(c['offline_until']),
        issuedAt: _time(c['iat']),
      );
      if (accountId != null && e.accountId != accountId) throw const EntitlementException('other account');
      if (installId != null && e.installId != installId) throw const EntitlementException('other phone');
      return e;
    } on TypeError {
      throw const EntitlementException('missing claims');
    }
  }

  static DateTime _time(Object? seconds) =>
      DateTime.fromMillisecondsSinceEpoch((seconds as num).toInt() * 1000, isUtc: true);

  static DateTime? _optTime(Object? seconds) => seconds == null ? null : _time(seconds);

  static List<int> _b64(String s) => base64Url.decode(base64Url.normalize(s));
}
