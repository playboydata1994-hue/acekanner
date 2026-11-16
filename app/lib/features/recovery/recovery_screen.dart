import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/bootstrap.dart';
import '../../app/providers.dart';
import '../../core/theme/spacing.dart';

/// Shown when the encrypted database exists but cannot be unlocked, usually
/// because Android reset the phone's secure key storage.
class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  bool _busy = false;

  Future<void> _startFresh() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start with an empty database?'),
        content: const Text(
          'ACEkanner will create a new, empty database. The locked file is '
          'kept on this phone and is not deleted, but ACEkanner cannot read it '
          'without its key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start fresh'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(bootstrapControllerProvider.notifier).startFresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = ref.watch(bootstrapControllerProvider).value;
    final reason = result is BootstrapNeedsRecovery ? result.reason : null;
    final explanation = switch (reason) {
      RecoveryReason.keyRejected =>
        'The key stored on this phone does not unlock your examination data.',
      _ =>
        'The key that unlocks your examination data is no longer in this '
            "phone's secure storage. This can happen after a system reset of "
            'the secure storage or a change to the screen lock.',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Data can’t be unlocked')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.page),
          children: [
            Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: Space.l),
            Text(explanation, style: theme.textTheme.bodyLarge),
            const SizedBox(height: Space.m),
            Text(
              'Your data is encrypted so that nobody can read it without that '
              'key, including ACEkanner. “Try again” is safe and changes '
              'nothing. “Start fresh” keeps the locked file and begins a new, '
              'empty database.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => ref.read(bootstrapControllerProvider.notifier).retry(),
              child: const Text('Try again'),
            ),
            const SizedBox(height: Space.m),
            OutlinedButton(
              onPressed: _busy ? null : _startFresh,
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start fresh'),
            ),
          ],
        ),
      ),
    );
  }
}
