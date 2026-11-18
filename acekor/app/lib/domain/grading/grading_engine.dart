import '../categories.dart';
import '../scoring/ratio.dart';
import 'default_scale.dart';
import 'grade_scale.dart';

/// How several activities of one category combine.
enum CombineMethod {
  /// Σ scores ÷ Σ maximum points (owner's default): bigger activities count more.
  totalPoints('total_points', 'Total points'),

  /// Mean of the activity percentages: every activity counts equally.
  averagePercent('average_percent', 'Average of percentages');

  const CombineMethod(this.code, this.label);
  final String code;
  final String label;

  static CombineMethod parse(String code) => code == averagePercent.code ? averagePercent : totalPoints;
}

class GradeCategory {
  const GradeCategory({required this.id, required this.name, required this.kind, required this.weightBp});
  final String id;
  final String name;
  final CategoryKind kind;

  /// 3000 = 30.00 %.
  final int weightBp;
}

class GradeActivity {
  const GradeActivity({required this.id, required this.categoryId, required this.maxPoints});
  final String id;
  final String categoryId;
  final int maxPoints;
}

class CategoryResult {
  const CategoryResult({
    required this.category,
    required this.activityCount,
    required this.missingCount,
    required this.earned,
    required this.possible,
    required this.percent,
  });

  final GradeCategory category;
  final int activityCount;

  /// Activities without a recorded score (counted as 0).
  final int missingCount;
  final int earned;
  final int possible;

  /// Category percentage, or null when the category has no activities yet.
  final Ratio? percent;

  bool get hasActivities => activityCount > 0;
  bool get counts => category.weightBp > 0;

  /// Category percentage × weight, in percentage points (88.33 % × 30 % = 26.50).
  Ratio? get contribution => percent == null ? null : percent! * Ratio.of(category.weightBp, 10000);
}

class StudentGrade {
  const StudentGrade({
    required this.categories,
    required this.weightsValid,
    required this.percent,
    required this.complete,
    required this.componentsCounted,
    required this.componentsWeighted,
    required this.equivalent,
    required this.passed,
  });

  final List<CategoryResult> categories;

  /// The weights total exactly 100 %.
  final bool weightsValid;

  /// Final weighted grade when [complete]; otherwise the running grade over
  /// the components that already have activities. Null when nothing can be
  /// computed yet (or the weights are invalid).
  final Ratio? percent;

  /// Every weighted component has at least one activity.
  final bool complete;
  final int componentsCounted;
  final int componentsWeighted;
  final ScaleItem? equivalent;
  final bool? passed;

  int get missingCount => categories.fold(0, (s, c) => s + c.missingCount);
}

/// The grading engine: category percentages, weighted contributions, final
/// weighted grade and grade equivalent. Pure and exact (see [Ratio]).
class GradingEngine {
  const GradingEngine({required this.categories, required this.method, this.scale});

  final List<GradeCategory> categories;
  final CombineMethod method;
  final GradeScale? scale;

  int get totalWeightBp => categories.fold(0, (s, c) => s + c.weightBp);
  bool get weightsValid => totalWeightBp == 10000;

  /// [scores]: activity id → points for one student (absent = not recorded).
  StudentGrade grade(List<GradeActivity> activities, Map<String, int> scores) {
    final results = <CategoryResult>[];
    final byCategory = <String, List<GradeActivity>>{};
    for (final a in activities) {
      byCategory.putIfAbsent(a.categoryId, () => []).add(a);
    }
    final known = {for (final c in categories) c.id};
    // Categories with activities but no weight row still appear (weight 0).
    final all = [
      ...categories,
      for (final id in byCategory.keys)
        if (!known.contains(id)) GradeCategory(id: id, name: id, kind: CategoryKind.exam, weightBp: 0),
    ];
    for (final c in all) {
      final acts = byCategory[c.id] ?? const <GradeActivity>[];
      var earned = 0, possible = 0, missing = 0;
      var sumPct = Ratio.zero;
      for (final a in acts) {
        final p = scores[a.id];
        if (p == null) missing++;
        earned += p ?? 0;
        possible += a.maxPoints;
        sumPct = sumPct + Ratio.of((p ?? 0) * 100, a.maxPoints);
      }
      Ratio? pct;
      if (acts.isNotEmpty) {
        pct = method == CombineMethod.totalPoints ? Ratio.of(earned * 100, possible) : sumPct / Ratio.of(acts.length);
      }
      results.add(
        CategoryResult(
          category: c,
          activityCount: acts.length,
          missingCount: missing,
          earned: earned,
          possible: possible,
          percent: pct,
        ),
      );
    }

    final weighted = results.where((r) => r.counts).toList();
    final counted = weighted.where((r) => r.hasActivities).toList();
    final complete = weighted.isNotEmpty && counted.length == weighted.length;
    Ratio? percent;
    if (weightsValid && counted.isNotEmpty) {
      final sum = counted.fold(Ratio.zero, (s, r) => s + r.contribution!);
      if (complete) {
        percent = sum;
      } else {
        final w = counted.fold(0, (s, r) => s + r.category.weightBp);
        percent = sum / Ratio.of(w, 10000);
      }
    }
    return StudentGrade(
      categories: results,
      weightsValid: weightsValid,
      percent: percent,
      complete: complete,
      componentsCounted: counted.length,
      componentsWeighted: weighted.length,
      equivalent: percent == null ? null : scale?.equivalent(percent),
      passed: percent == null || scale == null ? null : scale!.passed(percent),
    );
  }
}
