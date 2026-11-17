import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../secure/secret_store.dart';

class AuthAccount {
  const AuthAccount({required this.id, this.email});
  final String id;
  final String? email;
}

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;

  @override
  String toString() => message;
}

/// The instructor's account: Google sign-in exchanged for a Supabase session.
abstract interface class AuthService {
  AuthAccount? get current;
  Stream<AuthAccount?> get changes;

  /// Throws [AuthFailure].
  Future<AuthAccount> signIn();
  Future<void> signOut();
}

/// Used when licensing is not configured in this build.
class DisabledAuthService implements AuthService {
  const DisabledAuthService();

  @override
  AuthAccount? get current => null;

  @override
  Stream<AuthAccount?> get changes => const Stream.empty();

  @override
  Future<AuthAccount> signIn() async =>
      throw const AuthFailure('Sign-in is not available in this test build.');

  @override
  Future<void> signOut() async {}
}

class GoogleSupabaseAuthService implements AuthService {
  GoogleSupabaseAuthService(this._client, this._webClientId);

  final SupabaseClient _client;
  final String _webClientId;
  Future<void>? _googleInit;

  static AuthAccount? _account(User? u) => u == null ? null : AuthAccount(id: u.id, email: u.email);

  @override
  AuthAccount? get current => _account(_client.auth.currentUser);

  @override
  Stream<AuthAccount?> get changes => _client.auth.onAuthStateChange.map((s) => _account(s.session?.user));

  @override
  Future<AuthAccount> signIn() async {
    _googleInit ??= GoogleSignIn.instance.initialize(serverClientId: _webClientId);
    await _googleInit;
    final GoogleSignInAccount google;
    try {
      google = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('Sign-in was cancelled.', cancelled: true);
      }
      throw AuthFailure(switch (e.code) {
        GoogleSignInExceptionCode.clientConfigurationError || GoogleSignInExceptionCode.providerConfigurationError =>
          'Google sign-in is not set up correctly for this app version.',
        _ => 'Google sign-in did not complete. Check your internet connection and try again.',
      });
    }
    final idToken = google.authentication.idToken;
    if (idToken == null) throw const AuthFailure('Google did not return a sign-in token. Try again.');
    try {
      final res = await _client.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);
      final account = _account(res.user);
      if (account == null) throw const AuthFailure('Sign-in did not complete. Try again.');
      return account;
    } on AuthException catch (e) {
      throw AuthFailure('The ACEkanner server refused the sign-in (${e.message}).');
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Could not reach the ACEkanner server. Check your connection and try again.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } finally {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Google sign-out is best effort; the ACEkanner session is gone.
      }
    }
  }
}

/// Keeps the Supabase session in the Android Keystore-backed store instead
/// of plain SharedPreferences.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage(this._store);

  static const String key = 'acekanner.supabase_session.v1';
  final SecretStore _store;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await _store.read(key) != null;

  @override
  Future<String?> accessToken() => _store.read(key);

  @override
  Future<void> removePersistedSession() => _store.delete(key);

  @override
  Future<void> persistSession(String persistSessionString) => _store.write(key, persistSessionString);
}
