import '../../core/util/clock.dart';
import '../db/app_database.dart';

/// Keys stored in `application_settings`.
abstract final class SettingKeys {
  static const String onboardingCompleted = 'onboarding.completed.v1';

  /// School student-number format, e.g. "####-#####".
  static const String studentNoFormat = 'school.student_no_format';

  /// Answer sheets: print the instructor's name (default on).
  static const String sheetsShowInstructor = 'sheets.show_instructor';

  /// Answer sheets: print the school logo when one is set (default on).
  static const String sheetsShowLogo = 'sheets.show_logo';
}

/// Typed access to the `application_settings` table.
class SettingsRepository {
  SettingsRepository(this._db, {this.clock = const Clock()});

  final AppDatabase _db;
  final Clock clock;

  Future<String?> getString(String key) async {
    final row = await (_db.select(_db.applicationSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watchString(String key) {
    return (_db.select(_db.applicationSettings)
          ..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  Future<void> setString(String key, String value) {
    return _db.into(_db.applicationSettings).insertOnConflictUpdate(
          ApplicationSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: clock.now(),
          ),
        );
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await getString(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<void> setBool(String key, bool value) =>
      setString(key, value ? 'true' : 'false');
}
