import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/licensing_providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/activities_repository.dart';
import '../../domain/categories.dart';
import 'calculator_controller.dart';
import 'class_picker.dart';

/// Chooses (or creates) the quiz, recitation or examination being scored.
Future<void> showActivityPicker(BuildContext context) async {
  final container = ProviderScope.containerOf(context);
  if (container.read(calculatorProvider).subjectId == null) {
    showMessage(context, 'Choose a class (subject) first.');
    await showClassPicker(context);
    if (!context.mounted || container.read(calculatorProvider).subjectId == null) return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _ActivityPickerSheet(),
  );
}

class _ActivityPickerSheet extends ConsumerWidget {
  const _ActivityPickerSheet();

  Future<void> _create(BuildContext context, WidgetRef ref, CategoryKind kind) async {
    final subjectId = ref.read(calculatorProvider).subjectId!;
    final id = await context.push<String>(Routes.newActivity(subjectId, kind: kind));
    if (id == null || !context.mounted) return;
    final a = await ref.read(activitiesProvider(subjectId).future).then((l) => l.where((x) => x.id == id).firstOrNull);
    if (a != null) {
      await ref.read(calculatorProvider.notifier).selectActivity(a);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc = ref.watch(calculatorProvider);
    final list = ref.watch(activitiesProvider(calc.subjectId!)).value ?? const <ActivityView>[];
    final enrolled = ref.watch(enrolledProvider(calc.subjectId!)).value?.length ?? 0;
    final hasMax = ref.watch(planStatusProvider).hasMax;
    final groups = <CategoryKind, List<ActivityView>>{
      for (final k in CategoryKind.values) k: list.where((a) => a.kind == k).toList(),
    };
    String title(CategoryKind k) => switch (k) {
      CategoryKind.quiz => 'Quizzes',
      CategoryKind.recitation => 'Recitations',
      CategoryKind.exam => 'Examinations',
    };
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text('Activity', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  key: const ValueKey('new-quiz'),
                  onPressed: () => _create(context, ref, CategoryKind.quiz),
                  icon: const Icon(Icons.add),
                  label: const Text('New quiz'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _create(context, ref, CategoryKind.recitation),
                  icon: const Icon(Icons.add),
                  label: const Text('New recitation'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _create(context, ref, CategoryKind.exam),
                  icon: Icon(hasMax ? Icons.add : Icons.lock_outline),
                  label: const Text('New examination'),
                ),
              ],
            ),
          ),
          for (final k in CategoryKind.values)
            if (groups[k]!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Text(
                  title(k).toUpperCase() + (k.needsMax ? '  ·  MAX' : ''),
                  style: const TextStyle(
                    fontSize: 14,
                    letterSpacing: 1.1,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final a in groups[k]!)
                ListTile(
                  leading: Icon(
                    a.id == calc.activity?.id ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: a.id == calc.activity?.id ? AppColors.teal : AppColors.muted,
                  ),
                  title: Text(a.label + (a.row.title.isNotEmpty && a.row.number != null ? ' – ${a.row.title}' : '')),
                  subtitle: Text(
                    '${a.maxPoints} points · ${a.recorded} of $enrolled recorded'
                    '${a.row.activityDate == null ? '' : ' · ${a.row.activityDate}'}',
                  ),
                  onTap: () {
                    ref.read(calculatorProvider.notifier).selectActivity(a);
                    Navigator.pop(context);
                  },
                ),
            ],
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No activities yet. Tap "New quiz" to create Quiz 1.',
                style: TextStyle(fontSize: 18, color: AppColors.muted),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
