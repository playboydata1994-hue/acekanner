import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/roster_repository.dart';
import '../../data/settings/settings_repository.dart';
import '../../domain/search/student_search.dart';
import 'calculator_controller.dart';

/// Students in the current class, for ordering suggestions.
final _classIdsProvider = Provider.autoDispose<Set<String>>((ref) {
  final subjectId = ref.watch(calculatorProvider.select((s) => s.subjectId));
  if (subjectId == null) return const {};
  return {for (final s in ref.watch(enrolledProvider(subjectId)).value ?? const <StudentView>[]) s.id};
});

final _searchIndexProvider = Provider.autoDispose<(StudentSearch, Map<String, StudentView>)>((ref) {
  final all = ref.watch(allStudentsProvider).value ?? const <StudentView>[];
  return (StudentSearch(all.map((s) => s.searchable)), {for (final s in all) s.id: s});
});

final _recentProvider = StreamProvider.autoDispose<List<String>>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchString(SettingKeys.recentStudents)
      .asyncMap((_) => ref.read(settingsRepositoryProvider).getList(SettingKeys.recentStudents));
});

/// Dropdown suggestions under the search box. Works entirely offline on the
/// phone's roster. Students of the current class (and section) come first;
/// others are marked "Not in this class" and join it when a score is saved.
class StudentSearchPanel extends ConsumerWidget {
  const StudentSearchPanel({super.key, required this.query, required this.onSelected});
  final TextEditingController query;
  final ValueChanged<StudentView> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.black,
      child: ListenableBuilder(
        listenable: query,
        builder: (context, _) {
          final (index, byId) = ref.watch(_searchIndexProvider);
          final classIds = ref.watch(_classIdsProvider);
          final calc = ref.watch(calculatorProvider);
          final text = query.text.trim();
          if (byId.isEmpty) {
            return _Hint(
              icon: Icons.group_add_outlined,
              text: 'No students yet. Add your class list first.',
              action: FilledButton.icon(
                onPressed: () => context.push(Routes.students),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add students'),
              ),
            );
          }
          List<StudentView> results;
          String header;
          if (text.isEmpty) {
            final recent = ref.watch(_recentProvider).value ?? const [];
            results = [for (final id in recent) ?byId[id]];
            header = results.isEmpty ? 'Type a name or student ID' : 'Recent students';
          } else {
            final hits = index.search(text, limit: 40);
            int group(SearchHit h) {
              final s = byId[h.student.id]!;
              if (!classIds.contains(s.id)) return 2;
              if (calc.sectionId != null && s.row.sectionId != calc.sectionId) return 1;
              return 0;
            }

            final ordered = [...hits]
              ..sort((a, b) {
                final g = group(a).compareTo(group(b));
                return g != 0 ? g : a.rank.compareTo(b.rank);
              });
            results = [for (final h in ordered.take(12)) byId[h.student.id]!];
            header = results.isEmpty
                ? 'No student matches "$text"'
                : '${results.length} match${results.length == 1 ? '' : 'es'}';
          }
          return ListView(
            key: const ValueKey('search-results'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Text(header, style: const TextStyle(fontSize: 15, color: AppColors.muted)),
              ),
              for (final s in results)
                _ResultTile(
                  student: s,
                  inClass: calc.subjectId == null || classIds.contains(s.id),
                  onTap: () => onSelected(s),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.student, required this.inClass, required this.onTap});
  final StudentView student;
  final bool inClass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (student.row.studentNo != null) student.row.studentNo!,
      if (student.sectionName != null) student.sectionName!,
    ].join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.key,
              child: Text(
                student.row.firstName.isEmpty ? '?' : student.row.firstName[0].toUpperCase(),
                style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.natural,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.white),
                  ),
                  if (details.isNotEmpty || !inClass)
                    Text(
                      [if (details.isNotEmpty) details, if (!inClass) 'Not in this class'].join(' · '),
                      style: TextStyle(fontSize: 15, color: inClass ? AppColors.muted : AppColors.amber),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: AppColors.muted),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
