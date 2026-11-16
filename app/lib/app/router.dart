import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/classes/classes_screen.dart';
import '../features/classes/roster_import_screen.dart';
import '../features/classes/section_detail_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/exams/answer_key_screen.dart';
import '../features/exams/deleted_exams_screen.dart';
import '../features/exams/exam_detail_screen.dart';
import '../features/exams/exam_form_screen.dart';
import '../features/exams/exams_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/recovery/recovery_screen.dart';
import '../features/results/analytics_screen.dart';
import '../features/results/paper_result_screen.dart';
import '../features/scanner/scan_screen.dart';
import '../features/sheets/sheets_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/splash/splash_screen.dart';
import 'bootstrap.dart';
import 'providers.dart';

abstract final class Routes {
  static const String splash = '/';
  static const String recovery = '/recovery';
  static const String onboarding = '/onboarding';
  static const String replayOnboarding = '/onboarding?replay=1';
  static const String home = '/home';
  static const String exams = '/exams';
  static const String examTrash = '/exams/trash';
  static const String newExam = '/exam-editor/new';
  static const String classes = '/classes';
  static const String settings = '/settings';
  static const String about = '/settings/about';
  static const String privacy = '/settings/privacy';
  static const String profile = '/profile';

  static String exam(String id) => '/exams/$id';
  static String editExam(String id) => '/exam-editor/$id';
  static String answerKey(String versionId) => '/answer-key/$versionId';
  static String section(String id) => '/classes/sections/$id';
  static String rosterImport(String sectionId) => '/roster-import/$sectionId';
  static String sheets(String examId) => '/sheets/$examId';
  static String analytics(String examId) => '/exams/$examId/analytics';
  static String paper(String examId, String sheetId) => '/exams/$examId/papers/$sheetId';
  static String scan(String examId) => '/scan/$examId';
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final refresh = ValueNotifier<int>(0);
  ref.listen(bootstrapControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootKey,
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
      StatefulShellRoute(
        builder: (_, _, shell) => HomeShell(shell: shell),
        navigatorContainerBuilder: (_, shell, children) =>
            BranchStack(currentIndex: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (_, _) => const DashboardScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.exams,
                builder: (_, _) => const ExamsScreen(),
                routes: [
                  GoRoute(path: 'trash', builder: (_, _) => const DeletedExamsScreen()),
                  GoRoute(
                    path: ':examId',
                    builder: (_, state) => ExamDetailScreen(examId: state.pathParameters['examId']!),
                    routes: [
                      GoRoute(
                        path: 'analytics',
                        builder: (_, state) => AnalyticsScreen(examId: state.pathParameters['examId']!),
                      ),
                      GoRoute(
                        path: 'papers/:sheetId',
                        builder: (_, state) => PaperResultScreen(sheetId: state.pathParameters['sheetId']!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.classes,
                builder: (_, _) => const ClassesScreen(),
                routes: [
                  GoRoute(
                    path: 'sections/:sectionId',
                    builder: (_, state) =>
                        SectionDetailScreen(sectionId: state.pathParameters['sectionId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => const SettingsScreen(),
                routes: [
                  GoRoute(path: 'about', builder: (_, _) => const AboutScreen()),
                  GoRoute(path: 'privacy', builder: (_, _) => const PrivacyScreen()),
                ],
              ),
            ],
          ),
        ],
      ),
      // Full-screen editors (no bottom navigation). Each has its own
      // ScaffoldMessenger so its messages never leak onto other screens;
      // results the user should see after closing are shown by the caller.
      GoRoute(
        path: Routes.profile,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const ScaffoldMessenger(child: ProfileScreen()),
      ),
      GoRoute(
        path: Routes.newExam,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const ScaffoldMessenger(child: ExamFormScreen()),
      ),
      GoRoute(
        path: '/exam-editor/:examId',
        parentNavigatorKey: rootKey,
        builder: (_, state) => ScaffoldMessenger(
          child: ExamFormScreen(examId: state.pathParameters['examId']),
        ),
      ),
      GoRoute(
        path: '/answer-key/:versionId',
        parentNavigatorKey: rootKey,
        builder: (_, state) => ScaffoldMessenger(
          child: AnswerKeyScreen(versionId: state.pathParameters['versionId']!),
        ),
      ),
      GoRoute(
        path: '/sheets/:examId',
        parentNavigatorKey: rootKey,
        builder: (_, state) => ScaffoldMessenger(child: SheetsScreen(examId: state.pathParameters['examId']!)),
      ),
      GoRoute(
        path: '/scan/:examId',
        parentNavigatorKey: rootKey,
        builder: (_, state) => ScaffoldMessenger(child: ScanScreen(examId: state.pathParameters['examId']!)),
      ),
      GoRoute(
        path: '/roster-import/:sectionId',
        parentNavigatorKey: rootKey,
        builder: (_, state) => ScaffoldMessenger(
          child: RosterImportScreen(sectionId: state.pathParameters['sectionId']!),
        ),
      ),
    ],
  );
});
