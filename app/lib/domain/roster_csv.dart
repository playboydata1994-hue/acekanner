import 'package:csv/csv.dart';

import '../core/util/text.dart';
import 'student_number.dart';
import 'validators.dart';

/// One student read from a roster file.
class RosterRow {
  const RosterRow({
    required this.line,
    required this.studentNo,
    required this.lastName,
    required this.firstName,
    this.middleName,
    this.suffix,
    this.email,
  });

  /// 1-based line in the file (for messages).
  final int line;
  final String studentNo;
  final String lastName;
  final String firstName;
  final String? middleName;
  final String? suffix;
  final String? email;

  String get key => StudentNumber.normalize(studentNo);
}

class RosterIssue {
  const RosterIssue(this.line, this.message);

  final int line;
  final String message;

  @override
  String toString() => 'Line $line: $message';
}

class RosterParseResult {
  const RosterParseResult({required this.rows, required this.issues, this.fatal});

  final List<RosterRow> rows;
  final List<RosterIssue> issues;

  /// Set when the file cannot be used at all (e.g. no student-number column).
  final String? fatal;
}

enum _Col { studentNo, lastName, firstName, middleName, suffix, email, fullName }

const Map<_Col, List<String>> _aliases = {
  _Col.studentNo: [
    'studentno', 'studentnumber', 'studentid', 'idnumber', 'idno', 'id',
    'studno', 'studentidnumber', 'studentnum', 'schoolid',
  ],
  _Col.lastName: ['lastname', 'surname', 'familyname', 'lname'],
  _Col.firstName: ['firstname', 'givenname', 'fname'],
  _Col.middleName: ['middlename', 'middleinitial', 'mi', 'mname'],
  _Col.suffix: ['suffix', 'ext', 'extension', 'nameextension', 'extname'],
  _Col.email: ['email', 'emailaddress', 'eaddress'],
  _Col.fullName: ['name', 'fullname', 'studentname', 'nameofstudent'],
};

String _headerKey(Object? cell) =>
    '$cell'.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

/// Parses a class list exported from Excel/Google Sheets as CSV.
///
/// Recognized headers (any order, case and punctuation ignored): student no /
/// student number / ID number; last name / surname; first name / given name;
/// middle name / M.I.; suffix; email. A single "Name" column in the form
/// "DELA CRUZ, Juan P." is also accepted. Comma, semicolon and tab separators
/// are detected automatically; values are always read as text so leading
/// zeros in student numbers are kept.
RosterParseResult parseRosterCsv(String input) {
  var text = input;
  if (text.startsWith('\uFEFF')) text = text.substring(1);
  final List<List<dynamic>> table;
  try {
    table = Csv(dynamicTyping: false, skipEmptyLines: true).decode(text);
  } on Object {
    return const RosterParseResult(
      rows: [],
      issues: [],
      fatal: 'The file could not be read as CSV.',
    );
  }
  return parseRosterTable(table);
}

/// Reads a class list from rows of cells (from CSV or an Excel sheet). Same
/// header detection and checks as [parseRosterCsv].
RosterParseResult parseRosterTable(List<List<dynamic>> table) {
  if (table.isEmpty) {
    return const RosterParseResult(rows: [], issues: [], fatal: 'The file is empty.');
  }

  // Find the header row within the first 10 lines (lists often start with a title).
  int? headerIndex;
  late Map<_Col, int> columns;
  for (var i = 0; i < table.length && i < 10; i++) {
    final found = <_Col, int>{};
    for (var c = 0; c < table[i].length; c++) {
      final key = _headerKey(table[i][c]);
      for (final entry in _aliases.entries) {
        if (!found.containsKey(entry.key) && entry.value.contains(key)) {
          found[entry.key] = c;
        }
      }
    }
    final hasNames = (found.containsKey(_Col.lastName) && found.containsKey(_Col.firstName)) ||
        found.containsKey(_Col.fullName);
    if (found.containsKey(_Col.studentNo) && hasNames) {
      headerIndex = i;
      columns = found;
      break;
    }
  }
  if (headerIndex == null) {
    return const RosterParseResult(
      rows: [],
      issues: [],
      fatal: 'No header row found. The first row must name the columns, for '
          'example: Student No, Last Name, First Name, Middle Name.',
    );
  }

  String? cell(List<dynamic> row, _Col col) {
    final index = columns[col];
    if (index == null || index >= row.length) return null;
    final v = cleanSpaces('${row[index] ?? ''}');
    return v.isEmpty ? null : v;
  }

  final rows = <RosterRow>[];
  final issues = <RosterIssue>[];
  final seen = <String, int>{};
  for (var i = headerIndex + 1; i < table.length; i++) {
    final row = table[i];
    final line = i + 1;
    if (row.every((c) => '${c ?? ''}'.trim().isEmpty)) continue;

    final studentNo = cell(row, _Col.studentNo) ?? '';
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
      if (rest.length > 1 && RegExp(r'^[A-Za-z]\.?$').hasMatch(rest.last)) {
        middle ??= rest.removeLast();
      }
      first = rest.join(' ').trim();
    }

    final noError = StudentNumber.validate(studentNo);
    if (noError != null) {
      issues.add(RosterIssue(line, noError));
      continue;
    }
    final lastError = Validators.required(last, 'last name', max: 80);
    final firstError = Validators.required(first, 'first name', max: 80);
    if (lastError != null || firstError != null) {
      issues.add(RosterIssue(line, lastError ?? firstError!));
      continue;
    }
    final email = cell(row, _Col.email);
    if (Validators.email(email) != null) {
      issues.add(RosterIssue(line, 'Invalid email address "$email".'));
      continue;
    }
    final key = StudentNumber.normalize(studentNo);
    final earlier = seen[key];
    if (earlier != null) {
      issues.add(RosterIssue(line, 'Student number $studentNo is also on line $earlier.'));
      continue;
    }
    seen[key] = line;
    rows.add(
      RosterRow(
        line: line,
        studentNo: studentNo,
        lastName: last!,
        firstName: first!,
        middleName: middle,
        suffix: cell(row, _Col.suffix),
        email: email,
      ),
    );
  }
  return RosterParseResult(rows: rows, issues: issues);
}
