import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/licensing/reminder_schedule.dart';

/// Schedules the plan reminders as local notifications. Once scheduled, they
/// are delivered by Android even with no internet and the app closed; the
/// plugin's boot receiver restores them after a restart.
abstract interface class ReminderScheduler {
  /// Cancels every ACEKOR reminder and schedules exactly [reminders].
  Future<void> apply(List<Reminder> reminders);

  /// Asks for the notification permission (Android 13+). Returns whether
  /// notifications are allowed.
  Future<bool> requestPermission();
}

class LocalReminderScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _init;

  static const AndroidNotificationDetails _channel = AndroidNotificationDetails(
    'acekor_plan',
    'Subscription reminders',
    channelDescription: 'Reminders before your ACEKOR trial or subscription ends.',
    importance: Importance.high,
    priority: Priority.high,
    styleInformation: BigTextStyleInformation(''),
  );

  Future<void> _ensure() => _init ??= () async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
  }();

  @override
  Future<void> apply(List<Reminder> reminders) async {
    await _ensure();
    for (final id in ReminderSchedule.allIds) {
      await _plugin.cancel(id: id);
    }
    for (final r in reminders) {
      final when = tz.TZDateTime(tz.local, r.at.year, r.at.month, r.at.day, r.at.hour, r.at.minute);
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.channelId,
            _channel.channelName,
            channelDescription: _channel.channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(r.body),
          ),
        ),
        // Inexact is fine for a reminder days ahead and needs no special
        // "alarms" permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
      );
    }
  }

  @override
  Future<bool> requestPermission() async {
    await _ensure();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    final enabled = await android.areNotificationsEnabled() ?? false;
    if (enabled) return true;
    return await android.requestNotificationsPermission() ?? false;
  }
}

/// Does nothing (tests).
class NoReminderScheduler implements ReminderScheduler {
  final List<List<Reminder>> applied = [];

  @override
  Future<void> apply(List<Reminder> reminders) async => applied.add(reminders);

  @override
  Future<bool> requestPermission() async => true;
}
