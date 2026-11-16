import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/domain/analytics.dart';
import 'package:acekanner/domain/grading.dart';

const a = 1, b = 2, c = 4, d = 8, e = 16;

List<GradeKeyItem> keyOf(List<int> masks, {double points = 1, double negative = 0}) => [
      for (var i = 0; i < masks.length; i++)
        GradeKeyItem(questionNo: i + 1, correctMask: masks[i], points: points, negativePoints: negative),
    ];

void main() {
  group('grade', () {
    test('the example from the specification', () {
      // Q1 A/A correct, Q2 B/C wrong, Q3 D/D correct, Q4 unanswered.
      final r = grade(
        key: keyOf([a, c, d, b]),
        answers: {1: a, 2: b, 3: d, 4: 0},
        rules: const GradingRules(),
      );
      expect(r.questions.map((q) => q.outcome), [
        ItemOutcome.correct,
        ItemOutcome.incorrect,
        ItemOutcome.correct,
        ItemOutcome.blank,
      ]);
      expect([r.correct, r.incorrect, r.blank, r.multiple], [2, 1, 1, 0]);
      expect(r.earned, 2);
      expect(r.possible, 4);
      expect(r.percentage, 50);
      expect(r.passed, isFalse);
    });

    test('multiple marks: wrong with deduction, or zero', () {
      final key = keyOf([a, a], negative: 0.25);
      final answers = {1: a, 2: a | b};
      final asWrong = grade(key: key, answers: answers, rules: const GradingRules(allowNegativeTotal: true));
      expect(asWrong.multiple, 1);
      expect(asWrong.earned, 0.75);
      final asZero = grade(key: key, answers: answers, rules: const GradingRules(multipleMarkPolicy: 'zero'));
      expect(asZero.earned, 1);
    });

    test('accepted alternatives, weighted items and negative marking', () {
      final key = [
        const GradeKeyItem(questionNo: 1, correctMask: a | c, points: 2),
        const GradeKeyItem(questionNo: 2, correctMask: b, points: 3, negativePoints: 1),
        const GradeKeyItem(questionNo: 3, correctMask: e),
      ];
      final r = grade(key: key, answers: {1: c, 2: d, 3: e}, rules: const GradingRules(passingPercentage: 50));
      expect(r.questions[0].outcome, ItemOutcome.correct);
      expect(r.questions[1].earned, -1);
      expect(r.earned, 2); // 2 - 1 + 1
      expect(r.possible, 6);
      expect(r.percentage, closeTo(33.3333, 1e-4));
      expect(r.passed, isFalse);
    });

    test('bonus items award points to everyone; dropped items leave the total', () {
      final key = [
        const GradeKeyItem(questionNo: 1, correctMask: a),
        const GradeKeyItem(questionNo: 2, correctMask: b, mode: 'bonus'),
        const GradeKeyItem(questionNo: 3, correctMask: c, mode: 'dropped'),
      ];
      final r = grade(key: key, answers: {1: a, 2: 0, 3: d}, rules: const GradingRules());
      expect(r.questions.map((q) => q.outcome), [ItemOutcome.correct, ItemOutcome.bonus, ItemOutcome.dropped]);
      expect(r.earned, 2);
      expect(r.possible, 2);
      expect(r.percentage, 100);
      expect(r.correct, 2);
    });

    test('totals stay at zero unless negative totals are allowed', () {
      final key = keyOf([a, a], negative: 1);
      final answers = {1: b, 2: b};
      expect(grade(key: key, answers: answers, rules: const GradingRules()).earned, 0);
      final allowed = grade(key: key, answers: answers, rules: const GradingRules(allowNegativeTotal: true));
      expect(allowed.earned, -2);
      expect(allowed.percentage, -100);
    });

    test('decimal points add up exactly; pass mark is inclusive', () {
      final key = [
        for (var i = 1; i <= 3; i++) GradeKeyItem(questionNo: i, correctMask: a, points: i == 3 ? 0.2 : 0.1),
      ];
      final r = grade(key: key, answers: {1: a, 2: a, 3: a}, rules: const GradingRules(passingPercentage: 100));
      expect(r.earned, 0.4);
      expect(r.percentage, 100);
      expect(r.passed, isTrue);
    });

    test('a key with only dropped items scores 0 %', () {
      final r = grade(
        key: const [GradeKeyItem(questionNo: 1, correctMask: a, mode: 'dropped')],
        answers: {1: a},
        rules: const GradingRules(),
      );
      expect(r.possible, 0);
      expect(r.percentage, 0);
    });
  });

  group('analytics', () {
    test('score statistics', () {
      final s = scoreStats([50, 70, 80, 90, 100], passed: [false, false, true, true, true]);
      expect(s.count, 5);
      expect(s.mean, 78);
      expect(s.median, 80);
      expect(s.highest, 100);
      expect(s.lowest, 50);
      expect(s.passRate, 60);
      expect(s.stdDev, closeTo(17.2047, 1e-3)); // sqrt(1480 / 5)
      expect(s.histogram, [0, 0, 0, 0, 0, 1, 0, 1, 1, 2]);
      expect(scoreStats(const [], passed: const []).count, 0);
      expect(scoreStats([60, 70], passed: [true, true]).median, 65);
    });

    test('item difficulty, distractors and discrimination', () {
      final key = keyOf([a, b]);
      // 20 papers. Q1: the 10 best answer A, the 10 weakest answer C.
      // Q2: everyone answers B except two who leave it blank.
      final papers = [
        for (var i = 0; i < 20; i++)
          GradedPaper(
            percentage: 100.0 - i * 4,
            questions: grade(
              key: key,
              answers: {1: i < 10 ? a : c, 2: i < 18 ? b : 0},
              rules: const GradingRules(),
            ).questions,
          ),
      ];
      final stats = itemAnalysis(papers, key);
      expect(stats[0].difficulty, 0.5);
      expect(stats[0].choiceCounts, [10, 0, 10, 0, 0]);
      expect(stats[0].topDistractor, 2); // C
      expect(stats[0].discrimination, 1.0);
      expect(stats[0].difficultyLabel, 'Moderate');
      expect(stats[1].difficulty, 0.9);
      expect(stats[1].blank, 2);
      expect(stats[1].topDistractor, isNull);
      expect(stats[1].difficultyLabel, 'Easy');
    });

    test('discrimination needs at least 10 papers', () {
      final key = keyOf([a]);
      final papers = [
        for (var i = 0; i < 5; i++)
          GradedPaper(
            percentage: 100,
            questions: grade(key: key, answers: {1: a}, rules: const GradingRules()).questions,
          ),
      ];
      expect(itemAnalysis(papers, key).single.discrimination, isNull);
    });
  });
}
