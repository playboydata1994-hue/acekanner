import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/section_header.dart';
import '../../data/repositories/exams_repository.dart';
import '../../domain/student_number.dart';
import '../../domain/validators.dart';
import '../classes/class_forms.dart';
import 'class_list_upload.dart';

/// Create a new examination ([examId] null) or edit an existing one.
class ExamFormScreen extends ConsumerStatefulWidget {
  const ExamFormScreen({super.key, this.examId});

  final String? examId;

  @override
  ConsumerState<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends ConsumerState<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _passing = TextEditingController(text: '75');
  final _points = TextEditingController(text: '1');
  final _negative = TextEditingController(text: '0');

  bool _loading = true;
  bool _saving = false;
  bool _locked = false;
  String? _loadError;

  String? _subjectId;
  DateTime? _date;
  int _items = 50;
  int _sets = 1;
  Set<String> _sectionIds = {};
  String _multiplePolicy = MultipleMarkPolicy.incorrect;
  bool _allowNegativeTotal = false;
  int _idDigits = 10;
  String _format = '##########';

  bool get _editing => widget.examId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _format = await ref.read(profileRepositoryProvider).studentNoFormat();
      _idDigits = StudentNumber.digitsIn(_format);
      if (_editing) {
        final detail = await ref.read(examsRepositoryProvider).loadDetail(widget.examId!);
        if (detail == null) throw StateError('missing');
        final e = detail.exam;
        _title.text = e.title;
        _passing.text = _fmt(e.passingPercentage);
        _subjectId = e.subjectId;
        _date = e.examDate;
        _items = e.itemCount;
        _sets = detail.versions.length;
        _sectionIds = {for (final s in detail.sections) s.id};
        _multiplePolicy = e.multipleMarkPolicy;
        _allowNegativeTotal = e.allowNegativeTotal;
        _idDigits = e.studentIdDigits;
        _locked = detail.structureLocked;
      }
    } catch (_) {
      _loadError = 'This examination could not be opened.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_title, _passing, _points, _negative]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _newSubject() async {
    final id = await showSubjectForm(context);
    if (id != null) setState(() => _subjectId = id);
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final input = ExamInput(
      title: _title.text,
      subjectId: _subjectId,
      examDate: _date,
      itemCount: _items,
      versionCount: _sets,
      sectionIds: _sectionIds.toList(),
      passingPercentage: double.parse(_passing.text.trim()),
      pointsPerItem: double.parse(_points.text.trim()),
      negativePoints: double.parse(_negative.text.trim()),
      multipleMarkPolicy: _multiplePolicy,
      allowNegativeTotal: _allowNegativeTotal,
      studentIdDigits: _idDigits,
    );
    try {
      final repo = ref.read(examsRepositoryProvider);
      if (_editing) {
        await repo.update(widget.examId!, input);
        if (mounted) context.pop(true);
      } else {
        final id = await repo.create(input);
        if (mounted) context.go('/exams/$id');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = ref.watch(subjectsProvider).value ?? const [];
    final sections = ref.watch(sectionsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit examination' : 'New examination'),
        actions: [
          TextButton(
            onPressed: _loading || _saving || _loadError != null ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text(_loadError!))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xxl),
                    children: [
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(
                          labelText: 'Examination title',
                          hintText: 'e.g. Midterm Examination',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => Validators.required(v, 'examination title'),
                      ),
                      const SizedBox(height: Space.m),
                      DropdownButtonFormField<String?>(
                        initialValue: subjects.any((s) => s.id == _subjectId) ? _subjectId : null,
                        decoration: const InputDecoration(labelText: 'Subject'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          for (final s in subjects)
                            DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.code} — ${s.title}', overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) => setState(() => _subjectId = v),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _newSubject,
                          icon: const Icon(Icons.add),
                          label: const Text('New subject'),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Examination date (optional)'),
                        subtitle: Text(_date == null ? 'Not set · tap to choose' : DateFormat('EEEE, d MMMM y').format(_date!)),
                        onTap: _pickDate,
                        trailing: _date == null
                            ? null
                            : IconButton(
                                tooltip: 'Clear date',
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _date = null),
                              ),
                      ),
                      const SectionHeader('Answer sheet'),
                      if (_locked)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Space.m),
                          child: Text(
                            'Sheets for this examination were already printed or scanned, '
                            'so the number of items and sets can no longer change.',
                            style: TextStyle(color: context.statusColors.uncertain),
                          ),
                        ),
                      Text('Number of items (choices A–E)', style: theme.textTheme.labelLarge),
                      const SizedBox(height: Space.s),
                      SegmentedButton<int>(
                        segments: [
                          for (final n in AppConstants.itemCounts)
                            ButtonSegment(value: n, label: Text('$n')),
                        ],
                        selected: {_items},
                        showSelectedIcon: false,
                        onSelectionChanged: _locked ? null : (s) => setState(() => _items = s.first),
                      ),
                      const SizedBox(height: Space.l),
                      Text('Exam sets (shuffled versions)', style: theme.textTheme.labelLarge),
                      const SizedBox(height: Space.s),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('A')),
                          ButtonSegment(value: 2, label: Text('A–B')),
                          ButtonSegment(value: 3, label: Text('A–C')),
                          ButtonSegment(value: 4, label: Text('A–D')),
                        ],
                        selected: {_sets},
                        showSelectedIcon: false,
                        onSelectionChanged: _locked ? null : (s) => setState(() => _sets = s.first),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        'Each set has its own answer key. Students shade their set on the sheet.',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: Space.l),
                      DropdownButtonFormField<int>(
                        initialValue: _idDigits,
                        decoration: InputDecoration(
                          labelText: 'Student-number digits on the sheet',
                          helperText: 'Your school format: $_format (${StudentNumber.digitsIn(_format)} digits)',
                        ),
                        items: [
                          for (var d = 4; d <= 12; d++) DropdownMenuItem(value: d, child: Text('$d digits')),
                        ],
                        onChanged: _locked ? null : (v) => setState(() => _idDigits = v ?? _idDigits),
                      ),
                      const SectionHeader('Sections taking this examination'),
                      if (sections.isEmpty)
                        Text(
                          'No sections yet. Upload a class list below, or add sections under Classes.',
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        Wrap(
                          spacing: Space.s,
                          runSpacing: Space.s,
                          children: [
                            for (final s in sections)
                              FilterChip(
                                label: Text(s.section.name),
                                selected: _sectionIds.contains(s.section.id),
                                onSelected: (on) => setState(() {
                                  on ? _sectionIds.add(s.section.id) : _sectionIds.remove(s.section.id);
                                }),
                              ),
                          ],
                        ),
                      const SizedBox(height: Space.m),
                      ClassListUploadBox(
                        onImported: (sectionId, message) {
                          setState(() => _sectionIds.add(sectionId));
                          showMessage(context, message);
                        },
                      ),
                      const SectionHeader('Scoring'),
                      TextFormField(
                        controller: _passing,
                        decoration: const InputDecoration(labelText: 'Passing percentage', suffixText: '%'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => Validators.number(v, min: 0, max: 100, label: 'the passing percentage'),
                      ),
                      if (!_editing) ...[
                        const SizedBox(height: Space.m),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _points,
                                decoration: const InputDecoration(labelText: 'Points per item'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) => Validators.number(v, min: 0, max: 100, label: 'the points'),
                              ),
                            ),
                            const SizedBox(width: Space.m),
                            Expanded(
                              child: TextFormField(
                                controller: _negative,
                                decoration: const InputDecoration(labelText: 'Deduction per wrong'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) => Validators.number(v, min: 0, max: 100, label: 'the deduction'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          'Use 0 for no negative marking. Points can be changed per item in the answer key.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: Space.m),
                      DropdownButtonFormField<String>(
                        initialValue: _multiplePolicy,
                        decoration: const InputDecoration(labelText: 'Two or more shaded answers'),
                        items: const [
                          DropdownMenuItem(
                            value: MultipleMarkPolicy.incorrect,
                            child: Text('Count as a wrong answer'),
                          ),
                          DropdownMenuItem(
                            value: MultipleMarkPolicy.zero,
                            child: Text('Score zero (no deduction)'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _multiplePolicy = v ?? _multiplePolicy),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Allow totals below zero'),
                        subtitle: const Text('Only matters when deductions are used'),
                        value: _allowNegativeTotal,
                        onChanged: (v) => setState(() => _allowNegativeTotal = v),
                      ),
                      const SizedBox(height: Space.l),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: Text(_editing ? 'Save changes' : 'Create examination'),
                      ),
                    ],
                  ),
                ),
    );
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
