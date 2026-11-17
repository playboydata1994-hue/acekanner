import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:acekanner/app/bootstrap.dart';
import 'package:acekanner/app/providers.dart';
import 'package:acekanner/data/secure/secret_store.dart';
import 'package:acekanner/features/splash/splash_screen.dart';

/// Start-up that never finishes, so the splash screen stays on screen.
class _Waiting extends AppBootstrapper {
  _Waiting()
      : super(
          dataDirectory: () => throw UnimplementedError(),
          secrets: MemorySecretStore(),
          openExecutor: (_, _) => throw UnimplementedError(),
        );

  @override
  Future<BootstrapResult> run() => Completer<BootstrapResult>().future;
}

void main() {
  testWidgets('the start-up screen shows the developer credit', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [appBootstrapperProvider.overrideWithValue(_Waiting())],
      child: const MaterialApp(home: SplashScreen()),
    ));
    await tester.pump();
    expect(find.text('Developed by NYE94'), findsOneWidget);
  });
}
