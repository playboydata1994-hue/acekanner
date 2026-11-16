import 'answer_mask.dart';

/// How one question was scored.
enum ItemOutcome {
  correct,
  incorrect,
  blank,

  /// Two or more bubbles shaded.
  multiple,

  /// Bonus item: everyone earns the points.
  bonus,

  /// Dropped item: excluded from scoring.
  dropped,
}

/// Answer-key entry as the grading engine needs it.
class GradeKeyItem {
  const GradeKeyItem({
    required this.questionNo,
    required this.correctMask,
    this.points = 1,
    this.negativePoints = 0,
    this.mode = 'normal',
  });

  final int questionNo;

  /// Accepted answers (any one of them is correct).
  final int correctMask;
  final double points;
  final double negativePoints;

  /// `normal`, `bonus` or `dropped`.
  final String mode;
}

class GradingRules {
  const GradingRules({
    this.passingPercentage = 75,
    this.multipleMarkPolicy = 'incorrect',
    this.allowNegativeTotal = false,
  });

  final double passingPercentage;

  /// `incorrect`: two or more marks count as wrong (deduction applies);
  /// `zero`: they score zero with no deduction.
  final String multipleMarkPolicy;
  final bool allowNegativeTotal;
}

class QuestionGrade {
  const QuestionGrade({
    required this.questionNo,
    required this.answerMask,
    required this.correctMask,
    required this.outcome,
    required this.earned,
    required this.possible,
  });

  final int questionNo;
  final int answerMask;
  final int correctMask;
  final ItemOutcome outcome;

  /// Points earned; negative when a deduction applies.
  final double earned;

  /// Points this item contributes to the total (0 when dropped).
  final double possible;
}

class GradeResult {
  const GradeResult({
    required this.questions,
    required this.correct,
    required this.incorrect,
    required this.blank,
    required this.multiple,
    required this.earned,
    required this.possible,
    required this.percentage,
    required this.passed,
  });

  final List<QuestionGrade> questions;

  /// Correct answers, including bonus items.
  final int correct;
  final int incorrect;
  final int blank;
  final int multiple;
  final double earned;
  final double possible;

  /// earned / possible × 100 (0 when nothing is scorable).
  final double percentage;
  final bool passed;
}

/// Deterministic scoring of one paper.
///
/// - Dropped items are excluded from earned and possible points.
/// - Bonus items award their points to everyone.
/// - Blank: 0 points, no deduction.
/// - Two or more marks: per [GradingRules.multipleMarkPolicy] — counted as a
///   wrong answer (deduction applies) or as zero.
/// - One mark: correct when it is one of the accepted answers; otherwise wrong
///   and the item's deduction applies.
/// - The total is not allowed below zero unless [GradingRules.allowNegativeTotal].
///
/// Percentage = earned points / total possible points × 100.
GradeResult grade({
  required List<GradeKeyItem> key,
  required Map<int, int> answers,
  required GradingRules rules,
}) {
  final graded = <QuestionGrade>[];
  var correct = 0, incorrect = 0, blank = 0, multiple = 0;
  var earned = 0.0, possible = 0.0;

  for (final item in key) {
    final answer = answers[item.questionNo] ?? 0;
    ItemOutcome outcome;
    var points = 0.0;
    var counts = item.points;
    if (item.mode == 'dropped') {
      outcome = ItemOutcome.dropped;
      counts = 0;
    } else if (item.mode == 'bonus') {
      outcome = ItemOutcome.bonus;
      points = item.points;
      correct++;
    } else if (answer == 0) {
      outcome = ItemOutcome.blank;
      blank++;
    } else if (AnswerMask.count(answer) > 1) {
      outcome = ItemOutcome.multiple;
      multiple++;
      if (rules.multipleMarkPolicy == 'incorrect') points = -item.negativePoints;
    } else if (answer & item.correctMask != 0) {
      outcome = ItemOutcome.correct;
      points = item.points;
      correct++;
    } else {
      outcome = ItemOutcome.incorrect;
      points = -item.negativePoints;
      incorrect++;
    }
    earned += points;
    possible += counts;
    graded.add(QuestionGrade(
      questionNo: item.questionNo,
      answerMask: answer,
      correctMask: item.correctMask,
      outcome: outcome,
      earned: _round(points),
      possible: counts,
    ));
  }

  earned = _round(earned);
  possible = _round(possible);
  if (!rules.allowNegativeTotal && earned < 0) earned = 0;
  final percentage = possible <= 0 ? 0.0 : _round(earned / possible * 100);
  return GradeResult(
    questions: graded,
    correct: correct,
    incorrect: incorrect,
    blank: blank,
    multiple: multiple,
    earned: earned,
    possible: possible,
    percentage: percentage,
    passed: percentage >= rules.passingPercentage,
  );
}

/// Rounds to 4 decimals so sums like 0.1 + 0.2 compare and display cleanly.
double _round(double v) => (v * 10000).roundToDouble() / 10000;
