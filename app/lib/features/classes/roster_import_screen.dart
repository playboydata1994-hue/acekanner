import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/section_header.dart';
import '../../domain/roster_csv.dart';
import '../../domain/roster_file.dart';

/// Imports a class list from an Excel (.xlsx) or CSV file into a section.
class RosterImportScreen extends ConsumerStatefulWidget {
  const RosterImportScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  ConsumerState<RosterImportScreen> createState() => _RosterImportScreenState();
}

class _RosterImportScreenState extends ConsumerState<RosterImportScreen> {
  String? _fileName;
  RosterParseResult? _result;
  bool _updateNames = true;
  bool _busy = false;

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: rosterFileExtensions,
    );
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final bytes = await file.xFile.readAsBytes();
      setState(() {
        _fileName = file.name;
        _result = parseRosterFile(file.name, bytes);
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final rows = _result?.rows ?? const [];
    if (rows.isEmpty) return;
    setState(() => _busy = true);
    try {
      final s = await ref
          .read(studentsRepositoryProvider)
          .importRoster(widget.sectionId, rows, updateExistingNames: _updateNames);
      if (!mounted) return;
      Navigator.of(context).pop(
        'Imported ${s.total}: ${s.added} new, ${s.enrolled} already saved, '
        '${s.updated} updated, ${s.unchanged} unchanged',
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final section = ref.watch(sectionProvider(widget.sectionId)).value;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text('Import into ${section?.section.name ?? 'section'}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xxl),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What the file needs', style: theme.textTheme.titleMedium),
                  const SizedBox(height: Space.s),
                  const Text(
                    'A first row with column names, then one student per row. '
                    'Required: Student No, Last Name, First Name. Optional: '
                    'Middle Name, Suffix, Email. A single "Name" column written '
                    'as "Dela Cruz, Juan P." also works.',
                  ),
                  const SizedBox(height: Space.s),
                  Text(
                    'Excel (.xlsx) files can be chosen directly. From Google Sheets: '
                    'File › Download › Microsoft Excel (.xlsx) or CSV.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.l),
          FilledButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.folder_open_outlined),
            label: Text(_fileName == null ? 'Choose Excel or CSV file' : 'Choose another file'),
          ),
          if (result != null) ...[
            SectionHeader(_fileName ?? 'File'),
            if (result.fatal != null)
              _Notice(icon: Icons.error_outline, color: theme.colorScheme.error, text: result.fatal!)
            else ...[
              _Notice(
                icon: Icons.check_circle_outline,
                color: context.statusColors.correct,
                text: '${result.rows.length} ${result.rows.length == 1 ? 'student' : 'students'} ready to import',
              ),
              if (result.issues.isNotEmpty) ...[
                const SizedBox(height: Space.s),
                _Notice(
                  icon: Icons.warning_amber_outlined,
                  color: context.statusColors.uncertain,
                  text: '${result.issues.length} ${result.issues.length == 1 ? 'line' : 'lines'} will be skipped:',
                ),
                for (final issue in result.issues.take(20))
                  Padding(
                    padding: const EdgeInsets.only(left: 36, top: 4),
                    child: Text(issue.toString(), style: theme.textTheme.bodySmall),
                  ),
                if (result.issues.length > 20)
                  Padding(
                    padding: const EdgeInsets.only(left: 36, top: 4),
                    child: Text('…and ${result.issues.length - 20} more', style: theme.textTheme.bodySmall),
                  ),
              ],
              if (result.rows.isNotEmpty) ...[
                const SizedBox(height: Space.m),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Update names of students already saved'),
                  subtitle: const Text('Uses the spelling in this file'),
                  value: _updateNames,
                  onChanged: (v) => setState(() => _updateNames = v),
                ),
                const SectionHeader('Preview'),
                Card(
                  child: Column(
                    children: [
                      for (final r in result.rows.take(10))
                        ListTile(
                          dense: true,
                          title: Text(
                            '${r.lastName}, ${[r.firstName, r.middleName, r.suffix].whereType<String>().join(' ')}',
                          ),
                          subtitle: Text(r.studentNo),
                        ),
                      if (result.rows.length > 10)
                        Padding(
                          padding: const EdgeInsets.all(Space.m),
                          child: Text('…and ${result.rows.length - 10} more'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.l),
                FilledButton(
                  onPressed: _busy ? null : _import,
                  child: Text('Import ${result.rows.length} ${result.rows.length == 1 ? 'student' : 'students'}'),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: Space.m),
          Expanded(child: Text(text)),
        ],
      );
}
