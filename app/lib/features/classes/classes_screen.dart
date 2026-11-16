import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/feedback.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/classes_repository.dart';
import 'class_forms.dart';

enum ClassesTab { sections, subjects, courses }

/// Sections (with rosters), subjects and courses.
class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  ClassesTab _tab = ClassesTab.sections;

  Future<void> _add() async {
    switch (_tab) {
      case ClassesTab.sections:
        final id = await showSectionForm(context);
        if (id != null && mounted) context.go('/classes/sections/$id');
      case ClassesTab.subjects:
        await showSubjectForm(context);
      case ClassesTab.courses:
        await showCourseForm(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(switch (_tab) {
          ClassesTab.sections => 'Add section',
          ClassesTab.subjects => 'Add subject',
          ClassesTab.courses => 'Add course',
        }),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.m),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ClassesTab>(
                segments: const [
                  ButtonSegment(value: ClassesTab.sections, label: Text('Sections')),
                  ButtonSegment(value: ClassesTab.subjects, label: Text('Subjects')),
                  ButtonSegment(value: ClassesTab.courses, label: Text('Courses')),
                ],
                selected: {_tab},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              ClassesTab.sections => const _SectionsList(),
              ClassesTab.subjects => const _SubjectsList(),
              ClassesTab.courses => const _CoursesList(),
            },
          ),
        ],
      ),
    );
  }
}

class _SectionsList extends ConsumerWidget {
  const _SectionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AsyncList<SectionSummary>(
      value: ref.watch(sectionsProvider),
      empty: const EmptyState(
        icon: Icons.groups_outlined,
        title: 'No sections yet',
        message: 'Add a section, then add students or import your class list.',
      ),
      itemBuilder: (context, s) => ListTile(
        leading: CircleAvatar(child: Text('${s.studentCount}')),
        title: Text(s.section.name),
        subtitle: Text(
          [
            ?s.courseCode,
            if (s.period.isNotEmpty) s.period,
            '${s.studentCount} ${s.studentCount == 1 ? 'student' : 'students'}',
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/classes/sections/${s.section.id}'),
      ),
    );
  }
}

class _SubjectsList extends ConsumerWidget {
  const _SubjectsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AsyncList<SubjectRow>(
      value: ref.watch(subjectsProvider),
      empty: const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No subjects yet',
        message: 'Subjects appear on answer sheets and reports.',
      ),
      itemBuilder: (context, s) => ListTile(
        title: Text(s.code, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(s.title),
        onTap: () => showSubjectForm(context, subject: s),
        trailing: _RowMenu(
          onEdit: () => showSubjectForm(context, subject: s),
          onDelete: () async {
            final ok = await confirmAction(
              context,
              title: 'Delete ${s.code}?',
              message: 'Examinations that already use this subject keep it.',
              confirmLabel: 'Delete',
              destructive: true,
            );
            if (ok) await ref.read(classesRepositoryProvider).deleteSubject(s.id);
          },
        ),
      ),
    );
  }
}

class _CoursesList extends ConsumerWidget {
  const _CoursesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AsyncList<CourseRow>(
      value: ref.watch(coursesProvider),
      empty: const EmptyState(
        icon: Icons.school_outlined,
        title: 'No courses yet',
        message: 'Courses (degree programs such as BSIT) group your sections.',
      ),
      itemBuilder: (context, c) => ListTile(
        title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(c.name),
        onTap: () => showCourseForm(context, course: c),
        trailing: _RowMenu(
          onEdit: () => showCourseForm(context, course: c),
          onDelete: () async {
            final ok = await confirmAction(
              context,
              title: 'Delete ${c.code}?',
              message: 'Sections that use this course keep their students.',
              confirmLabel: 'Delete',
              destructive: true,
            );
            if (ok) await ref.read(classesRepositoryProvider).deleteCourse(c.id);
          },
        ),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
        tooltip: 'More',
        onSelected: (v) => v == 0 ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 0, child: Text('Edit')),
          PopupMenuItem(value: 1, child: Text('Delete')),
        ],
      );
}

/// List with loading, error and empty states, padded clear of the FAB.
class _AsyncList<T> extends StatelessWidget {
  const _AsyncList({required this.value, required this.empty, required this.itemBuilder});

  final AsyncValue<List<T>> value;
  final Widget empty;
  final Widget Function(BuildContext, T) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) when value.isEmpty => ListView(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          children: [empty],
        ),
      AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(Space.s, 0, Space.s, 96),
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(indent: Space.l, endIndent: Space.l),
          itemBuilder: (context, i) => itemBuilder(context, value[i]),
        ),
      AsyncError() => const Center(child: Text('Could not load this list.')),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
