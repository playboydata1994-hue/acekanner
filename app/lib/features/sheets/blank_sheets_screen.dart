import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:printing/printing.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/theme/spacing.dart';
import '../../domain/sheet_layout.dart';
import '../../domain/sheet_qr.dart';
import '../../domain/student_number.dart';
import '../../services/answer_sheet_pdf.dart';
import '../exams/exam_widgets.dart' show setsLabel;

/// Choices for blank answer sheets (printed without an examination).
class BlankSheetOptions {
  const BlankSheetOptions({
    this.itemCount = 50,
    this.setCount = 1,
    this.title = '',
    this.paper = PaperSize.a4,
    this.copies = 1,
  });

  final int itemCount;
  final int setCount;

  /// Heading printed on the sheet, e.g. "Mock Board Exam – Physics".
  final String title;
  final PaperSize paper;
  final int copies;

  BlankSheetOptions copyWith({int? itemCount, int? setCount, String? title, PaperSize? paper, int? copies}) =>
      BlankSheetOptions(
        itemCount: itemCount ?? this.itemCount,
        setCount: setCount ?? this.setCount,
        title: title ?? this.title,
        paper: paper ?? this.paper,
        copies: copies ?? this.copies,
      );
}

/// Sheet layout and header of blank sheets: the profile's school, instructor
/// and logo, the reserved "any examination" code, the profile's
/// student-number length.
(SheetLayout, SheetHeader) blankSheetSpec(
  BlankSheetOptions o, {
  required int idDigits,
  String? schoolName,
  String? instructorName,
  Uint8List? logo,
}) =>
    (
      SheetLayout(itemCount: o.itemCount, idDigits: idDigits, setCount: o.setCount),
      SheetHeader(
        examTitle: o.title.trim().isEmpty ? 'Answer Sheet' : o.title.trim(),
        examCode: SheetQr.blankExamCode,
        schoolName: schoolName,
        instructorName: instructorName,
        logo: logo,
      ),
    );

/// Print or share answer sheets that are not tied to an examination, for
/// pre-examinations and mock examinations. They are checked later with any
/// examination that scans them.
class BlankSheetsScreen extends ConsumerStatefulWidget {
  const BlankSheetsScreen({super.key});

  @override
  ConsumerState<BlankSheetsScreen> createState() => _BlankSheetsScreenState();
}

class _BlankSheetsScreenState extends ConsumerState<BlankSheetsScreen> {
  BlankSheetOptions _o = const BlankSheetOptions();
  final _title = TextEditingController();
  SheetFonts? _fonts;
  int _idDigits = 10;
  String? _school;
  String? _instructor;
  Uint8List? _logo;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final profiles = ref.read(profileRepositoryProvider);
    final profile = await profiles.get();
    final format = await profiles.studentNoFormat();
    final logo = await ref.read(brandingStoreProvider).read(profile?.logoPath);
    if (!mounted) return;
    setState(() {
      _fonts = SheetFonts(regular, bold);
      _idDigits = StudentNumber.digitsIn(format);
      _school = profile?.schoolName;
      _instructor = profile?.fullName == null ? null : [?profile!.honorific, profile.fullName!].join(' ');
      _logo = logo;
      _loaded = true;
    });
  }

  Future<Uint8List> _build() {
    final (layout, header) = blankSheetSpec(
      _o,
      idDigits: _idDigits,
      schoolName: _school,
      instructorName: _instructor,
      logo: _logo,
    );
    return AnswerSheetPdf.build(layout: layout, header: header, paper: _o.paper, fonts: _fonts!, copies: _o.copies);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Blank answer sheets')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Flexible(
                  flex: 0,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'For pre-examinations and mock examinations. These sheets are not tied to an '
                          'examination: scan them inside any examination with enough questions, or with '
                          'Scan on Home (you choose the examination).',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: Space.m),
                        TextField(
                          controller: _title,
                          maxLength: 60,
                          decoration: const InputDecoration(
                            labelText: 'Title line (optional)',
                            hintText: 'e.g. Mock Board Exam – Physics',
                            counterText: '',
                          ),
                          onSubmitted: (v) => setState(() => _o = _o.copyWith(title: v)),
                          onTapOutside: (_) {
                            FocusScope.of(context).unfocus();
                            if (_title.text != _o.title) setState(() => _o = _o.copyWith(title: _title.text));
                          },
                        ),
                        const SizedBox(height: Space.m),
                        Text('Questions', style: theme.textTheme.labelLarge),
                        const SizedBox(height: Space.xs),
                        SegmentedButton<int>(
                          segments: [
                            for (final n in AppConstants.itemCounts) ButtonSegment(value: n, label: Text('$n')),
                          ],
                          selected: {_o.itemCount},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => setState(() => _o = _o.copyWith(itemCount: s.first)),
                        ),
                        const SizedBox(height: Space.m),
                        Text('Exam sets', style: theme.textTheme.labelLarge),
                        const SizedBox(height: Space.xs),
                        SegmentedButton<int>(
                          segments: [
                            for (var n = 1; n <= 5; n++)
                              ButtonSegment(value: n, label: Text(n == 1 ? 'A' : setsLabel(n).replaceFirst('Sets ', ''))),
                          ],
                          selected: {_o.setCount},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => setState(() => _o = _o.copyWith(setCount: s.first)),
                        ),
                        const SizedBox(height: Space.m),
                        SegmentedButton<PaperSize>(
                          segments: const [
                            ButtonSegment(value: PaperSize.a4, label: Text('A4')),
                            ButtonSegment(value: PaperSize.letter, label: Text('Letter')),
                            ButtonSegment(value: PaperSize.long, label: Text('8.5×13')),
                          ],
                          selected: {_o.paper},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => setState(() => _o = _o.copyWith(paper: s.first)),
                        ),
                        Row(
                          children: [
                            const Expanded(child: Text('Copies')),
                            IconButton(
                              tooltip: 'Fewer copies',
                              onPressed: _o.copies > 1 ? () => setState(() => _o = _o.copyWith(copies: _o.copies - 1)) : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Text('${_o.copies}', style: theme.textTheme.titleMedium),
                            IconButton(
                              tooltip: 'More copies',
                              onPressed:
                                  _o.copies < 100 ? () => setState(() => _o = _o.copyWith(copies: _o.copies + 1)) : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        Text(
                          [
                            'School, logo and instructor come from your profile.',
                            'Student number: $_idDigits digits.',
                            'Print at 100% (actual size).',
                          ].join(' '),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PdfPreview(
                    key: ValueKey((_o.itemCount, _o.setCount, _o.title, _o.paper, _o.copies)),
                    build: (_) => _build(),
                    allowPrinting: true,
                    allowSharing: true,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    pdfFileName: 'ACEkanner-blank-answer-sheets-${_o.itemCount}.pdf',
                  ),
                ),
              ],
            ),
    );
  }
}
