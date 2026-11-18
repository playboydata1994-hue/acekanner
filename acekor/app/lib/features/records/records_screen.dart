import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../core/widgets/common.dart';

/// Academic records: pick a subject.
class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
        actions: [
          IconButton(
            tooltip: 'Change history',
            icon: const Icon(Icons.history),
            onPressed: () => context.push(Routes.history()),
          ),
        ],
      ),
      body: AsyncView(
        value: ref.watch(subjectsProvider),
        builder: (subjects) => subjects.isEmpty
            ? const EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'No records yet',
                message: 'Create a subject and record scores first.',
              )
            : ListView(
                children: [
                  for (final s in subjects)
                    ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(s.label),
                      subtitle: Text(
                        '${s.students} students · ${s.activities} activities${s.term.isEmpty ? '' : ' · ${s.term}'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(Routes.gradebook(s.id)),
                    ),
                  ListTile(
                    leading: const Icon(Icons.person_search_outlined),
                    title: const Text('Individual student records'),
                    subtitle: const Text('Open a student from the roster'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.students),
                  ),
                ],
              ),
      ),
    );
  }
}
