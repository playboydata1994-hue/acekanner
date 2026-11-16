import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/domain/roster_csv.dart';

void main() {
  test('reads a typical class list with a title row and keeps leading zeros', () {
    const csv = 'BSIT 2-A Class List,,,\n'
        'Student No.,Last Name,First Name,M.I.\n'
        '2021-00123,Dela Cruz,Juan,P.\n'
        '0021-00007,  Santos ,Maria   Clara,\n';
    final result = parseRosterCsv(csv);

    expect(result.fatal, isNull);
    expect(result.issues, isEmpty);
    expect(result.rows, hasLength(2));
    expect(result.rows[0].studentNo, '2021-00123');
    expect(result.rows[0].middleName, 'P.');
    expect(result.rows[1].studentNo, '0021-00007');
    expect(result.rows[1].key, '002100007');
    expect(result.rows[1].lastName, 'Santos');
    expect(result.rows[1].firstName, 'Maria Clara');
  });

  test('accepts semicolons, a BOM and a single "Last, First M." name column', () {
    const csv = '﻿ID Number;Name;Email\n'
        '2021-1;"REYES, Ana B.";ana@school.edu.ph\n';
    final result = parseRosterCsv(csv);

    expect(result.issues, isEmpty);
    final row = result.rows.single;
    expect(row.lastName, 'REYES');
    expect(row.firstName, 'Ana');
    expect(row.middleName, 'B.');
    expect(row.email, 'ana@school.edu.ph');
  });

  test('reports bad rows by line and skips duplicates', () {
    const csv = 'student no,surname,given name,email\n'
        '1001,Cruz,Jose,\n'
        ',Lopez,Ana,\n'
        '1002,,Ben,\n'
        '1001,Cruz,Jose,\n'
        '1003,Ramos,Lea,bad-email\n';
    final result = parseRosterCsv(csv);

    expect(result.rows.map((r) => r.studentNo), ['1001']);
    expect(result.issues.map((i) => i.line), [3, 4, 5, 6]);
    expect(result.issues[2].message, contains('line 2'));
  });

  test('a file without recognizable headers is rejected', () {
    final result = parseRosterCsv('a,b,c\n1,2,3\n');
    expect(result.fatal, isNotNull);
    expect(result.rows, isEmpty);
  });
}
