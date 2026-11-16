import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_pill.dart';
import '../../domain/grading.dart';

String fmtNumber(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

String fmtPercent(double v) => '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1)}%';

/// "PASSED" / "FAILED" with icon (never color alone).
class PassPill extends StatelessWidget {
  const PassPill({super.key, required this.passed});

  final bool passed;

  @override
  Widget build(BuildContext context) {
    final c = context.statusColors;
    return passed
        ? StatusPill(label: 'PASSED', color: c.correct, icon: Icons.check)
        : StatusPill(label: 'FAILED', color: c.incorrect, icon: Icons.close);
  }
}

/// Icon + label for a question outcome.
(IconData, String, Color) outcomeStyle(BuildContext context, ItemOutcome o) {
  final c = context.statusColors;
  return switch (o) {
    ItemOutcome.correct => (Icons.check_circle, 'Correct', c.correct),
    ItemOutcome.incorrect => (Icons.cancel, 'Wrong', c.incorrect),
    ItemOutcome.blank => (Icons.remove_circle_outline, 'No answer', c.blank),
    ItemOutcome.multiple => (Icons.error, 'More than one', c.incorrect),
    ItemOutcome.bonus => (Icons.star, 'Bonus', c.premium),
    ItemOutcome.dropped => (Icons.block, 'Dropped', c.blank),
  };
}
