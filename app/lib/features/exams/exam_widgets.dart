import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/exams_repository.dart';

/// "Key incomplete" / "Key complete" / "Closed".
class ExamStatusPill extends StatelessWidget {
  const ExamStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.statusColors;
    return switch (status) {
      ExamStatus.ready => StatusPill(label: 'KEY COMPLETE', color: colors.correct, icon: Icons.check),
      ExamStatus.closed => StatusPill(label: 'CLOSED', color: colors.blank),
      _ => StatusPill(label: 'KEY INCOMPLETE', color: colors.uncertain, icon: Icons.edit_outlined),
    };
  }
}

String formatExamDate(DateTime? date) => date == null ? 'No date' : DateFormat('d MMM y').format(date);

/// "A", "A–B", "A–C", "A–D".
String setsLabel(int count) => count <= 1 ? 'Set A' : 'Sets A–${versionLabels[count - 1]}';

/// One line summary for lists.
String examSubtitle(ExamListItem item) => [
      ?item.subjectCode,
      formatExamDate(item.exam.examDate),
      '${item.exam.itemCount} items',
      if (item.versionCount > 1) setsLabel(item.versionCount),
      '${item.paperCount} ${item.paperCount == 1 ? 'paper' : 'papers'}',
    ].join(' · ');

class ExamListTile extends StatelessWidget {
  const ExamListTile({super.key, required this.item, this.onTap, this.trailing});

  final ExamListItem item;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ExaminationRow exam = item.exam;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      examSubtitle(item),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ExamStatusPill(status: exam.status),
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
