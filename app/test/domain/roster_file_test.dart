import 'dart:convert';
import 'dart:typed_data';

import 'package:acekanner/domain/roster_file.dart';
import 'package:acekanner/features/exams/class_list_upload.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';

/// A real .xlsx as Excel would save it: a title row, then the header.
Uint8List workbook(List<List<CellValue?>> rows, {String sheet = 'Sheet1'}) {
  final book = Excel.createExcel();
  final s = book[sheet];
  for (final r in rows) {
    s.appendRow(r);
  }
  if (sheet != 'Sheet1') book.delete('Sheet1');
  return Uint8List.fromList(book.encode()!);
}

void main() {
  test('reads an Excel class list, keeping student numbers typed as numbers', () {
    final bytes = workbook([
      [TextCellValue('BSIT 2-A — Programming 1')],
      [TextCellValue('Student No.'), TextCellValue('Last Name'), TextCellValue('First Name'), TextCellValue('M.I.')],
      [IntCellValue(202100123), TextCellValue('Dela Cruz'), TextCellValue('Juan'), TextCellValue('P.')],
      [TextCellValue('2021-00124'), TextCellValue('Peña'), TextCellValue('Niño'), null],
      [DoubleCellValue(202100125), TextCellValue('Reyes'), TextCellValue('Ana'), null],
      [null, null, null, null],
      [TextCellValue('bad!!'), TextCellValue('X'), TextCellValue('Y'), null],
    ]);
    final r = parseRosterFile('BSIT 2-A.xlsx', bytes);
    expect(r.fatal, isNull);
    expect(r.rows.map((x) => x.studentNo), ['202100123', '2021-00124', '202100125']);
    expect(r.rows[1].lastName, 'Peña');
    expect(r.rows[0].middleName, 'P.');
    expect(r.issues, hasLength(1), reason: 'the invalid student number is reported, not imported');
  });

  test('a single "Name" column and another sheet name work too', () {
    final bytes = workbook([
      [TextCellValue('ID Number'), TextCellValue('Name')],
      [TextCellValue('2021-00123'), TextCellValue('Dela Cruz, Juan P.')],
    ], sheet: 'Masterlist');
    final r = parseRosterFile('list.XLSX', bytes);
    expect(r.rows.single.firstName, 'Juan');
    expect(r.rows.single.middleName, 'P.');
  });

  test('CSV still works; old .xls and other files get a clear message', () {
    final csv = utf8.encode('Student No,Last Name,First Name\n2021-00123,Dela Cruz,Juan\n');
    expect(parseRosterFile('list.csv', csv).rows, hasLength(1));
    expect(parseRosterFile('list.xls', [1, 2, 3]).fatal, contains('.xlsx'));
    expect(parseRosterFile('photo.jpg', [1, 2, 3]).fatal, contains('Excel'));
    expect(parseRosterFile('broken.xlsx', [1, 2, 3]).fatal, contains('could not be read'));
    expect(parseRosterFile('empty.xlsx', workbook([])).fatal, isNotNull);
  });

  test('section name suggested from the file name', () {
    expect(sectionNameFromFile('BSIT_2-A.xlsx'), 'BSIT 2-A');
    expect(sectionNameFromFile('  Grade 10  Rizal .csv'), 'Grade 10 Rizal');
    expect(sectionNameFromFile('noext'), 'noext');
    expect(sectionNameFromFile('${'x' * 80}.xlsx'), hasLength(60));
  });
}
