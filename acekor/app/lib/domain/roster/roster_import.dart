import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel_plus/excel_plus.dart';

import '../../core/util/text.dart';

/// One student read from a class-list file.
class ParsedStudent {
  const ParsedStudent({
    required this.line,
    required this.firstName,
    required this.lastName,
    this.studentNo,
    this.middleName = '',
    this.suffix = '',
    this.program = '',
    this.yearLevel,
    this.section,
    this.academicYear = '',
    this.semester = '',
  });

  /// 1-based line (row) in the file, for messages.
  final int line;
  final String? studentNo;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String program;
  final int? yearLevel;
  final String? section;
  final String academicYear;
  final String semester;
}

class RosterIssue {
  const RosterIssue(this.line, this.message);
  final int line;
  final String message;

  @override
  String toString() => 'Row $line: $message';
}

class RosterParse {
  const RosterParse({required this.rows, required this.issues, this.fatal});
  final List<ParsedStudent> rows;
  final List<RosterIssue> issues;

  /// The file cannot be used at all (e.g. no name columns).
  final String? fatal;
}

enum _Col {
  studentNo,
  lastName,
  firstName,
  middleName,
  suffix,
  fullName,
  program,
  yearLevel,
  section,
  academicYear,
  semester,
}

const Map<_Col, List<String>> _aliases = {
  _Col.studentNo: [
    'studentno',
    'studentnumber',
    'studentid',
    'idnumber',
    'idno',
    'id',
    'studno',
    'studentidnumber',
    'studentnum',
    'schoolid',
    'lrn',
  ],
  _Col.lastName: ['lastname', 'surname', 'familyname', 'lname'],
  _Col.firstName: ['firstname', 'givenname', 'fname'],
  _Col.middleName: ['middlename', 'middleinitial', 'mi', 'mname'],
  _Col.suffix: ['suffix', 'ext', 'extension', 'nameextension', 'extname'],
  _Col.fullName: ['name', 'fullname', 'studentname', 'nameofstudent', 'completename'],
  _Col.program: ['course', 'program', 'courseprogram', 'degree', 'degreeprogram', 'strand'],
  _Col.yearLevel: ['year', 'yearlevel', 'yr', 'level', 'yearlvl'],
  _Col.section: ['section', 'block', 'class', 'sectionblock'],
  _Col.academicYear: ['academicyear', 'schoolyear', 'ay', 'sy'],
  _Col.semester: ['semester', 'sem', 'term'],
};

String _headerKey(Object? cell) => '$cell'.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

/// Decodes a CSV saved by Excel ("CSV UTF-8" or plain "CSV" in Windows-1252,
/// which would otherwise break names such as "Peña").
String decodeCsvBytes(List<int> bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}

/// File types a class list can be imported from.
const List<String> rosterFileExtensions = ['xlsx', 'csv', 'txt'];

/// Reads a class list from an Excel workbook (.xlsx) or a CSV/text file.
RosterParse parseRosterFile(String fileName, List<int> bytes) {
  final name = fileName.toLowerCase();
  if (name.endsWith('.xlsx')) return parseRosterXlsx(bytes);
  if (name.endsWith('.csv') || name.endsWith('.txt')) return parseRosterCsv(decodeCsvBytes(bytes));
  if (name.endsWith('.xls')) {
    return const RosterParse(
      rows: [],
      issues: [],
      fatal: 'This is an old Excel file (.xls). Open it in Excel or Google Sheets and save it as .xlsx or CSV.',
    );
  }
  return const RosterParse(rows: [], issues: [], fatal: 'Choose an Excel (.xlsx) or CSV file.');
}

RosterParse parseRosterCsv(String input) {
  var text = input;
  if (text.startsWith('﻿')) text = text.substring(1);
  final List<List<dynamic>> table;
  try {
    // Empty lines are kept so row numbers in messages match the file.
    table = Csv(dynamicTyping: false, skipEmptyLines: false).decode(text);
  } on Object {
    return const RosterParse(rows: [], issues: [], fatal: 'The file could not be read as CSV.');
  }
  return parseRosterTable(table);
}

RosterParse parseRosterXlsx(List<int> bytes) {
  final Excel book;
  try {
    book = Excel.decodeBytes(bytes);
  } on Object {
    return const RosterParse(rows: [], issues: [], fatal: 'The file could not be read as an Excel workbook.');
  }
  RosterParse? first;
  for (final sheet in book.tables.values) {
    final table = [
      for (final row in sheet.rows) [for (final cell in row) cellText(cell?.value)],
    ];
    if (table.every((r) => r.every((c) => c.isEmpty))) continue;
    final result = parseRosterTable(table);
    if (result.fatal == null) return result;
    first ??= result;
  }
  return first ?? const RosterParse(rows: [], issues: [], fatal: 'The workbook is empty.');
}

/// Text of an Excel cell as a teacher reads it ("2021001", not "2021001.0").
String cellText(CellValue? v) => switch (v) {
  null => '',
  TextCellValue() => v.value.toString(),
  IntCellValue(:final value) => '$value',
  DoubleCellValue(:final value) =>
    value == value.truncateToDouble() && value.abs() < 1e15 ? value.toInt().toString() : '$value',
  _ => v.toString(),
};

/// Parses rows of cells. Headers are recognized in any order (case and
/// punctuation ignored) within the first 10 rows. Required: first and last
/// name, or a single "Name" column written "DELA CRUZ, Juan P.". Optional:
/// student ID, middle name, suffix, course/program, year level, section,
/// academic year, semester.
RosterParse parseRosterTable(List<List<dynamic>> table) {
  if (table.isEmpty) return const RosterParse(rows: [], issues: [], fatal: 'The file is empty.');

  int? headerIndex;
  late Map<_Col, int> columns;
  for (var i = 0; i < table.length && i < 10; i++) {
    final found = <_Col, int>{};
    for (var c = 0; c < table[i].length; c++) {
      final key = _headerKey(table[i][c]);
      for (final entry in _aliases.entries) {
        if (!found.containsKey(entry.key) && entry.value.contains(key)) found[entry.key] = c;
      }
    }
    final hasNames =
        (found.containsKey(_Col.lastName) && found.containsKey(_Col.firstName)) || found.containsKey(_Col.fullName);
    if (hasNames) {
      headerIndex = i;
      columns = found;
      break;
    }
  }
  if (headerIndex == null) {
    return const RosterParse(
      rows: [],
      issues: [],
      fatal:
          'No header row found. The first row must name the columns, for example: '
          'Student ID, Last Name, First Name, Middle Name, Course, Year, Section.',
    );
  }

  String? cell(List<dynamic> row, _Col col) {
    final index = columns[col];
    if (index == null || index >= row.length) return null;
    final v = cleanSpaces('${row[index] ?? ''}');
    return v.isEmpty ? null : v;
  }

  final rows = <ParsedStudent>[];
  final issues = <RosterIssue>[];
  for (var i = headerIndex + 1; i < table.length; i++) {
    final row = table[i];
    final line = i + 1;
    if (row.every((c) => '${c ?? ''}'.trim().isEmpty)) continue;

    var last = cell(row, _Col.lastName);
    var first = cell(row, _Col.firstName);
    var middle = cell(row, _Col.middleName);
    if ((last == null || first == null) && cell(row, _Col.fullName) != null) {
      final full = cell(row, _Col.fullName)!;
      final comma = full.indexOf(',');
      if (comma <= 0) {
        issues.add(RosterIssue(line, 'Write the name as "Last name, First name".'));
        continue;
      }
      last = full.substring(0, comma).trim();
      final rest = full.substring(comma + 1).trim().split(' ');
      if (rest.length > 1 && RegExp(r'^[A-Za-z]\.?$').hasMatch(rest.last)) middle ??= rest.removeLast();
      first = rest.join(' ').trim();
    }
    if (last == null || last.isEmpty || first == null || first.isEmpty) {
      issues.add(RosterIssue(line, 'The first or last name is missing.'));
      continue;
    }
    final yearText = cell(row, _Col.yearLevel);
    final year = yearText == null ? null : int.tryParse(RegExp(r'\d').firstMatch(yearText)?.group(0) ?? '');
    rows.add(
      ParsedStudent(
        line: line,
        studentNo: cell(row, _Col.studentNo),
        firstName: _title(first),
        middleName: _title(middle ?? ''),
        lastName: _title(last),
        suffix: cell(row, _Col.suffix) ?? '',
        program: cell(row, _Col.program) ?? '',
        yearLevel: year != null && year >= 1 && year <= 6 ? year : null,
        section: cell(row, _Col.section),
        academicYear: cell(row, _Col.academicYear) ?? '',
        semester: cell(row, _Col.semester) ?? '',
      ),
    );
  }
  return RosterParse(rows: rows, issues: issues);
}

/// "DELA CRUZ" → "Dela Cruz" (lists are often in capitals); mixed case is kept.
String _title(String s) {
  if (s.isEmpty || s != s.toUpperCase()) return s;
  return s.toLowerCase().split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
}

const String classListTemplateName = 'ACEKOR class list.xlsx';

/// An empty class list to fill in, with the columns ACEKOR reads.
List<int> classListTemplateXlsx() {
  final book = Excel.createExcel();
  final defaultName = book.getDefaultSheet()!;
  book.rename(defaultName, 'Class list');
  final sheet = book['Class list'];
  const headers = ['Student ID', 'Last Name', 'First Name', 'Middle Name', 'Suffix', 'Course', 'Year', 'Section'];
  const widths = [16.0, 20.0, 20.0, 16.0, 8.0, 12.0, 6.0, 12.0];
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
