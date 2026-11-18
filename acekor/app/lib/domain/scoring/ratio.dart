/// An exact fraction. Scores, percentages and weighted grades are computed
/// with exact fractions so a grade at a boundary (exactly 75 %) can never be
/// pushed to the wrong side by floating-point error. Rounding happens only
/// when a value is displayed or looked up in a grade scale.
class Ratio implements Comparable<Ratio> {
  Ratio._(this.numerator, this.denominator);

  factory Ratio(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) throw ArgumentError('Denominator is zero');
    if (denominator.isNegative) {
      numerator = -numerator;
      denominator = -denominator;
    }
    final g = numerator.gcd(denominator);
    if (g > BigInt.one) {
      numerator = numerator ~/ g;
      denominator = denominator ~/ g;
    }
    return Ratio._(numerator, denominator);
  }

  factory Ratio.of(int numerator, [int denominator = 1]) => Ratio(BigInt.from(numerator), BigInt.from(denominator));

  static final Ratio zero = Ratio.of(0);
  static final Ratio hundred = Ratio.of(100);

  final BigInt numerator;
  final BigInt denominator;

  Ratio operator +(Ratio o) =>
      Ratio(numerator * o.denominator + o.numerator * denominator, denominator * o.denominator);
  Ratio operator -(Ratio o) =>
      Ratio(numerator * o.denominator - o.numerator * denominator, denominator * o.denominator);
  Ratio operator *(Ratio o) => Ratio(numerator * o.numerator, denominator * o.denominator);
  Ratio operator /(Ratio o) => Ratio(numerator * o.denominator, denominator * o.numerator);

  bool get isZero => numerator == BigInt.zero;

  double toDouble() => numerator / denominator;

  /// Rounded half up to [decimals] places, scaled by 10^decimals
  /// (e.g. 87.5 with decimals 2 → 8750). Values here are never negative.
  BigInt roundScaled(int decimals) {
    final scale = BigInt.from(10).pow(decimals);
    final two = BigInt.two;
    final n = numerator * scale * two + denominator;
    final d = denominator * two;
    final q = n ~/ d;
    // ~/ truncates toward zero; for negative values floor instead.
    return (n.isNegative && q * d != n) ? q - BigInt.one : q;
  }

  /// Whole number, rounded half up (74.5 → 75).
  int roundHalfUp() => roundScaled(0).toInt();

  @override
  int compareTo(Ratio other) => (numerator * other.denominator).compareTo(other.numerator * denominator);

  bool operator >=(Ratio o) => compareTo(o) >= 0;
  bool operator <(Ratio o) => compareTo(o) < 0;

  @override
  bool operator ==(Object other) => other is Ratio && numerator == other.numerator && denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => '$numerator/$denominator';
}
