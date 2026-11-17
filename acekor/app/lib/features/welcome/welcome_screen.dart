import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/logo.dart';
import '../../data/settings/settings_repository.dart';
import 'sample_class.dart';

/// Shown once, on the first start.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;

  Future<void> _finish({required bool sample}) async {
    setState(() => _busy = true);
    try {
      if (sample) await createSampleClass(ref);
      await ref.read(settingsRepositoryProvider).setBool(SettingKeys.onboardingDone, true);
      if (mounted) context.go(Routes.home);
    } catch (e) {
      if (mounted) showMessage(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          children: [
            const Center(child: AcekorMark(size: 76)),
            const SizedBox(height: 18),
            const Center(child: AcekorWordmark(size: 30)),
            const SizedBox(height: 32),
            const _Step(
              icon: Icons.menu_book_outlined,
              text: 'Add your subject and class list (type them or import a CSV/Excel file).',
            ),
            const _Step(icon: Icons.search_rounded, text: 'Search a student and type the score on the big keypad.'),
            const _Step(
              icon: Icons.check_circle_outline,
              text: 'Tap the green check key to save. The percentage is computed for you.',
            ),
            const _Step(
              icon: Icons.phone_android,
              text:
                  'Your records stay on this phone, encrypted, and work without internet. '
                  'Make a backup now and then (Settings › Backup) — uninstalling the app or clearing its data erases records that are not backed up.',
            ),
            const SizedBox(height: 28),
            FilledButton(
              key: const ValueKey('get-started'),
              onPressed: _busy ? null : () => _finish(sample: false),
              child: const Text('Get started'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : () => _finish(sample: true),
              child: const Text('Try with a sample class'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.teal, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 18, height: 1.4, color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}
