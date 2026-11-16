import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        // Never surface stack traces to users; keep them in debug output.
        FlutterError.presentError(details);
      };
      runApp(
        ProviderScope(
          // Startup and database errors are shown with an explicit
          // "Try again" button instead of silent automatic retries.
          retry: (retryCount, error) => null,
          child: const AcekannerApp(),
        ),
      );
    },
    (error, stack) {
      if (kDebugMode) debugPrint('Uncaught error: $error\n$stack');
    },
  );
}
