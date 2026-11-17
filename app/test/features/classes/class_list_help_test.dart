import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/domain/roster_csv.dart';
import 'package:acekanner/features/classes/class_list_help.dart';

void main() {
  test('the sample class list imports exactly as shown', () {
    final r = parseRosterTable(sampleClassList);
    expect(r.fatal, isNull);
    expect(r.issues, isEmpty);
    expect(r.rows.map((x) => (x.studentNo, x.lastName, x.firstName, x.middleName)), [
      ('2021-00123', 'Dela Cruz', 'Juan', 'Perez'),
      ('2021-00124', 'Santos', 'Maria Clara', 'Lopez'),
      ('2021-00125', 'Reyes', 'Jose', null),
      ('2021-00126', 'Garcia', 'Ana', 'Mendoza'),
    ]);
  });

  test('the one-column sample imports too', () {
    final r = parseRosterTable(sampleClassListOneName);
    expect(r.fatal, isNull);
    expect(r.issues, isEmpty);
    expect(r.rows.map((x) => (x.studentNo, x.lastName, x.firstName)), [
      ('2021-00123', 'Dela Cruz', 'Juan'),
      ('2021-00124', 'Santos', 'Maria Clara'),
    ]);
  });
}
