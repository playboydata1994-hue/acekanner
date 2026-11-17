import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/logo.dart';
import '../../data/db/database_opener.dart';

/// Opens the encrypted database. Errors show a clear "Try again".
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(bootstrapControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AcekorMark(size: 88),
                const SizedBox(height: 24),
                const AcekorWordmark(),
                const SizedBox(height: 40),
                if (boot.hasError) ...[
                  Text(
                    boot.error is DatabaseEncryptionUnavailableException
                        ? 'This phone could not start ACEKOR\'s encrypted storage.'
                        : 'ACEKOR could not open its records.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: AppColors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nothing was deleted. Close the app and open it again, or tap Try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppColors.muted),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => ref.read(bootstrapControllerProvider.notifier).retry(),
                    child: const Text('Try again'),
                  ),
                ] else
                  const CircularProgressIndicator(color: AppColors.teal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
