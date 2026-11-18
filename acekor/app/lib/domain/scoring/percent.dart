import 'ratio.dart';

/// Percentage = score ÷ maximum points × 100, exact.
Ratio percentOf(int score, int maxPoints) {
  if (maxPoints <= 0) throw ArgumentError('Maximum points must be positive');
  return Ratio.of(score * 100, maxPoints);
}

/// "84%" for whole numbers, otherwise two decimals: "87.50%", "33.33%".
/// Rounded half up.
String formatPercent(Ratio percent) {
  final hundredths = percent.roundScaled(2);
  final whole = hundredths ~/ BigInt.from(100);
  final frac = (hundredths % BigInt.from(100)).toInt();
  if (frac == 0) return '$whole%';
  return '$whole.${frac.toString().padLeft(2, '0')}%';
}

/// Percentage text for a score, e.g. 42/50 → "84%".
String scorePercentText(int score, int maxPoints) => formatPercent(percentOf(score, maxPoints));

/// "42/50".
String scoreText(int score, int maxPoints) => '$score/$maxPoints';

/// Basis points (7500) → "75%" / "37.50%".
String formatBp(int bp) => formatPercent(Ratio.of(bp, 100));
