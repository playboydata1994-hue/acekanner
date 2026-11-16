import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/recovery/recovery_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import 'bootstrap.dart';
import 'providers.dart';

abstract final class Routes {
  static const String splash = '/';
  static const String recovery = '/recovery';
  static const String onboarding = '/onboarding';
  static const String replayOnboarding = '/onboarding?replay=1';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String about = '/settings/about';
  static const String privacy = '/settings/privacy';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(bootstrapControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final boot = ref.read(bootstrapControllerProvider);
      final location = state.matchedLocation;
      final result = boot.value;
      if (boot.isLoading || boot.hasError || result == null) {
        return location == Routes.splash ? null : Routes.splash;
      }
      switch (result) {
        case BootstrapNeedsRecovery():
          return location == Routes.recovery ? null : Routes.recovery;
        case BootstrapReady(:final onboardingCompleted):
          if (location == Routes.splash || location == Routes.recovery) {
            return onboardingCompleted ? Routes.home : Routes.onboarding;
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.recovery, builder: (_, _) => const RecoveryScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, state) => OnboardingScreen(
          replay: state.uri.queryParameters['replay'] == '1',
        ),
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const DashboardScreen()),
      GoRoute(
        path: Routes.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(path: 'about', builder: (_, _) => const AboutScreen()),
          GoRoute(path: 'privacy', builder: (_, _) => const PrivacyScreen()),
        ],
      ),
    ],
  );
});
