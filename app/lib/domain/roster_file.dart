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
