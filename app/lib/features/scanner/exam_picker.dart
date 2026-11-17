import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../core/theme/spacing.dart';
import '../../data/db/app_database.dart';

/// Asks which examination to check a blank answer sheet with. Examinations
/// that use more questions than the sheet has cannot be chosen. Returns the
/// examination's ID, or null when cancelled.
Future<String?> pickExamination(BuildContext context, {required int sheetItems}) => showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ExamPicker(sheetItems: sheetItems),
    );

class ExamPicker extends ConsumerWidget {
  const ExamPicker({super.key, required this.sheetItems});

  final int sheetItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exams = ref.watch(activeExamsProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Which examination?', style: theme.textTheme.titleLarge),
                const SizedBox(height: Space.xs),
                Text(
                  'This is a blank $sheetItems-item answer sheet. Choose the examination whose answer key '
                  'checks it. The choice is kept for the next blank sheets.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (exams) {
              AsyncData(:final value) when value.isEmpty =>
                const Center(child: Text('No examinations yet. Create one first.')),
              AsyncData(:final value) => ListView(
                  children: [
                    for (final e in value)
                      ListTile(
                        enabled: e.exam.scoredItems <= sheetItems,
                        title: Text(e.exam.title),
                        subtitle: Text(
                          e.exam.scoredItems <= sheetItems
                              ? '${e.exam.scoredItems} questions · code ${e.exam.shortCode}'
                              : '${e.exam.scoredItems} questions: needs a bigger sheet',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pop(e.exam.id),
                      ),
                  ],
                ),
              AsyncError() => const Center(child: Text('Could not load the examinations.')),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}
