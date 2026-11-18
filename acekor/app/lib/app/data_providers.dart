import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/activities_repository.dart';
import '../data/repositories/roster_repository.dart';
import '../data/repositories/scores_repository.dart';
import '../data/repositories/subjects_repository.dart';
import 'providers.dart';

/// Live lists shown by the screens.

final profileProvider = StreamProvider<ProfileRow>((ref) => ref.watch(rosterRepositoryProvider).watchProfile());

final sectionsProvider = StreamProvider<List<SectionSummary>>(
  (ref) => ref.watch(rosterRepositoryProvider).watchSections(),
);

/// All active students.
final allStudentsProvider = StreamProvider<List<StudentView>>(
  (ref) => ref.watch(rosterRepositoryProvider).watchStudents(),
);

final deletedStudentsProvider = StreamProvider.autoDispose<List<StudentView>>(
  (ref) => ref.watch(rosterRepositoryProvider).watchStudents(deleted: true),
);

final sectionStudentsProvider = StreamProvider.autoDispose.family<List<StudentView>, String>(
  (ref, sectionId) => ref.watch(rosterRepositoryProvider).watchStudents(sectionId: sectionId),
);

/// Students enrolled in a subject (all sections).
final enrolledProvider = StreamProvider.family<List<StudentView>, String>(
  (ref, subjectId) => ref.watch(rosterRepositoryProvider).watchStudents(subjectId: subjectId),
);

final studentProvider = StreamProvider.autoDispose.family<StudentView?, String>(
  (ref, id) => ref.watch(rosterRepositoryProvider).watchStudent(id),
);

final subjectsProvider = StreamProvider<List<SubjectSummary>>(
  (ref) => ref.watch(subjectsRepositoryProvider).watchSubjects(),
);

final deletedSubjectsProvider = StreamProvider.autoDispose<List<SubjectSummary>>(
  (ref) => ref.watch(subjectsRepositoryProvider).watchSubjects(deleted: true),
);

final subjectProvider = StreamProvider.family<SubjectRow?, String>(
  (ref, id) => ref.watch(subjectsRepositoryProvider).watchSubject(id),
);

final categoriesProvider = StreamProvider<List<CategoryRow>>(
  (ref) => ref.watch(subjectsRepositoryProvider).watchCategories(),
);

final weightsProvider = StreamProvider.autoDispose.family<List<WeightView>, String>(
  (ref, subjectId) => ref.watch(subjectsRepositoryProvider).watchWeights(subjectId),
);

final scalesProvider = StreamProvider<List<ScaleView>>((ref) => ref.watch(subjectsRepositoryProvider).watchScales());

final activitiesProvider = StreamProvider.family<List<ActivityView>, String>(
  (ref, subjectId) => ref.watch(activitiesRepositoryProvider).watchActivities(subjectId),
);

final deletedActivitiesProvider = StreamProvider.autoDispose.family<List<ActivityView>, String>(
  (ref, subjectId) => ref.watch(activitiesRepositoryProvider).watchActivities(subjectId, deleted: true),
);

final activityProvider = StreamProvider.autoDispose.family<ActivityView?, String>(
  (ref, id) => ref.watch(activitiesRepositoryProvider).watchActivity(id),
);

typedef SheetKey = ({String activityId, String subjectId, String? sectionId});

final activitySheetProvider = StreamProvider.autoDispose.family<List<ActivityScoreLine>, SheetKey>(
  (ref, k) => ref.watch(scoresRepositoryProvider).watchActivitySheet(k.activityId, k.subjectId, sectionId: k.sectionId),
);

final studentScoresProvider = StreamProvider.autoDispose.family<List<StudentScoreLine>, String>(
  (ref, studentId) => ref.watch(scoresRepositoryProvider).watchStudentScores(studentId),
);

typedef HistoryKey = ({String? activityId, String? studentId});

final historyProvider = StreamProvider.autoDispose.family<List<HistoryView>, HistoryKey>(
  (ref, k) => ref.watch(scoresRepositoryProvider).watchHistory(activityId: k.activityId, studentId: k.studentId),
);

typedef BookKey = ({String subjectId, String? sectionId});

final gradebookProvider = StreamProvider.autoDispose.family<Gradebook?, BookKey>(
  (ref, k) => ref.watch(gradebookServiceProvider).watch(k.subjectId, sectionId: k.sectionId),
);

final calcHistoryProvider = StreamProvider.autoDispose<List<CalcHistoryRow>>(
  (ref) => ref.watch(calcHistoryRepositoryProvider).watch(),
);
