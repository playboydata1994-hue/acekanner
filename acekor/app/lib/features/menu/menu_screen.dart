import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/licensing_providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../plan/plan_text.dart';

/// Everything besides the calculator, as large tiles.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planStatusProvider);
    final tiles = <(IconData, String, String, String)>[
      (Icons.people_alt_outlined, 'Students', 'Class lists, import, profiles', Routes.students),
      (Icons.menu_book_outlined, 'Subjects', 'Activities, class lists, grading', Routes.subjects),
      (Icons.fact_check_outlined, 'Records', 'Scores, grades, class averages', Routes.records),
      (Icons.picture_as_pdf_outlined, 'Reports', 'PDF and Excel', Routes.reports),
      (Icons.calculate_outlined, 'Calculator', '+ − × ÷ %', Routes.miniCalculator),
      (Icons.settings_outlined, 'Settings', 'School, backup, lock, text size', Routes.settings),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('ACEKOR')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Card(
            color: AppColors.surfaceHigh,
            child: ListTile(
              key: const ValueKey('plan-tile'),
              leading: const Icon(Icons.workspace_premium_outlined, color: AppColors.teal, size: 32),
              title: const Text('Plan'),
              subtitle: Text(planSummary(plan)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.plan),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              for (final t in tiles)
                Material(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push(t.$4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(t.$1, size: 40, color: AppColors.teal),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.$2, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                t.$3,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
