import 'package:intl/intl.dart';

import 'entitlement.dart';
import 'plan_status.dart';

/// A local notification to schedule.
class Reminder {
  const Reminder({required this.id, required this.at, required this.title, required this.body});

  final int id;

  /// Local date-time.
  final DateTime at;
  final String title;
  final String body;

  @override
  String toString() => 'Reminder($id at $at: $body)';
}

/// Which reminders should be scheduled for a plan. Pure: the notification
/// service cancels the fixed IDs and schedules exactly this list, so changing
/// plans or renewing never leaves duplicates behind.
abstract final class ReminderSchedule {
  static const int fiveDayId = 5001;
  static const int oneDayId = 5002;
  static const int trialId = 5003;
  static const List<int> allIds = [fiveDayId, oneDayId, trialId];

  /// Reminders are shown at 9:00 in the morning, phone time.
  static const int hour = 9;
  static const String title = 'ACEkor Grading Sheet';

  static List<Reminder> build(PlanStatus status, {required bool oneDayBefore, DateTime? nowLocal}) {
    final now = nowLocal ?? status.now.toLocal();
    final out = <Reminder>[];
    final paidUntil = status.paidUntil;
    if (status.paidTier != Tier.none && paidUntil != null && !status.needsCheckIn) {
      final expiry = paidUntil.toLocal();
      final day = DateTime(expiry.year, expiry.month, expiry.day);
      final date = DateFormat('MMMM d, y').format(expiry);
      final plan = status.paidTier.label;
      void add(int id, int daysBefore) {
        final d = day.subtract(Duration(days: daysBefore));
        final at = DateTime(d.year, d.month, d.day, hour);
        if (!at.isAfter(now)) return;
        final when = daysBefore == 1 ? 'tomorrow' : 'in $daysBefore days';
        final body = status.autoRenew
            ? 'Your $plan subscription renews $when, on $date. Google Play will renew it automatically; nothing to do if you want to keep it.'
            : 'Your $plan subscription will expire $when ($date). Renew your subscription to continue enjoying premium academic scoring features.';
        out.add(Reminder(id: id, at: at, title: title, body: body));
      }

      add(fiveDayId, 5);
      if (oneDayBefore) add(oneDayId, 1);
    }
    final trialEnds = status.trialEnds;
    if (trialEnds != null && status.paidTier == Tier.none) {
      final at = trialEnds.toLocal().subtract(const Duration(days: 1));
      if (at.isAfter(now)) {
        final date = DateFormat('MMMM d, y – h:mm a').format(trialEnds.toLocal());
        out.add(
          Reminder(
            id: trialId,
            at: at,
            title: title,
            body:
                'Your free trial ends tomorrow ($date). Choose PRO or MAX to keep saving scores. Your records stay on your phone either way.',
          ),
        );
      }
    }
    return out;
  }
}
