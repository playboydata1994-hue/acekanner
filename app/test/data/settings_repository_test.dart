import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/settings/settings_repository.dart';

import '../support/test_db.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepository(db, clock: FixedClock(t0));
  });
  tearDown(() => db.close());

  test('missing values fall back to the default', () async {
    expect(await settings.getBool('x'), isFalse);
    expect(await settings.getBool('x', defaultValue: true), isTrue);
    expect(await settings.getString('x'), isNull);
  });

  test('values round-trip and overwrite', () async {
    await settings.setBool(SettingKeys.onboardingCompleted, true);
    expect(await settings.getBool(SettingKeys.onboardingCompleted), isTrue);
    await settings.setBool(SettingKeys.onboardingCompleted, false);
    expect(await settings.getBool(SettingKeys.onboardingCompleted), isFalse);

    final rows = await db.select(db.applicationSettings).get();
    expect(rows, hasLength(1));
    expect(rows.single.updatedAt.toUtc(), t0);
  });

  test('watchString emits changes', () async {
    final stream = settings.watchString('k');
    expect(stream, emitsInOrder([null, 'a', 'b']));
    await Future<void>.delayed(Duration.zero);
    await settings.setString('k', 'a');
    await Future<void>.delayed(Duration.zero);
    await settings.setString('k', 'b');
  });
}
