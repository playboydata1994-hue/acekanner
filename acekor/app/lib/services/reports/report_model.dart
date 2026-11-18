import '../../data/repositories/activities_repository.dart';
import '../../data/repositories/scores_repository.dart';
import '../../domain/categories.dart';

/// The eight report types.
enum ReportType {
  student('Individual student score report', needsStudent: true),
  quizzes('Quiz score summary'),
  recitations('Recitation score summary'),
  exams('Examination score summary', max: true),
  practical('Practical examination summary', max: true),
  classPerformance('Complete class performance report'),
  gradeSummary('Subject grade summary'),
  overall('Overall academic performance report', allSubjects: true);

  const ReportType(this.title, {this.needsStudent = false, this.max = false, this.allSubjects = false});
  final String title;
  final bool needsStudent;

  /// Examination reports are part of MAX.
  final bool max;

  /// Covers every subject (not one subject).
  final bool allSubjects;
}

/// Practical-type examinations get their own summary.
const Set<String> practicalCategoryIds = {'practical', 'laboratory', 'skills', 'performance'};

bool isPractical(ActivityView a) => practicalCategoryIds.contains(a.row.categoryId);

/// Activities a report shows.
List<ActivityView> activitiesFor(ReportType type, Gradebook book) => switch (type) {
  ReportType.quizzes => book.activities.where((a) => a.kind == CategoryKind.quiz).toList(),
  ReportType.recitations => book.activities.where((a) => a.kind == CategoryKind.recitation).toList(),
  ReportType.exams => book.activities.where((a) => a.kind == CategoryKind.exam && !isPractical(a)).toList(),
  ReportType.practical => book.activities.where(isPractical).toList(),
  _ => book.activities,
};

/// Heading printed on every report.
class ReportHeader {
  const ReportHeader({
    required this.title,
    required this.generated,
    this.schoolName = '',
    this.schoolAddress = '',
    this.department = '',
    this.instructor = '',
    this.extraLine = '',
    this.footerLine = '',
    this.subject,
    this.section,
    this.academicYear = '',
    this.semester = '',
    this.period,
  });

  final String title;
  final DateTime generated;
  final String schoolName;
  final String schoolAddress;
  final String department;
  final String instructor;
  final String extraLine;
  final String footerLine;

  /// "IT 101 – Introduction to Computing"
  final String? subject;

  /// "BSIT 1-A" or "All sections"
  final String? section;
  final String academicYear;
  final String semester;

  /// Grading period filter, if any.
  final String? period;
}
