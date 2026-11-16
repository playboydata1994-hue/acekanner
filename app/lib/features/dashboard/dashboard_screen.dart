import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/acekanner_logo.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/db/app_database.dart';
import 'dashboard_providers.dart';

/// Home dashboard: plan status, totals and recent examinations.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final recent = ref.watch(recentExaminationsProvider);
    final now = ref.watch(clockProvider).now();

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
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
          const SizedBox(width: Space.xs),
        ],
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
            _Greeting(now: now),
            const SizedBox(height: Space.l),
            switch (stats) {
              AsyncData(:final value) => _DashboardBody(stats: value),
              AsyncError() => const _LoadError(),
              _ => const _LoadingBlock(height: 260),
            },
            const SectionHeader('Recent examinations'),
            switch (recent) {
              AsyncData(:final value) when value.isEmpty => const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No examinations yet',
                  message: 'Examinations you create will appear here.',
                ),
              AsyncData(:final value) => _RecentList(items: value),
              AsyncError() => const _LoadError(),
              _ => const _LoadingBlock(height: 120),
            },
            const SizedBox(height: Space.xl),
            const _OfflineNote(),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.now});

  final DateTime now;

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
        Text(greeting, style: theme.textTheme.headlineSmall),
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

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern();
    return Column(
      children: [
        _PlanCard(stats: stats),
        const SizedBox(height: Space.m),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.assignment_outlined,
                value: number.format(stats.examCount),
                label: 'Examinations',
              ),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: StatCard(
                icon: Icons.fact_check_outlined,
                value: number.format(stats.papersScanned),
                label: 'Papers scanned',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const limit = AppConstants.freeScanLimit;
    final remaining = stats.freeScansRemaining;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusPill(
                  label: 'FREE PLAN',
                  color: scheme.primary,
                  icon: Icons.verified_outlined,
                ),
                const Spacer(),
                Text(
                  'Premium · PHP ${AppConstants.premiumPricePhp}/year',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: context.statusColors.premium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.m),
            Semantics(
              label: '$remaining of $limit free scans left',
              excludeSemantics: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$remaining',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: '  of $limit free scans left',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.m),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.freeScansUsed / limit,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: Space.m),
            Text(
              'Lifetime allowance. A scan is counted only when a student’s '
              'result is saved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.items});

  final List<RecentExaminationsResult> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(indent: Space.l, endIndent: Space.l),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text('${items[i].itemCount}'),
              ),
              title: Text(
                items[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(_subtitle(items[i])),
            ),
          ],
        ],
      ),
    );
  }

  static String _subtitle(RecentExaminationsResult e) {
    final parts = <String>[
      if (e.subjectCode != null) e.subjectCode!,
      '${e.itemCount} items',
      '${e.finalizedCount} ${e.finalizedCount == 1 ? 'paper' : 'papers'}',
    ];
    return parts.join(' · ');
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

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) => const EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load this section',
        message: 'Your data is safe. Close and reopen ACEkanner to try again.',
      );
}
