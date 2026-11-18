import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/licensing_providers.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/legal_links.dart';
import '../../core/widgets/section_header.dart';
import '../../data/licensing/auth_service.dart';
import '../../data/licensing/billing.dart';
import '../../data/licensing/license_api.dart';
import '../../domain/licensing/license_status.dart';
import 'plan_widgets.dart';

/// Account, plan and Premium: sign-in, scan allowance, online check,
/// purchase, restore, manage and account deletion.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  String? _busy;

  @override
  void initState() {
    super.initState();
    if (ref.read(billingGatewayProvider) != null) {
      Future.microtask(() => ref.read(billingControllerProvider.notifier).load());
    }
  }

  Future<void> _run(String label, Future<void> Function() action, {String? done}) async {
    if (_busy != null) return;
    setState(() => _busy = label);
    try {
      await action();
      if (mounted && done != null) showMessage(context, done);
    } on AuthFailure catch (e) {
      if (mounted && !e.cancelled) showMessage(context, e.message);
    } on LicenseApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await confirmAction(
      context,
      title: 'Delete your ACEkanner account?',
      message: 'This deletes your account on the ACEkanner server: your sign-in, your phones and your '
          'scan count. It does not cancel a Google Play subscription; cancel it in Google Play to stop '
          'renewals. Papers and results on this phone are kept. Free scans already used are not restored.',
      confirmLabel: 'Delete account',
      destructive: true,
    );
    if (!ok) return;
    await _run('delete', () => ref.read(licenseServiceProvider).deleteAccount(), done: 'Your account was deleted.');
  }

  Future<void> _manage() async {
    final uri = Uri.https('play.google.com', '/store/account/subscriptions', {
      'sku': AppConstants.premiumProductId,
      'package': AppConstants.applicationId,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      showMessage(context, 'Open Google Play → Payments & subscriptions → Subscriptions.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(licenseStatusProvider).value;
    final account = ref.watch(authAccountProvider).value;
    final billing = ref.watch(billingControllerProvider);
    final service = ref.watch(licenseServiceProvider);
    ref.listen(billingControllerProvider, (prev, next) {
      if (next.phase == BillingPhase.success && prev?.phase != BillingPhase.success) {
        showMessage(context, 'Premium is active. Thank you!');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Plan and account')),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xxl),
              children: [
                if (!status.configured) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Space.l),
                      child: Text(
                        'This is a test build without online licensing. It allows '
                        '${AppConstants.freeScanLimit} free scans on this phone. Google sign-in and '
                        'Premium are available in the Google Play version.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ] else ...[
                  const SectionHeader('Account'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Space.l),
                      child: account == null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sign in with Google once. ACEkanner then works offline and checks '
                                  'your plan online at least every ${AppConstants.offlineVerificationDays} days.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: Space.s),
                                Text(
                                  'The ACEkanner server keeps only your Google email and name, an ID for this phone, '
                                  'your scan count (as unreadable codes) and your subscription. Student names, '
                                  'numbers, answers and scores never leave this phone.',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: Space.l),
                                FilledButton.icon(
                                  onPressed: _busy == null ? () => _run('signin', service.signIn) : null,
                                  icon: _busy == 'signin'
                                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.login),
                                  label: const Text('Sign in with Google'),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.account_circle_outlined),
                                    const SizedBox(width: Space.m),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(account.email ?? 'Google account', style: theme.textTheme.titleSmall),
                                          Text('Signed in with Google', style: theme.textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: Space.s,
                                  children: [
                                    TextButton(
                                      onPressed: _busy == null ? () => _run('signout', service.signOut) : null,
                                      child: const Text('Sign out'),
                                    ),
                                    TextButton(
                                      onPressed: _busy == null ? _deleteAccount : null,
                                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                                      child: const Text('Delete account'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
                const SectionHeader('Plan'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlanSummary(status: status),
                        if (status.configured && account != null) ...[
                          const SizedBox(height: Space.m),
                          OutlinedButton.icon(
                            onPressed: _busy == null
                                ? () => _run('check', () async => service.checkin(), done: 'Plan updated.')
                                : null,
                            icon: _busy == 'check'
                                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.sync),
                            label: const Text('Check plan now'),
                          ),
                        ],
                        const SizedBox(height: Space.s),
                        Text(
                          'A scan is counted when a student’s paper is saved or checked with Scan on Home, '
                          'once per student per examination: scanning or checking that student’s paper '
                          'again is free. A quick check of a paper whose student is not identified is '
                          'counted each time.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                if (status.configured) ...[
                  const SectionHeader('Premium'),
                  _PremiumCard(
                    status: status,
                    billing: billing,
                    signedIn: account != null,
                    onBuy: () => ref.read(billingControllerProvider.notifier).buy(),
                    onRestore: () => ref.read(billingControllerProvider.notifier).restore(),
                    onManage: _manage,
                  ),
                ],
                const SizedBox(height: Space.s),
                const LegalLinksRow(),
              ],
            ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.status,
    required this.billing,
    required this.signedIn,
    required this.onBuy,
    required this.onRestore,
    required this.onManage,
  });

  final LicenseStatus status;
  final BillingState billing;
  final bool signedIn;
  final VoidCallback onBuy;
  final VoidCallback onRestore;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final price = billing.price ?? 'PHP ${AppConstants.premiumPricePhp}';
    final premium = status.premiumActive;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACEkanner Premium', style: theme.textTheme.titleMedium),
            const SizedBox(height: Space.xs),
            Text(
              'Unlimited scans for one year · $price per year. Renews automatically; cancel any time in '
              'Google Play.',
              style: theme.textTheme.bodyMedium,
            ),
            if (billing.message != null) ...[
              const SizedBox(height: Space.m),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    billing.phase == BillingPhase.error ? Icons.error_outline : Icons.info_outline,
                    size: 18,
                    color: billing.phase == BillingPhase.error ? theme.colorScheme.error : colors.uncertain,
                  ),
                  const SizedBox(width: Space.s),
                  Expanded(child: Text(billing.message!, style: theme.textTheme.bodySmall)),
                ],
              ),
            ],
            const SizedBox(height: Space.m),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                if (premium)
                  OutlinedButton.icon(
                    onPressed: onManage,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Manage subscription'),
                  )
                else
                  FilledButton.icon(
                    onPressed: signedIn && billing.available && !billing.busy && billing.phase != BillingPhase.pending
                        ? onBuy
                        : null,
                    icon: billing.busy
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.workspace_premium_outlined),
                    label: const Text('Upgrade to Premium'),
                  ),
                TextButton(
                  onPressed: signedIn && !billing.busy ? onRestore : null,
                  child: const Text('Restore purchase'),
                ),
              ],
            ),
            if (!signedIn)
              Padding(
                padding: const EdgeInsets.only(top: Space.s),
                child: Text('Sign in first to buy or restore Premium.', style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}
