import 'package:material_ui/material_ui.dart';

/// ACEkor palette: black calculator, white digits, dark-gray round keys,
/// teal-green save key, red backspace. High contrast throughout.
abstract final class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceHigh = Color(0xFF1C1C1E);
  static const Color key = Color(0xFF2A2A2C);
  static const Color keyPressed = Color(0xFF3A3A3D);
  static const Color white = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFA1A1A6);
  static const Color faint = Color(0xFF6E6E73);
  static const Color outline = Color(0xFF3A3A3C);

  /// Save / confirm.
  static const Color save = Color(0xFF13A57C);
  static const Color savePressed = Color(0xFF0E8A67);

  /// Accent for links and selected items.
  static const Color teal = Color(0xFF2CC5A0);

  /// Backspace and destructive actions.
  static const Color red = Color(0xFFFF5A52);
  static const Color amber = Color(0xFFFFB020);

  // Light theme (management screens only, when chosen)
  static const Color lightBackground = Color(0xFFF7F7F8);
  static const Color tealDark = Color(0xFF087F63);
}
