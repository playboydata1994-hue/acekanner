import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../core/util/clock.dart';
import '../data/db/app_database.dart';
import '../data/db/database_opener.dart';
import '../data/secure/database_key_manager.dart';
import '../data/secure/secret_store.dart';
import '../data/settings/settings_repository.dart';

/// Outcome of starting the app's local storage.
sealed class BootstrapResult {
  const BootstrapResult();
}

class BootstrapReady extends BootstrapResult {
  const BootstrapReady({
    required this.database,
    required this.onboardingCompleted,
    required this.cipherVersion,
    required this.databaseFile,
  });

  final AppDatabase database;
  final bool onboardingCompleted;

  /// SQLCipher version, or null if the database is not encrypted (tests only).
  final String? cipherVersion;
  final File databaseFile;
}

enum RecoveryReason {
  /// The database exists but its key is no longer in secure storage.
  keyMissing,

  /// A key exists but does not open the database.
  keyRejected,
}

class BootstrapNeedsRecovery extends BootstrapResult {
  const BootstrapNeedsRecovery({required this.reason, required this.databaseFile});

  final RecoveryReason reason;
  final File databaseFile;
}

typedef ExecutorFactory = QueryExecutor Function(File file, String hexKey);

/// Opens (or creates) the encrypted database and reads startup settings.
class AppBootstrapper {
  AppBootstrapper({
    required this.dataDirectory,
    required this.secrets,
    required this.openExecutor,
    this.clock = const Clock(),
    this.minimumSplash = const Duration(milliseconds: 700),
  });

  /// Production configuration: app-private storage, Android Keystore, SQLCipher.
  factory AppBootstrapper.production() => AppBootstrapper(
    dataDirectory: getApplicationSupportDirectory,
    secrets: KeystoreSecretStore(),
    openExecutor: (file, key) => openEncryptedDatabase(file, hexKey: key),
  );

  static const String databaseFileName = 'acekor.db';

  final Future<Directory> Function() dataDirectory;
  final SecretStore secrets;
  final ExecutorFactory openExecutor;
  final Clock clock;

  /// Keeps the splash screen up long enough not to flash.
  final Duration minimumSplash;

  Future<BootstrapResult> run() async {
    final dir = await dataDirectory();
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, databaseFileName));

    final outcome = await DatabaseKeyManager(secrets).obtain(databaseExists: await file.exists());
    switch (outcome) {
      case DatabaseKeyMissing():
        return BootstrapNeedsRecovery(reason: RecoveryReason.keyMissing, databaseFile: file);
      case DatabaseKeyReady(:final hexKey):
        final db = AppDatabase(openExecutor(file, hexKey));
        try {
          // The first query opens the file, applies the key and runs migrations.
          final cipher = await db.cipherVersion();
          final onboarded = await SettingsRepository(db, clock: clock).getBool(SettingKeys.onboardingDone);
          return BootstrapReady(
            database: db,
            onboardingCompleted: onboarded,
            cipherVersion: cipher,
            databaseFile: file,
          );
        } catch (error) {
          await db.close();
          final cause = rootCause(error);
          if (cause is SqliteException && cause.resultCode == 26) {
            return BootstrapNeedsRecovery(reason: RecoveryReason.keyRejected, databaseFile: file);
          }
          if (cause != error) throw cause;
          rethrow;
        }
    }
  }

  /// Moves an unreadable database (and its WAL files) aside so a new one can
  /// be created. The old file is renamed, never deleted.
  Future<File> setAsideUnreadableDatabase(File file) async {
    final stamp = clock.now().toUtc().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '');
    final target = File(p.join(file.parent.path, 'acekor.locked-$stamp.db'));
    if (await file.exists()) await file.rename(target.path);
    for (final suffix in const ['-wal', '-shm']) {
      final side = File('${file.path}$suffix');
      if (await side.exists()) await side.rename('${target.path}$suffix');
    }
    return target;
  }

  /// Errors from the background database isolate may arrive wrapped.
  static Object rootCause(Object error) => error is DriftRemoteException ? error.remoteCause : error;
}
