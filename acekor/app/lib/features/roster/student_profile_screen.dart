import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/roster_repository.dart';
import '../../data/repositories/scores_repository.dart';
import '../../domain/grading/grading_engine.dart';
import '../../domain/scoring/percent.dart';
import '../records/score_editor.dart';

/// Weighted grade of a student in each subject they take or have scores in.
final _studentGradesProvider = FutureProvider.autoDispose.family<List<(Gradebook, StudentGrade)>, String>((
  ref,
  studentId,
) async {
  final lines = ref.watch(studentScoresProvider(studentId)).value ?? const <StudentScoreLine>[];
  final subjectIds = {
    ...lines.map((l) => l.subject.id),
    ...await ref.read(subjectsRepositoryProvider).subjectIdsOf(studentId),
  };
  final service = ref.read(gradebookServiceProvider);
  final out = <(Gradebook, StudentGrade)>[];
  for (final id in subjectIds) {
    final book = await service.build(id, studentIds: {studentId});
    if (book == null || book.subject.deletedAt != null) continue;
    final grade = book.grades[studentId];
    if (grade != null) out.add((book, grade));
  }
  out.sort((a, b) => a.$1.subject.code.compareTo(b.$1.subject.code));
  return out;
});

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key, required this.studentId});
  final String studentId;

  Future<void> _move(BuildContext context, WidgetRef ref, StudentView s) async {
    final sections = await ref.read(rosterRepositoryProvider).sections();
    if (!context.mounted) return;
    final picked = await showDialog<(String?,)>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Move to section'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, (null,)),
            child: const Text('No section', style: TextStyle(fontSize: 18)),
          ),
          for (final sec in sections)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, (sec.id,)),
              child: Text(sec.name, style: const TextStyle(fontSize: 18)),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await ref.read(rosterRepositoryProvider).moveToSection([s.id], picked.$1);
    if (context.mounted) showMessage(context, 'Moved. All scores are kept.');
  }

  Future<void> _subjects(BuildContext context, WidgetRef ref, StudentView s) async {
    final all = await ref.read(subjectsRepositoryProvider).subjects();
    final current = (await ref.read(subjectsRepositoryProvider).subjectIdsOf(s.id)).toSet();
    if (!context.mounted) return;
    final chosen = {...current};
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Subjects'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (all.isEmpty) const Text('No subjects yet.'),
                for (final sub in all)
                  CheckboxListTile(
                    value: chosen.contains(sub.id),
                    title: Text(sub.label),
                    onChanged: (v) => setState(() => v! ? chosen.add(sub.id) : chosen.remove(sub.id)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final repo = ref.read(subjectsRepositoryProvider);
    for (final id in chosen.difference(current)) {
      await repo.enrolStudents(id, [s.id]);
    }
    for (final id in current.difference(chosen)) {
      await repo.unenrol(id, s.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(studentProvider(studentId));
    return AsyncView(
      value: student,
      builder: (s) {
        if (s == null) return const Scaffold(body: Center(child: Text('Student not found.')));
        final grades = ref.watch(_studentGradesProvider(studentId)).value ?? const [];
        final scores = ref.watch(studentScoresProvider(studentId)).value ?? const <StudentScoreLine>[];
        final r = s.row;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Student'),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(Routes.editStudent(s.id)),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'move':
                      await _move(context, ref, s);
                    case 'subjects':
                      await _subjects(context, ref, s);
                    case 'history':
                      await context.push(Routes.history(studentId: s.id));
                    case 'delete':
                      final ok = await confirm(
                        context,
                        title: 'Delete ${s.natural}?',
                        message: 'The student moves to Recently deleted with all scores, and can be restored.',
                        confirmLabel: 'Delete',
                        destructive: true,
                      );
                      if (ok) {
                        await ref.read(rosterRepositoryProvider).deleteStudent(s.id);
                        if (context.mounted) context.pop();
                      }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'move', child: Text('Move to section')),
                  PopupMenuItem(value: 'subjects', child: Text('Subjects')),
                  PopupMenuItem(value: 'history', child: Text('Change history')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(s.complete, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  [
                    'ID: ${r.studentNo ?? '—'}',
                    if (s.sectionName != null) 'Section: ${s.sectionName}',
                    if (r.program.isNotEmpty) r.program,
                    if (r.yearLevel != null) 'Year ${r.yearLevel}',
                    if (r.academicYear.isNotEmpty) r.academicYear,
                    if (r.semester.isNotEmpty) r.semester,
                  ].join('\n'),
                  style: const TextStyle(fontSize: 17, height: 1.5, color: AppColors.muted),
                ),
              ),
              const SectionTitle('Grades'),
              if (grades.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Not enrolled in any subject yet.', style: TextStyle(color: AppColors.muted)),
                ),
              for (final (book, g) in grades)
                ListTile(
                  title: Text(book.subject.code),
                  subtitle: Text(
                    g.percent == null
                        ? (g.weightsValid ? 'No scores yet' : 'Grading weights are not 100% yet')
                        : '${g.complete ? 'Final' : 'Running'} grade · ${g.componentsCounted} of ${g.componentsWeighted} components'
                              '${g.missingCount > 0 ? ' · ${g.missingCount} missing' : ''}',
                  ),
                  trailing: g.percent == null
                      ? null
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatPercent(g.percent!),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            if (g.equivalent != null)
                              Text(
                                g.equivalent!.grade,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: g.passed == false ? AppColors.red : AppColors.teal,
                                ),
                              ),
                          ],
                        ),
                  onTap: () => context.push(Routes.gradebook(book.subject.id)),
                ),
              const SectionTitle('Scores'),
              if (scores.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('No scores recorded yet.', style: TextStyle(color: AppColors.muted)),
                ),
              for (final l in scores)
                ListTile(
                  title: Text('${l.subject.code} · ${l.activity.label}'),
                  subtitle: l.score.remarks.isEmpty ? null : Text(l.score.remarks),
                  trailing: Text(
                    '${l.score.points}/${l.activity.maxPoints}  ${scorePercentText(l.score.points, l.activity.maxPoints)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  onTap: () => showScoreEditor(context, ref, activity: l.activity, student: s, existing: l.score),
                ),
            ],
          ),
        );
      },
    );
  }
}
