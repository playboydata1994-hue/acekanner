import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/spacing.dart';
import '../../core/util/text.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/classes_repository.dart';
import '../../data/repositories/students_repository.dart';
import '../../domain/roster_csv.dart';
import '../../domain/roster_file.dart';
import '../../domain/validators.dart';

/// Section name suggested from a file name: "BSIT_2-A list.xlsx" -> "BSIT 2-A list".
String sectionNameFromFile(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final base = dot > 0 ? fileName.substring(0, dot) : fileName;
  final name = cleanSpaces(base.replaceAll('_', ' '));
  return name.length > 60 ? name.substring(0, 60).trim() : name;
}

/// Adds the students of an uploaded class list to the section named [name]
/// (an existing one with that name, ignoring case, or a new one). Returns the
/// section's ID and a summary for the user.
Future<(String, String)> importClassList(
  ClassesRepository classes,
  StudentsRepository students,
  String name,
  List<RosterRow> rows,
) async {
  final clean = cleanSpaces(name);
  final existing = (await classes.watchSections().first)
      .where((s) => s.section.name.toLowerCase() == clean.toLowerCase())
      .firstOrNull;
  final id = existing?.section.id ?? await classes.createSection(SectionInput(name: clean));
  final s = await students.importRoster(id, rows);
  final where = existing == null ? 'new section $clean' : 'section ${existing.section.name}';
  return (id, '${s.total} students added to $where (${s.added} new, ${s.total - s.added} already saved).');
}

/// Upload box on the examination form: pick an Excel or CSV list of names
/// and student numbers; the students go into a section that is then selected
/// for this examination.
class ClassListUploadBox extends ConsumerStatefulWidget {
  const ClassListUploadBox({super.key, required this.onImported});

  /// Called with the section's ID and a message after a successful import.
  final void Function(String sectionId, String message) onImported;

  @override
  ConsumerState<ClassListUploadBox> createState() => _ClassListUploadBoxState();
}

class _ClassListUploadBoxState extends ConsumerState<ClassListUploadBox> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: rosterFileExtensions);
    if (file == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = parseRosterFile(file.name, await file.xFile.readAsBytes());
      if (!mounted) return;
      if (result.fatal != null) {
        showMessage(context, result.fatal!);
        return;
      }
      if (result.rows.isEmpty) {
        showMessage(context, 'No students were found in ${file.name}.');
        return;
      }
      final name = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _ImportPreview(fileName: file.name, result: result),
      );
      if (name == null || !mounted) return;
      final (id, message) = await importClassList(
        ref.read(classesRepositoryProvider),
        ref.read(studentsRepositoryProvider),
        name,
        result.rows,
      );
      widget.onImported(id, message);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: 'Upload class list',
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outline, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _busy ? null : _pick,
          child: Padding(
            padding: const EdgeInsets.all(Space.l),
            child: Row(
              children: [
                _busy
                    ? const SizedBox.square(dimension: 32, child: CircularProgressIndicator(strokeWidth: 3))
                    : Icon(Icons.upload_file_outlined, size: 32, color: scheme.primary),
                const SizedBox(width: Space.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upload class list', style: theme.textTheme.titleMedium),
                      const SizedBox(height: Space.xs),
                      Text(
                        'Names and student numbers from Excel (.xlsx) or CSV. The students are '
                        'saved as a section and selected for this examination.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows what was found and asks for the section name. Pops with the name.
class _ImportPreview extends StatefulWidget {
  const _ImportPreview({required this.fileName, required this.result});

  final String fileName;
  final RosterParseResult result;

  @override
  State<_ImportPreview> createState() => _ImportPreviewState();
}

class _ImportPreviewState extends State<_ImportPreview> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: sectionNameFromFile(widget.fileName));

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = widget.result.rows;
    final issues = widget.result.issues;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.l + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${rows.length} students found', style: theme.textTheme.titleLarge),
            Text(widget.fileName, style: theme.textTheme.bodySmall),
            const SizedBox(height: Space.m),
            for (final r in rows.take(3))
              Text('${r.studentNo} · ${r.lastName}, ${r.firstName}', style: theme.textTheme.bodyMedium),
            if (rows.length > 3) Text('… and ${rows.length - 3} more', style: theme.textTheme.bodySmall),
            if (issues.isNotEmpty) ...[
              const SizedBox(height: Space.m),
              Text(
                '${issues.length} ${issues.length == 1 ? 'row was' : 'rows were'} skipped:',
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.error),
              ),
              for (final i in issues.take(3)) Text(i.toString(), style: theme.textTheme.bodySmall),
              if (issues.length > 3) Text('… and ${issues.length - 3} more', style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: Space.l),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Section name',
                helperText: 'An existing section with this name gets the students added.',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => Validators.required(v, 'a section name', max: 60),
            ),
            const SizedBox(height: Space.l),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) Navigator.of(context).pop(_name.text);
                    },
                    child: Text('Add ${rows.length} students'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
