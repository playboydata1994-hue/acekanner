import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/settings/settings_repository.dart';
import '../domain/licensing/plan_status.dart';
import '../domain/licensing/reminder_schedule.dart';
import '../services/notifications/reminder_service.dart';
import 'bootstrap.dart';
import 'licensing_providers.dart';
import 'providers.dart';

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => LocalReminderScheduler());

/// Asks once for the notification permission (Android 13+), so the expiry
/// reminders can be shown. A refusal is respected and not asked again.
Future<void> ensureNotificationPermission(WidgetRef ref) async {
  final settings = ref.read(settingsRepositoryProvider);
  if (await settings.getBool(SettingKeys.notificationsAsked)) return;
  await settings.setBool(SettingKeys.notificationsAsked, true);
  try {
    await ref.read(reminderSchedulerProvider).requestPermission();
  } catch (_) {
    // Not available (tests or unsupported platform).
  }
}

/// Keeps the plan fresh and the reminders scheduled:
/// * once the database is open, and whenever the app returns to the
///   foreground, it checks in with the licensing server if due (silently);
/// * whenever the plan changes (trial, purchase, renewal, expiry), it
///   cancels and reschedules the local reminders (no duplicates).
class PlanLifecycle extends ConsumerStatefulWidget {
  const PlanLifecycle({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<PlanLifecycle> createState() => _PlanLifecycleState();
}

class _PlanLifecycleState extends ConsumerState<PlanLifecycle> with WidgetsBindingObserver {
  bool _running = false;
  String? _scheduled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(startup: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  bool get _ready => ref.read(bootstrapControllerProvider).value is BootstrapReady;

  Future<void> _refresh({bool startup = false}) async {
    if (_running || !_ready || ref.read(licenseApiProvider) == null) return;
    _running = true;
    try {
      await ref
          .read(licenseServiceProvider)
          .refreshIfDue(maxAge: startup ? const Duration(hours: 1) : const Duration(hours: 12));
    } catch (_) {
      // Background refresh never interrupts the instructor.
    } finally {
      _running = false;
    }
  }

  Future<void> _reschedule(PlanStatus status) async {
    final oneDay = ref.read(appSettingsProvider).oneDayReminder;
    final reminders = ReminderSchedule.build(status, oneDayBefore: oneDay);
    final signature = reminders.map((r) => '${r.id}@${r.at.toIso8601String()}:${r.body}').join('|');
    if (signature == _scheduled) return;
    _scheduled = signature;
    try {
      await ref.read(reminderSchedulerProvider).apply(reminders);
    } catch (_) {
      _scheduled = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bootstrapControllerProvider, (_, next) {
      if (next.value is BootstrapReady) _refresh(startup: true);
    });
    final ready = ref.watch(bootstrapControllerProvider).value is BootstrapReady;
    if (ready) {
      ref.listen(planStatusStreamProvider, (_, next) {
        final s = next.value;
        if (s != null) _reschedule(s);
      });
      ref.listen(appSettingsProvider.select((s) => s.oneDayReminder), (_, _) {
        final s = ref.read(planStatusStreamProvider).value;
        if (s != null) {
          _scheduled = null;
          _reschedule(s);
        }
      });
      if (ref.watch(billingGatewayProvider) != null) {
        // Purchase updates for the whole session (pending payments).
        ref.watch(billingControllerProvider);
      }
    }
    return widget.child;
  }
}
