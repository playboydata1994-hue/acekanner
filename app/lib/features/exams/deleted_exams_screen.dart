import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/exams_repository.dart';
import 'exam_widgets.dart';

/// Examinations in the trash: restore or delete permanently.
class DeletedExamsScreen extends ConsumerWidget {
  const DeletedExamsScreen({super.key});

  Future<void> _deleteForever(BuildContext context, WidgetRef ref, ExamListItem item) async {
    final papers = item.paperCount;
    final ok = await confirmAction(
      context,
      title: 'Delete permanently?',
      message: '“${item.exam.title}”, its answer keys'
          '${papers > 0 ? ' and $papers scanned ${papers == 1 ? 'paper' : 'papers'} with their scores' : ''} '
          'will be erased from this phone. This cannot be undone.',
      confirmLabel: 'Delete permanently',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(examsRepositoryProvider).deletePermanently(item.exam.id);
      if (context.mounted) showMessage(context, 'Examination deleted permanently');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deleted = ref.watch(deletedExamsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recently deleted')),
      body: switch (deleted) {
        AsyncData(:final value) when value.isEmpty => ListView(
            padding: const EdgeInsets.all(Space.page),
            children: const [
              EmptyState(
                icon: Icons.delete_outline,
                title: 'Nothing here',
                message: 'Examinations you delete stay here until you restore or erase them.',
              ),
            ],
          ),
        AsyncData(:final value) => ListView.separated(
            padding: const EdgeInsets.all(Space.page),
            itemCount: value.length,
            separatorBuilder: (_, _) => const SizedBox(height: Space.m),
            itemBuilder: (context, i) {
              final item = value[i];
              return ExamListTile(
                item: item,
                trailing: PopupMenuButton<int>(
                  tooltip: 'More',
                  onSelected: (v) async {
                    if (v == 0) {
                      await ref.read(examsRepositoryProvider).restore(item.exam.id);
                      if (context.mounted) showMessage(context, 'Examination restored');
                    } else {
                      await _deleteForever(context, ref, item);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 0, child: Text('Restore')),
                    PopupMenuItem(value: 1, child: Text('Delete permanently')),
                  ],
                ),
              );
            },
          ),
        AsyncError() => const Center(child: Text('Could not load deleted examinations.')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
