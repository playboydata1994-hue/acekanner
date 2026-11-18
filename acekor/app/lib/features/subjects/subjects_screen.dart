import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        actions: [
          IconButton(
            tooltip: 'Sections',
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => context.push(Routes.sections),
          ),
          PopupMenuButton<String>(
            onSelected: context.push,
            itemBuilder: (_) => const [PopupMenuItem(value: Routes.deletedSubjects, child: Text('Recently deleted'))],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.newSubject),
        icon: const Icon(Icons.add),
        label: const Text('New subject', style: TextStyle(fontSize: 17)),
      ),
      body: AsyncView(
        value: ref.watch(subjectsProvider),
        builder: (subjects) => subjects.isEmpty
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No subjects yet',
                message: 'Create a subject (e.g. IT 101), add its students, then record quizzes and recitations on the calculator.',
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  for (final s in subjects)
                    ListTile(
                      title: Text(s.label),
                      subtitle: Text(
                        [
                          '${s.students} student${s.students == 1 ? '' : 's'}',
                          '${s.activities} activit${s.activities == 1 ? 'y' : 'ies'}',
                          if (s.term.isNotEmpty) s.term,
                        ].join(' · '),
                      ),
                      trailing: s.weightTotalBp == 10000
                          ? const Icon(Icons.chevron_right)
                          : const Tooltip(
                              message: 'Grading weights are not 100%',
                              child: Icon(Icons.warning_amber, color: AppColors.amber),
                            ),
                      onTap: () => context.push(Routes.subject(s.id)),
                    ),
                ],
              ),
      ),
    );
  }
}
