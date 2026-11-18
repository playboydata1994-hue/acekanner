import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/text.dart';
import '../../core/widgets/common.dart';
import '../../data/repositories/roster_repository.dart';

/// The student roster: search, filter by section, add, import.
class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _query = TextEditingController();
  String? _sectionId;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(StudentView s, String q) {
    if (q.isEmpty) return true;
    final hay = foldForSearch('${s.row.firstName} ${s.row.middleName} ${s.row.lastName} ${s.row.studentNo ?? ''}');
    return foldForSearch(q).split(' ').every(hay.contains);
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(allStudentsProvider);
    final sections = ref.watch(sectionsProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            tooltip: 'Import class list',
            onPressed: () => context.push(Routes.importStudents),
            icon: const Icon(Icons.upload_file),
          ),
          PopupMenuButton<String>(
            onSelected: context.push,
            itemBuilder: (_) => const [
              PopupMenuItem(value: Routes.sections, child: Text('Sections')),
              PopupMenuItem(value: Routes.deletedStudents, child: Text('Recently deleted')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push(_sectionId == null ? Routes.newStudent : '${Routes.newStudent}?section=$_sectionId'),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add student', style: TextStyle(fontSize: 17)),
      ),
      body: AsyncView(
        value: students,
        builder: (all) {
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.people_alt_outlined,
              title: 'No students yet',
              message: 'Add students one by one, or import your class list from an Excel or CSV file.',
              action: FilledButton.icon(
                onPressed: () => context.push(Routes.importStudents),
                icon: const Icon(Icons.upload_file),
                label: const Text('Import class list'),
              ),
            );
          }
          return ListenableBuilder(
            listenable: _query,
            builder: (context, _) {
              final list = all
                  .where((s) => _sectionId == null || s.row.sectionId == _sectionId)
                  .where((s) => _matches(s, _query.text.trim()))
                  .toList();
              return ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: TextField(
                      controller: _query,
                      style: const TextStyle(fontSize: 18),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search name or student ID',
                      ),
                    ),
                  ),
                  if (sections.isNotEmpty)
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text('All (${all.length})'),
                              selected: _sectionId == null,
                              onSelected: (_) => setState(() => _sectionId = null),
                            ),
                          ),
                          for (final s in sections)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text('${s.name} (${s.studentCount})'),
                                selected: _sectionId == s.id,
                                onSelected: (_) => setState(() => _sectionId = s.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No student matches.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  for (final s in list)
                    ListTile(
                      title: Text(s.formal),
                      subtitle: Text(
                        [
                          if (s.row.studentNo != null) s.row.studentNo!,
                          if (s.sectionName != null) s.sectionName!,
                          if (s.row.program.isNotEmpty) s.row.program,
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(Routes.student(s.id)),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
