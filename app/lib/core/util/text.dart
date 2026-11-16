/// Trims and collapses runs of whitespace to single spaces.
String cleanSpaces(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Trimmed value, or null when blank.
String? blankToNull(String? value) {
  final v = value == null ? '' : cleanSpaces(value);
  return v.isEmpty ? null : v;
}
