import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/scores_repository.dart';
import '../../domain/categories.dart';
import '../../domain/scoring/percent.dart';
import '../../domain/scoring/ratio.dart';
import '../calculator/calculator_controller.dart';
import '../records/score_editor.dart';

/// One activity's score sheet with class statistics.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key, required this.activityId});
  final String activityId;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  String? _sectionId;

  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(activityProvider(widget.activityId));
    return AsyncView(
      value: activity,
      builder: (a) {
        if (a == null || a.row.deletedAt != null) {
          return const Scaffold(body: Center(child: Text('This activity was deleted.')));
        }
        final key = (activityId: a.id, subjectId: a.row.subjectId, sectionId: _sectionId);
        final sheet = ref.watch(activitySheetProvider(key)).value ?? const <ActivityScoreLine>[];
        final allLines =
            ref.watch(activitySheetProvider((activityId: a.id, subjectId: a.row.subjectId, sectionId: null))).value ??
            const <ActivityScoreLine>[];
        final sectionNames = <String, String>{
          for (final l in allLines)
            if (l.student.row.sectionId != null) l.student.row.sectionId!: l.student.sectionName ?? '',
        };
        final values = sheet.map((l) => l.score?.points).whereType<int>().toList();
        final avg = values.isEmpty
            ? null
            : Ratio.of(values.fold(0, (s, v) => s + v) * 100, values.length * a.maxPoints);
        return Scaffold(
          appBar: AppBar(
            title: Text(a.label),
            actions: [
              IconButton(
                tooltip: 'Record on the calculator',
                icon: const Icon(Icons.dialpad),
                onPressed: () async {
                  final ctrl = ref.read(calculatorProvider.notifier);
                  await ctrl.selectClass(a.row.subjectId, sectionId: _sectionId);
                  await ctrl.selectActivity(a);
                  if (context.mounted) context.go(Routes.home);
                },
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'edit':
                      await context.push(Routes.editActivity(a.id));
                    case 'history':
                      await context.push(Routes.history(activityId: a.id));
                    case 'delete':
                      final ok = await confirm(
                        context,
                        title: 'Delete ${a.label}?',
                        message: 'It moves to Recently deleted with its ${a.recorded} scores, and can be restored.',
                        confirmLabel: 'Delete',
                        destructive: true,
                      );
                      if (ok) {
                        await ref.read(activitiesRepositoryProvider).deleteActivity(a.id);
                        if (context.mounted) context.pop();
                      }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'history', child: Text('Change history')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  [
                    if (a.row.title.isNotEmpty && a.row.number != null) a.row.title,
                    '${a.maxPoints} points',
                    ?a.row.activityDate,
                    if (a.period != Period.none) a.period.label,
                    if (a.kind.needsMax) 'MAX',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 17, color: AppColors.muted),
                ),
              ),
              _Stats(
                recorded: values.length,
                total: sheet.length,
                average: avg,
                highest: values.isEmpty ? null : values.reduce((x, y) => x > y ? x : y),
                lowest: values.isEmpty ? null : values.reduce((x, y) => x < y ? x : y),
                max: a.maxPoints,
              ),
              if (sectionNames.length > 1)
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('All sections'),
                          selected: _sectionId == null,
                          onSelected: (_) => setState(() => _sectionId = null),
                        ),
                      ),
                      for (final e in sectionNames.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(e.value),
                            selected: _sectionId == e.key,
                            onSelected: (_) => setState(() => _sectionId = e.key),
                          ),
                        ),
                    ],
                  ),
                ),
              if (sheet.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No students in this class yet.', style: TextStyle(color: AppColors.muted)),
                ),
              for (final l in sheet) _ScoreTile(line: l, activity: a),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreTile extends ConsumerWidget {
  const _ScoreTile({required this.line, required this.activity});
  final ActivityScoreLine line;
  final ActivityView activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = line.score;
    return ListTile(
      title: Text(line.student.formal),
      subtitle: s == null
          ? const Text('No score yet', style: TextStyle(color: AppColors.amber))
          : (s.remarks.isEmpty ? null : Text(s.remarks)),
      trailing: s == null
          ? const Icon(Icons.add_circle_outline, color: AppColors.muted)
          : Text(
              '${s.points}/${activity.maxPoints}   ${scorePercentText(s.points, activity.maxPoints)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
      onTap: () => showScoreEditor(context, ref, activity: activity, student: line.student, existing: s),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({
    required this.recorded,
    required this.total,
    required this.average,
    required this.highest,
    required this.lowest,
    required this.max,
  });
  final int recorded;
  final int total;
  final Ratio? average;
  final int? highest;
  final int? lowest;
  final int max;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          cell('recorded', '$recorded/$total'),
          cell('class average', average == null ? '—' : formatPercent(average!)),
          cell('highest', highest == null ? '—' : '$highest/$max'),
          cell('lowest', lowest == null ? '—' : '$lowest/$max'),
        ],
      ),
    );
  }
}
