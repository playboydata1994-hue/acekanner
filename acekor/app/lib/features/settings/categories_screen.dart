import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/licensing_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/feedback.dart';
import '../../domain/categories.dart';

/// Built-in and custom examination categories (MAX).
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMax = ref.watch(planStatusProvider).hasMax;
    final repo = ref.read(subjectsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Examination categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!hasMax) {
            context.push(Routes.plan);
            return;
          }
          final name = await askText(context, title: 'New examination category', hint: 'e.g. Oral Examination');
          if (name == null || name.isEmpty || !context.mounted) return;
          final pts = await askNumber(context, title: 'Default points', initial: 100, min: 1, max: 1000);
          if (pts == null || !context.mounted) return;
          await guard(context, () => repo.createCategory(name, pts), success: 'Added $name.');
        },
        icon: Icon(hasMax ? Icons.add : Icons.lock_outline),
        label: const Text('Custom category'),
      ),
      body: AsyncView(
        value: ref.watch(categoriesProvider),
        builder: (cats) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            for (final c in cats)
              ListTile(
                title: Text(c.name),
                subtitle: Text(
                  '${switch (CategoryKind.parse(c.kind)) {
                    CategoryKind.quiz => 'Quiz · PRO',
                    CategoryKind.recitation => 'Recitation · PRO',
                    CategoryKind.exam => 'Examination · MAX',
                  }} · default ${c.defaultMaxPoints} points${c.builtIn ? '' : ' · custom'}',
                ),
                trailing: c.builtIn
                    ? null
                    : IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, color: AppColors.red),
                        onPressed: () async {
                          final ok = await confirm(
                            context,
                            title: 'Delete ${c.name}?',
                            message: 'Only possible while no activity uses it.',
                            confirmLabel: 'Delete',
                            destructive: true,
                          );
                          if (ok && context.mounted) await guard(context, () => repo.deleteCategory(c.id));
                        },
                      ),
                onTap: () async {
                  if (c.builtIn) {
                    final pts = await askNumber(
                      context,
                      title: '${c.name}: default points',
                      initial: c.defaultMaxPoints,
                      min: 1,
                      max: 1000,
                    );
                    if (pts != null) await repo.updateCategory(c.id, defaultMax: pts);
                    return;
                  }
                  final name = await askText(context, title: 'Rename', initial: c.name);
                  if (name == null || name.isEmpty || !context.mounted) return;
                  await guard(context, () => repo.updateCategory(c.id, name: name));
                },
              ),
          ],
        ),
      ),
    );
  }
}
