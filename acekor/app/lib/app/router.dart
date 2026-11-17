import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/categories.dart';
import '../features/calculator/calculator_screen.dart';
import '../features/menu/menu_screen.dart';
import '../features/mini_calculator/mini_calculator_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/records/gradebook_screen.dart';
import '../features/records/history_screen.dart';
import '../features/records/records_screen.dart';
import '../features/recovery/recovery_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/roster/deleted_students_screen.dart';
import '../features/roster/import_screen.dart';
import '../features/roster/sections_screen.dart';
import '../features/roster/student_form_screen.dart';
import '../features/roster/student_profile_screen.dart';
import '../features/roster/students_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/backup_screen.dart';
import '../features/settings/calculator_settings_screen.dart';
import '../features/settings/categories_screen.dart';
import '../features/settings/lock_settings_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/profile_screen.dart';
import '../features/settings/scales_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/subjects/activity_form_screen.dart';
import '../features/subjects/activity_screen.dart';
import '../features/subjects/deleted_subjects_screen.dart';
import '../features/subjects/enrol_screen.dart';
import '../features/subjects/grading_screen.dart';
import '../features/subjects/subject_form_screen.dart';
import '../features/subjects/subject_screen.dart';
import '../features/subjects/subjects_screen.dart';
import '../features/welcome/welcome_screen.dart';
import 'bootstrap.dart';
import 'providers.dart';
import 'routes.dart';

GoRoute _page(String path, Widget Function(GoRouterState s) build) =>
    GoRoute(path: path, builder: (_, state) => build(state));

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
            return onboardingCompleted ? Routes.home : Routes.welcome;
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.recovery, builder: (_, _) => const RecoveryScreen()),
      _page(Routes.welcome, (_) => const WelcomeScreen()),
      _page(Routes.home, (_) => const CalculatorScreen()),
      _page(Routes.menu, (_) => const MenuScreen()),
      _page(Routes.miniCalculator, (_) => const MiniCalculatorScreen()),

      _page(Routes.students, (_) => const StudentsScreen()),
      _page(Routes.newStudent, (s) => StudentFormScreen(sectionId: s.uri.queryParameters['section'])),
      _page(Routes.importStudents, (s) => ImportScreen(subjectId: s.uri.queryParameters['subject'])),
      _page(Routes.deletedStudents, (_) => const DeletedStudentsScreen()),
      _page('/students/:id', (s) => StudentProfileScreen(studentId: s.pathParameters['id']!)),
      _page('/students/:id/edit', (s) => StudentFormScreen(studentId: s.pathParameters['id'])),
      _page(Routes.sections, (_) => const SectionsScreen()),

      _page(Routes.subjects, (_) => const SubjectsScreen()),
      _page(Routes.newSubject, (_) => const SubjectFormScreen()),
      _page(Routes.deletedSubjects, (_) => const DeletedSubjectsScreen()),
      _page('/subjects/:id', (s) => SubjectScreen(subjectId: s.pathParameters['id']!)),
      _page('/subjects/:id/edit', (s) => SubjectFormScreen(subjectId: s.pathParameters['id'])),
      _page('/subjects/:id/grading', (s) => GradingScreen(subjectId: s.pathParameters['id']!)),
      _page('/subjects/:id/enrol', (s) => EnrolScreen(subjectId: s.pathParameters['id']!)),
      _page(
        '/subjects/:id/new-activity',
        (s) => ActivityFormScreen(
          subjectId: s.pathParameters['id']!,
          kind:
              CategoryKind.values.where((k) => k.name == s.uri.queryParameters['kind']).firstOrNull ??
              CategoryKind.quiz,
        ),
      ),
      _page('/activities/:id', (s) => ActivityScreen(activityId: s.pathParameters['id']!)),
      _page('/activities/:id/edit', (s) => ActivityFormScreen(activityId: s.pathParameters['id'])),

      _page(Routes.records, (_) => const RecordsScreen()),
      _page('/records/:subjectId', (s) => GradebookScreen(subjectId: s.pathParameters['subjectId']!)),
      _page(
        '/history',
        (s) =>
            HistoryScreen(activityId: s.uri.queryParameters['activity'], studentId: s.uri.queryParameters['student']),
      ),
      _page(Routes.reports, (_) => const ReportsScreen()),
      _page(Routes.plan, (_) => const PlanScreen()),

      _page(Routes.settings, (_) => const SettingsScreen()),
      _page(Routes.calculatorSettings, (_) => const CalculatorSettingsScreen()),
      _page(Routes.profile, (_) => const ProfileScreen()),
      _page(Routes.scales, (_) => const ScalesScreen()),
      _page(Routes.newScale, (_) => const ScaleEditScreen()),
      _page('/settings/scales/:id', (s) => ScaleEditScreen(scaleId: s.pathParameters['id'])),
      _page(Routes.categories, (_) => const CategoriesScreen()),
      _page(Routes.backup, (_) => const BackupScreen()),
      _page(Routes.lock, (_) => const LockSettingsScreen()),
      _page(Routes.privacy, (_) => const PrivacyScreen()),
      _page(Routes.about, (_) => const AboutScreen()),
    ],
  );
});
