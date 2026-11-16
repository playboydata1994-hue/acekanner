import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/domain/sheet_layout.dart';
import 'package:acekanner/services/answer_sheet_pdf.dart';

SheetFonts loadFonts() => SheetFonts(
      ByteData.sublistView(File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync()),
      ByteData.sublistView(File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync()),
    );

const header = SheetHeader(
  examTitle: 'Midterm Examination',
  examCode: 'K7M2Q9XA',
  subjectLine: 'CS101 — Programming 1',
  dateText: '16 November 2026',
  schoolName: 'Mindanao State University',
  instructorName: 'Prof. Maria Peña Santos',
);

int pageCount(Uint8List pdf) => RegExp(r'/Type\s*/Page\b').allMatches(String.fromCharCodes(pdf)).length;

void main() {
  final fonts = loadFonts();

  test('generic sheets: one page per copy, every paper size', () async {
    for (final paper in PaperSize.values) {
      final pdf = await AnswerSheetPdf.build(
        layout: SheetLayout(itemCount: 100, idDigits: 12, setCount: 4),
        header: header,
        paper: paper,
        fonts: fonts,
        copies: 3,
      );
      expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
      expect(pageCount(pdf), 3);
      // MediaBox matches the paper size (points).
      final box = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)').firstMatch(String.fromCharCodes(pdf))!;
      expect(double.parse(box.group(1)!), closeTo(paper.widthMm * 72 / 25.4, 0.5));
      expect(double.parse(box.group(2)!), closeTo(paper.heightMm * 72 / 25.4, 0.5));
    }
  });

  test('personalized sheets: one page per student, names with ñ are embedded', () async {
    final pdf = await AnswerSheetPdf.build(
      layout: SheetLayout(itemCount: 50),
      header: header,
      paper: PaperSize.a4,
      fonts: fonts,
      students: const [
        SheetStudent(name: 'PEÑA, Niño', studentNo: '2021-00123', sheetCode: 'P0000001', section: 'BSIT 2-A'),
        SheetStudent(name: 'DELA CRUZ, Juan', studentNo: '2021-00124', sheetCode: 'P0000002'),
      ],
    );
    expect(pageCount(pdf), 2);
  });

  test('frame is centred on every paper size', () {
    expect(PaperSize.a4.frameOffset.x, closeTo(10, 1e-9));
    expect(PaperSize.a4.frameOffset.y, closeTo(23.5, 1e-9));
    expect(PaperSize.letter.frameOffset.y, closeTo(14.7, 1e-9));
    expect(PaperSize.long.frameOffset.y, closeTo(40.1, 1e-9));
    expect(PaperSize.fromCode('long'), PaperSize.long);
    expect(PaperSize.fromCode('bogus'), PaperSize.a4);
  });

  test('engine PDF fixtures (exported with ACEK_EXPORT_FIXTURES=1)', () async {
    if (Platform.environment['ACEK_EXPORT_FIXTURES'] != '1') return;
    final dir = Directory('../omr_engine/src/test/resources/sheets')..createSync(recursive: true);
    final fixtures = {
      'a4-ack1-50-d10-s1': (SheetLayout(itemCount: 50), PaperSize.a4),
      'letter-ack1-75-d9-s2': (SheetLayout(itemCount: 75, idDigits: 9, setCount: 2), PaperSize.letter),
      'long-ack1-100-d12-s4': (SheetLayout(itemCount: 100, idDigits: 12, setCount: 4), PaperSize.long),
    };
    for (final MapEntry(:key, value: (layout, paper)) in fixtures.entries) {
      final pdf = await AnswerSheetPdf.build(layout: layout, header: header, paper: paper, fonts: fonts);
      File('${dir.path}/$key.pdf').writeAsBytesSync(pdf);
    }
  });
}
