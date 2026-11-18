import 'dart:convert';

/// Links to the public privacy policy and terms pages, set at build time
/// (`ACEKOR_PRIVACY_POLICY_URL`, `ACEKOR_TERMS_URL`,
/// `ACEKOR_ACCOUNT_DELETION_URL`). A link is shown only when set.
class LegalLinks {
  const LegalLinks({this.privacyPolicy = '', this.terms = '', this.accountDeletion = ''});

  factory LegalLinks.fromEnvironment() => const LegalLinks(
    privacyPolicy: String.fromEnvironment('ACEKOR_PRIVACY_POLICY_URL'),
    terms: String.fromEnvironment('ACEKOR_TERMS_URL'),
    accountDeletion: String.fromEnvironment('ACEKOR_ACCOUNT_DELETION_URL'),
  );

  final String privacyPolicy;
  final String terms;
  final String accountDeletion;

  Uri? get privacyPolicyUri => _https(privacyPolicy);
  Uri? get termsUri => _https(terms);
  Uri? get accountDeletionUri => _https(accountDeletion);

  static Uri? _https(String text) {
    final uri = Uri.tryParse(text.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty ? uri : null;
  }
}

/// Licensing configuration compiled into the app with `--dart-define-from-file`
/// (see config/README.md). All values are public; no secret is ever compiled in.
class LicensingConfig {
  const LicensingConfig({
    required this.supabaseUrl,
    required this.supabaseKey,
    required this.googleWebClientId,
    required this.entitlementKeys,
  });

  factory LicensingConfig.fromEnvironment() => LicensingConfig(
    supabaseUrl: const String.fromEnvironment('ACEKOR_SUPABASE_URL'),
    supabaseKey: const String.fromEnvironment('ACEKOR_SUPABASE_KEY'),
    googleWebClientId: const String.fromEnvironment('ACEKOR_GOOGLE_WEB_CLIENT_ID'),
    entitlementKeys: parseKeys(const String.fromEnvironment('ACEKOR_ENTITLEMENT_KEYS')),
  );

  /// A test build without licensing: a phone-only 7-day trial; never PRO/MAX.
  static const LicensingConfig none = LicensingConfig(
    supabaseUrl: '',
    supabaseKey: '',
    googleWebClientId: '',
    entitlementKeys: {},
  );

  final String supabaseUrl;
  final String supabaseKey;
  final String googleWebClientId;

  /// Entitlement-signing public keys by key ID (raw 32-byte Ed25519).
  final Map<String, List<int>> entitlementKeys;

  bool get configured =>
      supabaseUrl.startsWith('https://') &&
      supabaseKey.isNotEmpty &&
      googleWebClientId.endsWith('.apps.googleusercontent.com') &&
      entitlementKeys.isNotEmpty;

  /// `k1:BASE64,k2:BASE64` → {k1: bytes, k2: bytes}; invalid entries are dropped.
  static Map<String, List<int>> parseKeys(String text) {
    final out = <String, List<int>>{};
    for (final part in text.split(',')) {
      final i = part.indexOf(':');
      if (i <= 0) continue;
      try {
        final bytes = base64.decode(part.substring(i + 1).trim());
        if (bytes.length == 32) out[part.substring(0, i).trim()] = bytes;
      } on FormatException {
        // Ignore malformed keys; the build is then treated as unconfigured.
      }
    }
    return out;
  }
}
