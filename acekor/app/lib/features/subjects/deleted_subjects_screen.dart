import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';

/// Deleted subjects, and deleted activities of active subjects.
class DeletedSubjectsScreen extends ConsumerWidget {
  const DeletedSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(deletedSubjectsProvider).value ?? const [];
    final active = ref.watch(subjectsProvider).value ?? const [];
    final subjRepo = ref.read(subjectsRepositoryProvider);
    final actRepo = ref.read(activitiesRepositoryProvider);
    final activityTiles = <Widget>[
      for (final s in active)
        for (final a in ref.watch(deletedActivitiesProvider(s.id)).value ?? const [])
          ListTile(
            title: Text('${s.subject.code} · ${a.label}'),
            subtitle: Text('${a.recorded} scores'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => guard(context, () => actRepo.restoreActivity(a.id), success: 'Restored ${a.label}.'),
                  child: const Text('Restore'),
                ),
                IconButton(
                  tooltip: 'Delete forever',
                  icon: const Icon(Icons.delete_forever_outlined),
                  onPressed: () async {
                    final ok = await confirm(
                      context,
                      title: 'Delete forever?',
                      message: '${a.label} and its ${a.recorded} scores will be removed permanently.',
                      confirmLabel: 'Delete forever',
                      destructive: true,
                    );
                    if (ok && context.mounted) await guard(context, () => actRepo.purgeActivity(a.id));
                  },
                ),
              ],
            ),
          ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Recently deleted')),
      body: ListView(
        children: [
          const SectionTitle('Subjects'),
          if (subjects.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('None', style: TextStyle(color: AppColors.muted)),
            ),
          for (final s in subjects)
            ListTile(
              title: Text(s.label),
              subtitle: Text('${s.activities} activities'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () =>
                        guard(context, () => subjRepo.restoreSubject(s.id), success: 'Restored ${s.subject.code}.'),
                    child: const Text('Restore'),
                  ),
                  IconButton(
                    tooltip: 'Delete forever',
                    icon: const Icon(Icons.delete_forever_outlined),
                    onPressed: () async {
                      final ok = await confirm(
                        context,
                        title: 'Delete forever?',
                        message: '${s.subject.code}, its activities and all their scores will be removed permanently.',
                        confirmLabel: 'Delete forever',
                        destructive: true,
                      );
                      if (ok && context.mounted) await guard(context, () => subjRepo.purgeSubject(s.id));
                    },
                  ),
                ],
              ),
            ),
          const SectionTitle('Activities'),
          if (activityTiles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('None', style: TextStyle(color: AppColors.muted)),
            ),
          ...activityTiles,
        ],
      ),
    );
  }
}
