import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/licensing_providers.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/acekanner_logo.dart';
import '../../core/widgets/app_footnote.dart';
import '../plan/plan_widgets.dart';

/// Home: greeting, plan status, the round Scan button (quick check) and
/// blank answer sheets. Examinations are created and listed in the Exams tab.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).now();
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: Space.page,
        title: const Row(
          children: [
            AcekannerLogo(size: 32),
            SizedBox(width: Space.m),
            AcekannerWordmark(fontSize: 22),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            Space.s,
            Space.page,
            Space.xxl,
          ),
          children: [
            _Greeting(now: now, name: profile.value?.fullName),
            const SizedBox(height: Space.l),
            if (profile.hasValue && profile.value == null) ...[
              const _ProfilePrompt(),
              const SizedBox(height: Space.m),
            ],
            const _PlanCard(),
            const SizedBox(height: Space.xl),
            const _QuickCheckButton(),
            const SizedBox(height: Space.l),
            OutlinedButton.icon(
              onPressed: () => context.push(Routes.blankSheets),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print blank answer sheets'),
            ),
            const SizedBox(height: Space.xl),
            const _OfflineNote(),
            const SizedBox(height: Space.l),
            const AppFootnote(),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.now, this.name});

  final DateTime now;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name == null ? greeting : '$greeting, ${name!.split(' ').first}',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: Space.xs),
        Text(
          DateFormat('EEEE, d MMMM y').format(now),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(licenseStatusProvider).value;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.plan),
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: status == null
              ? const SizedBox(height: 96, child: Center(child: CircularProgressIndicator()))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlanSummary(status: status),
                    const SizedBox(height: Space.s),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        status.premiumActive ? 'Plan and account ›' : 'Plan, sign-in and Premium ›',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProfilePrompt extends StatelessWidget {
  const _ProfilePrompt();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.badge_outlined, color: scheme.onPrimaryContainer),
        title: Text(
          'Add your name and school',
          style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'They appear on answer sheets and reports.',
          style: TextStyle(color: scheme.onPrimaryContainer),
        ),
        trailing: Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
        onTap: () => _openProfile(context),
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 16, color: color),
        const SizedBox(width: Space.s),
        Flexible(
          child: Text(
            'Works offline · Your data is encrypted on this phone',
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

Future<void> _openProfile(BuildContext context) async {
  final saved = await context.push<bool>(Routes.profile);
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profile saved')));
  }
}

/// Round brand-blue "Scan" button with the ACEkanner mark: opens the
/// scanner for any ACEkanner answer sheet (quick check: nothing saved, each
/// check counted as a scan).
class _QuickCheckButton extends ConsumerWidget {
  const _QuickCheckButton();

  static const double _size = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Future<void> open() async {
      final status = await ref.read(licenseRepositoryProvider).status();
      if (!context.mounted) return;
      if (status.block != null) {
        await showScanBlocked(context, status.block!);
      } else {
        await context.push(Routes.quickCheck);
      }
    }

    return Center(
      child: Semantics(
        button: true,
        label: 'Scan an answer sheet',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: BrandColors.blue,
              shape: const CircleBorder(),
              elevation: 4,
              shadowColor: BrandColors.blue.withValues(alpha: 0.5),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: open,
                customBorder: const CircleBorder(),
                child: const SizedBox.square(
                  dimension: _size,
                  child: Center(child: AcekannerLogo(size: _size * 0.86, background: LogoBackground.none)),
                ),
              ),
            ),
            const SizedBox(height: Space.s),
            Text('Scan', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
