import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../domain/roster_csv.dart';
import '../../domain/student_number.dart';
import '../../domain/validators.dart';
import '../exams/class_list_upload.dart' show importClassList;

/// Type several students at once, one row each (Student No, Last name, First
/// name, Middle name). With [sectionId] the students join that section;
/// without it the instructor names a section (new, or an existing one with
/// the same name). Pops with the section's ID and a summary.
class TypeStudentsScreen extends ConsumerStatefulWidget {
  const TypeStudentsScreen({super.key, this.sectionId, this.sectionName});

  final String? sectionId;
  final String? sectionName;

  @override
  ConsumerState<TypeStudentsScreen> createState() => _TypeStudentsScreenState();
}

class _Row {
  final number = TextEditingController();
  final last = TextEditingController();
  final first = TextEditingController();
  final middle = TextEditingController();
  final focus = FocusNode();

  List<TextEditingController> get fields => [number, last, first, middle];
  bool get isBlank => fields.every((c) => c.text.trim().isEmpty);

  void dispose() {
    for (final c in fields) {
      c.dispose();
    }
    focus.dispose();
  }
}

class _TypeStudentsScreenState extends ConsumerState<TypeStudentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _section = TextEditingController();
  final List<_Row> _rows = [_Row(), _Row(), _Row()];
  bool _saving = false;

  @override
  void dispose() {
    _section.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  List<_Row> get _filled => _rows.where((r) => !r.isBlank).toList();

  void _addRow() {
    final row = _Row();
    setState(() => _rows.add(row));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) row.focus.requestFocus();
    });
  }

  void _removeRow(int i) {
    final row = _rows.removeAt(i);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
  }

  /// Error for a row's student number: format, or the same number as an
  /// earlier row.
  String? _numberError(int i) {
    final row = _rows[i];
    if (row.isBlank) return null;
    final error = StudentNumber.validate(row.number.text.trim());
    if (error != null) return error;
    final key = StudentNumber.normalize(row.number.text.trim());
    for (var j = 0; j < i; j++) {
      if (!_rows[j].isBlank && StudentNumber.normalize(_rows[j].number.text.trim()) == key) {
        return 'Same number as student ${j + 1}';
      }
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    final filled = _filled;
    if (filled.isEmpty) {
      showMessage(context, 'Type at least one student.');
      return;
    }
    // Mistakes are shown in red under the fields.
    if (!_formKey.currentState!.validate()) return;
    final rows = [
      for (final (i, r) in _rows.indexed)
        if (!r.isBlank)
          RosterRow(
            line: i + 1,
            studentNo: r.number.text.trim(),
            lastName: r.last.text.trim(),
            firstName: r.first.text.trim(),
            middleName: r.middle.text.trim().isEmpty ? null : r.middle.text.trim(),
          ),
    ];
    setState(() => _saving = true);
    try {
      final classes = ref.read(classesRepositoryProvider);
      final students = ref.read(studentsRepositoryProvider);
      final (String, String) result;
      if (widget.sectionId == null) {
        result = await importClassList(classes, students, _section.text, rows);
      } else {
        final s = await students.importRoster(widget.sectionId!, rows);
        result = (
          widget.sectionId!,
          '${s.total} ${s.total == 1 ? 'student' : 'students'} saved '
              '(${s.added} new, ${s.total - s.added} already saved).',
        );
      }
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _leave() async {
    if (_filled.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final ok = await confirmAction(
      context,
      title: 'Discard the students you typed?',
      message: 'They have not been saved.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _filled.length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.sectionName == null ? 'Type the students' : 'Add to ${widget.sectionName}'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xxl),
            children: [
              if (widget.sectionId == null) ...[
                TextFormField(
                  controller: _section,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Section name',
                    hintText: 'e.g. BSIT 2-A',
                    helperText: 'The students are saved in this section and selected for the examination.',
                    helperMaxLines: 2,
                  ),
                  validator: (v) => Validators.required(v, 'section name', max: 60),
                ),
                const SizedBox(height: Space.l),
              ],
              Text(
                'One student per box. Middle name is optional. Empty boxes are ignored.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: Space.s),
              for (var i = 0; i < _rows.length; i++)
                _StudentRowCard(
                  key: ObjectKey(_rows[i]),
                  index: i,
                  row: _rows[i],
                  numberError: () => _numberError(i),
                  onChanged: () => setState(() {}),
                  onRemove: _rows.length > 1 ? () => _removeRow(i) : null,
                ),
              const SizedBox(height: Space.s),
              OutlinedButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Add another student'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.s),
            child: FilledButton(
              onPressed: _saving || count == 0 ? null : _save,
              child: Text(count == 0 ? 'Save students' : 'Save $count ${count == 1 ? 'student' : 'students'}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentRowCard extends StatelessWidget {
  const _StudentRowCard({
    super.key,
    required this.index,
    required this.row,
    required this.numberError,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _Row row;
  final String? Function() numberError;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? name(String? v, String label) =>
        row.isBlank ? null : Validators.required(v, label, max: 80);
    return Card(
      margin: const EdgeInsets.only(bottom: Space.m),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.s, Space.l),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Student ${index + 1}', style: theme.textTheme.titleSmall)),
                if (onRemove != null)
                  IconButton(
                    tooltip: 'Remove student ${index + 1}',
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: Space.s),
              child: Column(
                children: [
                  TextFormField(
                    controller: row.number,
                    focusNode: row.focus,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Student No'),
                    validator: (_) => numberError(),
                    onChanged: (_) => onChanged(),
                  ),
                  const SizedBox(height: Space.s),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: row.last,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Last name'),
                          validator: (v) => name(v, 'last name'),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                      const SizedBox(width: Space.s),
                      Expanded(
                        child: TextFormField(
                          controller: row.first,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'First name'),
                          validator: (v) => name(v, 'first name'),
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.s),
                  TextFormField(
                    controller: row.middle,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Middle name (optional)'),
                    validator: (v) => Validators.optional(v, max: 80),
                    onChanged: (_) => onChanged(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
