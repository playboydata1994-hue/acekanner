import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/text.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/roster_repository.dart';
import '../../domain/roster/roster_import.dart';
import '../../services/files.dart';

enum _SectionMode { none, existing, fromFile }

/// Imports a class list from CSV or Excel (.xlsx). Duplicate student IDs
/// (in the file or already on the phone) are detected.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, this.subjectId});
  final String? subjectId;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  PickedFile? _file;
  RosterParse? _parse;
  _SectionMode _mode = _SectionMode.none;
  String? _sectionId;
  String? _subjectId;
  DuplicatePolicy _policy = DuplicatePolicy.skip;
  bool _busy = false;
  ImportResult? _result;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.subjectId;
  }

  Future<void> _pick() async {
    try {
      final f = await pickFile(extensions: rosterFileExtensions);
      if (f == null) return;
      final parse = parseRosterFile(f.name, f.bytes);
      setState(() {
        _file = f;
        _parse = parse;
        _result = null;
        _mode = parse.rows.any((r) => r.section != null) ? _SectionMode.fromFile : _SectionMode.none;
      });
    } catch (e) {
      if (mounted) showMessage(context, 'The file could not be opened ($e).', error: true);
    }
  }

  Future<void> _template() async {
    await guard(context, () => shareFile(classListTemplateXlsx(), classListTemplateName, mimeType: Mime.xlsx));
  }

  Future<void> _import() async {
    final parse = _parse;
    if (parse == null || parse.rows.isEmpty) return;
    setState(() => _busy = true);
    try {
      final roster = ref.read(rosterRepositoryProvider);
      final settings = ref.read(appSettingsProvider);
      final sectionIds = <String, String>{};
      if (_mode == _SectionMode.fromFile) {
        final existing = await roster.sections();
        for (final name in parse.rows.map((r) => r.section).whereType<String>().toSet()) {
          final key = cleanSpaces(name).toLowerCase();
          final found = existing.where((s) => s.name.toLowerCase() == key).firstOrNull;
          final sample = parse.rows.firstWhere((r) => r.section == name);
          sectionIds[name] =
              found?.id ??
              await roster.createSection(
                SectionInput(
                  name: name,
                  program: sample.program,
                  yearLevel: sample.yearLevel,
                  academicYear: sample.academicYear.isEmpty ? settings.academicYear : sample.academicYear,
                  semester: sample.semester.isEmpty ? settings.semester : sample.semester,
                ),
              );
        }
      }
      final rows = [
        for (final r in parse.rows)
          StudentInput(
            studentNo: r.studentNo,
            firstName: r.firstName,
            middleName: r.middleName,
            lastName: r.lastName,
            suffix: r.suffix,
            program: r.program,
            yearLevel: r.yearLevel,
            sectionId: switch (_mode) {
              _SectionMode.none => null,
              _SectionMode.existing => _sectionId,
              _SectionMode.fromFile => r.section == null ? null : sectionIds[r.section],
            },
            academicYear: r.academicYear.isEmpty ? settings.academicYear : r.academicYear,
            semester: r.semester.isEmpty ? settings.semester : r.semester,
          ),
      ];
      final result = await roster.importStudents(rows, subjectId: _subjectId, policy: _policy);
      // Line numbers from the file, not the list position.
      final lines = parse.rows.map((r) => r.line).toList();
      final fixed = ImportResult(
        added: result.added,
        updated: result.updated,
        skipped: result.skipped,
        problems: [
          for (final p in result.problems)
            p.replaceFirstMapped(RegExp(r'^Row (\d+)'), (m) {
              final i = int.parse(m.group(1)!) - 2;
              return 'Row ${i >= 0 && i < lines.length ? lines[i] : m.group(1)}';
            }),
        ],
      );
      setState(() => _result = fixed);
    } catch (e) {
      if (mounted) showMessage(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(sectionsProvider).value ?? const [];
    final subjects = ref.watch(subjectsProvider).value ?? const [];
    final parse = _parse;
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Import class list')),
      bottomNavigationBar: parse != null && parse.rows.isNotEmpty && result == null
          ? BottomAction(
              label: 'Import ${parse.rows.length} students',
              onPressed: _busy ? null : _import,
              icon: Icons.download_done,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              'Choose an Excel (.xlsx) or CSV file. The first row must name the columns: Student ID, Last Name, '
              'First Name, Middle Name, and optionally Suffix, Course, Year, Section. Columns may be in any order.',
              style: TextStyle(fontSize: 17, height: 1.4, color: AppColors.muted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: FilledButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.folder_open),
              label: Text(_file == null ? 'Choose file' : 'Choose another file'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _template,
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Get an empty template'),
            ),
          ),
          if (parse != null) ...[
            SectionTitle(_file!.name),
            if (parse.fatal != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(parse.fatal!, style: const TextStyle(color: AppColors.red, fontSize: 17)),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text('${parse.rows.length} students found'),
                subtitle: parse.rows.isEmpty
                    ? null
                    : Text(
                        parse.rows.take(3).map((r) => '${r.lastName}, ${r.firstName}').join('; ') +
                            (parse.rows.length > 3 ? '…' : ''),
                      ),
              ),
              for (final i in parse.issues.take(20))
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.warning_amber, color: AppColors.amber),
                  title: Text(i.toString()),
                ),
              const SectionTitle('Section'),
              RadioGroup<_SectionMode>(
                groupValue: _mode,
                onChanged: (v) => setState(() => _mode = v!),
                child: Column(
                  children: [
                    if (parse.rows.any((r) => r.section != null))
                      const RadioListTile(
                        value: _SectionMode.fromFile,
                        title: Text('Use the Section column (new sections are created)'),
                      ),
                    const RadioListTile(value: _SectionMode.existing, title: Text('Put everyone in one section')),
                    const RadioListTile(value: _SectionMode.none, title: Text('No section')),
                  ],
                ),
              ),
              if (_mode == _SectionMode.existing)
                DropdownField<String?>(
                  label: 'Section',
                  value: _sectionId,
                  items: [for (final s in sections) DropdownMenuItem(value: s.id, child: Text(s.name))],
                  onChanged: (v) => setState(() => _sectionId = v),
                ),
              const SectionTitle('Subject'),
              DropdownField<String?>(
                label: 'Enrol in subject (optional)',
                value: _subjectId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Do not enrol')),
                  for (final s in subjects) DropdownMenuItem(value: s.id, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => _subjectId = v),
              ),
              const SectionTitle('Student IDs already on this phone'),
              RadioGroup<DuplicatePolicy>(
                groupValue: _policy,
                onChanged: (v) => setState(() => _policy = v!),
                child: const Column(
                  children: [
                    RadioListTile(
                      value: DuplicatePolicy.skip,
                      title: Text('Keep the student on the phone (skip the row)'),
                    ),
                    RadioListTile(
                      value: DuplicatePolicy.update,
                      title: Text('Update their details from the file (scores are kept)'),
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (result != null) ...[
            const SectionTitle('Done'),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.save),
              title: Text('${result.added} added · ${result.updated} updated · ${result.skipped} skipped'),
            ),
            for (final p in result.problems.take(50))
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline, color: AppColors.amber),
                title: Text(p),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Close')),
            ),
          ],
        ],
      ),
    );
  }
}
