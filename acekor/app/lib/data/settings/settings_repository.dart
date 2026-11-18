import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../db/app_database.dart';

/// Keys stored in `app_settings`.
abstract final class SettingKeys {
  static const String onboardingDone = 'onboarding.done.v1';

  // Academic calculator
  static const String currentSubject = 'calc.subject';
  static const String currentSection = 'calc.section';
  static const String currentActivity = 'calc.activity';
  static const String quickMax = 'calc.quick_max';
  static const String continuousEntry = 'calc.continuous';
  static const String confirmReplace = 'calc.confirm_replace';
  static const String confirmMessage = 'calc.confirm_message';
  static const String sound = 'calc.sound';
  static const String showPercent = 'calc.show_percent';
  static const String recentStudents = 'calc.recent_students';

  // Quiz, recitation and examination settings
  static const String quizMaxAllowed = 'quiz.max_allowed';
  static const String quizFirstNumber = 'quiz.first_number';
  static const String recitationMaxAllowed = 'recitation.max_allowed';
  static const String recitationMethod = 'recitation.method';
  static const String examMaxAllowed = 'exam.max_allowed';

  // General
  static const String academicYear = 'general.academic_year';
  static const String semester = 'general.semester';
  static const String textSize = 'ui.text_size';
  static const String themeMode = 'ui.theme';

  // Reports
  static const String reportHeaderLine = 'report.header_line';
  static const String reportFooterLine = 'report.footer_line';

  // Plans and reminders
  static const String oneDayReminder = 'plan.one_day_reminder';
  static const String localTrialStarted = 'plan.local_trial_started';
  static const String notificationsAsked = 'plan.notifications_asked';

  // Security and backup
  static const String lockEnabled = 'lock.enabled';
  static const String lockBiometric = 'lock.biometric';
  static const String lastBackupAt = 'backup.last_at';
}

/// Typed access to the `app_settings` table.
class SettingsRepository {
  SettingsRepository(this._db, {this.clock = const Clock()});

  final AppDatabase _db;
  final Clock clock;

  Future<String?> getString(String key) async {
    final row = await (_db.select(_db.appSettings)..where((t) => t.settingKey.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchString(String key) {
    return (_db.select(
      _db.appSettings,
    )..where((t) => t.settingKey.equals(key))).watchSingleOrNull().map((row) => row?.value);
  }

  /// Every setting as a map, live.
  Stream<Map<String, String>> watchAll() =>
      _db.select(_db.appSettings).watch().map((rows) => {for (final r in rows) r.settingKey: r.value});

  Future<Map<String, String>> all() async => {
    for (final r in await _db.select(_db.appSettings).get()) r.settingKey: r.value,
  };

  Future<void> setString(String key, String value) {
    return _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(AppSettingsCompanion.insert(settingKey: key, value: value, updatedAt: clock.now()));
  }

  Future<void> remove(String key) => (_db.delete(_db.appSettings)..where((t) => t.settingKey.equals(key))).go();

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await getString(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<void> setBool(String key, bool value) => setString(key, value ? 'true' : 'false');

  Future<int?> getInt(String key) async => int.tryParse(await getString(key) ?? '');

  Future<void> setInt(String key, int value) => setString(key, '$value');

  Future<List<String>> getList(String key) async {
    final v = await getString(key);
    if (v == null) return const [];
    try {
      return (jsonDecode(v) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  Future<void> setList(String key, List<String> values) => setString(key, jsonEncode(values));

  /// Moves [id] to the front of a most-recent-first list of at most [max].
  Future<void> pushRecent(String key, String id, {int max = 8}) async {
    final list = [id, ...(await getList(key)).where((e) => e != id)];
    await setList(key, list.take(max).toList());
  }

  /// Writes several settings in one transaction.
  Future<void> setMany(Map<String, String> values) => _db.batch((b) {
    for (final e in values.entries) {
      b.insert(
        _db.appSettings,
        AppSettingsCompanion.insert(settingKey: e.key, value: e.value, updatedAt: clock.now()),
        mode: InsertMode.insertOrReplace,
      );
    }
  });
}
