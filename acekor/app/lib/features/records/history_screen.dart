import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';

/// Every score change (created, changed, deleted), newest first.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, this.activityId, this.studentId});
  final String? activityId;
  final String? studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('MMM d, y · h:mm a');
    return Scaffold(
      appBar: AppBar(title: const Text('Change history')),
      body: AsyncView(
        value: ref.watch(historyProvider((activityId: activityId, studentId: studentId))),
        builder: (list) => list.isEmpty
            ? const EmptyState(icon: Icons.history, title: 'No changes yet')
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final h = list[i];
                  final r = h.row;
                  final max = r.maxPoints == null ? '' : '/${r.maxPoints}';
                  final (icon, color, what) = switch (r.change) {
                    'create' => (Icons.add_circle_outline, AppColors.save, 'Saved ${r.newPoints}$max'),
                    'update' => (Icons.edit_outlined, AppColors.amber, 'Changed ${r.oldPoints} → ${r.newPoints}$max'),
                    _ => (Icons.remove_circle_outline, AppColors.red, 'Deleted ${r.oldPoints}$max'),
                  };
                  return ListTile(
                    leading: Icon(icon, color: color),
                    title: Text(
                      '${h.studentName ?? 'Deleted student'} · ${h.subjectCode == null ? '' : '${h.subjectCode} '}${h.activityLabel ?? 'deleted activity'}',
                    ),
                    subtitle: Text('$what\n${fmt.format(r.at)}'),
                    isThreeLine: true,
                  );
                },
              ),
      ),
    );
  }
}
