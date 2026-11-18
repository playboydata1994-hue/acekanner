import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/util/clock.dart';
import '../../domain/licensing/entitlement.dart';
import 'auth_service.dart';
import 'license_api.dart';
import 'license_repository.dart';

/// Result of sending a Play purchase to the server.
enum PurchaseOutcome { granted, pending, notGranted }

/// Online plan actions: check-in, trial, sign-in, purchase verification and
/// account deletion. Paid features are only unlocked by a server-signed
/// entitlement, never by a client-side purchase result.
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

  final LicenseRepository repository;
  final LicenseApi? api;
  final AuthService auth;
  final EntitlementVerifier verifier;
  final Future<String> Function() installId;
  final Future<String> Function() appVersion;
  final Clock clock;

  bool get available => api != null;

  /// SHA-256("acekor-account|v1|" + account id): Play's obfuscatedAccountId,
  /// so a purchase is tied to the ACEkor account that made it.
  static String playAccountRef(String accountId) =>
      sha256.convert(utf8.encode('acekor-account|v1|$accountId')).toString();

  LicenseApi _api() =>
      api ?? (throw const LicenseApiException('not_configured', 'Plans are not set up in this test build.'));

  AuthAccount _user() =>
      auth.current ?? (throw const LicenseApiException('not_signed_in', 'Sign in with Google first.'));

  Future<Entitlement> _verifyAndStore(String token, String account, String device) async {
    final Entitlement e;
    try {
      e = await verifier.verify(token, accountId: account, installId: device);
    } on EntitlementException catch (x) {
      throw LicenseApiException('invalid_token', 'The plan information could not be verified (${x.reason}).');
    }
    await repository.store(e);
    return e;
  }

  /// Refreshes the plan from the server (which re-checks Google Play).
  Future<Entitlement> checkin() async {
    final api = _api();
    final user = _user();
    final device = await installId();
    final token = await api.checkin(deviceId: device, appVersion: await appVersion());
    return _verifyAndStore(token, user.id, device);
  }

  /// Checks in when signed in and the plan is older than [maxAge]; never throws.
  Future<void> refreshIfDue({Duration maxAge = const Duration(hours: 12)}) async {
    if (!available || auth.current == null) return;
    try {
      final current = await repository.current();
      final stale = current == null || clock.now().toUtc().difference(current.issuedAt) > maxAge;
      if (stale) await checkin();
    } catch (_) {
      // Offline or server busy: the stored entitlement keeps working until offline_until.
    }
  }

  Future<void> signIn() async {
    await auth.signIn();
    await checkin();
  }

  Future<void> signOut() async {
    await auth.signOut();
    await repository.clear();
  }

  /// Starts the 7-day trial: on the server (once per Google account) or, in
  /// test builds, on the phone.
  Future<void> startTrial() async {
    if (!available) {
      await repository.startLocalTrial();
      return;
    }
    final api = _api();
    final user = _user();
    final device = await installId();
    await _verifyAndStore(await api.startTrial(deviceId: device), user.id, device);
  }

  /// Sends a Play purchase token to the server, which verifies it with Google.
  Future<PurchaseOutcome> verifyPurchase(String purchaseToken, String productId) async {
    final api = _api();
    final user = _user();
    final device = await installId();
    final r = await api.verifyPurchase(deviceId: device, purchaseToken: purchaseToken, productId: productId);
    final e = await _verifyAndStore(r.token, user.id, device);
    if (r.granted && e.paid != Tier.none) return PurchaseOutcome.granted;
    return r.pending ? PurchaseOutcome.pending : PurchaseOutcome.notGranted;
  }

  /// Deletes the server account (Play policy). Records stay on the phone.
  Future<void> deleteAccount() async {
    _user();
    await _api().deleteAccount();
    await signOut();
  }
}
