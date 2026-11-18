/// Trims and collapses runs of whitespace to single spaces.
String cleanSpaces(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Trimmed value, or null when blank.
String? blankToNull(String? value) {
  final v = value == null ? '' : cleanSpaces(value);
  return v.isEmpty ? null : v;
}

const Map<String, String> _folds = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
  'ý': 'y',
  'ÿ': 'y',
};

/// Lower-case, accent-free form for searching ("Peña" → "pena").
String foldForSearch(String value) {
  final lower = value.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    out.write(_folds[ch] ?? ch);
  }
  return out.toString();
}

/// Student ID normalized for duplicate detection: upper-case letters and
/// digits only ("2021-00123" → "202100123"). Null when nothing is left.
String? studentNoKey(String? studentNo) {
  if (studentNo == null) return null;
  final key = studentNo.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  return key.isEmpty ? null : key;
}
