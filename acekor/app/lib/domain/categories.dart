/// Assessment kinds. Quiz and recitation are PRO features; every examination
/// category (built-in or custom) is a MAX feature.
enum CategoryKind {
  quiz,
  recitation,
  exam;

  static CategoryKind parse(String value) => switch (value) {
    'quiz' => CategoryKind.quiz,
    'recitation' => CategoryKind.recitation,
    _ => CategoryKind.exam,
  };

  bool get needsMax => this == CategoryKind.exam;
}

/// A built-in category, seeded when the database is created.
class BuiltInCategory {
  const BuiltInCategory(this.id, this.name, this.kind, this.defaultMax, this.sortOrder);

  final String id;
  final String name;
  final CategoryKind kind;
  final int defaultMax;
  final int sortOrder;
}

abstract final class CategoryCatalog {
  static const String quiz = 'quiz';
  static const String recitation = 'recitation';
  static const String prelim = 'prelim';
  static const String midterm = 'midterm';
  static const String finalExam = 'final';
  static const String written = 'written';
  static const String practical = 'practical';
  static const String laboratory = 'laboratory';
  static const String skills = 'skills';
  static const String performance = 'performance';
  static const String other = 'other';

  static const List<BuiltInCategory> builtIn = [
    BuiltInCategory(quiz, 'Quiz', CategoryKind.quiz, 50, 1),
    BuiltInCategory(recitation, 'Recitation', CategoryKind.recitation, 50, 2),
    BuiltInCategory(prelim, 'Preliminary Examination', CategoryKind.exam, 100, 3),
    BuiltInCategory(midterm, 'Midterm Examination', CategoryKind.exam, 100, 4),
    BuiltInCategory(finalExam, 'Final Examination', CategoryKind.exam, 100, 5),
    BuiltInCategory(written, 'Written Examination', CategoryKind.exam, 100, 6),
    BuiltInCategory(practical, 'Practical Examination', CategoryKind.exam, 100, 7),
    BuiltInCategory(laboratory, 'Laboratory Examination', CategoryKind.exam, 100, 8),
    BuiltInCategory(skills, 'Skills Demonstration', CategoryKind.exam, 100, 9),
    BuiltInCategory(performance, 'Performance Assessment', CategoryKind.exam, 100, 10),
    BuiltInCategory(other, 'Other Assessment', CategoryKind.exam, 100, 11),
  ];

  /// Weights a new subject starts with (the owner's example; total 100 %).
  static const Map<String, int> defaultWeightsBp = {
    quiz: 3000,
    recitation: 2000,
    midterm: 2000,
    finalExam: 2000,
    practical: 1000,
  };
}

/// Optional grading-period tags on activities.
enum Period {
  none('', 'No period'),
  prelim('prelim', 'Prelim'),
  midterm('midterm', 'Midterm'),
  prefinal('prefinal', 'Pre-final'),
  finals('final', 'Finals');

  const Period(this.code, this.label);
  final String code;
  final String label;

  static Period parse(String code) => Period.values.firstWhere((p) => p.code == code, orElse: () => Period.none);
}
