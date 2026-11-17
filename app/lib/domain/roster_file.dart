import 'dart:convert';

import 'package:excel_plus/excel_plus.dart';

import 'roster_csv.dart';

/// Decodes a CSV file saved by Excel ("CSV UTF-8" or plain "CSV", which uses
/// Windows-1252 and would break names such as "Peña").
String decodeCsvBytes(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}

/// File types a class list can be uploaded as.
const List<String> rosterFileExtensions = ['xlsx', 'csv', 'txt'];

/// Reads a class list from an Excel workbook (.xlsx, first sheet with data) or
/// a CSV/text file, chosen by the file name's extension.
RosterParseResult parseRosterFile(String fileName, List<int> bytes) {
  final name = fileName.toLowerCase();
  if (name.endsWith('.xlsx')) return parseRosterXlsx(bytes);
  if (name.endsWith('.csv') || name.endsWith('.txt')) return parseRosterCsv(decodeCsvBytes(bytes));
  if (name.endsWith('.xls')) {
    return const RosterParseResult(
      rows: [],
      issues: [],
      fatal: 'This is an old Excel file (.xls). Open it in Excel or Google Sheets and save it as .xlsx or CSV.',
    );
  }
  return const RosterParseResult(rows: [], issues: [], fatal: 'Choose an Excel (.xlsx) or CSV file.');
}

/// Reads the first sheet that has a recognizable class list.
RosterParseResult parseRosterXlsx(List<int> bytes) {
  final Excel book;
  try {
    book = Excel.decodeBytes(bytes);
  } on Object {
    return const RosterParseResult(rows: [], issues: [], fatal: 'The file could not be read as an Excel workbook.');
  }
  RosterParseResult? first;
  for (final sheet in book.tables.values) {
    final table = [
      for (final row in sheet.rows) [for (final cell in row) cellText(cell?.value)],
    ];
    if (table.every((r) => r.every((c) => c.isEmpty))) continue;
    final result = parseRosterTable(table);
    if (result.fatal == null) return result;
    first ??= result;
  }
  return first ?? const RosterParseResult(rows: [], issues: [], fatal: 'The workbook is empty.');
}

/// Text of one Excel cell as a teacher would read it. Whole numbers lose the
/// ".0" Excel stores (student numbers typed as numbers).
String cellText(CellValue? v) => switch (v) {
      null => '',
      TextCellValue() => v.value.toString(),
      IntCellValue(:final value) => '$value',
      DoubleCellValue(:final value) =>
        value == value.truncateToDouble() && value.abs() < 1e15 ? value.toInt().toString() : '$value',
      _ => v.toString(),
    };

/// File name of the class list template teachers can save and fill in.
const String classListTemplateName = 'ACEkanner class list.xlsx';

/// An empty class list to fill in: one sheet, "Class list", with the column
/// names in row 1 (bold) and the Student No column formatted as text so
/// numbers keep their leading zeros.
List<int> classListTemplateXlsx() {
  final book = Excel.createExcel();
  final defaultName = book.getDefaultSheet()!;
  book.rename(defaultName, 'Class list');
  final sheet = book['Class list'];
  const headers = ['Student No', 'Last Name', 'First Name', 'Middle Name'];
  const widths = [18.0, 22.0, 22.0, 18.0];
  for (var c = 0; c < headers.length; c++) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
      TextCellValue(headers[c]),
      cellStyle: CellStyle(bold: true, numberFormat: NumFormat.standard_49),
    );
    sheet.setColumnWidth(c, widths[c]);
  }
  final asText = CellStyle(numberFormat: NumFormat.standard_49);
  for (var r = 1; r <= 200; r++) {
    sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r), null, cellStyle: asText);
  }
  return book.encode()!;
}
