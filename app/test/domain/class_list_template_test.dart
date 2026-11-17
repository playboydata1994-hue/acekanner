import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/domain/roster_file.dart';

void main() {
  test('the template has the column names and no students', () {
    final bytes = classListTemplateXlsx();
    final book = Excel.decodeBytes(bytes);
    expect(book.tables.keys, ['Class list']);
    final header = book.tables['Class list']!.rows.first.map((c) => cellText(c?.value)).toList();
    expect(header, ['Student No', 'Last Name', 'First Name', 'Middle Name']);

    final r = parseRosterXlsx(bytes);
    expect(r.fatal, isNull, reason: 'the header is recognized');
    expect(r.rows, isEmpty);
    expect(r.issues, isEmpty, reason: 'formatted empty rows are not reported');
  });

  test('a filled-in template imports', () {
    final book = Excel.decodeBytes(classListTemplateXlsx());
    final sheet = book['Class list'];
    for (final (r, row) in [
      ['00123', 'Dela Cruz', 'Juan', 'Perez'],
      ['2021-00124', 'Santos', 'Maria Clara', ''],
    ].indexed) {
      for (final (c, v) in row.indexed) {
        sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1), TextCellValue(v));
      }
    }
    final result = parseRosterXlsx(book.encode()!);
    expect(result.issues, isEmpty);
    expect(result.rows.map((x) => (x.studentNo, x.lastName, x.firstName, x.middleName)), [
      ('00123', 'Dela Cruz', 'Juan', 'Perez'),
      ('2021-00124', 'Santos', 'Maria Clara', null),
    ]);
  });
}
