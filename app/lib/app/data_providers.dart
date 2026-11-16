import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/repositories/classes_repository.dart';
import '../data/repositories/exams_repository.dart';
import '../data/repositories/grading_repository.dart';
import '../data/repositories/scan_repository.dart';
import 'providers.dart';

/// Live lists and records shown by the management screens.

final profileProvider = StreamProvider<InstructorProfileRow?>(
  (ref) => ref.watch(profileRepositoryProvider).watch(),
);

final studentNoFormatProvider = StreamProvider<String>(
  (ref) => ref.watch(profileRepositoryProvider).watchStudentNoFormat(),
);

final subjectsProvider = StreamProvider<List<SubjectRow>>(
  (ref) => ref.watch(classesRepositoryProvider).watchSubjects(),
);

final coursesProvider = StreamProvider<List<CourseRow>>(
  (ref) => ref.watch(classesRepositoryProvider).watchCourses(),
);

final sectionsProvider = StreamProvider<List<SectionSummary>>(
  (ref) => ref.watch(classesRepositoryProvider).watchSections(),
);

final sectionProvider = StreamProvider.autoDispose.family<SectionSummary?, String>(
  (ref, id) => ref.watch(classesRepositoryProvider).watchSection(id),
);

final rosterProvider = StreamProvider.autoDispose.family<List<StudentRow>, String>(
  (ref, sectionId) => ref.watch(studentsRepositoryProvider).watchRoster(sectionId),
);

final activeExamsProvider = StreamProvider<List<ExamListItem>>(
  (ref) => ref.watch(examsRepositoryProvider).watchActive(),
);

final deletedExamsProvider = StreamProvider.autoDispose<List<ExamListItem>>(
  (ref) => ref.watch(examsRepositoryProvider).watchDeleted(),
);

final examDetailProvider = StreamProvider.autoDispose.family<ExamDetail?, String>(
  (ref, id) => ref.watch(examsRepositoryProvider).watchDetail(id),
);

final scannedPapersProvider = StreamProvider.autoDispose.family<List<ScannedPaper>, String>(
  (ref, examId) => ref.watch(scanRepositoryProvider).watchPapers(examId),
);

final paperDetailProvider = StreamProvider.autoDispose.family<PaperDetail?, String>(
  (ref, sheetId) => ref.watch(gradingRepositoryProvider).watchPaper(sheetId),
);

final examAnalyticsProvider = StreamProvider.autoDispose.family<ExamAnalytics, String>(
  (ref, examId) => ref.watch(gradingRepositoryProvider).watchAnalytics(examId),
);
