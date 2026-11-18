import '../../core/util/text.dart';

/// What the search engine needs to know about a student.
class SearchableStudent {
  const SearchableStudent({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName = '',
    this.suffix = '',
    this.studentNo,
    this.sectionName,
  });

  final String id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String suffix;
  final String? studentNo;
  final String? sectionName;
}

class SearchHit {
  const SearchHit(this.student, this.rank);
  final SearchableStudent student;

  /// Lower is better.
  final int rank;
}

/// Offline student search over the local roster.
///
/// Matches first, middle and last names, the complete name, partial names and
/// the student ID; ignores case and accents ("pena" finds "Peña"). Results
/// whose first name starts with the query come first, then last name, then
/// other name parts, then partial matches inside a name, then student IDs.
class StudentSearch {
  StudentSearch(Iterable<SearchableStudent> students) : _entries = [for (final s in students) _Entry(s)];

  final List<_Entry> _entries;

  int get size => _entries.length;

  List<SearchHit> search(String query, {int limit = 8}) {
    final q = foldForSearch(cleanSpaces(query));
    if (q.isEmpty) return const [];
    final qTokens = q.split(' ');
    final qDigits = q.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final hits = <SearchHit>[];
    for (final e in _entries) {
      final rank = e.rank(q, qTokens, qDigits);
      if (rank != null) hits.add(SearchHit(e.student, rank));
    }
    hits.sort((a, b) {
      final r = a.rank.compareTo(b.rank);
      if (r != 0) return r;
      final l = foldForSearch(a.student.lastName).compareTo(foldForSearch(b.student.lastName));
      if (l != 0) return l;
      return foldForSearch(a.student.firstName).compareTo(foldForSearch(b.student.firstName));
    });
    return hits.length > limit ? hits.sublist(0, limit) : hits;
  }
}

class _Entry {
  _Entry(this.student)
    : first = _words(student.firstName),
      middle = _words(student.middleName),
      last = _words(student.lastName),
      suffix = _words(student.suffix),
      full = foldForSearch(
        cleanSpaces('${student.firstName} ${student.middleName} ${student.lastName} ${student.suffix}'),
      ),
      fullLastFirst = foldForSearch(cleanSpaces('${student.lastName} ${student.firstName} ${student.middleName}')),
      number = (student.studentNo ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  final SearchableStudent student;
  final List<String> first;
  final List<String> middle;
  final List<String> last;
  final List<String> suffix;
  final String full;
  final String fullLastFirst;
  final String number;

  static List<String> _words(String s) =>
      foldForSearch(cleanSpaces(s.replaceAll(',', ' '))).split(' ').where((w) => w.isNotEmpty).toList();

  List<String> get _all => [...first, ...middle, ...last, ...suffix];

  int? rank(String q, List<String> qTokens, String qDigits) {
    final plain = q.replaceAll(',', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (plain == full || plain == fullLastFirst) return 0;

    // Every query word must start some word of the name.
    final words = _all;
    final tokens = plain.split(' ').where((t) => t.isNotEmpty).toList();
    final allPrefix = tokens.every((t) => words.any((w) => w.startsWith(t)));
    if (allPrefix) {
      final t0 = tokens.first;
      if (first.isNotEmpty && first.first.startsWith(t0)) return 1;
      if (last.isNotEmpty && last.first.startsWith(t0)) return 2;
      return 3;
    }
    if (full.startsWith(plain) || fullLastFirst.startsWith(plain)) return 3;
    if (plain.length >= 2 && (full.contains(plain) || fullLastFirst.contains(plain))) return 4;
    if (qDigits.isNotEmpty && number.isNotEmpty && number.contains(qDigits) && RegExp(r'[0-9]').hasMatch(qDigits)) {
      return number.startsWith(qDigits) ? 5 : 6;
    }
    return null;
  }
}
