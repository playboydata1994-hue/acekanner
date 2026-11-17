import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/licensing_providers.dart';
import '../../app/plan_lifecycle.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/licensing/billing.dart';
import '../../data/licensing/license_api.dart';
import '../../domain/licensing/entitlement.dart';
import '../../domain/licensing/plan_status.dart';
import 'plan_actions.dart';
import 'plan_text.dart';

const List<String> proFeatures = [
  'Unlimited quiz and recitation recording',
  'Student roster, multiple subjects, classes and sections',
  'Automatic percentages; custom quiz and recitation points',
  'Weighted quiz and recitation grades',
  'Score history and academic records',
  'PDF and Excel reports',
  'Works offline; backup and restore',
];

const List<String> maxFeatures = [
  'Everything in PRO, plus:',
  'Preliminary, midterm, final and written examinations',
  'Practical and laboratory examinations',
  'Performance assessments and skills demonstrations',
  'Custom examination categories',
  'Advanced grading configuration (all weights)',
  'Examination reports and additional class analytics',
];

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(billingControllerProvider.notifier).load());
  }

  Future<void> _buy(Tier tier) async {
    if (!await signInFlow(context, ref) || !mounted) return;
    await ensureNotificationPermission(ref);
    await ref.read(billingControllerProvider.notifier).buy(tier);
  }

  Future<void> _manage() async {
    final status = ref.read(planStatusProvider);
    final sku = status.paidTier == Tier.max ? AppConstants.maxProductId : AppConstants.proProductId;
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions?sku=$sku&package=${AppConstants.applicationId}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(planStatusProvider);
    final billing = ref.watch(billingControllerProvider);
    final configured = ref.watch(licensingConfigProvider).configured;
    final account = ref.watch(authAccountProvider).value;
    ref.listen(billingControllerProvider, (prev, next) {
      if (next.message != null && next.message != prev?.message && next.phase != BillingPhase.loading) {
        showMessage(context, next.message!, error: next.phase == BillingPhase.error);
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _StatusCard(status: status),
          if (!configured)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Test build: the trial runs on this phone only and purchases are turned off. '
                'The Google Play version checks plans with Google.',
                style: TextStyle(color: AppColors.amber, fontSize: 15),
              ),
            ),
          if (!status.trialUsed && status.paidTier == Tier.none)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: FilledButton.icon(
                key: const ValueKey('start-trial'),
                onPressed: () => startTrialFlow(context, ref),
                icon: const Icon(Icons.card_giftcard),
                label: const Text('Start 7-day free trial'),
              ),
            ),
          _PlanCard(
            tier: Tier.pro,
            price: billing.prices[Tier.pro] ?? '₱${AppConstants.proPricePhp}',
            features: proFeatures,
            status: status,
            busy: billing.busy,
            enabled: configured,
            onBuy: () => _buy(Tier.pro),
          ),
          _PlanCard(
            tier: Tier.max,
            price: billing.prices[Tier.max] ?? '₱${AppConstants.maxPricePhp}',
            features: maxFeatures,
            status: status,
            busy: billing.busy,
            enabled: configured,
            onBuy: () => _buy(Tier.max),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Yearly subscriptions through Google Play; they renew automatically until you cancel. '
              'When a plan ends, your records stay on the phone and can still be viewed and exported.',
              style: TextStyle(fontSize: 15, color: AppColors.muted, height: 1.4),
            ),
          ),
          if (billing.busy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (configured) ...[
            const SectionTitle('Account'),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(account?.email ?? 'Not signed in'),
              subtitle: const Text('Only used for your trial and subscription'),
              trailing: account == null
                  ? TextButton(onPressed: () => signInFlow(context, ref), child: const Text('Sign in'))
                  : null,
            ),
            if (account != null) ...[
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Check plan now'),
                onTap: () => checkInFlow(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore purchase'),
                onTap: () => ref.read(billingControllerProvider.notifier).restore(),
              ),
              if (status.paidTier != Tier.none)
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('Manage subscription in Google Play'),
                  subtitle: const Text('Cancel, change payment method'),
                  onTap: _manage,
                ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  final ok = await confirm(
                    context,
                    title: 'Sign out?',
                    message: 'Paid features lock on this phone until you sign in again. Your records are not affected.',
                    confirmLabel: 'Sign out',
                  );
                  if (ok) await ref.read(licenseServiceProvider).signOut();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.red),
                title: const Text('Delete licensing account'),
                subtitle: const Text('Removes your account from ACEKOR\'s server. Records on the phone stay.'),
                onTap: () async {
                  final ok = await confirm(
                    context,
                    title: 'Delete your licensing account?',
                    message:
                        'Cancel any subscription in Google Play first. The free trial cannot be started again '
                        'with this Google account. Records on this phone are not deleted.',
                    confirmLabel: 'Delete account',
                    destructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  try {
                    await ref.read(licenseServiceProvider).deleteAccount();
                    if (context.mounted) showMessage(context, 'Your licensing account was deleted.');
                  } on LicenseApiException catch (e) {
                    if (context.mounted) showMessage(context, e.message, error: true);
                  }
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});
  final PlanStatus status;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      if (status.trialStarted != null) ('Trial started', longDate(status.trialStarted!)),
      if (status.trialEnds != null) ('Trial ends', longDate(status.trialEnds!)),
      if (status.trialActive) ('Trial days left', '${status.trialDaysLeft}'),
      if (status.paidTier != Tier.none) ('Subscription', status.paidTier.label),
      if (status.paidUntil != null) (status.autoRenew ? 'Renews on' : 'Expires on', longDate(status.paidUntil!)),
      if (status.entitlement != null) ('Last checked', longDate(status.entitlement!.verifiedAt)),
    ];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(switch (status.tier) {
            Tier.max => status.isTrialOnly ? 'FREE TRIAL (all features)' : 'MAX',
            Tier.pro => 'PRO',
            Tier.none => 'NO ACTIVE PLAN',
          }, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.teal)),
          const SizedBox(height: 4),
          Text(planSummary(status), style: const TextStyle(fontSize: 17)),
          if (rows.isNotEmpty) const SizedBox(height: 12),
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(k, style: const TextStyle(fontSize: 16, color: AppColors.muted)),
                  ),
                  Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.tier,
    required this.price,
    required this.features,
    required this.status,
    required this.busy,
    required this.enabled,
    required this.onBuy,
  });

  final Tier tier;
  final String price;
  final List<String> features;
  final PlanStatus status;
  final bool busy;
  final bool enabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final current = status.paidActive && status.paidTier == tier;
    final upgrade = tier == Tier.max && status.paidActive && status.paidTier == Tier.pro;
    final lower = tier == Tier.pro && status.paidActive && status.paidTier == Tier.max;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tier == Tier.max ? AppColors.teal : AppColors.outline,
          width: tier == Tier.max ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tier.label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(
                '$price / year',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.teal),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(f.endsWith(':') ? Icons.add : Icons.check, size: 20, color: AppColors.save),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 16, height: 1.3))),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: current
                ? const OutlinedButton(onPressed: null, child: Text('Your plan'))
                : lower
                ? const OutlinedButton(onPressed: null, child: Text('Included in MAX'))
                : FilledButton(
                    onPressed: busy || !enabled ? null : onBuy,
                    child: Text(upgrade ? 'Upgrade to MAX' : 'Choose ${tier.label}'),
                  ),
          ),
          if (upgrade)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Google Play charges only the difference for the rest of your PRO year.',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
