import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../data/settings/settings_repository.dart';

/// Recitation scoring methods (Settings › Recitation).
enum RecitationMethod {
  points('points', 'Points (score / total)'),
  rating5('rating5', 'Rating 1–5');

  const RecitationMethod(this.code, this.label);
  final String code;
  final String label;

  static RecitationMethod parse(String? c) => c == rating5.code ? rating5 : points;
}

/// Typed, defaulted view of every setting.
class UserSettings {
  const UserSettings(this.raw);

  static const UserSettings defaults = UserSettings({});

  final Map<String, String> raw;

  bool _b(String k, bool d) => raw[k] == null ? d : raw[k] == 'true';
  int _i(String k, int d) => int.tryParse(raw[k] ?? '') ?? d;
  String? _s(String k) {
    final v = raw[k];
    return (v == null || v.isEmpty) ? null : v;
  }

  // Calculator
  String? get currentSubject => _s(SettingKeys.currentSubject);
  String? get currentSection => _s(SettingKeys.currentSection);
  String? get currentActivity => _s(SettingKeys.currentActivity);
  int get quickMax => _i(SettingKeys.quickMax, 50);
  bool get continuousEntry => _b(SettingKeys.continuousEntry, true);
  bool get confirmReplace => _b(SettingKeys.confirmReplace, true);
  bool get confirmMessage => _b(SettingKeys.confirmMessage, true);
  bool get sound => _b(SettingKeys.sound, true);
  bool get showPercent => _b(SettingKeys.showPercent, true);

  // Quiz / recitation / examination
  int get quizMaxAllowed => _i(SettingKeys.quizMaxAllowed, 100);
  int get quizFirstNumber => _i(SettingKeys.quizFirstNumber, 1);
  int get recitationMaxAllowed => _i(SettingKeys.recitationMaxAllowed, 100);
  RecitationMethod get recitationMethod => RecitationMethod.parse(raw[SettingKeys.recitationMethod]);
  int get examMaxAllowed => _i(SettingKeys.examMaxAllowed, 1000);

  // General
  String get academicYear => raw[SettingKeys.academicYear] ?? '';
  String get semester => raw[SettingKeys.semester] ?? '';
  TextSize get textSize => TextSize.parse(raw[SettingKeys.textSize]);
  ThemeMode get themeMode => switch (raw[SettingKeys.themeMode]) {
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.dark,
  };

  // Reports
  String get reportHeaderLine => raw[SettingKeys.reportHeaderLine] ?? '';
  String get reportFooterLine => raw[SettingKeys.reportFooterLine] ?? '';

  // Plan, security, backup
  bool get oneDayReminder => _b(SettingKeys.oneDayReminder, true);
  bool get lockEnabled => _b(SettingKeys.lockEnabled, false);
  bool get lockBiometric => _b(SettingKeys.lockBiometric, false);
  DateTime? get lastBackupAt {
    final v = int.tryParse(raw[SettingKeys.lastBackupAt] ?? '');
    return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
  }

  bool get onboardingDone => _b(SettingKeys.onboardingDone, false);
}
