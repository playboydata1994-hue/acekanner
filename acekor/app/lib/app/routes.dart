import '../domain/categories.dart';

abstract final class Routes {
  static const String splash = '/';
  static const String recovery = '/recovery';
  static const String welcome = '/welcome';
  static const String home = '/home';
  static const String menu = '/menu';
  static const String miniCalculator = '/calculator';

  static const String students = '/students';
  static const String newStudent = '/students/new';
  static const String importStudents = '/students/import';
  static const String deletedStudents = '/students/deleted';
  static String student(String id) => '/students/$id';
  static String editStudent(String id) => '/students/$id/edit';
  static const String sections = '/sections';

  static const String subjects = '/subjects';
  static const String newSubject = '/subjects/new';
  static const String deletedSubjects = '/subjects/deleted';
  static String subject(String id) => '/subjects/$id';
  static String editSubject(String id) => '/subjects/$id/edit';
  static String grading(String id) => '/subjects/$id/grading';
  static String enrol(String id) => '/subjects/$id/enrol';
  static String newActivity(String subjectId, {CategoryKind kind = CategoryKind.quiz}) =>
      '/subjects/$subjectId/new-activity?kind=${kind.name}';
  static String activity(String id) => '/activities/$id';
  static String editActivity(String id) => '/activities/$id/edit';

  static const String records = '/records';
  static String gradebook(String subjectId) => '/records/$subjectId';
  static String history({String? activityId, String? studentId}) =>
      Uri(path: '/history', queryParameters: {'activity': ?activityId, 'student': ?studentId}).toString();

  static const String reports = '/reports';
  static const String plan = '/plan';

  static const String settings = '/settings';
  static const String calculatorSettings = '/settings/calculator';
  static const String profile = '/settings/profile';
  static const String scales = '/settings/scales';
  static String scale(String id) => '/settings/scales/$id';
  static const String newScale = '/settings/scales/new';
  static const String categories = '/settings/categories';
  static const String backup = '/settings/backup';
  static const String lock = '/settings/lock';
  static const String privacy = '/settings/privacy';
  static const String about = '/settings/about';
}
