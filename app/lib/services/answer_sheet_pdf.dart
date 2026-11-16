import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/sheet_layout.dart';
import '../domain/sheet_qr.dart';

/// Supported paper. The 190 × 250 mm sheet frame is centred on each.
enum PaperSize {
  a4('A4', 210, 297),
  letter('Letter (8.5 × 11 in)', 215.9, 279.4),
  long('Long (8.5 × 13 in)', 215.9, 330.2);

  const PaperSize(this.label, this.widthMm, this.heightMm);

  final String label;
  final double widthMm;
  final double heightMm;

  String get code => switch (this) { PaperSize.a4 => 'a4', PaperSize.letter => 'letter', PaperSize.long => 'long' };

  static PaperSize fromCode(String? code) =>
      PaperSize.values.firstWhere((p) => p.code == code, orElse: () => PaperSize.a4);

  /// Top-left of the sheet frame on the page, in mm.
  Mm get frameOffset => Mm(
        (widthMm - SheetLayout.frameWidth) / 2,
        (heightMm - SheetLayout.frameHeight) / 2,
      );
}

/// Printed examination details. [instructorName] and [logo] are optional:
/// leave them null to keep them off the sheet.
class SheetHeader {
  const SheetHeader({
    required this.examTitle,
    required this.examCode,
    this.subjectLine,
    this.dateText,
    this.schoolName,
    this.instructorName,
    this.logo,
  });

  final String examTitle;
  final String examCode;
  final String? subjectLine;
  final String? dateText;
  final String? schoolName;
  final String? instructorName;

  /// School logo (PNG or JPEG bytes), printed beside the title.
  final Uint8List? logo;
}

/// One personalized sheet.
class SheetStudent {
  const SheetStudent({
    required this.name,
    required this.studentNo,
    required this.sheetCode,
    this.section,
  });

  final String name;
  final String studentNo;
  final String sheetCode;
  final String? section;
}

class SheetFonts {
  SheetFonts(ByteData regular, ByteData bold)
      : regular = pw.Font.ttf(regular),
        bold = pw.Font.ttf(bold);

  final pw.Font regular;
  final pw.Font bold;
}

/// Generates printable answer sheets that the OMR engine reads.
///
/// All geometry comes from [SheetLayout]; nothing here may move a bubble,
/// marker or the QR code. Text is drawn in grey or kept outside the reading
/// areas so it never adds darkness to a bubble except its own printed letter.
abstract final class AnswerSheetPdf {
  static const PdfColor _ink = PdfColor.fromInt(0xFF000000);
  static const PdfColor _bubble = PdfColor.fromInt(0xFF4D4D4D);
  static const PdfColor _letter = PdfColor.fromInt(0xFF8C8C8C);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5F6368);
  static const PdfColor _rule = PdfColor.fromInt(0xFFC8C8C8);

  /// Logo box beside the top-left marker, clear of its quiet zone (mm).
  static const MmRect logoBox = MmRect(13, 0, 11, 11);

  /// Generic sheets ([students] empty: [copies] identical pages, may be
  /// photocopied) or one personalized page per student.
  static Future<Uint8List> build({
    required SheetLayout layout,
    required SheetHeader header,
    required PaperSize paper,
    required SheetFonts fonts,
    int copies = 1,
    List<SheetStudent> students = const [],
  }) {
    final doc = pw.Document(
      title: '${header.examTitle} — answer sheets',
      author: header.instructorName,
      creator: 'ACEkanner',
      producer: 'ACEkanner',
    );
    final format = PdfPageFormat(paper.widthMm * PdfPageFormat.mm, paper.heightMm * PdfPageFormat.mm);
    // One image object shared by every page; an unreadable logo is left out.
    pw.ImageProvider? logo;
    if (header.logo != null) {
      try {
        logo = pw.MemoryImage(header.logo!);
      } catch (_) {
        logo = null;
      }
    }
    final pages = students.isEmpty ? List<SheetStudent?>.filled(copies.clamp(1, 500), null) : students;
    for (final student in pages) {
      final qr = SheetQr(
        examCode: header.examCode,
        itemCount: layout.itemCount,
        idDigits: layout.idDigits,
        setCount: layout.setCount,
        sheetCode: student?.sheetCode,
      ).encode();
      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
            children: [
              pw.Positioned(
                left: paper.frameOffset.x * PdfPageFormat.mm,
                top: paper.frameOffset.y * PdfPageFormat.mm,
                child: _frame(context, layout, header, fonts, qr, student, logo),
              ),
            ],
          ),
        ),
      );
    }
    return doc.save();
  }

  static const double mm = PdfPageFormat.mm;

  static pw.Widget _frame(
    pw.Context context,
    SheetLayout l,
    SheetHeader header,
    SheetFonts fonts,
    String qr,
    SheetStudent? student,
    pw.ImageProvider? logo,
  ) {
    final regular = fonts.regular.getFont(context);
    final bold = fonts.bold.getFont(context);
    const w = SheetLayout.frameWidth;
    const h = SheetLayout.frameHeight;

    return pw.SizedBox(
      width: w * mm,
      height: h * mm,
      child: pw.Stack(
        children: [
          pw.CustomPaint(
            size: const PdfPoint(w * mm, h * mm),
            painter: (canvas, size) {
              // Layout coordinates (mm, y down) -> PDF points (y up).
              double x(double v) => v * mm;
              double y(double v) => (h - v) * mm;

              void text(String s, double xMm, double baselineMm, double pt, PdfFont font, PdfColor color,
                  {bool center = false, bool right = false}) {
                final width = font.stringMetrics(s).width * pt;
                var left = x(xMm);
                if (center) left -= width / 2;
                if (right) left -= width;
                canvas
                  ..setFillColor(color)
                  ..drawString(font, pt, s, left, y(baselineMm));
              }

              // Corner markers (OpenCV DICT_4X4_50): black square, white bits.
              final cell = SheetLayout.markerSize / 6;
              for (var i = 0; i < 4; i++) {
                final o = l.markerOrigins[i];
                final bits = ArucoMarkers.bits[l.markerIds[i]];
                canvas
                  ..setFillColor(_ink)
                  ..drawRect(x(o.x), y(o.y + SheetLayout.markerSize), SheetLayout.markerSize * mm, SheetLayout.markerSize * mm)
                  ..fillPath()
                  ..setFillColor(PdfColors.white);
                for (var r = 0; r < 4; r++) {
                  for (var c = 0; c < 4; c++) {
                    if (bits[r * 4 + c] == '1') {
                      canvas.drawRect(
                        x(o.x + (c + 1) * cell),
                        y(o.y + (r + 2) * cell),
                        cell * mm + 0.05,
                        cell * mm + 0.05,
                      );
                    }
                  }
                }
                canvas.fillPath();
              }

              // Board-exam style oval with its letter or digit inside.
              void bubble(Mm c, double rx, double ry, String label, double labelPt) {
                canvas
                  ..setStrokeColor(_bubble)
                  ..setLineWidth(0.3 * mm)
                  ..drawEllipse(x(c.x), y(c.y), rx * mm, ry * mm)
                  ..strokePath();
                text(label, c.x, c.y + labelPt * 0.125, labelPt, regular, _letter, center: true);
              }

              // Answer area: numbers, ovals, a light rule every 5 rows.
              const letters = ['A', 'B', 'C', 'D', 'E'];
              for (var q = 0; q < l.questions.length; q++) {
                final row = l.questions[q];
                text('${q + 1}', row[0].x - SheetLayout.bubbleRx - 2.0, row[0].y + 1.2, 8, bold, _ink, right: true);
                for (var c = 0; c < 5; c++) {
                  bubble(row[c], SheetLayout.bubbleRx, SheetLayout.bubbleRy, letters[c], 5.5);
                }
                if (q % SheetLayout.rowsPerColumn % 5 == 4 && q % SheetLayout.rowsPerColumn != SheetLayout.rowsPerColumn - 1) {
                  final ry = row[0].y + SheetLayout.rowPitch / 2;
                  canvas
                    ..setStrokeColor(_rule)
                    ..setLineWidth(0.2 * mm)
                    ..moveTo(x(row[0].x - SheetLayout.numberWidth + 0.5), y(ry))
                    ..lineTo(x(row[4].x + SheetLayout.bubbleRx), y(ry))
                    ..strokePath();
                }
              }

              // Header rule.
              canvas
                ..setStrokeColor(_rule)
                ..setLineWidth(0.3 * mm)
                ..moveTo(x(0), y(SheetLayout.headerBottom))
                ..lineTo(x(w), y(SheetLayout.headerBottom))
                ..strokePath();

              // Student-number grid: write-in boxes and digit bubbles.
              final firstCol = l.idColumns.first.first;
              text('STUDENT NUMBER', firstCol.x - SheetLayout.idBubbleRx, 16.2, 6.5, bold, _muted);
              for (final column in l.idColumns) {
                final cx = column.first.x;
                canvas
                  ..setStrokeColor(_bubble)
                  ..setLineWidth(0.25 * mm)
                  ..drawRect(
                    x(cx - SheetLayout.idBoxSize / 2),
                    y(SheetLayout.idBoxTop + SheetLayout.idBoxSize),
                    SheetLayout.idBoxSize * mm,
                    SheetLayout.idBoxSize * mm,
                  )
                  ..strokePath();
                for (var d = 0; d < 10; d++) {
                  bubble(column[d], SheetLayout.idBubbleRx, SheetLayout.idBubbleRy, '$d', 5);
                }
              }

              // Set row.
              if (l.setBubbles.isNotEmpty) {
                text('SET', SheetLayout.qr.left, 47.2, 6.5, bold, _muted);
                for (var i = 0; i < l.setBubbles.length; i++) {
                  bubble(l.setBubbles[i], SheetLayout.bubbleRx, SheetLayout.bubbleRy, letters[i], 5.5);
                }
              }
              text('Code ${header.examCode}', SheetLayout.qr.left, 60, 6.5, regular, _muted);
              text('${l.itemCount} items · A–E', SheetLayout.qr.left, 64, 6.5, regular, _muted);

              // Title block between the top markers, beside the logo if any.
              final tx = logo == null ? 14.0 : logoBox.left + logoBox.width + 2.5;
              final school = header.schoolName?.trim();
              if (school != null && school.isNotEmpty) {
                text(_fit(school.toUpperCase(), 70), tx, 3.6, 8, bold, _ink);
              } else {
                text('ANSWER SHEET', tx, 3.6, 6.5, bold, _muted);
              }
              text(_fit(header.examTitle, 60), tx, 8.8, 11, bold, _ink);
              final sub = [?header.subjectLine, ?header.dateText].join('  ·  ');
              if (sub.isNotEmpty) text(_fit(sub, 90), tx, 12.8, 7.5, regular, _muted);

              // Write-in fields (or printed details on personalized sheets).
              final fields = <(String, String?)>[
                ('Name', student?.name),
                ('Student no.', student?.studentNo),
                ('Course & section', student?.section),
                ('Date', null),
              ];
              for (var i = 0; i < fields.length; i++) {
                final fy = 21.0 + i * 7.5;
                text(fields[i].$1, 0, fy, 7.5, regular, _muted);
                final value = fields[i].$2;
                if (value != null) text(_fit(value, 42), 23, fy, 9, bold, _ink);
                canvas
                  ..setStrokeColor(_rule)
                  ..setLineWidth(0.25 * mm)
                  ..moveTo(x(22), y(fy + 0.9))
                  ..lineTo(x(90), y(fy + 0.9))
                  ..strokePath();
              }

              // Instructions.
              final lines = [
                'HOW TO MARK',
                'Use a dark No. 2 pencil or a black pen.',
                'Shade ONE oval completely for each item.',
                'Erase changes cleanly. Do not use check marks.',
                if (student == null)
                  'Shade your student number, starting at the left.'
                else
                  'Your name and number are printed above.',
                if (l.setBubbles.isNotEmpty) 'Shade your exam SET (A–${letters[l.setCount - 1]}).',
                'Do not fold or write on the black corner squares.',
              ];
              for (var i = 0; i < lines.length; i++) {
                text(lines[i], 0, 50.5 + i * 3.2, i == 0 ? 6.5 : 7, i == 0 ? bold : regular, i == 0 ? _muted : _ink);
              }

              // Shading examples, as on board-exam answer sheets. Kept left of
              // x 88 so they stay well clear of the student-number grid.
              const rx = SheetLayout.bubbleRx;
              const ry = SheetLayout.bubbleRy;
              void outline(double cx, double cy) => canvas
                ..setStrokeColor(_bubble)
                ..setLineWidth(0.3 * mm)
                ..drawEllipse(x(cx), y(cy), rx * mm, ry * mm)
                ..strokePath();
              void stroke(List<(double, double)> pts) {
                canvas
                  ..setStrokeColor(_ink)
                  ..setLineWidth(0.35 * mm)
                  ..moveTo(x(pts.first.$1), y(pts.first.$2));
                for (final (px, py) in pts.skip(1)) {
                  canvas.lineTo(x(px), y(py));
                }
                canvas.strokePath();
              }

              text('CORRECT', 64, 51, 5.5, bold, _muted);
              canvas
                ..setFillColor(_ink)
                ..drawEllipse(x(81), y(50.2), rx * mm, ry * mm)
                ..fillPath();
              text('WRONG', 64, 56.5, 5.5, bold, _muted);
              const wy = 60.5;
              const wx = [66.0, 73.0, 80.0, 87.0];
              for (final cx in wx) {
                outline(cx, wy);
              }
              stroke([(wx[0] - 1.2, wy), (wx[0] - 0.3, wy + 1.0), (wx[0] + 1.4, wy - 1.3)]); // check
              stroke([(wx[1] - 1.2, wy - 1.0), (wx[1] + 1.2, wy + 1.0)]); // cross
              stroke([(wx[1] - 1.2, wy + 1.0), (wx[1] + 1.2, wy - 1.0)]);
              canvas
                ..saveContext()
                ..drawRect(x(wx[2] - rx), y(wy + ry), rx * mm, 2 * ry * mm) // half shaded
                ..clipPath()
                ..setFillColor(_ink)
                ..drawEllipse(x(wx[2]), y(wy), rx * mm, ry * mm)
                ..fillPath()
                ..restoreContext()
                ..setFillColor(_ink)
                ..drawEllipse(x(wx[3]), y(wy), 0.6 * mm, 0.6 * mm) // dot
                ..fillPath();
              text('check', wx[0], wy + 4, 4.5, regular, _muted, center: true);
              text('cross', wx[1], wy + 4, 4.5, regular, _muted, center: true);
              text('half', wx[2], wy + 4, 4.5, regular, _muted, center: true);
              text('dot', wx[3], wy + 4, 4.5, regular, _muted, center: true);
              final footer = [
                if (header.instructorName case final name? when name.trim().isNotEmpty) 'Instructor: ${name.trim()}',
                'ACEkanner form ${l.templateId.toUpperCase()}',
              ].join('   ·   ');
              text(_fit(footer, 100), w / 2, h - 3, 6.5, regular, _muted, center: true);
            },
          ),
          if (logo != null)
            pw.Positioned(
              left: logoBox.left * mm,
              top: logoBox.top * mm,
              child: pw.SizedBox(
                width: logoBox.width * mm,
                height: logoBox.height * mm,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
            ),
          pw.Positioned(
            left: SheetLayout.qr.left * mm,
            top: SheetLayout.qr.top * mm,
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium),
              data: qr,
              width: SheetLayout.qr.width * mm,
              height: SheetLayout.qr.height * mm,
              drawText: false,
            ),
          ),
        ],
      ),
    );
  }

  static String _fit(String s, int max) => s.length <= max ? s : '${s.substring(0, max - 1)}…';
}
