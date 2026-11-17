/// One row of a grade-equivalent table.
class ScaleItem {
  const ScaleItem(this.minBp, this.grade, this.remark);

  /// Lowest percentage (inclusive) for this grade, in basis points (9700 = 97 %).
  final int minBp;
  final String grade;
  final String remark;
}

/// The default scale (owner's choice): 1.00-5.00, passing 75 %.
abstract final class DefaultScale {
  static const String id = 'scale-ph-1to5';
  static const String name = '1.00–5.00 (passing 75%)';
  static const int passingBp = 7500;

  static const List<ScaleItem> items = [
    ScaleItem(9700, '1.00', 'Excellent'),
    ScaleItem(9400, '1.25', 'Excellent'),
    ScaleItem(9100, '1.50', 'Very good'),
    ScaleItem(8800, '1.75', 'Very good'),
    ScaleItem(8500, '2.00', 'Good'),
    ScaleItem(8200, '2.25', 'Good'),
    ScaleItem(7900, '2.50', 'Satisfactory'),
    ScaleItem(7600, '2.75', 'Satisfactory'),
    ScaleItem(7500, '3.00', 'Passed'),
    ScaleItem(0, '5.00', 'Failed'),
  ];
}
