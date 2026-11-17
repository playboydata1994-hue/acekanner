import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import 'license_lifecycle.dart';
import 'router.dart';

class AcekannerApp extends ConsumerWidget {
  const AcekannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ACEkanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => LicenseLifecycle(child: child ?? const SizedBox.shrink()),
    );
  }
}
