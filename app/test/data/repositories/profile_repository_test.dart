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

  test('the instructor name and title are optional', () async {
    await profiles.save(const ProfileInput(schoolName: 'SSU'));
    final p = (await profiles.get())!;
    expect(p.fullName, isNull);
    expect(p.honorific, isNull);
    expect(p.schoolName, 'SSU');
    await profiles.save(const ProfileInput(fullName: '   ', honorific: ' ', schoolName: 'SSU'));
    expect((await profiles.get())!.fullName, isNull, reason: 'blank is stored as no name');
    await profiles.save(const ProfileInput(fullName: 'Maria  Santos'));
    expect((await profiles.get())!.fullName, 'Maria Santos');
  });

  test('school logo path is set, kept across profile saves, and cleared', () async {
    await expectLater(profiles.setLogoPath('/x/logo.png'), throwsStateError);
    await profiles.save(const ProfileInput(fullName: 'Maria Santos'));
    expect(await profiles.setLogoPath('/data/branding/logo-a.png'), isNull);
    await profiles.save(const ProfileInput(fullName: 'Maria Santos', schoolName: 'SSU'));
    expect((await profiles.get())!.logoPath, '/data/branding/logo-a.png', reason: 'profile save keeps the logo');
    expect(await profiles.setLogoPath(null), '/data/branding/logo-a.png', reason: 'returns the old path');
    expect((await profiles.get())!.logoPath, isNull);
  });

  test('student number format defaults to 10 digits and persists', () async {
    expect(await profiles.studentNoFormat(), '##########');
    await profiles.setStudentNoFormat(' ####-##### ');
    expect(await profiles.studentNoFormat(), '####-#####');
  });
}
