import '../scoring/ratio.dart';
import 'default_scale.dart';

/// A grade-equivalent table (e.g. 1.00-5.00), applied to a final percentage.
class GradeScale {
  GradeScale({
    required this.id,
    required this.name,
    required List<ScaleItem> items,
    this.passingBp = 7500,
    this.roundBeforeLookup = true,
  }) : items = List.unmodifiable([...items]..sort((a, b) => b.minBp.compareTo(a.minBp)));

  factory GradeScale.defaultScale() => GradeScale(
    id: DefaultScale.id,
    name: DefaultScale.name,
    items: DefaultScale.items,
    passingBp: DefaultScale.passingBp,
  );

  final String id;
  final String name;

  /// Highest threshold first.
  final List<ScaleItem> items;
  final int passingBp;

  /// Round the percentage to a whole number (half up) before the lookup:
  /// 74.5 % → 75 % → 3.00.
  final bool roundBeforeLookup;

  /// The percentage the lookup uses, in basis points.
  Ratio lookupValue(Ratio percent) =>
      roundBeforeLookup ? Ratio.of(percent.roundHalfUp() * 100) : percent * Ratio.of(100);

  ScaleItem? equivalent(Ratio percent) {
    final v = lookupValue(percent);
    for (final item in items) {
      if (v >= Ratio.of(item.minBp)) return item;
    }
    return null;
  }

  bool passed(Ratio percent) => lookupValue(percent) >= Ratio.of(passingBp);

  /// Problems that would make the table ambiguous or incomplete.
  static List<String> validate(List<ScaleItem> items) {
    final problems = <String>[];
    if (items.isEmpty) problems.add('Add at least one grade.');
    final mins = items.map((i) => i.minBp).toList();
    if (mins.toSet().length != mins.length) problems.add('Two grades start at the same percentage.');
    if (items.isNotEmpty && !mins.contains(0)) problems.add('One grade must start at 0% (the lowest grade).');
    if (mins.any((m) => m < 0 || m > 10000)) problems.add('Percentages must be between 0 and 100.');
    if (items.any((i) => i.grade.trim().isEmpty)) problems.add('Every row needs a grade.');
    return problems;
  }
}
