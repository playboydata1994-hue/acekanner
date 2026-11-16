import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/acekanner_logo.dart';
import '../../data/db/database_opener.dart';

/// Brand screen shown while the encrypted local database opens. Navigation
/// away from it is handled by the router once startup completes.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(bootstrapControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AcekannerLogo(size: 96),
                const SizedBox(height: Space.xl),
                const AcekannerWordmark(fontSize: 34),
                const SizedBox(height: Space.s),
                Text(
                  'Scan · Check · Grade',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: Space.xxl + Space.l),
                if (boot.hasError && !boot.isLoading)
                  _StartupError(
                    error: boot.error!,
                    onRetry: () =>
                        ref.read(bootstrapControllerProvider.notifier).retry(),
                  )
                else
                  const _Loading(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: Space.l),
        Text(
          'Preparing your local database…',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = error is DatabaseEncryptionUnavailableException
        ? 'This copy of ACEkanner cannot encrypt its database, so it stopped '
            'to protect student data. Please reinstall ACEkanner from Google Play.'
        : 'ACEkanner could not open its local database. Your data has not been '
            'changed. Please try again; if this keeps happening, restart your phone.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 32),
            const SizedBox(height: Space.m),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: Space.s),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: Space.s),
            Text(
              'Details: ${error.runtimeType}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.l),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
