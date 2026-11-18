import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/licensing_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/feedback.dart';
import '../../data/db/app_database.dart';
import '../../data/errors.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/roster_repository.dart';
import '../../domain/scoring/percent.dart';
import '../plan/paywall.dart';

/// Edit, add or delete one score from the records screens. Every change is
/// kept in the change history.
Future<void> showScoreEditor(
  BuildContext context,
  WidgetRef ref, {
  required ActivityView activity,
  required StudentView student,
  ScoreRow? existing,
}) async {
  final points = TextEditingController(text: existing == null ? '' : '${existing.points}');
  final remarks = TextEditingController(text: existing?.remarks ?? '');
  String? error;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final value = int.tryParse(points.text);
        final pct = value != null && value <= activity.maxPoints ? scorePercentText(value, activity.maxPoints) : '';
        return AlertDialog(
          title: Text(student.natural),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.label, style: const TextStyle(fontSize: 18, color: AppColors.muted)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: points,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                        style: const TextStyle(fontSize: 32),
                        textAlign: TextAlign.center,
                        onChanged: (_) => setState(() => error = null),
                      ),
                    ),
                    Text(' / ${activity.maxPoints}', style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Text(pct, style: const TextStyle(fontSize: 22, color: AppColors.teal)),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: AppColors.red, fontSize: 16)),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: remarks,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'Remarks (optional)', counterText: ''),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                onPressed: () async {
                  final ok = await confirm(
                    dialogContext,
                    title: 'Delete this score?',
                    message:
                        '${existing.points}/${activity.maxPoints} will be removed. The change history keeps a record.',
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                  if (!ok) return;
                  await ref.read(scoresRepositoryProvider).deleteScore(existing.id);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Delete'),
              ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final v = int.tryParse(points.text);
                if (v == null) {
                  setState(() => error = 'Type the score.');
                  return;
                }
                if (v > activity.maxPoints) {
                  setState(() => error = 'The maximum is ${activity.maxPoints} points.');
                  return;
                }
                final block = ref.read(planStatusProvider).block(activity.kind);
                if (block != null) {
                  Navigator.pop(dialogContext);
                  await showPaywall(context, block);
                  return;
                }
                try {
                  await ref.read(scoresRepositoryProvider).save(activity.id, student.id, v, remarks: remarks.text);
                  await ref.read(subjectsRepositoryProvider).enrolStudents(activity.row.subjectId, [student.id]);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on DataError catch (e) {
                  setState(() => error = e.message);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}
