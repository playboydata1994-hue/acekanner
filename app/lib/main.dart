import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'app/licensing_providers.dart';
import 'data/licensing/auth_service.dart';
import 'data/secure/secret_store.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        // Never surface stack traces to users; keep them in debug output.
        FlutterError.presentError(details);
      };
      final client = await _startLicensing(LicensingConfig.fromEnvironment());
      runApp(
        ProviderScope(
          // Startup and database errors are shown with an explicit
          // "Try again" button instead of silent automatic retries.
          retry: (retryCount, error) => null,
          overrides: [supabaseClientProvider.overrideWithValue(client)],
          child: const AcekannerApp(),
        ),
      );
    },
    (error, stack) {
      if (kDebugMode) debugPrint('Uncaught error: $error\n$stack');
    },
  );
}

/// Starts Supabase when this build has licensing configured. Works offline:
/// the saved session is read from secure storage, nothing is fetched here.
Future<SupabaseClient?> _startLicensing(LicensingConfig config) async {
  if (!config.configured) return null;
  try {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(KeystoreSecretStore()),
        detectSessionInUri: false,
      ),
    );
    return Supabase.instance.client;
  } catch (e) {
    if (kDebugMode) debugPrint('Supabase failed to start: $e');
    return null;
  }
}
