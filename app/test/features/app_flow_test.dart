import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

import '../support/test_db.dart';

/// Bootstrapper that hands the app an in-memory database (no file I/O, so it
/// runs inside the widget-test fake clock).
class _InMemoryBootstrapper extends AppBootstrapper {
  _InMemoryBootstrapper(this.db, {this.onboarded = false})
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
    final done =
        await SettingsRepository(db).getBool(SettingKeys.onboardingCompleted);
    return BootstrapReady(
      database: db,
      onboardingCompleted: onboarded || done,
      cipherVersion: null,
      databaseFile: File('in-memory.db'),
    );
  }
}

/// Host tests have no Android engine; mimic the real "not available" answer.
class _HostEngine extends OmrEngineChannel {
  const _HostEngine();

  @override
  Future<EngineInfo> engineInfo() async => const EngineInfo.unavailable(
        'The scanner engine runs on Android phones only',
      );
}

void main() {
  late AppDatabase db;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
  });

  Future<void> pumpApp(WidgetTester tester, {bool onboarded = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          appBootstrapperProvider.overrideWithValue(
            _InMemoryBootstrapper(db, onboarded: onboarded),
          ),
          omrEngineChannelProvider.overrideWithValue(const _HostEngine()),
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'ACEkanner',
              packageName: 'com.acekanner.app',
              version: '0.2.0',
              buildNumber: '2',
            ),
          ),
        ],
        child: const AcekannerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets('first launch: onboarding, then the dashboard', (tester) async {
    await pumpApp(tester);

    expect(find.text('Scan, check and grade in seconds'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Works offline. Data stays on your phone.'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.textContaining('of 100 free scans left'), findsOneWidget);
    expect(find.text('No examinations yet'), findsOneWidget);
    expect(
      await SettingsRepository(db).getBool(SettingKeys.onboardingCompleted),
      isTrue,
    );
    await tearDownApp(tester);
  });

  testWidgets('dashboard shows live totals and recent examinations', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, onboarded: true);
    expect(find.text('No examinations yet'), findsOneWidget);

    await insertExam(db, id: 'e1', title: 'Prelim Examination', itemCount: 75);
    await insertSheet(db, id: 's1', examId: 'e1');
    await insertLedger(db, id: 'L1', submissionKey: hex64(9));
    await tester.pumpAndSettle();

    expect(find.text('Prelim Examination'), findsOneWidget);
    expect(find.text('75 items · 1 paper'), findsOneWidget);
    expect(find.textContaining('of 100 free scans left'), findsOneWidget);
    // The plan card is one merged accessibility node (read as a unit).
    expect(find.bySemanticsLabel(RegExp('99 of 100 free scans left')), findsOneWidget);
    expect(find.bySemanticsLabel('Examinations: 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Papers scanned: 1'), findsOneWidget);
    await tearDownApp(tester);
    semantics.dispose();
  });

  testWidgets('settings and about show storage and engine status', (tester) async {
    await pumpApp(tester, onboarded: true);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('About ACEkanner'));
    await tester.pumpAndSettle();
    expect(find.text('Not encrypted (development build)'), findsOneWidget);
    expect(find.textContaining('Android phones only'), findsOneWidget);
    expect(find.text('Version 1'), findsOneWidget);
    expect(find.text('Version 0.2.0 (build 2)'), findsOneWidget);
    expect(find.text('com.acekanner.app'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('introduction can be replayed from settings', (tester) async {
    await pumpApp(tester, onboarded: true);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Introduction'));
    await tester.pumpAndSettle();

    expect(find.text('Scan, check and grade in seconds'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tearDownApp(tester);
  });
}
