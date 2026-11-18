import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/roster_repository.dart';
import 'calculator_controller.dart';

/// "IT 101 · BSIT 1-A" — the calculator's class, or null when none is chosen.
final classLabelProvider = Provider<String?>((ref) {
  final calc = ref.watch(calculatorProvider);
  final subjects = ref.watch(subjectsProvider).value ?? const [];
  final subject = subjects.where((s) => s.id == calc.subjectId).firstOrNull;
  if (subject == null) return null;
  final sections = ref.watch(sectionsProvider).value ?? const [];
  final section = sections.where((s) => s.id == calc.sectionId).firstOrNull;
  return '${subject.subject.code}${section == null ? '' : ' · ${section.name}'}';
});

/// "IT 101 · BSIT 1-A ▾" at the top of the calculator.
class ClassChip extends ConsumerWidget {
  const ClassChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(classLabelProvider);
    final label = chosen ?? 'Choose class';
    return Center(
      child: InkWell(
        key: const ValueKey('class-chip'),
        borderRadius: BorderRadius.circular(24),
        onTap: () => showClassPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: chosen == null ? AppColors.teal : AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chooses the subject (and optionally one section) scores are recorded for.
Future<void> showClassPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _ClassPickerSheet(),
  );
}

class _ClassPickerSheet extends ConsumerWidget {
  const _ClassPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc = ref.watch(calculatorProvider);
    final subjects = ref.watch(subjectsProvider).value ?? const [];
    final ctrl = ref.read(calculatorProvider.notifier);
    final enrolled = calc.subjectId == null
        ? const <StudentView>[]
        : (ref.watch(enrolledProvider(calc.subjectId!)).value ?? const <StudentView>[]);
    final sectionNames = <String, String>{
      for (final s in enrolled)
        if (s.row.sectionId != null) s.row.sectionId!: s.sectionName ?? '',
    };
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Class', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          if (subjects.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No subjects yet. Create your first subject, then add its students.',
                style: TextStyle(fontSize: 18, color: AppColors.muted),
              ),
            ),
          for (final s in subjects)
            ListTile(
              leading: Icon(
                s.id == calc.subjectId ? Icons.radio_button_checked : Icons.radio_button_off,
                color: s.id == calc.subjectId ? AppColors.teal : AppColors.muted,
              ),
              title: Text(s.label),
              subtitle: Text(
                ['${s.students} student${s.students == 1 ? '' : 's'}', if (s.term.isNotEmpty) s.term].join(' · '),
              ),
              onTap: () => ctrl.selectClass(s.id),
            ),
          if (calc.subjectId != null && sectionNames.length > 1) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'SECTION',
                style: TextStyle(fontSize: 14, letterSpacing: 1.1, color: AppColors.teal, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All sections', style: TextStyle(fontSize: 16)),
                    selected: calc.sectionId == null,
                    onSelected: (_) => ctrl.selectClass(calc.subjectId, sectionId: null),
                  ),
                  for (final e in sectionNames.entries)
                    ChoiceChip(
                      label: Text(e.value, style: const TextStyle(fontSize: 16)),
                      selected: calc.sectionId == e.key,
                      onSelected: (_) => ctrl.selectClass(calc.subjectId, sectionId: e.key),
                    ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(Routes.newSubject);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New subject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
