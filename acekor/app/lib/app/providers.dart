import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/util/clock.dart';
import '../data/db/app_database.dart';
import '../data/licensing/license_repository.dart';
import '../data/repositories/activities_repository.dart';
import '../data/repositories/calc_history_repository.dart';
import '../data/repositories/roster_repository.dart';
import '../data/repositories/scores_repository.dart';
import '../data/repositories/subjects_repository.dart';
import '../data/secure/secret_store.dart';
import '../data/settings/settings_repository.dart';
import '../domain/licensing/entitlement.dart';
import 'app_config.dart';
import 'app_settings.dart';
import 'bootstrap.dart';

final clockProvider = Provider<Clock>((ref) => const Clock());

/// Licensing settings compiled into this build (empty in tests and test builds).
final licensingConfigProvider = Provider<LicensingConfig>((ref) => LicensingConfig.fromEnvironment());

final legalLinksProvider = Provider<LegalLinks>((ref) => LegalLinks.fromEnvironment());

/// Android Keystore-backed secrets (database key, PIN hash, install ID, session).
final secretStoreProvider = Provider<SecretStore>((ref) => KeystoreSecretStore());

final appBootstrapperProvider = Provider<AppBootstrapper>((ref) => AppBootstrapper.production());

/// Opens local storage once per app start. Every screen except the splash and
/// recovery screens needs [BootstrapReady] (enforced by the router).
final bootstrapControllerProvider = AsyncNotifierProvider<BootstrapController, BootstrapResult>(
  BootstrapController.new,
);

class BootstrapController extends AsyncNotifier<BootstrapResult> {
  @override
  Future<BootstrapResult> build() async {
    final bootstrapper = ref.read(appBootstrapperProvider);
    final started = DateTime.now();
    final result = await bootstrapper.run();
    if (result is BootstrapReady) {
      ref.onDispose(() => result.database.close());
    }
    final remaining = bootstrapper.minimumSplash - DateTime.now().difference(started);
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    return result;
  }

  /// Runs the startup sequence again (after an error or a restore).
  void retry() => ref.invalidateSelf();

  /// Sets an unreadable database aside and starts with an empty one.
  Future<void> startFresh() async {
    final current = state.value;
    if (current is! BootstrapNeedsRecovery) return;
    await ref.read(appBootstrapperProvider).setAsideUnreadableDatabase(current.databaseFile);
    ref.invalidateSelf();
  }
}

/// The open database. Only valid after a successful bootstrap.
final databaseProvider = Provider<AppDatabase>((ref) {
  final result = ref.watch(bootstrapControllerProvider).value;
  if (result is BootstrapReady) return result.database;
  throw StateError('The database is not open yet.');
});

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

/// Every setting, live, with defaults.
final settingsProvider = StreamProvider<UserSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watchAll().map(UserSettings.new),
);

/// The current settings (defaults until loaded).
final appSettingsProvider = Provider<UserSettings>((ref) => ref.watch(settingsProvider).value ?? UserSettings.defaults);

final rosterRepositoryProvider = Provider<RosterRepository>(
  (ref) => RosterRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final subjectsRepositoryProvider = Provider<SubjectsRepository>(
  (ref) => SubjectsRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final activitiesRepositoryProvider = Provider<ActivitiesRepository>(
  (ref) => ActivitiesRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final scoresRepositoryProvider = Provider<ScoresRepository>(
  (ref) => ScoresRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final gradebookServiceProvider = Provider<GradebookService>(
  (ref) => GradebookService(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final calcHistoryRepositoryProvider = Provider<CalcHistoryRepository>(
  (ref) => CalcHistoryRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final entitlementVerifierProvider = Provider<EntitlementVerifier>(
  (ref) => EntitlementVerifier(ref.watch(licensingConfigProvider).entitlementKeys),
);

final licenseRepositoryProvider = Provider<LicenseRepository>(
  (ref) => LicenseRepository(
    ref.watch(databaseProvider),
    ref.watch(settingsRepositoryProvider),
    configured: ref.watch(licensingConfigProvider).configured,
    verifier: ref.watch(entitlementVerifierProvider),
    clock: ref.watch(clockProvider),
  ),
);
