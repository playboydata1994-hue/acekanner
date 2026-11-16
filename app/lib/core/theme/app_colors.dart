import 'package:material_ui/material_ui.dart';

/// Brand palette. Use [Theme.of] / [AcekannerColors] in widgets; these raw
/// values are for the theme builder, icons and generated documents.
abstract final class BrandColors {
  static const Color blue = Color(0xFF1D4ED8);
  static const Color navy = Color(0xFF172554);
  static const Color amber = Color(0xFFF59E0B);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color night = Color(0xFF0B1220);
}

/// Semantic colors for grading states, available in light and dark themes via
/// `Theme.of(context).extension<AcekannerColors>()!`.
@immutable
class AcekannerColors extends ThemeExtension<AcekannerColors> {
  const AcekannerColors({
    required this.correct,
    required this.incorrect,
    required this.uncertain,
    required this.blank,
    required this.premium,
    required this.onStatus,
  });

  static const AcekannerColors light = AcekannerColors(
    correct: Color(0xFF15803D),
    incorrect: Color(0xFFB91C1C),
    uncertain: Color(0xFFB45309),
    blank: Color(0xFF64748B),
    premium: Color(0xFFB45309),
    onStatus: Color(0xFFFFFFFF),
  );

  static const AcekannerColors dark = AcekannerColors(
    correct: Color(0xFF4ADE80),
    incorrect: Color(0xFFF87171),
    uncertain: Color(0xFFFBBF24),
    blank: Color(0xFF94A3B8),
    premium: Color(0xFFFBBF24),
    onStatus: Color(0xFF0B1220),
  );

  /// Answer matches the key.
  final Color correct;

  /// Answer does not match the key, or multiple marks.
  final Color incorrect;

  /// Needs instructor review.
  final Color uncertain;

  /// No answer.
  final Color blank;

  /// Premium plan accents.
  final Color premium;

  /// Text/icons drawn on a solid status color.
  final Color onStatus;

  @override
  AcekannerColors copyWith({
    Color? correct,
    Color? incorrect,
    Color? uncertain,
    Color? blank,
    Color? premium,
    Color? onStatus,
  }) {
    return AcekannerColors(
      correct: correct ?? this.correct,
      incorrect: incorrect ?? this.incorrect,
      uncertain: uncertain ?? this.uncertain,
      blank: blank ?? this.blank,
      premium: premium ?? this.premium,
      onStatus: onStatus ?? this.onStatus,
    );
  }

  @override
  AcekannerColors lerp(AcekannerColors? other, double t) {
    if (other == null) return this;
    return AcekannerColors(
      correct: Color.lerp(correct, other.correct, t)!,
      incorrect: Color.lerp(incorrect, other.incorrect, t)!,
      uncertain: Color.lerp(uncertain, other.uncertain, t)!,
      blank: Color.lerp(blank, other.blank, t)!,
      premium: Color.lerp(premium, other.premium, t)!,
      onStatus: Color.lerp(onStatus, other.onStatus, t)!,
    );
  }
}

extension AcekannerThemeX on BuildContext {
  AcekannerColors get statusColors =>
      Theme.of(this).extension<AcekannerColors>() ?? AcekannerColors.light;
}
