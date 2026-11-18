import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/licensing_providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../plan/plan_text.dart';

/// Everything besides the calculator, as large full-width tiles. Each tile
/// grows with its text, so nothing is cut off with the largest text size.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planStatusProvider);
    final tiles = <(IconData, String, String, String)>[
      (Icons.workspace_premium_outlined, 'Plan', planSummary(plan), Routes.plan),
      (Icons.people_alt_outlined, 'Students', 'Class lists, import, profiles', Routes.students),
      (Icons.menu_book_outlined, 'Subjects', 'Activities, class lists, grading', Routes.subjects),
      (Icons.fact_check_outlined, 'Records', 'Scores, grades, class averages', Routes.records),
      (Icons.picture_as_pdf_outlined, 'Reports', 'PDF and Excel', Routes.reports),
      (Icons.calculate_outlined, 'Calculator', '+ − × ÷ %', Routes.miniCalculator),
      (Icons.settings_outlined, 'Settings', 'School, backup, lock, text size', Routes.settings),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('ACEkor')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: tiles.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final t = tiles[i];
          return Material(
            key: i == 0 ? const ValueKey('plan-tile') : null,
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push(t.$4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    Icon(t.$1, size: 36, color: AppColors.teal),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.$2, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(t.$3, style: const TextStyle(fontSize: 15, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
