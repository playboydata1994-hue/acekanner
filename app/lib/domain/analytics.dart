import 'dart:math';

import 'answer_mask.dart';
import 'grading.dart';

/// Class-level score statistics.
class ScoreStats {
  const ScoreStats({
    required this.count,
    required this.mean,
    required this.median,
    required this.stdDev,
    required this.highest,
    required this.lowest,
    required this.passed,
    required this.histogram,
  });

  static const ScoreStats empty =
      ScoreStats(count: 0, mean: 0, median: 0, stdDev: 0, highest: 0, lowest: 0, passed: 0, histogram: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);

  final int count;

  /// Percentages.
  final double mean;
  final double median;

  /// Population standard deviation of the percentages.
  final double stdDev;
  final double highest;
  final double lowest;
  final int passed;

  /// Papers per 10-point band: [0–9.99, 10–19.99, …, 90–100].
  final List<int> histogram;

  double get passRate => count == 0 ? 0 : passed / count * 100;
}

ScoreStats scoreStats(List<double> percentages, {required List<bool> passed}) {
  if (percentages.isEmpty) return ScoreStats.empty;
  final sorted = [...percentages]..sort();
  final n = sorted.length;
  final mean = sorted.reduce((a, b) => a + b) / n;
  final median = n.isOdd ? sorted[n ~/ 2] : (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
  final variance = sorted.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / n;
  final histogram = List<int>.filled(10, 0);
  for (final v in sorted) {
    histogram[(v.clamp(0, 100) / 10).floor().clamp(0, 9)]++;
  }
  return ScoreStats(
    count: n,
    mean: mean,
    median: median,
    stdDev: sqrt(variance),
    highest: sorted.last,
    lowest: sorted.first,
    passed: passed.where((p) => p).length,
    histogram: histogram,
  );
}

/// One graded paper, as item analysis needs it.
class GradedPaper {
  const GradedPaper({required this.percentage, required this.questions});

  final double percentage;
  final List<QuestionGrade> questions;
}

class ItemStat {
  const ItemStat({
    required this.questionNo,
    required this.correctMask,
    required this.mode,
    required this.takers,
    required this.correct,
    required this.blank,
    required this.multiple,
    required this.choiceCounts,
    required this.difficulty,
    required this.discrimination,
    required this.topDistractor,
  });

  final int questionNo;
  final int correctMask;
  final String mode;

  /// Papers that contain this item.
  final int takers;
  final int correct;
  final int blank;
  final int multiple;

  /// How many single answers chose A..E.
  final List<int> choiceCounts;

  /// Proportion answering correctly (0–1). Higher = easier.
  final double difficulty;

  /// Upper-group minus lower-group proportion correct (−1..1), using the top
  /// and bottom 27 % of papers by total score. Null with fewer than 10 papers.
  final double? discrimination;

  /// Most-chosen wrong answer (choice index), if any.
  final int? topDistractor;

  bool get scored => mode == 'normal';

  String get difficultyLabel => difficulty >= 0.8
      ? 'Easy'
      : difficulty >= 0.3
          ? 'Moderate'
          : 'Difficult';
}

/// Item analysis for papers answered with the same answer key (one exam set).
List<ItemStat> itemAnalysis(List<GradedPaper> papers, List<GradeKeyItem> key) {
  final n = papers.length;
  final ranked = [...papers]..sort((a, b) => b.percentage.compareTo(a.percentage));
  final groupSize = n >= 10 ? (n * 0.27).round() : 0;
  final upper = ranked.take(groupSize).toList();
  final lower = ranked.reversed.take(groupSize).toList();

  double share(List<GradedPaper> group, int q) {
    if (group.isEmpty) return 0;
    final right = group.where((p) => _outcome(p, q) == ItemOutcome.correct).length;
    return right / group.length;
  }

  return [
    for (final item in key)
      () {
        final q = item.questionNo;
        final counts = List<int>.filled(5, 0);
        var correct = 0, blank = 0, multiple = 0;
        for (final p in papers) {
          final g = p.questions.firstWhere((x) => x.questionNo == q);
          switch (g.outcome) {
            case ItemOutcome.correct:
              correct++;
            case ItemOutcome.blank:
              blank++;
            case ItemOutcome.multiple:
              multiple++;
            case ItemOutcome.bonus || ItemOutcome.dropped || ItemOutcome.incorrect:
              break;
          }
          if (AnswerMask.count(g.answerMask) == 1 && g.answerMask != AnswerMask.markedWrong) {
            counts[AnswerMask.labels.indexOf(AnswerMask.format(g.answerMask))]++;
          }
        }
        int? distractor;
        var best = 0;
        for (var c = 0; c < 5; c++) {
          if (!AnswerMask.has(item.correctMask, c) && counts[c] > best) {
            best = counts[c];
            distractor = c;
          }
        }
        return ItemStat(
          questionNo: q,
          correctMask: item.correctMask,
          mode: item.mode,
          takers: n,
          correct: correct,
          blank: blank,
          multiple: multiple,
          choiceCounts: counts,
          difficulty: n == 0 ? 0 : correct / n,
          discrimination: groupSize == 0 ? null : share(upper, q) - share(lower, q),
          topDistractor: distractor,
        );
      }(),
  ];
}

ItemOutcome _outcome(GradedPaper p, int q) => p.questions.firstWhere((x) => x.questionNo == q).outcome;
