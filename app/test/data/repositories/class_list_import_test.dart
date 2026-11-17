import 'package:acekanner/core/util/clock.dart';
import 'package:acekanner/data/audit/audit_logger.dart';
import 'package:acekanner/data/db/app_database.dart';
import 'package:acekanner/data/repositories/classes_repository.dart';
import 'package:acekanner/data/repositories/students_repository.dart';
import 'package:acekanner/domain/roster_csv.dart';
import 'package:acekanner/features/exams/class_list_upload.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_db.dart';

void main() {
  late AppDatabase db;
  late ClassesRepository classes;
  late StudentsRepository students;

  setUp(() {
    db = openTestDatabase();
    final clock = FixedClock(t0);
    classes = ClassesRepository(db, clock: clock);
    students = StudentsRepository(db, AuditLogger(db, clock: clock), clock: clock);
  });
  tearDown(() => db.close());

  List<RosterRow> rows(List<String> numbers) => [
        for (final (i, n) in numbers.indexed) RosterRow(line: i + 2, studentNo: n, lastName: 'L$i', firstName: 'F$i'),
      ];

  test('creates a new section with the students, then reuses it by name', () async {
    final (id, message) = await importClassList(classes, students, 'BSIT 2-A', rows(['2021-00001', '2021-00002']));
    expect(message, contains('2 students added to new section BSIT 2-A'));
    expect((await students.watchRoster(id).first).map((s) => s.studentNo), containsAll(['2021-00001', '2021-00002']));

    final (again, message2) = await importClassList(classes, students, 'bsit 2-a', rows(['2021-00002', '2021-00003']));
    expect(again, id, reason: 'same section, name compared without case');
    expect(message2, contains('to section BSIT 2-A'));
    expect(await students.watchRoster(id).first, hasLength(3));
    expect(await classes.watchSections().first, hasLength(1));
  });
}
