import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../features/lock/app_lock.dart';
import 'plan_lifecycle.dart';
import 'providers.dart';
import 'router.dart';

class AcekorApp extends ConsumerWidget {
  const AcekorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      title: 'ACEkor Grading Sheet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Optional larger text (Settings › Text size), on top of the phone's own setting.
        final media = MediaQuery.of(context);
        final factor = settings.textSize.factor;
        final scaled = MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear((media.textScaler.scale(1) * factor).clamp(1.0, 2.0))),
          child: child ?? const SizedBox.shrink(),
        );
        return PlanLifecycle(child: AppLockGate(child: scaled));
      },
    );
  }
}
