import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/widgets/feedback.dart';
import '../../data/db/app_database.dart';
import '../../data/errors.dart';
import '../../data/repositories/roster_repository.dart';

/// Creates (or edits [existing]) a section. Returns its id.
Future<String?> showSectionDialog(BuildContext context, WidgetRef ref, {SectionRow? existing}) async {
  final settings = ref.read(appSettingsProvider);
  final name = TextEditingController(text: existing?.name ?? '');
  final program = TextEditingController(text: existing?.program ?? '');
  final ay = TextEditingController(text: existing?.academicYear ?? settings.academicYear);
  final sem = TextEditingController(text: existing?.semester ?? settings.semester);
  int? year = existing?.yearLevel;
  final result = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? 'New section' : 'Edit section'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Section (e.g. BSIT 1-A)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: program,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Course / program'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: year,
                decoration: const InputDecoration(labelText: 'Year level'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  for (var y = 1; y <= 6; y++) DropdownMenuItem(value: y, child: Text('Year $y')),
                ],
                onChanged: (v) => setState(() => year = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ay,
                decoration: const InputDecoration(labelText: 'Academic year'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sem,
                decoration: const InputDecoration(labelText: 'Semester'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final input = SectionInput(
                name: name.text,
                program: program.text,
                yearLevel: year,
                academicYear: ay.text,
                semester: sem.text,
              );
              try {
                final repo = ref.read(rosterRepositoryProvider);
                String id;
                if (existing == null) {
                  id = await repo.createSection(input);
                } else {
                  await repo.updateSection(existing.id, input);
                  id = existing.id;
                }
                if (context.mounted) Navigator.pop(context, id);
              } on DataError catch (e) {
                if (context.mounted) showMessage(context, e.message, error: true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  return result;
}
