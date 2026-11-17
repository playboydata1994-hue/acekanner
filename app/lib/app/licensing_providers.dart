import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/licensing/auth_service.dart';
import '../data/licensing/billing.dart';
import '../data/licensing/install_id.dart';
import '../data/licensing/license_api.dart';
import '../data/licensing/license_service.dart';
import '../domain/licensing/license_status.dart';
import '../features/settings/about_screen.dart' show packageInfoProvider;
import 'providers.dart';

/// The Supabase client, set by main() when this build has licensing configured
/// and Supabase started. Null in tests and unconfigured test builds.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const DisabledAuthService();
  return GoogleSupabaseAuthService(client, ref.watch(licensingConfigProvider).googleWebClientId);
});

final licenseApiProvider = Provider<LicenseApi?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseLicenseApi(client);
});

final installIdProvider = Provider<InstallIdStore>((ref) => InstallIdStore(ref.watch(secretStoreProvider)));

final licenseServiceProvider = Provider<LicenseService>((ref) {
  final installs = ref.watch(installIdProvider);
  return LicenseService(
    repository: ref.watch(licenseRepositoryProvider),
    api: ref.watch(licenseApiProvider),
    auth: ref.watch(authServiceProvider),
    verifier: ref.watch(entitlementVerifierProvider),
    installId: installs.get,
    appVersion: () async {
      try {
        return (await ref.read(packageInfoProvider.future)).version;
      } catch (_) {
        return 'unknown';
      }
    },
    clock: ref.watch(clockProvider),
  );
});

/// The signed-in account (null when signed out or not configured).
final authAccountProvider = StreamProvider<AuthAccount?>((ref) {
  final auth = ref.watch(authServiceProvider);
  late final StreamController<AuthAccount?> controller;
  StreamSubscription<AuthAccount?>? sub;
  controller = StreamController<AuthAccount?>(
    onListen: () {
      controller.add(auth.current);
      sub = auth.changes.listen(controller.add, onError: controller.addError);
    },
    onCancel: () => sub?.cancel(),
  );
  return controller.stream;
});

/// Live plan status (re-emits when the entitlement or the ledger changes).
final licenseStatusProvider = StreamProvider<LicenseStatus>((ref) {
  final email = ref.watch(authAccountProvider).value?.email;
  return ref.watch(licenseRepositoryProvider).watch(email: email);
});

final billingGatewayProvider = Provider<BillingGateway?>(
  (ref) => ref.watch(supabaseClientProvider) == null ? null : PlayBillingGateway(),
);

/// Purchase flow; keep it alive from app start so purchase updates that
/// arrive later (pending payments) are handled.
final billingControllerProvider = NotifierProvider<BillingController, BillingState>(
  () => BillingController(
    (ref) => BillingDeps(
      gateway: ref.watch(billingGatewayProvider),
      service: ref.watch(licenseServiceProvider),
      accountId: () => ref.read(authServiceProvider).current?.id,
    ),
  ),
);
