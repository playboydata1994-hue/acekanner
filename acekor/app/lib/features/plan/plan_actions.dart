import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/licensing_providers.dart';
import '../../app/plan_lifecycle.dart';
import '../../app/providers.dart';
import '../../core/widgets/feedback.dart';
import '../../data/licensing/auth_service.dart';
import '../../data/licensing/license_api.dart';

String _date(DateTime d) => DateFormat('MMMM d, y').format(d.toLocal());

/// Shows a message; the calculator passes its inline banner so nothing ever
/// covers the keypad.
typedef Notify = void Function(String text, {bool error});

Notify _default(BuildContext context) =>
    (String text, {bool error = false}) => showMessage(context, text, error: error);

/// Signs in with Google (configured builds). Returns success.
Future<bool> signInFlow(BuildContext context, WidgetRef ref, {Notify? notify}) async {
  final say = notify ?? _default(context);
  final service = ref.read(licenseServiceProvider);
  if (!service.available) return true;
  if (ref.read(authServiceProvider).current != null) return true;
  try {
    await service.signIn();
    return true;
  } on AuthFailure catch (e) {
    if (!e.cancelled && context.mounted) say(e.message, error: true);
  } on LicenseApiException catch (e) {
    if (context.mounted) say(e.message, error: true);
  }
  return false;
}

/// Starts the 7-day trial (signing in first when needed). Returns whether
/// the trial is now active.
Future<bool> startTrialFlow(BuildContext context, WidgetRef ref, {Notify? notify}) async {
  final say = notify ?? _default(context);
  final service = ref.read(licenseServiceProvider);
  if (service.available) {
    final go = await confirm(
      context,
      title: 'Start your free trial',
      message:
          'You will sign in once with your Google account. This keeps your trial and '
          'subscription safe if you change phones.\n\nOnly your account is sent to ACEkor\'s '
          'licensing server — never student names or scores.',
      confirmLabel: 'Continue',
    );
    if (!go || !context.mounted) return false;
    if (!await signInFlow(context, ref, notify: notify) || !context.mounted) return false;
  }
  try {
    await service.startTrial();
    final fresh = await ref
        .read(licenseRepositoryProvider)
        .status(signedIn: ref.read(authServiceProvider).current != null);
    if (!context.mounted) return false;
    if (fresh.trialActive) {
      await ensureNotificationPermission(ref);
      if (context.mounted) {
        say('Your free trial has started. Everything is unlocked until ${_date(fresh.trialEnds!)}.');
      }
      return true;
    }
    say(
      fresh.trialEnds == null
          ? 'The trial could not be started. Try again later.'
          : 'This Google account already used its free trial (ended ${_date(fresh.trialEnds!)}). Choose PRO or MAX to continue.',
      error: true,
    );
  } on LicenseApiException catch (e) {
    if (context.mounted) say(e.message, error: true);
  }
  return false;
}

/// Checks the plan with the server now. Returns success.
Future<bool> checkInFlow(BuildContext context, WidgetRef ref, {Notify? notify}) async {
  final say = notify ?? _default(context);
  final service = ref.read(licenseServiceProvider);
  if (!service.available) return true;
  if (!await signInFlow(context, ref, notify: notify) || !context.mounted) return false;
  try {
    await service.checkin();
    if (context.mounted) say('Your plan is up to date.');
    return true;
  } on LicenseApiException catch (e) {
    if (context.mounted) say(e.message, error: true);
    return false;
  }
}
