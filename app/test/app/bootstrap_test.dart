import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/app/bootstrap.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/db/database_opener.dart';
import 'package:acekanner/data/secure/database_key_manager.dart';
import 'package:acekanner/data/secure/secret_store.dart';
import 'package:acekanner/data/settings/settings_repository.dart';

void main() {
  late Directory dir;
  late MemorySecretStore secrets;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = await Directory.systemTemp.createTemp('acekanner_boot_');
    secrets = MemorySecretStore();
  });
  tearDown(() => dir.delete(recursive: true));

  // Host machines have no SQLCipher, so these tests open plain files. The
  // encrypted path is verified on a real phone (Settings › About).
  AppBootstrapper bootstrapper() => AppBootstrapper(
        dataDirectory: () async => dir,
        secrets: secrets,
        openExecutor: (file, key) => NativeDatabase(file),
        minimumSplash: Duration.zero,
      );

  test('first launch creates the key and an empty database', () async {
    final result = await bootstrapper().run();

    expect(result, isA<BootstrapReady>());
    final ready = result as BootstrapReady;
    expect(ready.onboardingCompleted, isFalse);
    expect(ready.cipherVersion, isNull);
    expect(await ready.databaseFile.exists(), isTrue);
    expect(secrets.values[DatabaseKeyManager.storageKey], isNotNull);
    await ready.database.close();
  });

  test('settings persist across launches', () async {
    final first = await bootstrapper().run() as BootstrapReady;
    await SettingsRepository(first.database)
        .setBool(SettingKeys.onboardingCompleted, true);
    await first.database.close();

    final second = await bootstrapper().run() as BootstrapReady;
    expect(second.onboardingCompleted, isTrue);
    await second.database.close();
  });

  test('a database whose key is gone goes to recovery, then can start fresh', () async {
    final first = await bootstrapper().run() as BootstrapReady;
    await first.database.close();
    secrets.values.clear();

    final b = bootstrapper();
    final locked = await b.run();
    expect(locked, isA<BootstrapNeedsRecovery>());
    expect((locked as BootstrapNeedsRecovery).reason, RecoveryReason.keyMissing);

    final aside = await b.setAsideUnreadableDatabase(locked.databaseFile);
    expect(await aside.exists(), isTrue, reason: 'locked data is kept');
    expect(aside.path, contains('acekanner.locked-'));

    final fresh = await b.run();
    expect(fresh, isA<BootstrapReady>());
    await (fresh as BootstrapReady).database.close();
  });

  test('the production opener refuses to create an unencrypted database', () async {
    final file = File('${dir.path}/plain.db');
    final db = AppDatabase(openEncryptedDatabase(file, hexKey: 'a' * 64));
    Object? caught;
    try {
      await db.cipherVersion();
    } catch (e) {
      caught = AppBootstrapper.rootCause(e);
    }
    expect(caught, isA<DatabaseEncryptionUnavailableException>());
    await db.close();
  });

  test('the opener rejects malformed keys', () {
    expect(
      () => openEncryptedDatabase(File('${dir.path}/x.db'), hexKey: "1' OR '1"),
      throwsArgumentError,
    );
  });
}
