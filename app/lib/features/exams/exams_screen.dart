import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';

import '../../app/data_providers.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/empty_state.dart';
import 'exam_widgets.dart';

/// All active examinations.
class ExamsScreen extends ConsumerWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = ref.watch(activeExamsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examinations'),
        actions: [
          IconButton(
            tooltip: 'Print blank answer sheets',
            icon: const Icon(Icons.print_outlined),
            onPressed: () => context.push(Routes.blankSheets),
          ),
          IconButton(
            tooltip: 'Recently deleted',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => context.go('/exams/trash'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exam-editor/new'),
        icon: const Icon(Icons.add),
        label: const Text('New examination'),
      ),
      body: switch (exams) {
        AsyncData(:final value) when value.isEmpty => ListView(
            padding: const EdgeInsets.all(Space.page),
            children: const [
              EmptyState(
                icon: Icons.assignment_outlined,
                title: 'No examinations yet',
                message: 'Create an examination, then enter its answer key.',
              ),
            ],
          ),
        AsyncData(:final value) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, 96),
            itemCount: value.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.m),
            itemBuilder: (context, i) => ExamListTile(
              item: value[i],
              onTap: () => context.go('/exams/${value[i].exam.id}'),
            ),
          ),
        AsyncError() => const Center(child: Text('Could not load examinations.')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
