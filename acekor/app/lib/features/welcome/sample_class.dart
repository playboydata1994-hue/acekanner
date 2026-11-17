import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/roster_repository.dart';
import '../../data/repositories/subjects_repository.dart';
import '../../domain/categories.dart';
import '../calculator/calculator_controller.dart';

/// Creates a small sample class so the instructor can try the calculator
/// right away. It can be deleted like any other subject.
Future<void> createSampleClass(WidgetRef ref) async {
  final roster = ref.read(rosterRepositoryProvider);
  final subjects = ref.read(subjectsRepositoryProvider);
  final sections = await roster.sections();
  final existing = sections.where((s) => s.name == 'SAMPLE 1-A').firstOrNull;
  final sectionId =
      existing?.id ??
      await roster.createSection(const SectionInput(name: 'SAMPLE 1-A', program: 'Sample program', yearLevel: 1));
  final subjectId = await subjects.createSubject(const SubjectInput(code: 'SAMPLE 101', title: 'Sample subject'));
  const people = [
    ('Juan', 'Dela Cruz', 'S-0001'),
    ('Juan Miguel', 'Santos', 'S-0002'),
    ('Juan Carlo', 'Reyes', 'S-0003'),
    ('Mark Juan', 'Garcia', 'S-0004'),
    ('Maria Clara', 'Peña', 'S-0005'),
    ('Jose', 'Rizal', 'S-0006'),
  ];
  final ids = <String>[];
  for (final p in people) {
    final dup = await roster.findByStudentNo(p.$3);
    ids.add(
      dup?.id ??
          await roster.addStudent(StudentInput(firstName: p.$1, lastName: p.$2, studentNo: p.$3, sectionId: sectionId)),
    );
  }
  await subjects.enrolStudents(subjectId, ids);
  final quizId = await ref
      .read(activitiesRepositoryProvider)
      .createActivity(ActivityInput(subjectId: subjectId, categoryId: CategoryCatalog.quiz, number: 1, maxPoints: 50));
  final ctrl = ref.read(calculatorProvider.notifier);
  await ctrl.selectClass(subjectId);
  final quiz = await ref.read(activitiesRepositoryProvider).activity(quizId);
  if (quiz != null) await ctrl.selectActivity(quiz);
}
