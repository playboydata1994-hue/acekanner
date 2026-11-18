import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/licensing_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/activities_repository.dart';
import '../../domain/categories.dart';
import '../../domain/grading/grading_engine.dart';
import '../../domain/scoring/percent.dart';

/// One subject: its activities, class list and grading set-up.
class SubjectScreen extends ConsumerWidget {
  const SubjectScreen({super.key, required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = ref.watch(subjectProvider(subjectId));
    return AsyncView(
      value: subject,
      builder: (s) {
        if (s == null || s.deletedAt != null) {
          return const Scaffold(body: Center(child: Text('This subject was deleted.')));
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(s.code),
              actions: [
                IconButton(
                  tooltip: 'Records',
                  icon: const Icon(Icons.fact_check_outlined),
                  onPressed: () => context.push(Routes.gradebook(s.id)),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    switch (v) {
                      case 'edit':
                        await context.push(Routes.editSubject(s.id));
                      case 'delete':
                        final ok = await confirm(
                          context,
                          title: 'Delete ${s.code}?',
                          message: 'The subject moves to Recently deleted with its activities and scores, and can be restored.',
                          confirmLabel: 'Delete',
                          destructive: true,
                        );
                        if (ok) {
                          await ref.read(subjectsRepositoryProvider).deleteSubject(s.id);
                          if (context.mounted) context.pop();
                        }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit subject')),
                    PopupMenuItem(value: 'delete', child: Text('Delete subject')),
                  ],
                ),
              ],
              bottom: const TabBar(
                labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                tabs: [
                  Tab(text: 'Activities'),
                  Tab(text: 'Students'),
                  Tab(text: 'Grading'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _ActivitiesTab(subjectId: s.id),
                _StudentsTab(subjectId: s.id),
                _GradingTab(subjectId: s.id),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivitiesTab extends ConsumerWidget {
  const _ActivitiesTab({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(activitiesProvider(subjectId)).value ?? const <ActivityView>[];
    final enrolled = ref.watch(enrolledProvider(subjectId)).value?.length ?? 0;
    final hasMax = ref.watch(planStatusProvider).hasMax;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final k in CategoryKind.values)
                FilledButton.tonalIcon(
                  onPressed: () => context.push(Routes.newActivity(subjectId, kind: k)),
                  icon: Icon(k.needsMax && !hasMax ? Icons.lock_outline : Icons.add),
                  label: Text(switch (k) {
                    CategoryKind.quiz => 'Quiz',
                    CategoryKind.recitation => 'Recitation',
                    CategoryKind.exam => 'Examination',
                  }),
                ),
            ],
          ),
        ),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No activities yet. Add Quiz 1 to start recording.',
              style: TextStyle(fontSize: 17, color: AppColors.muted),
            ),
          ),
        for (final a in list)
          ListTile(
            leading: Icon(switch (a.kind) {
              CategoryKind.quiz => Icons.quiz_outlined,
              CategoryKind.recitation => Icons.record_voice_over_outlined,
              CategoryKind.exam => Icons.assignment_outlined,
            }, color: AppColors.teal),
            title: Text(a.label + (a.row.title.isNotEmpty && a.row.number != null ? ' – ${a.row.title}' : '')),
            subtitle: Text(
              [
                '${a.maxPoints} points',
                '${a.recorded}/$enrolled recorded',
                ?a.row.activityDate,
                if (a.period != Period.none) a.period.label,
              ].join(' · '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.activity(a.id)),
          ),
      ],
    );
  }
}

class _StudentsTab extends ConsumerWidget {
  const _StudentsTab({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(enrolledProvider(subjectId)).value ?? const [];
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push(Routes.enrol(subjectId)),
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Add students'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('${Routes.importStudents}?subject=$subjectId'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            '${list.length} student${list.length == 1 ? '' : 's'} in this class',
            style: const TextStyle(color: AppColors.muted, fontSize: 16),
          ),
        ),
        for (final s in list)
          ListTile(
            title: Text(s.formal),
            subtitle: Text(
              [if (s.row.studentNo != null) s.row.studentNo!, if (s.sectionName != null) s.sectionName!].join(' · '),
            ),
            onTap: () => context.push(Routes.student(s.id)),
            trailing: IconButton(
              tooltip: 'Remove from this class',
              icon: const Icon(Icons.person_remove_outlined),
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'Remove ${s.natural}?',
                  message: 'They leave this class list. Their scores are kept and return if they are added again.',
                  confirmLabel: 'Remove',
                );
                if (ok) await ref.read(subjectsRepositoryProvider).unenrol(subjectId, s.id);
              },
            ),
          ),
      ],
    );
  }
}

class _GradingTab extends ConsumerWidget {
  const _GradingTab({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = ref.watch(subjectProvider(subjectId)).value;
    final weights = ref.watch(weightsProvider(subjectId)).value ?? const [];
    final scales = ref.watch(scalesProvider).value ?? const [];
    if (subject == null) return const SizedBox.shrink();
    final used = weights.where((w) => w.weightBp > 0).toList();
    final total = used.fold(0, (s, w) => s + w.weightBp);
    final scale = scales.where((s) => s.row.id == subject.gradeScaleId).firstOrNull;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        ListTile(
          leading: Icon(
            total == 10000 ? Icons.check_circle : Icons.warning_amber,
            color: total == 10000 ? AppColors.save : AppColors.amber,
          ),
          title: Text('Weights total ${formatBp(total)}'),
          subtitle: Text(
            total == 10000 ? 'Grading is active.' : 'Grades are computed only when the weights total exactly 100%.',
          ),
        ),
        for (final w in used)
          ListTile(
            dense: true,
            title: Text(w.category.name),
            trailing: Text(formatBp(w.weightBp), style: const TextStyle(fontSize: 18)),
          ),
        const Divider(),
        ListTile(
          title: const Text('Combining activities'),
          subtitle: Text(CombineMethod.parse(subject.combineMethod).label),
        ),
        ListTile(title: const Text('Grade scale'), subtitle: Text(scale?.row.name ?? 'None (percentage only)')),
        Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton.icon(
            onPressed: () => context.push(Routes.grading(subjectId)),
            icon: const Icon(Icons.tune),
            label: const Text('Change grading'),
          ),
        ),
      ],
    );
  }
}
