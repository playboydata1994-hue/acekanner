import 'dart:io';

import 'package:acekor/app/app.dart';
import 'package:acekor/app/bootstrap.dart';
import 'package:acekor/app/plan_lifecycle.dart';
import 'package:acekor/app/providers.dart';
import 'package:acekor/data/db/app_database.dart';
import 'package:acekor/data/secure/secret_store.dart';
import 'package:acekor/features/lock/app_lock.dart';
import 'package:acekor/services/notifications/reminder_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class FakeBiometrics implements Biometrics {
  @override
  Future<bool> available() async => false;
  @override
  Future<bool> authenticate(String reason) async => false;
}

/// Runs the real app on an in-memory database, without licensing (test build).
class AppHarness {
  AppHarness();

  final MemorySecretStore secrets = MemorySecretStore();
  final NoReminderScheduler reminders = NoReminderScheduler();
  late ProviderContainer container;

  AppDatabase get db => container.read(databaseProvider);

  Future<void> pump(WidgetTester tester, {Size size = const Size(412, 892), double pixelRatio = 2.625}) async {
    tester.view.physicalSize = size * pixelRatio;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = Directory.systemTemp.createTempSync('acekor_test');
    final bootstrapper = AppBootstrapper(
      dataDirectory: () async => dir,
      secrets: secrets,
      openExecutor: (file, key) => NativeDatabase.memory(),
      minimumSplash: Duration.zero,
    );
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        appBootstrapperProvider.overrideWithValue(bootstrapper),
        secretStoreProvider.overrideWithValue(secrets),
        reminderSchedulerProvider.overrideWithValue(reminders),
        biometricsProvider.overrideWithValue(FakeBiometrics()),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AcekorApp()));
    await settle(tester);
  }

  /// Lets database streams and navigation finish (no endless animations).
  static Future<void> settle(WidgetTester tester, [int frames = 12]) async {
    for (var i = 0; i < frames; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(seconds: 5));
  }
}

/// The scores repository of the running app (for screenshots and tests).
final scoresRepoForShots = scoresRepositoryProvider;
