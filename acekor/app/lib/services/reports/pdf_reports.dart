import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/roster_repository.dart';
import '../../data/repositories/scores_repository.dart';
import '../../domain/categories.dart';
import '../../domain/scoring/percent.dart';
import 'report_model.dart';

/// Builds the printable PDF reports. Works offline; fonts are passed in
/// (Roboto, bundled with the app) so names such as "Peña" print correctly.
class PdfReports {
  PdfReports({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;

  static const PdfColor _ink = PdfColor.fromInt(0xFF111111);
  static const PdfColor _muted = PdfColor.fromInt(0xFF555555);
  static const PdfColor _rule = PdfColor.fromInt(0xFFBBBBBB);
  static const PdfColor _band = PdfColor.fromInt(0xFFEFF7F4);
  static const PdfColor _accent = PdfColor.fromInt(0xFF087F63);

  /// Activities per table before the matrix continues in another table.
  static const int columnsPerTable = 10;

  pw.ThemeData get _theme => pw.ThemeData.withFont(base: regular, bold: bold);

  pw.Widget _header(ReportHeader h) {
    final meta = <String>[
      if (h.subject != null) 'Subject: ${h.subject}',
      if (h.section != null) 'Course and section: ${h.section}',
      if (h.academicYear.isNotEmpty) 'Academic year: ${h.academicYear}',
      if (h.semester.isNotEmpty) 'Semester: ${h.semester}',
      if (h.period != null) 'Grading period: ${h.period}',
      if (h.instructor.isNotEmpty) 'Instructor: ${h.instructor}',
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (h.schoolName.isNotEmpty)
          pw.Text(
            h.schoolName.toUpperCase(),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(font: bold, fontSize: 14, color: _ink),
          ),
        if (h.schoolAddress.isNotEmpty)
          pw.Text(
            h.schoolAddress,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
        if (h.department.isNotEmpty)
          pw.Text(
            h.department,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10, color: _ink),
          ),
        if (h.extraLine.isNotEmpty)
          pw.Text(
            h.extraLine,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10, color: _ink),
          ),
        pw.SizedBox(height: 8),
        pw.Text(
          h.title.toUpperCase(),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: bold, fontSize: 13, color: _accent, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 6),
        pw.Wrap(
          spacing: 18,
          runSpacing: 2,
          alignment: pw.WrapAlignment.center,
          children: [for (final m in meta) pw.Text(m, style: const pw.TextStyle(fontSize: 9, color: _ink))],
        ),
        pw.SizedBox(height: 4),
        pw.Divider(color: _rule, thickness: 0.8),
      ],
    );
  }

  pw.Widget _footer(pw.Context context, ReportHeader h) {
    return pw.Column(
      children: [
        if (h.footerLine.isNotEmpty && context.pageNumber == context.pagesCount)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 18),
            child: pw.Row(children: [pw.Text(h.footerLine, style: const pw.TextStyle(fontSize: 10))]),
          ),
        pw.Row(
          children: [
            pw.Text(
              'Generated ${DateFormat('MMMM d, y h:mm a').format(h.generated)} · ACEKOR Calculator',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.Spacer(),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _table(
    List<String> headers,
    List<List<String>> rows, {
    Map<int, pw.TableColumnWidth>? widths,
    int leftColumns = 2,
  }) {
    pw.Widget cell(String text, {bool head = false, bool left = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: pw.Text(
        text,
        textAlign: left ? pw.TextAlign.left : pw.TextAlign.center,
        style: pw.TextStyle(font: head ? bold : regular, fontSize: head ? 7.5 : 8),
      ),
    );
    return pw.Table(
      border: pw.TableBorder.all(color: _rule, width: 0.5),
      columnWidths: widths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _band),
          repeat: true,
          children: [for (var i = 0; i < headers.length; i++) cell(headers[i], head: true, left: i < leftColumns)],
        ),
        for (final r in rows)
          pw.TableRow(children: [for (var i = 0; i < r.length; i++) cell(r[i], left: i < leftColumns)]),
      ],
    );
  }

  static String _scoreCell(int? points, int max) => points == null ? '—' : '$points\n${scorePercentText(points, max)}';

  /// Students × activities, split into tables of [columnsPerTable] activities.
  List<pw.Widget> _matrix(Gradebook book, List<ActivityView> acts, {bool totals = true}) {
    if (acts.isEmpty) {
      return [pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text('No activities of this kind.'))];
    }
    final out = <pw.Widget>[];
    for (var start = 0; start < acts.length; start += columnsPerTable) {
      final chunk = acts.sublist(start, (start + columnsPerTable).clamp(0, acts.length));
      final last = start + columnsPerTable >= acts.length;
      final headers = [
        'No.',
        'Student',
        for (final a in chunk) '${a.label}\n(${a.maxPoints})',
        if (last && totals) ...['Total', '%'],
      ];
      final possible = acts.fold(0, (s, a) => s + a.maxPoints);
      final rows = <List<String>>[];
      for (var i = 0; i < book.students.length; i++) {
        final s = book.students[i];
        final earned = acts.fold(0, (sum, a) => sum + (book.scoreOf(s.id, a.id) ?? 0));
        rows.add([
          '${i + 1}',
          s.formal,
          for (final a in chunk) _scoreCell(book.scoreOf(s.id, a.id), a.maxPoints),
          if (last && totals) ...['$earned/$possible', possible == 0 ? '' : scorePercentText(earned, possible)],
        ]);
      }
      // Class average row.
      rows.add([
        '',
        'Class average',
        for (final a in chunk)
          (() {
            final st = book.stats(a);
            return st.average == null ? '—' : formatPercent(st.average!);
          })(),
        if (last && totals) ...['', ''],
      ]);
      if (start > 0) out.add(pw.SizedBox(height: 12));
      out.add(_table(headers, rows, widths: {0: const pw.FixedColumnWidth(22), 1: const pw.FixedColumnWidth(120)}));
    }
    return out;
  }

  List<pw.Widget> _gradeSummary(Gradebook book) {
    final weighted = book.weights.where((w) => w.weightBp > 0).toList();
    final headers = [
      'No.',
      'Student',
      for (final w in weighted) '${w.category.name}\n${formatBp(w.weightBp)}',
      'Weighted\ngrade',
      'Equivalent',
      'Remarks',
    ];
    final rows = <List<String>>[];
    for (var i = 0; i < book.students.length; i++) {
      final s = book.students[i];
      final g = book.grades[s.id]!;
      rows.add([
        '${i + 1}',
        s.formal,
        for (final w in weighted)
          (() {
            final c = g.categories.where((c) => c.category.id == w.category.id).firstOrNull;
            if (c == null || c.percent == null) return '—';
            return '${formatPercent(c.percent!)}\n(${formatPercent(c.contribution!).replaceAll('%', '')})';
          })(),
        g.percent == null ? '—' : formatPercent(g.percent!) + (g.complete ? '' : '*'),
        g.equivalent?.grade ?? '—',
        g.passed == null ? '' : (g.passed! ? 'Passed' : 'Failed'),
      ]);
    }
    final avg = book.classAverage;
    return [
      _table(headers, rows, widths: {0: const pw.FixedColumnWidth(22), 1: const pw.FixedColumnWidth(120)}),
      pw.SizedBox(height: 8),
      pw.Text(
        'Class average: ${avg == null ? '—' : formatPercent(avg)}.  '
        'Each cell shows the component percentage and its weighted contribution.  '
        '* Running grade: some weighted components have no activities yet.  '
        '${book.subject.combineMethod == 'average_percent' ? 'Activities combined by average of percentages.' : 'Activities combined by total points.'}'
        '${book.scale == null ? '' : '  Scale: ${book.scale!.name}${book.scale!.roundBeforeLookup ? ' (rounded to whole %)' : ''}.'}',
        style: const pw.TextStyle(fontSize: 8, color: _muted),
      ),
    ];
  }

  List<pw.Widget> _student(Gradebook book, StudentView s) {
    final g = book.grades[s.id];
    final lines = <List<String>>[];
    for (final k in CategoryKind.values) {
      for (final a in book.activities.where((a) => a.kind == k)) {
        final p = book.scoreOf(s.id, a.id);
        lines.add([
          a.label,
          a.row.activityDate ?? '',
          p == null ? '—' : '$p/${a.maxPoints}',
          p == null ? 'missing' : scorePercentText(p, a.maxPoints),
        ]);
      }
    }
    return [
      pw.Text(s.complete, style: pw.TextStyle(font: bold, fontSize: 13)),
      pw.Text(
        [
          if (s.row.studentNo != null) 'Student ID: ${s.row.studentNo}',
          if (s.sectionName != null) 'Section: ${s.sectionName}',
          if (s.row.program.isNotEmpty) s.row.program,
          if (s.row.yearLevel != null) 'Year ${s.row.yearLevel}',
        ].join('   '),
        style: const pw.TextStyle(fontSize: 9),
      ),
      pw.SizedBox(height: 10),
      _table(['Activity', 'Date', 'Score', 'Percentage'], lines, leftColumns: 1),
      if (g != null) ...[
        pw.SizedBox(height: 14),
        pw.Text('Grade computation', style: pw.TextStyle(font: bold, fontSize: 11)),
        pw.SizedBox(height: 4),
        _table(
          ['Component', 'Weight', 'Points', 'Percentage', 'Contribution'],
          [
            for (final c in g.categories.where((c) => c.hasActivities || c.counts))
              [
                c.category.name,
                formatBp(c.category.weightBp),
                c.hasActivities ? '${c.earned}/${c.possible}' : '—',
                c.percent == null ? '—' : formatPercent(c.percent!),
                c.contribution == null || !c.counts ? '—' : formatPercent(c.contribution!).replaceAll('%', ''),
              ],
            [
              g.complete
                  ? 'FINAL WEIGHTED GRADE'
                  : 'RUNNING GRADE (${g.componentsCounted} of ${g.componentsWeighted} components)',
              '',
              '',
              '',
              g.percent == null ? '—' : formatPercent(g.percent!),
            ],
            if (g.equivalent != null)
              ['Equivalent grade', '', '', '', '${g.equivalent!.grade} ${g.equivalent!.remark}'],
          ],
          leftColumns: 1,
        ),
      ],
    ];
  }

  List<pw.Widget> _overall(List<Gradebook> books, List<StudentView> students) {
    final headers = ['No.', 'Student', for (final b in books) b.subject.code, 'General\naverage'];
    final rows = <List<String>>[];
    for (var i = 0; i < students.length; i++) {
      final s = students[i];
      final cells = <String>[];
      var sum = 0.0;
      var n = 0;
      for (final b in books) {
        final g = b.grades[s.id];
        if (g == null || g.percent == null) {
          cells.add(b.grades.containsKey(s.id) ? '—' : '');
          continue;
        }
        sum += g.percent!.toDouble();
        n++;
        cells.add('${formatPercent(g.percent!)}${g.equivalent == null ? '' : '\n${g.equivalent!.grade}'}');
      }
      rows.add(['${i + 1}', s.formal, ...cells, n == 0 ? '—' : '${(sum / n).toStringAsFixed(2)}%']);
    }
    return [
      _table(headers, rows, widths: {0: const pw.FixedColumnWidth(22), 1: const pw.FixedColumnWidth(120)}),
      pw.SizedBox(height: 8),
      pw.Text(
        'Empty cell: not enrolled in the subject. General average: mean of the subject percentages shown.',
        style: const pw.TextStyle(fontSize: 8, color: _muted),
      ),
    ];
  }

  /// Builds a report. [books] has one gradebook (or one per subject for
  /// [ReportType.overall]); [student] is required for [ReportType.student].
  Future<Uint8List> build({
    required ReportType type,
    required ReportHeader header,
    required List<Gradebook> books,
    StudentView? student,
    List<StudentView>? overallStudents,
  }) async {
    final doc = pw.Document(
      title: header.title,
      author: header.instructor,
      creator: 'ACEKOR Calculator',
      theme: _theme,
    );
    final landscape = type != ReportType.student;
    final List<pw.Widget> body;
    switch (type) {
      case ReportType.student:
        body = _student(books.single, student!);
      case ReportType.gradeSummary:
        body = _gradeSummary(books.single);
      case ReportType.overall:
        body = _overall(books, overallStudents ?? const []);
      case ReportType.classPerformance:
        body = [
          ..._matrix(books.single, books.single.activities),
          pw.SizedBox(height: 16),
          pw.Text('Weighted grades', style: pw.TextStyle(font: bold, fontSize: 11)),
          pw.SizedBox(height: 6),
          ..._gradeSummary(books.single),
        ];
      default:
        final book = books.single;
        body = _matrix(book, activitiesFor(type, book));
        if (type == ReportType.recitations) {
          body.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                'Total = accumulated recitation points; % = accumulated points ÷ points possible.',
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ),
          );
        }
    }
    doc.addPage(
      pw.MultiPage(
        pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 24),
        header: (context) => context.pageNumber == 1 ? _header(header) : pw.SizedBox(),
        footer: (context) => _footer(context, header),
        build: (context) => body,
      ),
    );
    return doc.save();
  }
}
