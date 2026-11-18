import 'package:intl/intl.dart';

import '../../domain/licensing/entitlement.dart';
import '../../domain/licensing/plan_status.dart';

String longDate(DateTime d) => DateFormat('MMMM d, y').format(d.toLocal());

/// One line describing the plan, e.g. "Free trial · 5 days left".
String planSummary(PlanStatus s) {
  if (s.paidActive) {
    final until = s.paidUntil!;
    return '${s.paidTier.label} · ${s.autoRenew ? 'renews' : 'ends'} ${longDate(until)}'
        '${s.trialActive ? ' · trial until ${longDate(s.trialEnds!)}' : ''}';
  }
  if (s.trialActive) {
    final d = s.trialDaysLeft;
    return 'Free trial · $d day${d == 1 ? '' : 's'} left';
  }
  if (s.needsCheckIn) return 'Connect to the internet to confirm your plan';
  if (s.paidTier != Tier.none && s.paidUntil != null) return '${s.paidTier.label} ended ${longDate(s.paidUntil!)}';
  if (s.trialUsed) return 'Free trial ended · choose PRO or MAX';
  return 'No plan · try everything free for 7 days';
}
