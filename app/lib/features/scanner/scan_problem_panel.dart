import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../domain/scan_problem.dart';

/// Stays on the scanner until the instructor taps "OK, scan again": what was
/// wrong with the photo, why the sheet was not read, and what to do.
class ScanProblemPanel extends StatelessWidget {
  const ScanProblemPanel({super.key, required this.problem, required this.onAcknowledge});

  final ScanProblem problem;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(Radii.l),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.report_problem_outlined, color: colors.uncertain),
                        const SizedBox(width: Space.s),
                        Text(
                          'NOT SCANNED',
                          style: theme.textTheme.labelMedium?.copyWith(color: colors.uncertain, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.s),
                    Text(problem.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: Space.xs),
                    Text(problem.reason, style: theme.textTheme.bodyMedium),
                    if (problem.tips.isNotEmpty) ...[
                      const SizedBox(height: Space.m),
                      Text('What to do', style: theme.textTheme.titleSmall),
                      const SizedBox(height: Space.xs),
                      for (final tip in problem.tips)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Space.xs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 7, right: Space.m),
                                child: Icon(Icons.circle, size: 6),
                              ),
                              Expanded(child: Text(tip, style: theme.textTheme.bodyMedium)),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: Space.xs),
                    Text('Nothing was saved and no scan was counted.', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.m),
            FilledButton.icon(
              onPressed: onAcknowledge,
              icon: const Icon(Icons.check),
              label: const Text('OK, scan again'),
            ),
          ],
        ),
      ),
    );
  }
}
