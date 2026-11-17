import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:acekanner/app/app.dart';
import 'package:acekanner/app/bootstrap.dart';
import 'package:acekanner/app/providers.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/secure/secret_store.dart';
import 'package:acekanner/data/settings/settings_repository.dart';
import 'package:acekanner/features/settings/about_screen.dart';
import 'package:acekanner/platform/omr_engine_channel.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Bootstrapper that hands the app an in-memory database (no file I/O, so it
/// runs inside the widget-test fake clock).
class InMemoryBootstrapper extends AppBootstrapper {
  InMemoryBootstrapper(this.db, {this.onboarded = false})
      : super(
          dataDirectory: () => throw UnimplementedError(),
          secrets: MemorySecretStore(),
          openExecutor: (_, _) => throw UnimplementedError(),
          minimumSplash: Duration.zero,
        );

  final AppDatabase db;
  final bool onboarded;

  @override
  Future<BootstrapResult> run() async {
    final done = await SettingsRepository(db).getBool(SettingKeys.onboardingCompleted);
    return BootstrapReady(
      database: db,
      onboardingCompleted: onboarded || done,
      cipherVersion: null,
      databaseFile: File('in-memory.db'),
    );
  }
}

/// Host tests have no Android engine; mimic the real "not available" answer.
class HostEngine extends OmrEngineChannel {
  const HostEngine();

  @override
  Future<EngineInfo> engineInfo() async => const EngineInfo.unavailable(
        'The scanner engine runs on Android phones only',
      );
}

AppDatabase newTestAppDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Pumps the whole app on [db] and waits for startup to finish.
Future<void> pumpApp(
  WidgetTester tester,
  AppDatabase db, {
  bool onboarded = true,
  List<Override> overrides = const [],
  SecretStore? secrets,
}) async {
  // A tall phone screen so long forms fit without scrolling.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        appBootstrapperProvider.overrideWithValue(InMemoryBootstrapper(db, onboarded: onboarded)),
        omrEngineChannelProvider.overrideWithValue(const HostEngine()),
        secretStoreProvider.overrideWithValue(secrets ?? MemorySecretStore()),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'ACEkanner',
            packageName: 'com.acekanner.app',
            version: '0.2.0',
            buildNumber: '2',
          ),
        ),
        ...overrides,
      ],
      child: const AcekannerApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Disposes the app (closing streams) so no timers leak between tests.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}

/// Taps a bottom-navigation destination by its label.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}
