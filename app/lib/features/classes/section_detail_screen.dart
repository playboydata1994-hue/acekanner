import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/section_header.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/students_repository.dart';
import '../../domain/student_number.dart';
import 'class_forms.dart';

/// A section and its class list.
class SectionDetailScreen extends ConsumerWidget {
  const SectionDetailScreen({super.key, required this.sectionId});

  final String sectionId;

  Future<void> _addStudent(BuildContext context) async {
    final message = await showStudentForm(context, sectionId: sectionId);
    if (message != null && context.mounted) showMessage(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(sectionProvider(sectionId));
    final roster = ref.watch(rosterProvider(sectionId));
    final format = ref.watch(studentNoFormatProvider).value;
    final gridDigits = format == null ? 10 : StudentNumber.digitsIn(format);
    final summary = section.value;
    final theme = Theme.of(context);

    if (section.hasValue && summary == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This section was deleted.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(summary?.section.name ?? 'Section'),
        actions: [
          if (summary != null)
            PopupMenuButton<int>(
              tooltip: 'More',
              onSelected: (v) async {
                if (v == 0) {
                  await showSectionForm(context, section: summary.section);
                } else {
                  final ok = await confirmAction(
                    context,
                    title: 'Delete ${summary.section.name}?',
                    message: 'The section is removed from your list. Students and '
                        'past examination results are kept.',
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                  if (!ok) return;
                  await ref.read(classesRepositoryProvider).deleteSection(sectionId);
                  if (context.mounted) context.go('/classes');
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 0, child: Text('Edit section')),
                PopupMenuItem(value: 1, child: Text('Delete section')),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addStudent(context),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add student'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, 96),
        children: [
          if (summary != null)
            Text(
              [
                ?summary.courseCode,
                if (summary.period.isNotEmpty) summary.period,
              ].join(' · '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: Space.m),
          OutlinedButton.icon(
            onPressed: () async {
              final summary = await context.push<String>('/roster-import/$sectionId');
              if (summary != null && context.mounted) showMessage(context, summary);
            },
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Import class list (CSV)'),
          ),
          SectionHeader(
            switch (roster) {
              AsyncData(:final value) => '${value.length} ${value.length == 1 ? 'student' : 'students'}',
              _ => 'Students',
            },
          ),
          switch (roster) {
            AsyncData(:final value) when value.isEmpty => const EmptyState(
                icon: Icons.person_outline,
                title: 'No students yet',
                message: 'Add students one by one or import your class list from a CSV file.',
              ),
            AsyncData(:final value) => Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < value.length; i++) ...[
                      if (i > 0) const Divider(indent: Space.l, endIndent: Space.l),
                      _StudentTile(
                        student: value[i],
                        sectionId: sectionId,
                        gridDigits: gridDigits,
                      ),
                    ],
                  ],
                ),
              ),
            AsyncError() => const Text('Could not load the class list.'),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ],
      ),
    );
  }
}

class _StudentTile extends ConsumerWidget {
  const _StudentTile({required this.student, required this.sectionId, required this.gridDigits});

  final StudentRow student;
  final String sectionId;
  final int gridDigits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shadeable = StudentNumber.isShadeable(student.studentNoKey, gridDigits: gridDigits);
    final warn = context.statusColors.uncertain;
    return ListTile(
      title: Text(studentDisplayName(student)),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: student.studentNo),
            if (!shadeable)
              TextSpan(
                text: '  ·  needs a personalized (QR) sheet',
                style: TextStyle(color: warn),
              ),
          ],
        ),
      ),
      trailing: PopupMenuButton<int>(
        tooltip: 'More',
        onSelected: (v) async {
          if (v == 0) {
            final message = await showStudentForm(context, sectionId: sectionId, student: student);
            if (message != null && context.mounted) showMessage(context, message);
          } else {
            final ok = await confirmAction(
              context,
              title: 'Remove from section?',
              message: '${studentDisplayName(student)} will be removed from this '
                  'class list. Their record and scanned papers are kept.',
              confirmLabel: 'Remove',
            );
            if (ok) {
              await ref.read(studentsRepositoryProvider).removeFromSection(sectionId, student.id);
            }
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 0, child: Text('Edit')),
          PopupMenuItem(value: 1, child: Text('Remove from section')),
        ],
      ),
    );
  }
}
