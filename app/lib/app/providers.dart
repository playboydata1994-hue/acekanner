import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/util/clock.dart';
import '../data/audit/audit_logger.dart';
import '../data/db/app_database.dart';
import '../data/repositories/answer_key_repository.dart';
import '../data/repositories/classes_repository.dart';
import '../data/repositories/exams_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/students_repository.dart';
import '../data/settings/settings_repository.dart';
import '../platform/omr_engine_channel.dart';
import 'bootstrap.dart';

final clockProvider = Provider<Clock>((ref) => const Clock());

final appBootstrapperProvider =
    Provider<AppBootstrapper>((ref) => AppBootstrapper.production());

/// Opens local storage once per app start. Screens other than the splash and
/// recovery screens are only reachable after this completes with
/// [BootstrapReady] (enforced by the router).
final bootstrapControllerProvider =
    AsyncNotifierProvider<BootstrapController, BootstrapResult>(
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
    final remaining =
        bootstrapper.minimumSplash - DateTime.now().difference(started);
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    return result;
  }

  /// Runs the startup sequence again (after an error).
  void retry() => ref.invalidateSelf();

  /// Sets an unreadable database aside and starts with an empty one.
  Future<void> startFresh() async {
    final current = state.value;
    if (current is! BootstrapNeedsRecovery) return;
    await ref
        .read(appBootstrapperProvider)
        .setAsideUnreadableDatabase(current.databaseFile);
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
  (ref) => SettingsRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final omrEngineChannelProvider =
    Provider<OmrEngineChannel>((ref) => const OmrEngineChannel());

final auditLoggerProvider = Provider<AuditLogger>(
  (ref) => AuditLogger(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(databaseProvider),
    ref.watch(settingsRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final classesRepositoryProvider = Provider<ClassesRepository>(
  (ref) => ClassesRepository(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final studentsRepositoryProvider = Provider<StudentsRepository>(
  (ref) => StudentsRepository(
    ref.watch(databaseProvider),
    ref.watch(auditLoggerProvider),
    clock: ref.watch(clockProvider),
  ),
);

final examsRepositoryProvider = Provider<ExamsRepository>(
  (ref) => ExamsRepository(
    ref.watch(databaseProvider),
    ref.watch(auditLoggerProvider),
    clock: ref.watch(clockProvider),
  ),
);

final answerKeyRepositoryProvider = Provider<AnswerKeyRepository>(
  (ref) => AnswerKeyRepository(
    ref.watch(databaseProvider),
    ref.watch(auditLoggerProvider),
    ref.watch(examsRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);
