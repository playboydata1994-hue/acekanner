import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/errors.dart';
import '../../data/repositories/roster_repository.dart';
import 'section_dialog.dart';

/// Add or edit a student. Editing never touches their scores.
class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, this.studentId, this.sectionId});
  final String? studentId;
  final String? sectionId;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _no = TextEditingController();
  final _last = TextEditingController();
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _suffix = TextEditingController();
  final _program = TextEditingController();
  final _ay = TextEditingController();
  final _sem = TextEditingController();
  int? _year;
  String? _sectionId;
  final Set<String> _subjects = {};
  bool _loaded = false;
  bool _saving = false;

  bool get _editing => widget.studentId != null;

  @override
  void initState() {
    super.initState();
    _sectionId = widget.sectionId;
    _load();
  }

  Future<void> _load() async {
    final settings = ref.read(appSettingsProvider);
    if (_editing) {
      final s = await ref.read(rosterRepositoryProvider).student(widget.studentId!);
      if (s != null) {
        final r = s.row;
        _no.text = r.studentNo ?? '';
        _last.text = r.lastName;
        _first.text = r.firstName;
        _middle.text = r.middleName;
        _suffix.text = r.suffix;
        _program.text = r.program;
        _ay.text = r.academicYear;
        _sem.text = r.semester;
        _year = r.yearLevel;
        _sectionId = r.sectionId;
      }
    } else {
      _ay.text = settings.academicYear;
      _sem.text = settings.semester;
      final calcSubject = settings.currentSubject;
      if (calcSubject != null) _subjects.add(calcSubject);
      if (_sectionId != null) {
        final sections = await ref.read(rosterRepositoryProvider).sections();
        final sec = sections.where((s) => s.id == _sectionId).firstOrNull?.section;
        if (sec != null) {
          _program.text = sec.program;
          _year = sec.yearLevel;
        }
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    for (final c in [_no, _last, _first, _middle, _suffix, _program, _ay, _sem]) {
      c.dispose();
    }
    super.dispose();
  }

  StudentInput get _input => StudentInput(
    studentNo: _no.text,
    firstName: _first.text,
    middleName: _middle.text,
    lastName: _last.text,
    suffix: _suffix.text,
    program: _program.text,
    yearLevel: _year,
    sectionId: _sectionId,
    academicYear: _ay.text,
    semester: _sem.text,
  );

  Future<void> _save({bool addAnother = false}) async {
    final problems = _input.problems();
    if (problems.isNotEmpty) {
      showMessage(context, problems.first, error: true);
      return;
    }
    setState(() => _saving = true);
    final roster = ref.read(rosterRepositoryProvider);
    try {
      if (_editing) {
        await roster.updateStudent(widget.studentId!, _input);
        if (mounted) context.pop();
      } else {
        await roster.addStudent(_input, subjectIds: _subjects.toList());
        if (!mounted) return;
        if (addAnother) {
          showMessage(context, 'Added ${_first.text} ${_last.text}.');
          for (final c in [_no, _last, _first, _middle, _suffix]) {
            c.clear();
          }
        } else {
          context.pop();
        }
      }
    } on DataError catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(sectionsProvider).value ?? const [];
    final subjects = ref.watch(subjectsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit student' : 'Add student')),
      bottomNavigationBar: BottomAction(label: 'Save', onPressed: _saving || !_loaded ? null : _save),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Field(
                  controller: _no,
                  label: 'Student ID (optional)',
                  textCapitalization: TextCapitalization.characters,
                ),
                Field(controller: _last, label: 'Last name', autofocus: !_editing),
                Field(controller: _first, label: 'First name'),
                Field(controller: _middle, label: 'Middle name (optional)'),
                Field(controller: _suffix, label: 'Suffix (Jr., III — optional)'),
                const SectionTitle('Class'),
                DropdownField<String?>(
                  label: 'Section',
                  value: _sectionId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No section')),
                    for (final s in sections) DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) => setState(() => _sectionId = v),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final id = await showSectionDialog(context, ref);
                        if (id != null) setState(() => _sectionId = id);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New section'),
                    ),
                  ),
                ),
                Field(
                  controller: _program,
                  label: 'Course / program (e.g. BSIT)',
                  textCapitalization: TextCapitalization.characters,
                ),
                DropdownField<int?>(
                  label: 'Year level',
                  value: _year,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('—')),
                    for (var y = 1; y <= 6; y++) DropdownMenuItem(value: y, child: Text('Year $y')),
                  ],
                  onChanged: (v) => setState(() => _year = v),
                ),
                Field(controller: _ay, label: 'Academic year (e.g. 2026-2027)'),
                Field(controller: _sem, label: 'Semester (e.g. 1st Semester)'),
                if (!_editing && subjects.isNotEmpty) ...[
                  const SectionTitle('Enrol in subjects'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in subjects)
                          FilterChip(
                            label: Text(s.subject.code, style: const TextStyle(fontSize: 16)),
                            selected: _subjects.contains(s.id),
                            onSelected: (v) => setState(() => v ? _subjects.add(s.id) : _subjects.remove(s.id)),
                          ),
                      ],
                    ),
                  ),
                ],
                if (!_editing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _save(addAnother: true),
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Save and add another'),
                    ),
                  ),
              ],
            ),
    );
  }
}
