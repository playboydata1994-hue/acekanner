import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:acekanner/app/data_providers.dart';
import 'package:acekanner/core/theme/app_theme.dart';
import 'package:acekanner/data/audit/audit_logger.dart';
import 'package:acekanner/data/repositories/exams_repository.dart';
import 'package:acekanner/domain/sheet_qr.dart';
import 'package:acekanner/features/scanner/exam_picker.dart';
import 'package:acekanner/features/sheets/blank_sheets_screen.dart';
import 'package:acekanner/services/answer_sheet_pdf.dart';

import '../../support/test_db.dart';

void main() {
  test('blank sheets: chosen size and sets, profile header, "any examination" code', () async {
    final (layout, header) = blankSheetSpec(
      const BlankSheetOptions(itemCount: 75, setCount: 3, title: '  Mock Board Exam – Physics '),
      idDigits: 9,
      schoolName: 'State University',
      instructorName: 'Prof. Reyes',
    );
    expect((layout.itemCount, layout.setCount, layout.idDigits), (75, 3, 9));
    expect(header.examTitle, 'Mock Board Exam – Physics');
    expect(header.examCode, SheetQr.blankExamCode);
    expect((header.schoolName, header.instructorName), ('State University', 'Prof. Reyes'));
    expect(blankSheetSpec(const BlankSheetOptions(), idDigits: 10).$2.examTitle, 'Answer Sheet');

    final fonts = SheetFonts(
      ByteData.sublistView(File('assets/fonts/Roboto-Regular.ttf').readAsBytesSync()),
      ByteData.sublistView(File('assets/fonts/Roboto-Bold.ttf').readAsBytesSync()),
    );
    final pdf = await AnswerSheetPdf.build(layout: layout, header: header, paper: PaperSize.long, fonts: fonts, copies: 4);
    expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
    expect(RegExp(r'/Type\s*/Page\b').allMatches(String.fromCharCodes(pdf)).length, 4);
  });

  test('the blank-sheet code marks a sheet as blank and keeps the QR format', () {
    const qr = SheetQr(examCode: SheetQr.blankExamCode, itemCount: 100, idDigits: 10, setCount: 2);
    expect(qr.blank, isTrue);
    expect(qr.encode(), 'ACK3|ANYEXAM0|100|10|2|G');
    expect(SheetQr.tryParse(qr.encode())!.blank, isTrue);
    expect(const SheetQr(examCode: 'K7M2Q9XA', itemCount: 50, idDigits: 10, setCount: 1).blank, isFalse);
  });

  testWidgets('picking the examination for a blank sheet: too-big examinations cannot be chosen', (tester) async {
    final db = openTestDatabase();
    final exams = ExamsRepository(db, AuditLogger(db));
    final small = await tester.runAsync(() => exams.create(const ExamInput(title: 'Quiz 50', itemCount: 50)));
    await tester.runAsync(() => exams.create(const ExamInput(title: 'Finals 100', itemCount: 100)));
    final list = (await tester.runAsync(() => exams.watchActive().first))!;
    String? picked;
    await tester.pumpWidget(ProviderScope(
      overrides: [activeExamsProvider.overrideWith((ref) => Stream.value(list))],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async => picked = await pickExamination(context, sheetItems: 75),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Which examination?'), findsOneWidget);
    expect(find.text('100 questions: needs a bigger sheet'), findsOneWidget);
    await tester.tap(find.text('Finals 100'));
    await tester.pumpAndSettle();
    expect(find.text('Which examination?'), findsOneWidget, reason: 'disabled');
    await tester.tap(find.text('Quiz 50'));
    await tester.pumpAndSettle();
    expect(picked, small);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });
}
