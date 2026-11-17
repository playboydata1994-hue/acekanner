import 'package:acekor/domain/roster/roster_import.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CSV with title line, any column order, capitals and accents', () {
    final r = parseRosterCsv(
      'CLASS LIST BSIT 1-A\n'
      'Section,First Name,Last Name,Student ID,Year,Course\n'
      'BSIT 1-A,JUAN,DELA CRUZ,2021-00123,1st,BSIT\n'
      'BSIT 1-A,María,Peña,2021-00124,1,BSIT\n'
      ',,,,,\n'
      'BSIT 1-A,,NoFirst,2021-9,1,BSIT\n',
    );
    expect(r.fatal, isNull);
    expect(r.rows.length, 2);
    expect(r.rows.first.firstName, 'Juan');
    expect(r.rows.first.lastName, 'Dela Cruz');
    expect(r.rows.first.yearLevel, 1);
    expect(r.rows[1].lastName, 'Peña');
    expect(r.rows.first.section, 'BSIT 1-A');
    expect(r.issues.single.line, 6);
  });
  test('single Name column', () {
    final r = parseRosterCsv('No,Name\n1,"DELA CRUZ, Juan P."\n');
    expect(r.rows.single.lastName, 'Dela Cruz');
    expect(r.rows.single.firstName, 'Juan');
    expect(r.rows.single.middleName, 'P.');
  });
  test('missing headers is fatal', () {
    expect(parseRosterCsv('a,b\n1,2').fatal, isNotNull);
  });
  test('the template round-trips through the xlsx reader', () {
    final bytes = classListTemplateXlsx();
    final book = Excel.decodeBytes(bytes);
    final sheet = book['Class list'];
    sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1), TextCellValue('0012'));
    sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1), TextCellValue('Reyes'));
    sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1), TextCellValue('Ana'));
    final r = parseRosterXlsx(book.encode()!);
    expect(r.rows.single.studentNo, '0012');
    expect(r.rows.single.lastName, 'Reyes');
  });
}
