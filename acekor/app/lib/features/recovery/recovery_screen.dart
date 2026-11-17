import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/bootstrap.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/feedback.dart';

/// The database exists but its key is gone (for example after the phone's
/// secure storage was reset). The locked file is never deleted.
class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(bootstrapControllerProvider).value;
    final reason = result is BootstrapNeedsRecovery ? result.reason : RecoveryReason.keyMissing;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const Icon(Icons.lock_reset, size: 72, color: AppColors.amber),
            const SizedBox(height: 16),
            const Text(
              'Your records are locked',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Text(
              reason == RecoveryReason.keyMissing
                  ? 'The phone\'s secure storage no longer has the key that unlocks ACEKOR\'s encrypted records. '
                        'This can happen after a system reset of the phone\'s security settings.'
                  : 'The saved key does not open ACEKOR\'s encrypted records.',
              style: const TextStyle(fontSize: 18, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'To continue, start with empty records and then restore your latest ACEKOR backup '
              '(Settings › Backup and restore). The locked file is kept on the phone, not deleted.',
              style: TextStyle(fontSize: 18, height: 1.4, color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'Start with empty records?',
                  message: 'The locked records are set aside (not deleted). You can then restore a backup.',
                  confirmLabel: 'Start',
                );
                if (ok) await ref.read(bootstrapControllerProvider.notifier).startFresh();
              },
              child: const Text('Start with empty records'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.read(bootstrapControllerProvider.notifier).retry(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
