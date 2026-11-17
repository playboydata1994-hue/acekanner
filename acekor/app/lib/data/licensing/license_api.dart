import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';

class PurchaseVerification {
  const PurchaseVerification({required this.token, required this.granted, required this.pending});

  /// Fresh entitlement token (verify before use).
  final String token;
  final bool granted;
  final bool pending;
}

/// A licensing-server error with a user-facing [message].
class LicenseApiException implements Exception {
  const LicenseApiException(this.code, this.message, {this.status});

  /// e.g. offline, not_signed_in, other_account, invalid_purchase,
  /// trial_used, billing_not_configured, server_error.
  final String code;
  final String message;
  final int? status;

  bool get offline => code == 'offline';

  @override
  String toString() => message;
}

/// The `acekor-license` Edge Function. Only the account, a random install ID
/// and Play purchase tokens are sent; never any student or score.
abstract interface class LicenseApi {
  Future<String> checkin({required String deviceId, required String appVersion});
  Future<String> startTrial({required String deviceId});
  Future<PurchaseVerification> verifyPurchase({
    required String deviceId,
    required String purchaseToken,
    required String productId,
  });
  Future<void> deleteAccount();
}

class SupabaseLicenseApi implements LicenseApi {
  SupabaseLicenseApi(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> _call(Map<String, Object?> body) async {
    try {
      final res = await _client.functions
          .invoke(AppConstants.licenseFunction, body: body)
          .timeout(const Duration(seconds: 25));
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      throw const LicenseApiException('server_error', 'The licensing server sent an unexpected reply.');
    } on FunctionException catch (e) {
      final details = e.details;
      final code = details is Map && details['error'] is String ? details['error'] as String : 'server_error';
      final message = details is Map && details['message'] is String
          ? details['message'] as String
          : 'The licensing server had a problem (${e.status}). Try again later.';
      throw LicenseApiException(code, message, status: e.status);
    } on SocketException {
      throw const LicenseApiException('offline', 'No internet connection. Connect and try again.');
    } on TimeoutException {
      throw const LicenseApiException('offline', 'The licensing server did not answer. Check your connection.');
    } on AuthException {
      throw const LicenseApiException('not_signed_in', 'Please sign in again.');
    } on LicenseApiException {
      rethrow;
    } catch (_) {
      throw const LicenseApiException('offline', 'Could not reach the licensing server. Check your connection.');
    }
  }

  String _token(Map<String, dynamic> data) {
    final token = data['token'];
    if (token is! String) throw const LicenseApiException('server_error', 'No plan information was returned.');
    return token;
  }

  @override
  Future<String> checkin({required String deviceId, required String appVersion}) async =>
      _token(await _call({'action': 'checkin', 'deviceId': deviceId, 'appVersion': appVersion}));

  @override
  Future<String> startTrial({required String deviceId}) async =>
      _token(await _call({'action': 'start-trial', 'deviceId': deviceId}));

  @override
  Future<PurchaseVerification> verifyPurchase({
    required String deviceId,
    required String purchaseToken,
    required String productId,
  }) async {
    final data = await _call({
      'action': 'verify-purchase',
      'deviceId': deviceId,
      'purchaseToken': purchaseToken,
      'productId': productId,
    });
    final purchase = data['purchase'];
    if (purchase is! Map) throw const LicenseApiException('server_error', 'No purchase result was returned.');
    return PurchaseVerification(
      token: _token(data),
      granted: purchase['granted'] == true,
      pending: purchase['pending'] == true,
    );
  }

  @override
  Future<void> deleteAccount() async {
    await _call({'action': 'delete-account', 'confirm': true});
  }
}
