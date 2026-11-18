import 'package:excel_plus/excel_plus.dart';

import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/roster_repository.dart';
import '../../data/repositories/scores_repository.dart';
import '../../domain/categories.dart';
import '../../domain/scoring/percent.dart';
import 'report_model.dart';

/// Builds real .xlsx workbooks with formulas (totals, percentages,
/// weighted contributions and the final grade recalculate in Excel, Google
/// Sheets and WPS). Each formula also carries its computed value, so viewers
/// that do not recalculate still show the right numbers.
class XlsxReports {
  const XlsxReports();

  static final CellStyle _title = CellStyle(bold: true, fontSize: 14);
  static final CellStyle _muted = CellStyle(fontColorHex: ExcelColor.fromHexString('#555555'));
  static final CellStyle _head = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#DDF1EA'),
    horizontalAlign: HorizontalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );
  static final CellStyle _maxRow = CellStyle(italic: true, backgroundColorHex: ExcelColor.fromHexString('#F3F3F3'));
  static final CellStyle _pct = CellStyle(numberFormat: NumFormat.standard_2);
  static final CellStyle _text = CellStyle(numberFormat: NumFormat.standard_49);

  /// Row of the "Maximum points" line and of the first student (0-based).
  static const int headRow = 3;
  static const int maxRow = 4;
  static const int firstStudentRow = 5;

  static String col(int c) => getColumnAlphabet(c);
  static String cell(int c, int r) => '${col(c)}${r + 1}';
  static String ref(String sheet, int c, int r, {bool absRow = false}) =>
      "'$sheet'!${col(c)}${absRow ? '\$' : ''}${r + 1}";

  void _put(Sheet s, int c, int r, CellValue? v, [CellStyle? style]) => s.updateCell(
    CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
    v,
    cellStyle: style,
  );

  void _heading(Sheet s, String title, ReportHeader h) {
    _put(s, 0, 0, TextCellValue(title), _title);
    _put(
      s,
      0,
      1,
      TextCellValue(
        [
          if (h.schoolName.isNotEmpty) h.schoolName,
          if (h.subject != null) h.subject!,
          if (h.section != null) h.section!,
          if (h.academicYear.isNotEmpty) h.academicYear,
          if (h.semester.isNotEmpty) h.semester,
          if (h.instructor.isNotEmpty) 'Instructor: ${h.instructor}',
        ].join(' · '),
      ),
      _muted,
    );
  }

  static FormulaCellValue _f(String formula, [num? cached]) =>
      FormulaCellValue(formula, cachedValue: cached == null ? null : _num(cached));

  static String _num(num v) => v is int ? '$v' : v.toStringAsFixed(6);

  /// A workbook for one subject: Roster, Quizzes, Recitations, Examinations,
  /// Practical, Summary and Weighted Grade.
  List<int> subjectWorkbook(Gradebook book, ReportHeader header) {
    final x = Excel.createExcel();
    final defaultSheet = x.getDefaultSheet()!;
    final where = <String, (String, int)>{}; // activity id → (sheet, column)

    // Roster
    x.rename(defaultSheet, 'Roster');
    final roster = x['Roster'];
    _heading(roster, '${header.title} – Student roster', header);
    const rosterHeads = [
      'No.',
      'Student ID',
      'Last name',
      'First name',
      'Middle name',
      'Suffix',
      'Course',
      'Year',
      'Section',
      'Academic year',
      'Semester',
    ];
    for (var c = 0; c < rosterHeads.length; c++) {
      _put(roster, c, headRow, TextCellValue(rosterHeads[c]), _head);
    }
    for (var i = 0; i < book.students.length; i++) {
      final s = book.students[i].row;
      final r = headRow + 1 + i;
      _put(roster, 0, r, IntCellValue(i + 1));
      _put(roster, 1, r, TextCellValue(s.studentNo ?? ''), _text);
      _put(roster, 2, r, TextCellValue(s.lastName));
      _put(roster, 3, r, TextCellValue(s.firstName));
      _put(roster, 4, r, TextCellValue(s.middleName));
      _put(roster, 5, r, TextCellValue(s.suffix));
      _put(roster, 6, r, TextCellValue(s.program));
      _put(roster, 7, r, s.yearLevel == null ? null : IntCellValue(s.yearLevel!));
      _put(roster, 8, r, TextCellValue(book.students[i].sectionName ?? ''));
      _put(roster, 9, r, TextCellValue(s.academicYear));
      _put(roster, 10, r, TextCellValue(s.semester));
    }
    for (final (c, w) in [(0, 5.0), (1, 14.0), (2, 18.0), (3, 18.0), (4, 14.0), (8, 12.0)]) {
      roster.setColumnWidth(c, w);
    }
    roster.freezePanes(rows: headRow + 1);

    // Score sheets
    final groups = <(String, List<ActivityView>)>[
      ('Quizzes', book.activities.where((a) => a.kind == CategoryKind.quiz).toList()),
      ('Recitations', book.activities.where((a) => a.kind == CategoryKind.recitation).toList()),
      ('Examinations', book.activities.where((a) => a.kind == CategoryKind.exam && !isPractical(a)).toList()),
      ('Practical', book.activities.where(isPractical).toList()),
    ];
    for (final (name, acts) in groups) {
      final s = x[name];
      _scoreSheet(s, name, book, acts, header);
      for (var j = 0; j < acts.length; j++) {
        where[acts[j].id] = (name, 3 + j);
      }
    }

    _summarySheet(x['Summary'], book, header, where);
    _weightedSheet(x['Weighted Grade'], book, header, where);
    return x.encode()!;
  }

  void _scoreSheet(Sheet s, String name, Gradebook book, List<ActivityView> acts, ReportHeader header) {
    _heading(s, '${header.subject ?? ''} – $name', header);
    final heads = [
      'No.',
      'Student ID',
      'Student name',
      for (final a in acts) a.label,
      'Total',
      'Possible',
      'Percentage (%)',
    ];
    for (var c = 0; c < heads.length; c++) {
      _put(s, c, headRow, TextCellValue(heads[c]), _head);
    }
    s.setColumnWidth(0, 5);
    s.setColumnWidth(1, 14);
    s.setColumnWidth(2, 26);
    for (var j = 0; j < acts.length; j++) {
      s.setColumnWidth(3 + j, 11);
    }
    if (acts.isEmpty) {
      _put(s, 0, maxRow, TextCellValue('No activities of this kind.'), _muted);
      return;
    }
    final first = 3;
    final last = 3 + acts.length - 1;
    final totalC = last + 1, possibleC = last + 2, pctC = last + 3;
    _put(s, 2, maxRow, TextCellValue('Maximum points'), _maxRow);
    final possible = acts.fold(0, (t, a) => t + a.maxPoints);
    for (var j = 0; j < acts.length; j++) {
      _put(s, first + j, maxRow, IntCellValue(acts[j].maxPoints), _maxRow);
    }
    _put(s, totalC, maxRow, _f('SUM(${cell(first, maxRow)}:${cell(last, maxRow)})', possible), _maxRow);
    for (var i = 0; i < book.students.length; i++) {
      final st = book.students[i];
      final r = firstStudentRow + i;
      _put(s, 0, r, IntCellValue(i + 1));
      _put(s, 1, r, TextCellValue(st.row.studentNo ?? ''), _text);
      _put(s, 2, r, TextCellValue(st.formal));
      var earned = 0;
      for (var j = 0; j < acts.length; j++) {
        final p = book.scoreOf(st.id, acts[j].id);
        earned += p ?? 0;
        if (p != null) _put(s, first + j, r, IntCellValue(p));
      }
      _put(s, totalC, r, _f('SUM(${cell(first, r)}:${cell(last, r)})', earned));
      _put(s, possibleC, r, _f('${col(totalC)}\$${maxRow + 1}', possible));
      _put(
        s,
        pctC,
        r,
        _f(
          'IF(${cell(possibleC, r)}>0,${cell(totalC, r)}/${cell(possibleC, r)}*100,"")',
          possible == 0 ? null : earned * 100 / possible,
        ),
        _pct,
      );
    }
    // Class average per activity (recorded scores only).
    final avgRow = firstStudentRow + book.students.length;
    if (book.students.isNotEmpty) {
      _put(s, 2, avgRow, TextCellValue('Class average (%)'), _maxRow);
      final lastStudent = avgRow - 1;
      for (var j = 0; j < acts.length; j++) {
        final c = first + j;
        final st = book.stats(acts[j]);
        _put(
          s,
          c,
          avgRow,
          _f(
            'IFERROR(AVERAGE(${cell(c, firstStudentRow)}:${cell(c, lastStudent)})/${col(c)}\$${maxRow + 1}*100,"")',
            st.average?.toDouble(),
          ),
          _pct,
        );
      }
    }
    s.freezePanes(rows: maxRow + 1, columns: 3);
  }

  void _summarySheet(Sheet s, Gradebook book, ReportHeader header, Map<String, (String, int)> where) {
    _heading(s, '${header.subject ?? ''} – Summary', header);
    const heads = [
      'Category',
      'Activity',
      'Date',
      'Period',
      'Maximum',
      'Recorded',
      'Students',
      'Average (%)',
      'Highest',
      'Lowest',
    ];
    for (var c = 0; c < heads.length; c++) {
      _put(s, c, headRow, TextCellValue(heads[c]), _head);
    }
    final lastStudent = firstStudentRow + book.students.length - 1;
    var r = headRow + 1;
    for (final a in book.activities) {
      final loc = where[a.id];
      final st = book.stats(a);
      _put(s, 0, r, TextCellValue(a.category.name));
      _put(s, 1, r, TextCellValue(a.label));
      _put(s, 2, r, TextCellValue(a.row.activityDate ?? ''));
      _put(s, 3, r, TextCellValue(a.period == Period.none ? '' : a.period.label));
      _put(s, 4, r, IntCellValue(a.maxPoints));
      if (loc != null && book.students.isNotEmpty) {
        final range = "'${loc.$1}'!${col(loc.$2)}${firstStudentRow + 1}:${col(loc.$2)}${lastStudent + 1}";
        _put(s, 5, r, _f('COUNT($range)', st.recorded));
        _put(s, 6, r, IntCellValue(book.students.length));
        _put(s, 7, r, _f('IFERROR(AVERAGE($range)/${cell(4, r)}*100,"")', st.average?.toDouble()), _pct);
        _put(s, 8, r, _f('IF(${cell(5, r)}>0,MAX($range),"")', st.highest));
        _put(s, 9, r, _f('IF(${cell(5, r)}>0,MIN($range),"")', st.lowest));
      }
      r++;
    }
    s.setColumnWidth(0, 22);
    s.setColumnWidth(1, 22);
    s.freezePanes(rows: headRow + 1);
  }

  void _weightedSheet(Sheet s, Gradebook book, ReportHeader header, Map<String, (String, int)> where) {
    _heading(s, '${header.subject ?? ''} – Weighted grade', header);
    final weighted = book.weights.where((w) => w.weightBp > 0).toList();
    final byCat = <String, List<ActivityView>>{};
    for (final a in book.activities) {
      byCat.putIfAbsent(a.row.categoryId, () => []).add(a);
    }
    final average = book.subject.combineMethod == 'average_percent';
    // Columns: No, ID, Name, then (%, contribution) per category, Final, Equivalent, Remarks
    final heads = ['No.', 'Student ID', 'Student name'];
    for (final w in weighted) {
      heads
        ..add('${w.category.name} (%)')
        ..add('${w.category.name} × weight');
    }
    final finalC = 3 + weighted.length * 2;
    heads.addAll(['Weighted grade (%)', 'Equivalent', 'Remarks']);
    for (var c = 0; c < heads.length; c++) {
      _put(s, c, headRow, TextCellValue(heads[c]), _head);
    }
    _put(s, 2, maxRow, TextCellValue('Weight (%)'), _maxRow);
    var usedBp = 0;
    for (var k = 0; k < weighted.length; k++) {
      _put(s, 3 + k * 2, maxRow, DoubleCellValue(weighted[k].weightBp / 100), _maxRow);
      if ((byCat[weighted[k].category.id] ?? const []).isNotEmpty) usedBp += weighted[k].weightBp;
    }
    for (var i = 0; i < book.students.length; i++) {
      final st = book.students[i];
      final g = book.grades[st.id]!;
      final r = firstStudentRow + i;
      _put(s, 0, r, IntCellValue(i + 1));
      _put(s, 1, r, TextCellValue(st.row.studentNo ?? ''), _text);
      _put(s, 2, r, TextCellValue(st.formal));
      final contribCells = <String>[];
      for (var k = 0; k < weighted.length; k++) {
        final w = weighted[k];
        final acts = byCat[w.category.id] ?? const <ActivityView>[];
        final pc = 3 + k * 2, cc = pc + 1;
        final result = g.categories.where((c) => c.category.id == w.category.id).firstOrNull;
        if (acts.isEmpty) {
          _put(s, pc, r, TextCellValue('—'));
          continue;
        }
        final refs = [
          for (final a in acts)
            (ref(where[a.id]!.$1, where[a.id]!.$2, r), ref(where[a.id]!.$1, where[a.id]!.$2, maxRow, absRow: true)),
        ];
        final formula = average
            ? 'IFERROR((${refs.map((e) => 'N(${e.$1})/${e.$2}').join('+')})/${refs.length}*100,"")'
            : 'IFERROR(SUM(${refs.map((e) => e.$1).join(',')})/SUM(${refs.map((e) => e.$2).join(',')})*100,"")';
        _put(s, pc, r, _f(formula, result?.percent?.toDouble()), _pct);
        _put(
          s,
          cc,
          r,
          _f('IF(${cell(pc, r)}="","",${cell(pc, r)}*${col(pc)}\$${maxRow + 1}/100)', result?.contribution?.toDouble()),
          _pct,
        );
        contribCells.add(cell(cc, r));
      }
      if (contribCells.isNotEmpty && usedBp > 0) {
        final sum = 'SUM(${contribCells.join(',')})';
        _put(s, finalC, r, _f(usedBp == 10000 ? sum : '$sum/${usedBp / 100}*100', g.percent?.toDouble()), _pct);
      }
      _put(s, finalC + 1, r, TextCellValue(g.equivalent?.grade ?? ''));
      _put(s, finalC + 2, r, TextCellValue(g.passed == null ? '' : (g.passed! ? 'Passed' : 'Failed')));
    }
    final avgRow = firstStudentRow + book.students.length;
    if (book.students.isNotEmpty) {
      _put(s, 2, avgRow, TextCellValue('Class average'), _maxRow);
      _put(
        s,
        finalC,
        avgRow,
        _f(
          'IFERROR(AVERAGE(${cell(finalC, firstStudentRow)}:${cell(finalC, avgRow - 1)}),"")',
          book.classAverage?.toDouble(),
        ),
        _pct,
      );
    }
    final notes = [
      book.engine.weightsValid ? 'Weights total 100%.' : 'Weights do not total 100%; grades are not final.',
      average ? 'Activities combined by average of percentages.' : 'Activities combined by total points.',
      if (usedBp != 10000 && usedBp > 0)
        'Running grade: only components with activities are counted (${formatBp(usedBp)} of the weight).',
      if (book.scale != null)
        'Equivalent grades: ${book.scale!.name}${book.scale!.roundBeforeLookup ? ', percentage rounded to a whole number first' : ''}.',
    ];
    for (var n = 0; n < notes.length; n++) {
      _put(s, 0, avgRow + 2 + n, TextCellValue(notes[n]), _muted);
    }
    s.setColumnWidth(2, 26);
    s.freezePanes(rows: maxRow + 1, columns: 3);
  }

  /// Students × subjects (Overall academic performance).
  List<int> overallWorkbook(List<Gradebook> books, List<StudentView> students, ReportHeader header) {
    final x = Excel.createExcel();
    final name = x.getDefaultSheet()!;
    x.rename(name, 'Overall');
    final s = x['Overall'];
    _heading(s, header.title, header);
    final heads = [
      'No.',
      'Student ID',
      'Student name',
      for (final b in books) '${b.subject.code} (%)',
      'General average (%)',
    ];
    for (var c = 0; c < heads.length; c++) {
      _put(s, c, headRow, TextCellValue(heads[c]), _head);
    }
    for (var i = 0; i < students.length; i++) {
      final st = students[i];
      final r = headRow + 1 + i;
      _put(s, 0, r, IntCellValue(i + 1));
      _put(s, 1, r, TextCellValue(st.row.studentNo ?? ''), _text);
      _put(s, 2, r, TextCellValue(st.formal));
      for (var j = 0; j < books.length; j++) {
        final g = books[j].grades[st.id];
        if (g?.percent != null) {
          _put(s, 3 + j, r, DoubleCellValue(double.parse(g!.percent!.toDouble().toStringAsFixed(2))), _pct);
        }
      }
      if (books.isNotEmpty) {
        _put(s, 3 + books.length, r, _f('IFERROR(AVERAGE(${cell(3, r)}:${cell(2 + books.length, r)}),"")'), _pct);
      }
    }
    s.setColumnWidth(2, 26);
    return x.encode()!;
  }
}
