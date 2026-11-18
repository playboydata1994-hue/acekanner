import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Text sizes the instructor can choose (Settings › Text size).
enum TextSize {
  normal('normal', 'Normal', 1.0),
  large('large', 'Large', 1.15),
  extraLarge('xlarge', 'Extra large', 1.3);

  const TextSize(this.code, this.label, this.factor);
  final String code;
  final String label;
  final double factor;

  static TextSize parse(String? code) =>
      TextSize.values.firstWhere((t) => t.code == code, orElse: () => TextSize.normal);
}

/// Bundled Roboto, so every screen and report looks the same on every phone.
const String _font = 'Roboto';

abstract final class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.teal, brightness: Brightness.dark).copyWith(
      primary: AppColors.teal,
      onPrimary: AppColors.black,
      secondary: AppColors.save,
      surface: AppColors.surface,
      onSurface: AppColors.white,
      surfaceContainerHighest: AppColors.surfaceHigh,
      error: AppColors.red,
      outline: AppColors.outline,
    );
    return _base(scheme, AppColors.black);
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.tealDark,
      brightness: Brightness.light,
    ).copyWith(primary: AppColors.tealDark, secondary: AppColors.save);
    return _base(scheme, AppColors.lightBackground);
  }

  static ThemeData _base(ColorScheme scheme, Color background) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: _font);
    final text = base.textTheme.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: text.copyWith(
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 18),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 16),
        titleMedium: text.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 22),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        titleTextStyle: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w500),
        subtitleTextStyle: TextStyle(fontFamily: _font, fontSize: 15),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(fontFamily: _font, fontSize: 17),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: TextStyle(fontFamily: _font, fontSize: 17),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline.withValues(alpha: 0.5), space: 1),
    );
  }
}
