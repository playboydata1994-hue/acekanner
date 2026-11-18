import 'package:acekor/data/backup/backup_service.dart';
import 'package:acekor/data/repositories/activities_repository.dart';
import 'package:acekor/data/repositories/roster_repository.dart';
import 'package:acekor/data/repositories/scores_repository.dart';
import 'package:acekor/data/repositories/subjects_repository.dart';
import 'package:acekor/data/secure/secret_store.dart';
import 'package:acekor/data/security/pin_store.dart';
import 'package:acekor/data/settings/settings_repository.dart';
import 'package:acekor/core/util/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_db.dart';

void main() {
  test('backup → restore into another phone, wrong password refused, history kept', () async {
    final a = newTestDatabase();
    final roster = RosterRepository(a);
    final subjects = SubjectsRepository(a);
    final sid = await subjects.createSubject(const SubjectInput(code: 'IT 101'));
    final st = await roster.addStudent(
      const StudentInput(firstName: 'Juan', lastName: 'Dela Cruz', studentNo: '1'),
      subjectIds: [sid],
    );
    final q = await ActivitiesRepository(a)
        .createActivity(ActivityInput(subjectId: sid, categoryId: 'quiz', number: 1, maxPoints: 50));
    await ScoresRepository(a).save(q, st, 40);
    await ScoresRepository(a).save(q, st, 42);
    await SettingsRepository(a).setBool(SettingKeys.lockEnabled, true);
    final bytes = await BackupService(a, iterations: 1000).create('secret-pass', appVersion: '1.0.0');
    await a.close();

    final b = newTestDatabase();
    final service = BackupService(b, iterations: 1000);
    expect(service.readHeader(bytes).appVersion, '1.0.0');
    await expectLater(service.open(bytes, 'wrong-pass'), throwsA(isA<BackupException>()));
    await RosterRepository(b).addStudent(const StudentInput(firstName: 'Will', lastName: 'Be Replaced'));
    final contents = await service.open(bytes, 'secret-pass');
    expect(contents.count('scores'), 1);
    await service.restore(contents);
    final students = await RosterRepository(b).students();
    expect(students.single.natural, 'Juan Dela Cruz');
    expect((await ScoresRepository(b).score(q, st))!.points, 42);
    expect((await ScoresRepository(b).history(activityId: q)).length, 2);
    // Device settings (the lock) are not restored from the file.
    expect(await SettingsRepository(b).getBool(SettingKeys.lockEnabled), isFalse);
    expect(await b.integrityProblems(), isEmpty);
    await b.close();
  });

  test('not a backup file', () {
    final b = newTestDatabase();
    expect(() => BackupService(b).readHeader(List<int>.filled(64, 1) as dynamic), throwsA(isA<Object>()));
    b.close();
  });

  test('PIN: hash only, wrong attempts slow down', () async {
    final store = MemorySecretStore();
    var t = DateTime(2027, 1, 1, 8);
    final pins = PinStore(store, clock: _Clock(() => t), iterations: 1000);
    await pins.setPin('2468');
    expect(store.values[PinStore.key], isNot(contains('2468')));
    expect(await pins.pinLength(), 4);
    expect(await pins.verify('2468'), isTrue);
    for (var i = 0; i < 5; i++) {
      expect(await pins.verify('0000'), isFalse);
    }
    expect(await pins.waitSeconds(), 30);
    expect(await pins.verify('2468'), isFalse); // locked out for now
    t = t.add(const Duration(seconds: 31));
    expect(await pins.verify('2468'), isTrue);
    expect(PinStore.validFormat('123'), isFalse);
  });
}

class _Clock extends Clock {
  const _Clock(this.f);
  final DateTime Function() f;
  @override
  DateTime now() => f();
}
