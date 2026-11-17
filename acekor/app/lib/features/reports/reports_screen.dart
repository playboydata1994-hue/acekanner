import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../app/data_providers.dart';
import '../../app/licensing_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/roster_repository.dart';
import '../../data/repositories/scores_repository.dart';
import '../../domain/categories.dart';
import '../../services/files.dart';
import '../../services/reports/pdf_reports.dart';
import '../../services/reports/report_model.dart';
import '../../services/reports/xlsx_reports.dart';

final _fontsProvider = FutureProvider<(pw.Font, pw.Font)>((ref) async {
  final r = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final b = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
  return (pw.Font.ttf(r), pw.Font.ttf(b));
});

/// PDF and Excel reports, generated on the phone (works offline).
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportType _type = ReportType.gradeSummary;
  String? _subjectId;
  String? _sectionId;
  String? _studentId;
  Period _period = Period.none;
  Set<String>? _activityIds;
  final _title = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _subjectId = ref.read(appSettingsProvider).currentSubject;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String get _effectiveTitle => _title.text.trim().isEmpty ? _type.title : _title.text.trim();

  Future<ReportHeader> _header({String? subject, String? section}) async {
    final p = await ref.read(rosterRepositoryProvider).profile();
    final s = ref.read(appSettingsProvider);
    final subj = _subjectId == null ? null : await ref.read(subjectsRepositoryProvider).subject(_subjectId!);
    return ReportHeader(
      title: _effectiveTitle,
      generated: DateTime.now(),
      schoolName: p.schoolName,
      schoolAddress: p.schoolAddress,
      department: p.department,
      instructor: p.instructorName,
      extraLine: s.reportHeaderLine,
      footerLine: s.reportFooterLine,
      subject: subject,
      section: section,
      academicYear: (subj?.academicYear.isNotEmpty ?? false) ? subj!.academicYear : s.academicYear,
      semester: (subj?.semester.isNotEmpty ?? false) ? subj!.semester : s.semester,
      period: _period == Period.none ? null : _period.label,
    );
  }

  Future<String?> _sectionLabel() async {
    if (_sectionId == null) return _type.allSubjects ? null : 'All sections';
    final sections = await ref.read(rosterRepositoryProvider).sections();
    final s = sections.where((x) => x.id == _sectionId).firstOrNull;
    if (s == null) return null;
    return [if (s.section.program.isNotEmpty) s.section.program, s.name].join(' ');
  }

  /// Generates the file; returns (bytes, file name, mime).
  Future<(List<int>, String, String)?> _generate({required bool excel}) async {
    if (_type.max && !ref.read(planStatusProvider).hasMax) {
      showMessage(context, 'Examination reports are part of MAX.', error: true);
      return null;
    }
    final service = ref.read(gradebookServiceProvider);
    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final section = await _sectionLabel();

    if (_type.allSubjects) {
      final subjects = await ref.read(subjectsRepositoryProvider).subjects();
      final books = <Gradebook>[];
      for (final s in subjects) {
        final b = await service.build(s.id, sectionId: _sectionId, period: _period);
        if (b != null && b.students.isNotEmpty) books.add(b);
      }
      final students = await ref.read(rosterRepositoryProvider).students(sectionId: _sectionId);
      final enrolledSomewhere = {for (final b in books) ...b.students.map((s) => s.id)};
      final list = students.where((s) => enrolledSomewhere.contains(s.id)).toList();
      final header = await _header(section: section);
      final name = safeFileName('$_effectiveTitle $stamp');
      if (excel) return (const XlsxReports().overallWorkbook(books, list, header), '$name.xlsx', Mime.xlsx);
      final (r, b) = await ref.read(_fontsProvider.future);
      final bytes = await PdfReports(
        regular: r,
        bold: b,
      ).build(type: _type, header: header, books: books, overallStudents: list);
      return (bytes, '$name.pdf', Mime.pdf);
    }

    if (!mounted) return null;
    if (_subjectId == null) {
      showMessage(context, 'Choose a subject.', error: true);
      return null;
    }
    if (_type.needsStudent && _studentId == null) {
      showMessage(context, 'Choose a student.', error: true);
      return null;
    }
    final book = await service.build(
      _subjectId!,
      sectionId: _sectionId,
      period: _period,
      activityIds: _activityIds,
      studentIds: _type.needsStudent ? {_studentId!} : null,
    );
    if (book == null) return null;
    final subjectLabel = book.subject.title.isEmpty
        ? book.subject.code
        : '${book.subject.code} – ${book.subject.title}';
    final header = await _header(subject: subjectLabel, section: section);
    final who = _type.needsStudent && book.students.isNotEmpty ? ' ${book.students.first.row.lastName}' : '';
    final name = safeFileName('${book.subject.code} $_effectiveTitle$who $stamp');
    if (excel) return (const XlsxReports().subjectWorkbook(book, header), '$name.xlsx', Mime.xlsx);
    final (r, b) = await ref.read(_fontsProvider.future);
    final bytes = await PdfReports(regular: r, bold: b).build(
      type: _type,
      header: header,
      books: [book],
      student: _type.needsStudent && book.students.isNotEmpty ? book.students.first : null,
    );
    return (bytes, '$name.pdf', Mime.pdf);
  }

  Future<void> _run({required bool excel, required String action}) async {
    setState(() => _busy = true);
    try {
      final out = await _generate(excel: excel);
      if (out == null || !mounted) return;
      final (bytes, name, mime) = out;
      switch (action) {
        case 'print':
          await Printing.layoutPdf(onLayout: (_) async => Uint8List.fromList(bytes), name: name);
        case 'share':
          await shareFile(bytes, name, mimeType: mime, subject: name);
        case 'save':
          if (await saveFileAs(bytes, name, mimeType: mime) && mounted) showMessage(context, 'Saved $name');
      }
    } catch (e) {
      if (mounted) showMessage(context, 'The report could not be created ($e).', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickActivities(List<ActivityView> all) async {
    final chosen = {...(_activityIds ?? all.map((a) => a.id))};
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Activities'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final a in all)
                  CheckboxListTile(
                    value: chosen.contains(a.id),
                    title: Text(a.label),
                    subtitle: Text(
                      '${a.maxPoints} points${a.row.activityDate == null ? '' : ' · ${a.row.activityDate}'}',
                    ),
                    onChanged: (v) => setState(() => v! ? chosen.add(a.id) : chosen.remove(a.id)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
          ],
        ),
      ),
    );
    if (ok == true) setState(() => _activityIds = chosen.length == all.length ? null : chosen);
  }

  @override
  Widget build(BuildContext context) {
    final hasMax = ref.watch(planStatusProvider).hasMax;
    final subjects = ref.watch(subjectsProvider).value ?? const [];
    final sections = ref.watch(sectionsProvider).value ?? const [];
    final students = _subjectId == null
        ? const <StudentView>[]
        : (ref.watch(enrolledProvider(_subjectId!)).value ?? const <StudentView>[])
              .where((s) => _sectionId == null || s.row.sectionId == _sectionId)
              .toList();
    final activities = _subjectId == null
        ? const <ActivityView>[]
        : (ref.watch(activitiesProvider(_subjectId!)).value ?? const <ActivityView>[]);
    final locked = _type.max && !hasMax;
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionTitle('Report'),
          RadioGroup<ReportType>(
            groupValue: _type,
            onChanged: (v) => setState(() {
              _type = v!;
              _title.clear();
            }),
            child: Column(
              children: [
                for (final t in ReportType.values)
                  RadioListTile<ReportType>(
                    value: t,
                    title: Text(t.title),
                    secondary: t.max && !hasMax ? const Icon(Icons.lock_outline, color: AppColors.muted) : null,
                    subtitle: t.max ? const Text('MAX') : null,
                  ),
              ],
            ),
          ),
          const SectionTitle('Choose'),
          if (!_type.allSubjects)
            DropdownField<String?>(
              label: 'Subject',
              value: subjects.any((s) => s.id == _subjectId) ? _subjectId : null,
              items: [for (final s in subjects) DropdownMenuItem(value: s.id, child: Text(s.label))],
              onChanged: (v) => setState(() {
                _subjectId = v;
                _studentId = null;
                _activityIds = null;
              }),
            ),
          DropdownField<String?>(
            label: 'Course and section',
            value: sections.any((s) => s.id == _sectionId) ? _sectionId : null,
            items: [
              const DropdownMenuItem(value: null, child: Text('Entire class (all sections)')),
              for (final s in sections) DropdownMenuItem(value: s.id, child: Text(s.name)),
            ],
            onChanged: (v) => setState(() {
              _sectionId = v;
              _studentId = null;
            }),
          ),
          if (_type.needsStudent)
            DropdownField<String?>(
              label: 'Student',
              value: students.any((s) => s.id == _studentId) ? _studentId : null,
              items: [for (final s in students) DropdownMenuItem(value: s.id, child: Text(s.formal))],
              onChanged: (v) => setState(() => _studentId = v),
            ),
          DropdownField<Period>(
            label: 'Grading period',
            value: _period,
            items: [
              for (final p in Period.values)
                DropdownMenuItem(value: p, child: Text(p == Period.none ? 'Whole semester (all activities)' : p.label)),
            ],
            onChanged: (v) => setState(() => _period = v ?? Period.none),
          ),
          if (!_type.allSubjects && activities.isNotEmpty)
            ListTile(
              title: const Text('Activities'),
              subtitle: Text(_activityIds == null ? 'All ${activities.length}' : '${_activityIds!.length} selected'),
              trailing: const Icon(Icons.checklist),
              onTap: () => _pickActivities(activities),
            ),
          Field(
            controller: _title,
            label: 'Report heading (default: ${_type.title})',
            textCapitalization: TextCapitalization.sentences,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextButton(
              onPressed: () => context.push(Routes.profile),
              child: const Text('School, instructor and heading lines…'),
            ),
          ),
          if (locked)
            ListTile(
              leading: const Icon(Icons.lock_outline, color: AppColors.amber),
              title: const Text('Examination reports are part of MAX'),
              onTap: () => context.push(Routes.plan),
            ),
          const SectionTitle('PDF'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _busy || locked ? null : () => _run(excel: false, action: 'print'),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Preview / print'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || locked ? null : () => _run(excel: false, action: 'share'),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || locked ? null : () => _run(excel: false, action: 'save'),
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),
          const SectionTitle('Excel (.xlsx)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _busy || locked ? null : () => _run(excel: true, action: 'share'),
                  icon: const Icon(Icons.share),
                  label: const Text('Share workbook'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || locked ? null : () => _run(excel: true, action: 'save'),
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save workbook'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              'The Excel workbook has Roster, Quizzes, Recitations, Examinations, Practical, Summary and Weighted Grade sheets, '
              'with formulas for totals, percentages and weighted grades.',
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
