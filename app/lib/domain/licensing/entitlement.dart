import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// A plan grant from the licensing server: an Ed25519-signed compact JWS. Every
/// field comes from a token whose signature was verified with a public key
/// built into the app, so it cannot be forged or edited on the phone.
class Entitlement {
  const Entitlement({
    required this.token,
    required this.tokenId,
    required this.accountId,
    required this.installId,
    required this.premiumPlan,
    required this.freeLimit,
    required this.freeUsed,
    required this.lease,
    required this.premiumUntil,
    required this.verifiedAt,
    required this.offlineUntil,
    required this.issuedAt,
  });

  final String token;
  final String tokenId;
  final String accountId;
  final String installId;

  /// The server saw an active subscription when it issued the token.
  final bool premiumPlan;
  final int freeLimit;
  final int freeUsed;

  /// Free scans this phone may still use (0 when another phone holds them).
  final int lease;
  final DateTime? premiumUntil;
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

/// Checks the server's signature and the token's binding to this account and phone.
class EntitlementVerifier {
  EntitlementVerifier(this.publicKeys);

  static const String tokenType = 'ACEK-ENT+JWS';

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
      final e = Entitlement(
        token: token,
        tokenId: c['jti'] as String,
        accountId: c['sub'] as String,
        installId: c['dev'] as String,
        premiumPlan: c['plan'] == 'premium',
        freeLimit: (c['free_limit'] as num).toInt(),
        freeUsed: (c['free_used'] as num).toInt(),
        lease: (c['lease'] as num).toInt(),
        premiumUntil: c['premium_until'] == null ? null : _time(c['premium_until']),
        verifiedAt: _time(c['verified_at']),
        offlineUntil: _time(c['offline_until']),
        issuedAt: _time(c['iat']),
      );
      if (accountId != null && e.accountId != accountId) throw const EntitlementException('other account');
      if (installId != null && e.installId != installId) throw const EntitlementException('other phone');
      if (e.lease < 0 || e.freeUsed < 0 || e.freeLimit < 0) throw const EntitlementException('invalid numbers');
      return e;
    } on TypeError {
      throw const EntitlementException('missing claims');
    }
  }

  static DateTime _time(Object? seconds) =>
      DateTime.fromMillisecondsSinceEpoch((seconds as num).toInt() * 1000, isUtc: true);

  static List<int> _b64(String s) => base64Url.decode(base64Url.normalize(s));
}
