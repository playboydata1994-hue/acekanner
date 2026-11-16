import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/repositories/profile_repository.dart';
import 'package:acekanner/data/settings/settings_repository.dart';

import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late ProfileRepository profiles;

  setUp(() {
    db = openTestDatabase();
    profiles = ProfileRepository(db, SettingsRepository(db), clock: FixedClock(t0));
  });
  tearDown(() => db.close());

  test('saving twice updates the single profile row', () async {
    expect(await profiles.get(), isNull);
    final id = await profiles.save(
      const ProfileInput(fullName: '  Maria   Santos ', schoolName: 'MSU', email: ''),
    );
    final again = await profiles.save(
      const ProfileInput(fullName: 'Maria Santos', department: 'CCS'),
    );
    expect(again, id);

    final rows = await db.select(db.instructorProfiles).get();
    expect(rows, hasLength(1));
    expect(rows.single.fullName, 'Maria Santos');
    expect(rows.single.email, isNull);
    expect(rows.single.department, 'CCS');
    expect(rows.single.schoolName, isNull, reason: 'cleared on second save');
  });

  test('student number format defaults to 10 digits and persists', () async {
    expect(await profiles.studentNoFormat(), '##########');
    await profiles.setStudentNoFormat(' ####-##### ');
    expect(await profiles.studentNoFormat(), '####-#####');
  });
}
