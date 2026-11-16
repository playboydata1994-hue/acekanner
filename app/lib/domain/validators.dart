/// Form validators. Each returns an error message, or null when valid.
abstract final class Validators {
  static String? required(String? value, String label, {int max = 160}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter the $label';
    if (v.length > max) return 'Use at most $max characters';
    return null;
  }

  static String? optional(String? value, {int max = 160}) {
    final v = value?.trim() ?? '';
    if (v.length > max) return 'Use at most $max characters';
    return null;
  }

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length > 254 || !_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? code(String? value, String label) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter the $label';
    if (v.length > 30) return 'Use at most 30 characters';
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9 \-._/]*$').hasMatch(v)) {
      return 'Use letters, digits, spaces and - . _ /';
    }
    return null;
  }

  /// Number within [min, max]; empty is allowed when [allowEmpty].
  static String? number(
    String? value, {
    required double min,
    required double max,
    bool allowEmpty = false,
    String label = 'a number',
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return allowEmpty ? null : 'Enter $label';
    final n = double.tryParse(v);
    if (n == null || n.isNaN) return 'Enter $label';
    if (n < min || n > max) return 'Enter a value from ${_fmt(min)} to ${_fmt(max)}';
    return null;
  }

  /// School year such as "2026-2027" (optional).
  static String? schoolYear(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final m = RegExp(r'^(\d{4})\s*-\s*(\d{4})$').firstMatch(v);
    if (m == null) return 'Use the form 2026-2027';
    final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
    if (b != a + 1) return 'The second year must follow the first';
    return null;
  }

  static String _fmt(double n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();
}
