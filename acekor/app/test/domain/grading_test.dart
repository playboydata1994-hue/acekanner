import 'package:acekor/domain/categories.dart';
import 'package:acekor/domain/grading/grade_scale.dart';
import 'package:acekor/domain/grading/grading_engine.dart';
import 'package:acekor/domain/scoring/percent.dart';
import 'package:acekor/domain/scoring/ratio.dart';
import 'package:flutter_test/flutter_test.dart';

const quiz = GradeCategory(id: 'quiz', name: 'Quiz', kind: CategoryKind.quiz, weightBp: 3000);
const rec = GradeCategory(id: 'recitation', name: 'Recitation', kind: CategoryKind.recitation, weightBp: 2000);
const mid = GradeCategory(id: 'midterm', name: 'Midterm', kind: CategoryKind.exam, weightBp: 2000);
const fin = GradeCategory(id: 'final', name: 'Final', kind: CategoryKind.exam, weightBp: 2000);
const prac = GradeCategory(id: 'practical', name: 'Practical', kind: CategoryKind.exam, weightBp: 1000);

const acts = [
  GradeActivity(id: 'q1', categoryId: 'quiz', maxPoints: 10),
  GradeActivity(id: 'q2', categoryId: 'quiz', maxPoints: 50),
  GradeActivity(id: 'r1', categoryId: 'recitation', maxPoints: 10),
  GradeActivity(id: 'm', categoryId: 'midterm', maxPoints: 100),
  GradeActivity(id: 'f', categoryId: 'final', maxPoints: 100),
  GradeActivity(id: 'p', categoryId: 'practical', maxPoints: 50),
];

void main() {
  final scale = GradeScale.defaultScale();

  test('owner example: total points vs average of percentages', () {
    const scores = {'q1': 8, 'q2': 45};
    final total = const GradingEngine(
      categories: [quiz],
      method: CombineMethod.totalPoints,
    ).grade(acts.where((a) => a.categoryId == 'quiz').toList(), scores);
    expect(formatPercent(total.categories.first.percent!), '88.33%'); // 53/60
    final avg = const GradingEngine(
      categories: [quiz],
      method: CombineMethod.averagePercent,
    ).grade(acts.where((a) => a.categoryId == 'quiz').toList(), scores);
    expect(formatPercent(avg.categories.first.percent!), '85%');
  });

  test('weighted contribution and final weighted grade', () {
    final engine = GradingEngine(
      categories: const [quiz, rec, mid, fin, prac],
      method: CombineMethod.totalPoints,
      scale: scale,
    );
    expect(engine.weightsValid, isTrue);
    final g = engine.grade(acts, const {'q1': 8, 'q2': 45, 'r1': 8, 'm': 80, 'f': 90, 'p': 45});
    // quiz 53/60 = 88.33 × 30% = 26.50; rec 80 × 20% = 16; mid 80 × 20% = 16;
    // final 90 × 20% = 18; practical 90 × 10% = 9 → 85.50
    final quizR = g.categories.firstWhere((c) => c.category.id == 'quiz');
    expect(formatPercent(quizR.contribution!), '26.50%');
    expect(g.complete, isTrue);
    expect(formatPercent(g.percent!), '85.50%');
    // 85.5 rounds to 86 → 2.00
    expect(g.equivalent!.grade, '2.00');
    expect(g.passed, isTrue);
  });

  test('missing scores count as zero and are reported', () {
    final engine = GradingEngine(categories: const [quiz], method: CombineMethod.totalPoints);
    final g = engine.grade(
      const [
        GradeActivity(id: 'q1', categoryId: 'quiz', maxPoints: 10),
        GradeActivity(id: 'q2', categoryId: 'quiz', maxPoints: 10),
      ],
      const {'q1': 10},
    );
    expect(g.categories.first.missingCount, 1);
    expect(formatPercent(g.categories.first.percent!), '50%');
  });

  test('weights must total 100%', () {
    final g = const GradingEngine(
      categories: [quiz, rec],
      method: CombineMethod.totalPoints,
    ).grade(acts, const {'q1': 10});
    expect(g.weightsValid, isFalse);
    expect(g.percent, isNull);
  });

  test('running grade while some components have no activities', () {
    final engine = GradingEngine(
      categories: const [quiz, rec, mid, fin, prac],
      method: CombineMethod.totalPoints,
      scale: scale,
    );
    final g = engine.grade(
      const [
        GradeActivity(id: 'q1', categoryId: 'quiz', maxPoints: 10),
        GradeActivity(id: 'r1', categoryId: 'recitation', maxPoints: 10),
      ],
      const {'q1': 9, 'r1': 7},
    );
    // (90 × 30 + 70 × 20) / 50 = 82
    expect(g.complete, isFalse);
    expect(g.componentsCounted, 2);
    expect(g.componentsWeighted, 5);
    expect(formatPercent(g.percent!), '82%');
  });

  test('grade scale boundaries', () {
    expect(scale.equivalent(Ratio.of(97))!.grade, '1.00');
    expect(scale.equivalent(Ratio.of(9649, 100))!.grade, '1.25'); // 96.49 → 96
    expect(scale.equivalent(Ratio.of(965, 10))!.grade, '1.00'); // 96.5 → 97
    expect(scale.equivalent(Ratio.of(75))!.grade, '3.00');
    expect(scale.equivalent(Ratio.of(149, 2))!.grade, '3.00'); // 74.5 → 75
    expect(scale.equivalent(Ratio.of(7449, 100))!.grade, '5.00');
    expect(scale.passed(Ratio.of(7449, 100)), isFalse);
    expect(scale.equivalent(Ratio.zero)!.grade, '5.00');
    final exact = GradeScale(id: 'x', name: 'x', items: scale.items, roundBeforeLookup: false);
    expect(exact.equivalent(Ratio.of(149, 2))!.grade, '5.00');
  });

  test('scale validation', () {
    expect(GradeScale.validate(scale.items), isEmpty);
    expect(GradeScale.validate(scale.items.where((i) => i.minBp != 0).toList()), isNotEmpty);
  });
}
