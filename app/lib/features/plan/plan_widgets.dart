import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/status_pill.dart';
import '../../domain/licensing/license_status.dart';

String planDate(DateTime d) => DateFormat('d MMMM y').format(d.toLocal());

/// Plan summary used on the dashboard and the Plan screen.
class PlanSummary extends StatelessWidget {
  const PlanSummary({super.key, required this.status});

  final LicenseStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = context.statusColors;
    final premium = status.premiumActive;
    final limit = status.freeLimit;
    final remaining = status.freeRemaining;
    final block = status.block;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusPill(
          label: premium ? 'PREMIUM' : 'FREE PLAN',
          color: premium ? colors.premium : scheme.primary,
          icon: premium ? Icons.workspace_premium_outlined : Icons.verified_outlined,
        ),
        const SizedBox(height: Space.m),
        if (premium)
          Text(
            'Unlimited scans until ${planDate(status.entitlement!.premiumUntil!)}',
            style: theme.textTheme.titleMedium,
          )
        else if (status.configured && status.entitlement == null)
          Text('Sign in once to start your $limit free scans.', style: theme.textTheme.titleMedium)
        else ...[
          Semantics(
            label: '$remaining of $limit free scans left',
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$remaining', style: theme.textTheme.displaySmall?.copyWith(color: scheme.primary)),
                  TextSpan(text: '  of $limit free scans left', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.m),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: limit == 0 ? 1 : (status.freeUsed / limit).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
        if (status.configured && status.entitlement != null) ...[
          const SizedBox(height: Space.s),
          Text(
            status.offlineExpired
                ? 'Online check overdue. Connect to the internet to keep scanning.'
                : 'Works offline. Next online check needed by ${planDate(status.checkDueBy!)}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: status.offlineExpired || status.checkDueSoon ? colors.uncertain : scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (block != null && block != ScanBlock.signInRequired) ...[
          const SizedBox(height: Space.s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: colors.uncertain),
              const SizedBox(width: Space.s),
              Expanded(child: Text(scanBlockMessage(block), style: theme.textTheme.bodySmall)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Explains why scanning is blocked and offers the way forward.
Future<void> showScanBlocked(BuildContext context, ScanBlock block) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(switch (block) {
        ScanBlock.signInRequired => 'Sign in to scan',
        ScanBlock.checkInRequired => 'Connect to the internet',
        ScanBlock.leaseOnOtherPhone => 'Free scans are on your other phone',
        ScanBlock.freeUsedUp => 'Free scans used up',
      }),
      content: Text(scanBlockMessage(block)),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Not now')),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            context.push(Routes.plan);
          },
          child: Text(block == ScanBlock.freeUsedUp ? 'See Premium' : 'Plan and account'),
        ),
      ],
    ),
  );
}
