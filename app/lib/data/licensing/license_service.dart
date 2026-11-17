import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/constants.dart';
import '../../core/util/clock.dart';
import '../../domain/licensing/entitlement.dart';
import 'auth_service.dart';
import 'license_api.dart';
import 'license_repository.dart';

/// Result of sending a Play purchase to the server.
enum PurchaseOutcome { granted, pending, notGranted }

/// Online licensing actions: check-in (sync scans, refresh the plan), sign-in,
/// purchase verification and account deletion. Premium is only ever unlocked
/// by a server-signed entitlement, never by a client-side purchase result.
class LicenseService {
  LicenseService({
    required this.repository,
    required this.api,
    required this.auth,
    required this.verifier,
    required this.installId,
    required this.appVersion,
    this.clock = const Clock(),
  });

  static const int batchSize = 500;

  final LicenseRepository repository;
  final LicenseApi? api;
  final AuthService auth;
  final EntitlementVerifier verifier;
  final Future<String> Function() installId;
  final Future<String> Function() appVersion;
  final Clock clock;

  bool get available => api != null;

  /// SHA-256("acekanner-account|v1|" + account id): Play's obfuscatedAccountId.
  static String playAccountRef(String accountId) =>
      sha256.convert(utf8.encode('acekanner-account|v1|$accountId')).toString();

  LicenseApi _api() => api ?? (throw const LicenseApiException('not_configured', 'Licensing is not set up in this build.'));

  AuthAccount _user() =>
      auth.current ?? (throw const LicenseApiException('not_signed_in', 'Sign in with Google first.'));

  /// Uploads unsynced scans and stores a fresh entitlement. [claim] moves the
  /// free-scan lease to this phone (done on sign-in).
  Future<Entitlement> checkin({bool claim = false}) async {
    final api = _api();
    final user = _user();
    final device = await installId();
    final version = await appVersion();
    Entitlement? latest;
    var first = true;
    while (true) {
      final rows = await repository.ledger.unsynced(limit: batchSize);
      final token = await api.checkin(
        deviceId: device,
        claim: claim && first,
        appVersion: version,
        charges: [
          for (final r in rows)
            ChargeUpload(keyHash: _chargeHash(r.submissionKey), tier: r.tier, consumedAt: r.consumedAt),
        ],
      );
      final e = await _verify(token, user.id, device);
      await repository.store(e, syncedLedgerIds: [for (final r in rows) r.id]);
      latest = e;
      first = false;
      if (rows.length < batchSize) return latest;
    }
  }

  Future<Entitlement> _verify(String token, String account, String device) async {
    try {
      return await verifier.verify(token, accountId: account, installId: device);
    } on EntitlementException catch (e) {
      throw LicenseApiException('invalid_token', 'The plan information could not be verified (${e.reason}).');
    }
  }

  static String _chargeHash(String submissionKey) =>
      sha256.convert(utf8.encode('acekanner-charge|v1|$submissionKey')).toString();

  /// Checks in when signed in and something is due; never throws.
  Future<void> refreshIfDue({Duration maxAge = const Duration(hours: 12)}) async {
    if (!available || auth.current == null) return;
    try {
      final current = await repository.current();
      final unsynced = await repository.ledger.unsynced(limit: 1);
      final stale = current == null || clock.now().difference(current.issuedAt) > maxAge;
      if (stale || unsynced.isNotEmpty) await checkin();
    } catch (_) {
      // Offline or server busy: the stored entitlement keeps working until offline_until.
    }
  }

  Future<void> signIn() async {
    await auth.signIn();
    await checkin(claim: true);
  }

  Future<void> signOut() async {
    await auth.signOut();
    await repository.clear();
  }

  /// Sends a Play purchase token to the server, which verifies it with Google.
  Future<PurchaseOutcome> verifyPurchase(String purchaseToken) async {
    final api = _api();
    final user = _user();
    final device = await installId();
    final r = await api.verifyPurchase(
      deviceId: device,
      purchaseToken: purchaseToken,
      productId: AppConstants.premiumProductId,
    );
    final e = await _verify(r.token, user.id, device);
    await repository.store(e);
    if (r.granted && e.premiumPlan) return PurchaseOutcome.granted;
    return r.pending ? PurchaseOutcome.pending : PurchaseOutcome.notGranted;
  }

  /// Deletes the server account (Play policy). Local data stays on the phone.
  Future<void> deleteAccount() async {
    _user();
    await _api().deleteAccount();
    await signOut();
  }
}
