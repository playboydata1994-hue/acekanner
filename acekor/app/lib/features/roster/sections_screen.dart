import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import 'section_dialog.dart';

class SectionsScreen extends ConsumerWidget {
  const SectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sections')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSectionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New section'),
      ),
      body: AsyncView(
        value: ref.watch(sectionsProvider),
        builder: (sections) => sections.isEmpty
            ? const EmptyState(
                icon: Icons.groups_outlined,
                title: 'No sections yet',
                message: 'Sections group your students, e.g. BSIT 1-A.',
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  for (final s in sections)
                    ListTile(
                      title: Text(s.name),
                      subtitle: Text(
                        [
                          '${s.studentCount} student${s.studentCount == 1 ? '' : 's'}',
                          if (s.subtitle.isNotEmpty) s.subtitle,
                        ].join(' · '),
                      ),
                      onTap: () => showSectionDialog(context, ref, existing: s.section),
                      trailing: IconButton(
                        tooltip: 'Delete section',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await confirm(
                            context,
                            title: 'Delete ${s.name}?',
                            message:
                                'Its ${s.studentCount} students stay on the phone with all their scores; '
                                'they will simply have no section.',
                            confirmLabel: 'Delete',
                            destructive: true,
                          );
                          if (ok) await ref.read(rosterRepositoryProvider).deleteSection(s.id);
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
