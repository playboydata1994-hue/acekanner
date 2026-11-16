/// Student numbers as schools write them ("2021-00123") and as ACEkanner
/// matches them (normalized key "202100123").
abstract final class StudentNumber {
  static final RegExp _allowed = RegExp(r'^[A-Za-z0-9][A-Za-z0-9 \-./]*$');

  /// Upper-case letters and digits only.
  static String normalize(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Error message, or null when valid.
  static String? validate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Enter the student number';
    if (value.length > 30) return 'Use at most 30 characters';
    if (!_allowed.hasMatch(value)) {
      return 'Use letters, digits, spaces, "-", "." or "/" only';
    }
    if (normalize(value).isEmpty) return 'Enter the student number';
    return null;
  }

  /// Whether students can shade this number in the digit grid on the sheet.
  /// Numbers with letters can still be scanned on personalized (QR) sheets.
  static bool isShadeable(String key, {required int gridDigits}) =>
      RegExp(r'^\d+$').hasMatch(key) && key.length <= gridDigits;

  /// Validates a school's number format such as "####-#####" ('#' = digit).
  static String? validateFormat(String format) {
    final f = format.trim();
    if (f.isEmpty) return 'Enter a format such as ####-#####';
    if (!RegExp(r'^[# \-./]+$').hasMatch(f)) {
      return 'Use # for each digit and -, space, . or / as separators';
    }
    final digits = digitsIn(f);
    if (digits < 4 || digits > 12) return 'Use between 4 and 12 digits (#)';
    return null;
  }

  static int digitsIn(String format) => '#'.allMatches(format).length;

  /// Formats shaded digits for display ("202100123" + "####-#####" →
  /// "2021-00123"). Returns [digits] unchanged if the count does not match.
  static String applyFormat(String digits, String format) {
    if (digits.length != digitsIn(format)) return digits;
    final out = StringBuffer();
    var i = 0;
    for (final ch in format.split('')) {
      out.write(ch == '#' ? digits[i++] : ch);
    }
    return out.toString();
  }
}
