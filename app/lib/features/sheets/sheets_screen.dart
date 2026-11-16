import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:printing/printing.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/exams_repository.dart';
import '../../data/repositories/students_repository.dart';
import '../../data/settings/settings_repository.dart';
import '../../domain/personal_sheet_code.dart';
import '../../domain/sheet_layout.dart';
import '../../services/answer_sheet_pdf.dart';

enum SheetKind { generic, personalized }

/// Preview, print and share answer sheets for an examination.
class SheetsScreen extends ConsumerStatefulWidget {
  const SheetsScreen({super.key, required this.examId});

  final String examId;

  @override
  ConsumerState<SheetsScreen> createState() => _SheetsScreenState();
}

class _SheetsScreenState extends ConsumerState<SheetsScreen> {
  PaperSize _paper = PaperSize.a4;
  SheetKind _kind = SheetKind.generic;
  int _copies = 1;
  final Set<String> _sectionIds = {};
  SheetFonts? _fonts;
  List<StudentRow> _students = const [];
  bool _showInstructor = true;
  bool _showLogo = true;
  String? _instructor;
  Uint8List? _logo;
  bool _brandingLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFonts();
    _loadBranding();
  }

  /// Instructor name, logo and the saved show/hide choices.
  Future<void> _loadBranding() async {
    final settings = ref.read(settingsRepositoryProvider);
    final profile = await ref.read(profileRepositoryProvider).get();
    final logo = await ref.read(brandingStoreProvider).read(profile?.logoPath);
    final showInstructor = await settings.getBool(SettingKeys.sheetsShowInstructor, defaultValue: true);
    final showLogo = await settings.getBool(SettingKeys.sheetsShowLogo, defaultValue: true);
    if (!mounted) return;
    setState(() {
      _instructor = profile == null ? null : [profile.honorific, profile.fullName].whereType<String>().join(' ');
      _logo = logo;
      _showInstructor = showInstructor;
      _showLogo = showLogo;
      _brandingLoaded = true;
    });
  }

  Future<void> _setShow(String key, bool value) async {
    setState(() => key == SettingKeys.sheetsShowLogo ? _showLogo = value : _showInstructor = value);
    try {
      await ref.read(settingsRepositoryProvider).setBool(key, value);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _openProfile() async {
    await context.push(Routes.profile);
    if (mounted) await _loadBranding();
  }

  Future<void> _loadFonts() async {
    final regular = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    if (mounted) setState(() => _fonts = SheetFonts(regular, bold));
  }

  Future<void> _loadStudents() async {
    final students = <String, StudentRow>{};
    for (final id in _sectionIds) {
      for (final s in await ref.read(studentsRepositoryProvider).watchRoster(id).first) {
        students[s.id] = s;
      }
    }
    final list = students.values.toList()
      ..sort((a, b) => studentDisplayName(a).toLowerCase().compareTo(studentDisplayName(b).toLowerCase()));
    if (mounted) setState(() => _students = list);
  }

  Future<Uint8List> _build(ExamDetail d) async {
    final profile = await ref.read(profileRepositoryProvider).get();
    final exam = d.exam;
    return AnswerSheetPdf.build(
      layout: SheetLayout(itemCount: exam.itemCount, idDigits: exam.studentIdDigits, setCount: d.versions.length),
      header: SheetHeader(
        examTitle: exam.title,
        examCode: exam.shortCode,
        subjectLine: d.subject == null ? null : '${d.subject!.code} — ${d.subject!.title}',
        dateText: exam.examDate == null ? null : DateFormat('d MMMM y').format(exam.examDate!),
        schoolName: profile?.schoolName,
        instructorName: _showInstructor ? _instructor : null,
        logo: _showLogo ? _logo : null,
      ),
      paper: _paper,
      fonts: _fonts!,
      copies: _copies,
      students: _kind == SheetKind.generic
          ? const []
          : [
              for (final s in _students)
                SheetStudent(
                  name: studentDisplayName(s),
                  studentNo: s.studentNo,
                  sheetCode: personalSheetCode(exam.id, s.id),
                ),
            ],
    );
  }

  Future<void> _record() async {
    final repo = ref.read(printedSheetsRepositoryProvider);
    try {
      if (_kind == SheetKind.generic) {
        await repo.recordGeneric(widget.examId, paper: _paper.code, copies: _copies);
      } else {
        await repo.recordPersonalized(widget.examId, paper: _paper.code, studentIds: [for (final s in _students) s.id]);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(examDetailProvider(widget.examId)).value;
    final theme = Theme.of(context);
    if (detail == null || _fonts == null || !_brandingLoaded) {
      return Scaffold(appBar: AppBar(title: const Text('Answer sheets')), body: const Center(child: CircularProgressIndicator()));
    }
    final canPersonalize = detail.sections.isNotEmpty;
    final ready = _kind == SheetKind.generic || _students.isNotEmpty;
    final key = ValueKey(
      '${_paper.code}-${_kind.name}-$_copies-${_students.length}-${_sectionIds.join(',')}'
      '-$_showInstructor-$_showLogo-${_logo?.length}-$_instructor',
    );
    final hasInstructor = _instructor != null && _instructor!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Answer sheets')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<PaperSize>(
                  segments: const [
                    ButtonSegment(value: PaperSize.a4, label: Text('A4')),
                    ButtonSegment(value: PaperSize.letter, label: Text('Letter')),
                    ButtonSegment(value: PaperSize.long, label: Text('8.5×13')),
                  ],
                  selected: {_paper},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _paper = s.first),
                ),
                const SizedBox(height: Space.s),
                SegmentedButton<SheetKind>(
                  segments: [
                    const ButtonSegment(value: SheetKind.generic, label: Text('Blank sheets')),
                    ButtonSegment(
                      value: SheetKind.personalized,
                      label: const Text('With names'),
                      enabled: canPersonalize,
                    ),
                  ],
                  selected: {_kind},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _kind = s.first),
                ),
                const SizedBox(height: Space.s),
                if (_kind == SheetKind.generic)
                  Row(
                    children: [
                      const Expanded(child: Text('Copies')),
                      IconButton(
                        tooltip: 'Fewer copies',
                        onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_copies', style: theme.textTheme.titleMedium),
                      IconButton(
                        tooltip: 'More copies',
                        onPressed: _copies < 100 ? () => setState(() => _copies++) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  )
                else
                  Wrap(
                    spacing: Space.s,
                    children: [
                      for (final s in detail.sections)
                        FilterChip(
                          label: Text(s.name),
                          selected: _sectionIds.contains(s.id),
                          onSelected: (on) {
                            setState(() => on ? _sectionIds.add(s.id) : _sectionIds.remove(s.id));
                            _loadStudents();
                          },
                        ),
                    ],
                  ),
                Wrap(
                  spacing: Space.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Instructor name'),
                      selected: hasInstructor && _showInstructor,
                      onSelected: hasInstructor ? (on) => _setShow(SettingKeys.sheetsShowInstructor, on) : null,
                    ),
                    FilterChip(
                      label: const Text('School logo'),
                      selected: _logo != null && _showLogo,
                      onSelected: _logo != null ? (on) => _setShow(SettingKeys.sheetsShowLogo, on) : null,
                    ),
                    if (_logo == null || !hasInstructor)
                      TextButton(
                        onPressed: _openProfile,
                        child: Text(_logo == null ? 'Add a logo' : 'Add your name'),
                      ),
                  ],
                ),
                Text(
                  _kind == SheetKind.generic
                      ? 'Blank sheets can be photocopied. Students shade their student number.'
                      : '${_students.length} personalized sheets. Each QR code identifies the student.',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Print at 100% (actual size). Printing or sharing locks the number of items and sets.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: ready
                ? PdfPreview(
                    key: key,
                    build: (_) => _build(detail),
                    allowPrinting: true,
                    allowSharing: true,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    pdfFileName: 'ACEkanner-${detail.exam.shortCode}-answer-sheets.pdf',
                    onPrinted: (_) => _record(),
                    onShared: (_) => _record(),
                  )
                : const Center(child: Text('Choose a section with students.')),
          ),
        ],
      ),
    );
  }
}
