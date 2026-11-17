import '../core/util/text.dart';

/// Ways of writing a student's name.
abstract final class Names {
  /// "Juan Dela Cruz Jr." — used on the calculator ("STUDENT: JUAN DELA CRUZ").
  static String natural(String first, String last, {String suffix = ''}) => cleanSpaces('$first $last $suffix');

  /// "Dela Cruz, Juan M. Jr." — lists and reports (sorted by last name).
  static String formal(String first, String last, {String middle = '', String suffix = ''}) {
    final m = cleanSpaces(middle);
    final initial = m.isEmpty ? '' : ' ${m[0].toUpperCase()}.';
    final s = cleanSpaces(suffix);
    return cleanSpaces('$last, $first$initial${s.isEmpty ? '' : ' $s'}');
  }

  /// "DELA CRUZ, Juan Miguel" — reports that need the complete name.
  static String complete(String first, String last, {String middle = '', String suffix = ''}) {
    final s = cleanSpaces(suffix);
    return cleanSpaces('${last.toUpperCase()}, $first $middle${s.isEmpty ? '' : ' $s'}');
  }
}
