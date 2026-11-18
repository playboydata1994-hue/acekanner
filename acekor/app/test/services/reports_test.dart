import 'dart:io';
import 'dart:typed_data';

import 'package:acekor/data/repositories/activities_repository.dart';
import 'package:acekor/data/repositories/roster_repository.dart';
import 'package:acekor/data/repositories/scores_repository.dart';
import 'package:acekor/data/repositories/subjects_repository.dart';
import 'package:acekor/services/reports/pdf_reports.dart';
import 'package:acekor/services/reports/report_model.dart';
import 'package:acekor/services/reports/xlsx_reports.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import '../support/test_db.dart';

pw.Font font(String name) => pw.Font.ttf(ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync()));

void main() {
  late Gradebook book;
  late List<Gradebook> books;
  late List<StudentView> students;
  final outDir = Platform.environment['ACEKOR_REPORT_OUT'];

  setUpAll(() async {
    final db = newTestDatabase();
    final roster = RosterRepository(db);
    final subjects = SubjectsRepository(db);
    final acts = ActivitiesRepository(db);
    final scores = ScoresRepository(db);
    final sec = await roster.createSection(const SectionInput(name: 'BSIT 1-A', program: 'BSIT', yearLevel: 1));
    final sid = await subjects.createSubject(
      const SubjectInput(
        code: 'IT 101',
        title: 'Introduction to Computing',
        academicYear: '2026-2027',
        semester: '1st Semester',
      ),
    );
    final names = [('Juan', 'Dela Cruz'), ('María', 'Peña'), ('Jose', 'Rizal'), ('Ana', 'Reyes'), ('Ben', 'Santos')];
    final ids = <String>[];
    for (var i = 0; i < names.length; i++) {
      ids.add(
        await roster.addStudent(
          StudentInput(firstName: names[i].$1, lastName: names[i].$2, studentNo: '2026-00${i + 1}', sectionId: sec),
          subjectIds: [sid],
        ),
      );
    }
    final q = [
      for (var n = 1; n <= 12; n++)
        await acts.createActivity(
          ActivityInput(subjectId: sid, categoryId: 'quiz', number: n, maxPoints: n.isEven ? 50 : 20),
        ),
    ];
    final r = [
      for (var n = 1; n <= 3; n++)
        await acts.createActivity(ActivityInput(subjectId: sid, categoryId: 'recitation', number: n, maxPoints: 10)),
    ];
    final mid = await acts.createActivity(ActivityInput(subjectId: sid, categoryId: 'midterm', maxPoints: 100));
    final prac = await acts.createActivity(ActivityInput(subjectId: sid, categoryId: 'practical', maxPoints: 50));
    for (var i = 0; i < ids.length; i++) {
      for (var j = 0; j < q.length; j++) {
        if (i == 4 && j == 3) continue; // one missing score
        await scores.save(q[j], ids[i], (j.isEven ? 20 : 50) - i - j % 3);
      }
      for (final x in r) {
        await scores.save(x, ids[i], 10 - i);
      }
      await scores.save(mid, ids[i], 95 - i * 7);
      await scores.save(prac, ids[i], 45 - i * 3);
    }
    final second = await subjects.createSubject(const SubjectInput(code: 'IT 102'));
    await subjects.enrolStudents(second, ids.take(3).toList());
    final q2 = await acts.createActivity(
      ActivityInput(subjectId: second, categoryId: 'quiz', number: 1, maxPoints: 10),
    );
    for (final s in ids.take(3)) {
      await scores.save(q2, s, 8);
    }
    final service = GradebookService(db);
    book = (await service.build(sid))!;
    books = [book, (await service.build(second))!];
    students = await roster.students();
  });

  ReportHeader header(String title) => ReportHeader(
    title: title,
    generated: DateTime(2026, 11, 17, 9),
    schoolName: 'Sample State University',
    schoolAddress: 'Quezon City',
    department: 'College of Information Technology',
    instructor: 'Prof. Maria Santos',
    subject: 'IT 101 – Introduction to Computing',
    section: 'BSIT 1-A',
    academicYear: '2026-2027',
    semester: '1st Semester',
    footerLine: 'Prepared by: ______________________',
  );

  test('all eight PDF reports build', () async {
    final pdf = PdfReports(regular: font('Roboto-Regular.ttf'), bold: font('Roboto-Bold.ttf'));
    for (final t in ReportType.values) {
      final bytes = await pdf.build(
        type: t,
        header: header(t.title),
        books: t.allSubjects ? books : [book],
        student: t.needsStudent ? book.students.first : null,
        overallStudents: students,
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(2000), reason: t.name);
      if (outDir != null) File('$outDir/${t.name}.pdf').writeAsBytesSync(bytes);
    }
  });

  test('Excel workbook: the seven sheets, formulas and correct values', () {
    final bytes = const XlsxReports().subjectWorkbook(book, header('Class record'));
    if (outDir != null) File('$outDir/IT101_class_record.xlsx').writeAsBytesSync(bytes);
    final x = Excel.decodeBytes(bytes);
    expect(
      x.tables.keys,
      containsAll(['Roster', 'Quizzes', 'Recitations', 'Examinations', 'Practical', 'Summary', 'Weighted Grade']),
    );
    final quizzes = x['Quizzes'];
    final total = quizzes.cell(CellIndex.indexByString('P6')).value; // 12 quizzes in D..O, Total in P
    expect(total, isA<FormulaCellValue>());
    expect((total as FormulaCellValue).formula, 'SUM(D6:O6)');
    final pct = quizzes.cell(CellIndex.indexByString('R6')).value as FormulaCellValue;
    expect(pct.formula, 'IF(Q6>0,P6/Q6*100,"")');
    final weighted = x['Weighted Grade'];
    final heads = [
      for (var c = 0; c < 16; c++)
        weighted.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3)).value?.toString() ?? '',
    ];
    expect(heads, contains('Weighted grade (%)'));
    final finalCol = heads.indexOf('Weighted grade (%)');
    final f = weighted.cell(CellIndex.indexByColumnRow(columnIndex: finalCol, rowIndex: 5)).value as FormulaCellValue;
    expect(f.formula, startsWith('SUM('));
    // The cached value matches the app's own grade.
    final g = book.grades[book.students.first.id]!.percent!.toDouble();
    expect(double.parse(f.cachedValue!), closeTo(g, 1e-6));
    expect(x['Roster'].cell(CellIndex.indexByString('B5')).value.toString(), startsWith('2026-00'));
  });

  test('overall workbook', () {
    final bytes = const XlsxReports().overallWorkbook(books, students, header('Overall'));
    final x = Excel.decodeBytes(bytes);
    expect(x.tables.keys, contains('Overall'));
  });
}
