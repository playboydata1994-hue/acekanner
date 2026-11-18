import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/licensing/plan_status.dart';
import 'plan_actions.dart';

/// Explains why saving is locked and offers the way forward. Existing
/// records always stay viewable and exportable.
Future<void> showPaywall(BuildContext context, PlanBlock block, {Notify? notify}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _Paywall(block: block, notify: notify),
  );
}

class _Paywall extends ConsumerWidget {
  const _Paywall({required this.block, this.notify});
  final PlanBlock block;
  final Notify? notify;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (title, message) = switch (block) {
      PlanBlock.noPlan => (
        'Start your free 7-day trial',
        'Saving scores is part of PRO and MAX. Try everything free for 7 days — no payment needed.',
      ),
      PlanBlock.trialEnded => (
        'Your free trial has ended',
        'Choose PRO (₱399/year) or MAX (₱499/year) to keep saving scores. Your records stay on your phone, and you can still view and export them.',
      ),
      PlanBlock.expired => (
        'Your subscription has ended',
        'Renew to keep saving scores. Your records stay on your phone, and you can still view and export them.',
      ),
      PlanBlock.checkInRequired => (
        'Connect to the internet once',
        'ACEkor needs to confirm your subscription with Google Play (the last check was more than 30 days ago, or the phone\'s date changed).',
      ),
      PlanBlock.needsMax => (
        'Examinations are part of MAX',
        'Upgrade to MAX (₱499/year) to record preliminary, midterm, final, practical and other examinations. Google Play credits the unused part of PRO.',
      ),
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.workspace_premium_outlined, size: 56, color: AppColors.teal),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, height: 1.4, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            if (block == PlanBlock.noPlan)
              FilledButton(
                onPressed: () async {
                  final ok = await startTrialFlow(context, ref, notify: notify);
                  if (ok && context.mounted) Navigator.pop(context);
                },
                child: const Text('Start free trial'),
              )
            else if (block == PlanBlock.checkInRequired)
              FilledButton(
                onPressed: () async {
                  final ok = await checkInFlow(context, ref, notify: notify);
                  if (ok && context.mounted) Navigator.pop(context);
                },
                child: const Text('Check now'),
              )
            else
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(Routes.plan);
                },
                child: Text(block == PlanBlock.needsMax ? 'Upgrade to MAX' : 'See plans'),
              ),
            const SizedBox(height: 8),
            if (block == PlanBlock.noPlan)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(Routes.plan);
                },
                child: const Text('See plans and prices'),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not now')),
          ],
        ),
      ),
    );
  }
}
