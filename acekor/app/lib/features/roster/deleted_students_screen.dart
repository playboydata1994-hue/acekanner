import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';

class DeletedStudentsScreen extends ConsumerWidget {
  const DeletedStudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(rosterRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recently deleted')),
      body: AsyncView(
        value: ref.watch(deletedStudentsProvider),
        builder: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.delete_outline,
                title: 'Nothing here',
                message: 'Deleted students appear here and can be restored.',
              )
            : ListView(
                children: [
                  for (final s in list)
                    ListTile(
                      title: Text(s.formal),
                      subtitle: Text(s.row.studentNo ?? 'No student ID'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () =>
                                guard(context, () => repo.restoreStudent(s.id), success: 'Restored ${s.natural}.'),
                            child: const Text('Restore'),
                          ),
                          IconButton(
                            tooltip: 'Delete forever',
                            icon: const Icon(Icons.delete_forever_outlined),
                            onPressed: () async {
                              final ok = await confirm(
                                context,
                                title: 'Delete forever?',
                                message:
                                    '${s.natural} and all their scores will be removed permanently. This cannot be undone.',
                                confirmLabel: 'Delete forever',
                                destructive: true,
                              );
                              if (ok && context.mounted) await guard(context, () => repo.purgeStudent(s.id));
                            },
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
