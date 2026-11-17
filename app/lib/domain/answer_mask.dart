import '../core/constants.dart';

/// Answers are stored as bitmasks: A = 1, B = 2, C = 4, D = 8, E = 16.
abstract final class AnswerMask {
  static const List<String> labels = AppConstants.choiceLabels;
  static const int all = 31;

  static int bit(int choiceIndex) {
    RangeError.checkValueInInterval(choiceIndex, 0, labels.length - 1);
    return 1 << choiceIndex;
  }

  static bool has(int mask, int choiceIndex) => mask & (1 << choiceIndex) != 0;

  static int toggle(int mask, int choiceIndex) => mask ^ bit(choiceIndex);

  static int count(int mask) {
    var n = 0;
    for (var m = mask; m != 0; m &= m - 1) {
      n++;
    }
    return n;
  }

  static bool isValid(int mask) => mask >= 0 && mask <= all;

  /// Final answer meaning "counted wrong by the instructor" (an unclear or
  /// double-shaded answer the instructor rejected). Never part of a key; stored
  /// only as a student's final answer and always scored as a wrong answer.
  static const int markedWrong = 32;

  /// A student's final answer: a choice mask (0 = no answer) or [markedWrong].
  static bool isValidAnswer(int mask) => isValid(mask) || mask == markedWrong;

  /// How a student's final answer is shown: "A", "A/C", "—" (no answer) or
  /// "✗" (counted wrong).
  static String describe(int mask) => switch (mask) {
        0 => '—',
        markedWrong => '✗',
        _ => format(mask),
      };

  /// "A", "A/C", or "" for no answer.
  static String format(int mask) => [
        for (var i = 0; i < labels.length; i++)
          if (has(mask, i)) labels[i],
      ].join('/');

  /// Parses letters such as "A", "ac", "A/C" or "A,C" into a mask.
  static int parse(String text) {
    var mask = 0;
    for (final rune in text.toUpperCase().runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '/' || ch == ',' || ch == ' ') continue;
      final index = labels.indexOf(ch);
      if (index < 0) throw FormatException('"$ch" is not a choice from A to E');
      mask |= 1 << index;
    }
    return mask;
  }

  /// Parses quick answer-key entry into question → mask.
  ///
  /// Accepts either a plain sequence, one letter per question starting at 1
  /// ("ABCDA EBCDA…", spaces and commas ignored, "-" or "?" skips a question),
  /// or numbered pairs ("1A 2B 3C", "1. A, 2) B", "10-AC").
  static Map<int, int> parseSequence(String input, {required int itemCount}) {
    final text = input.trim();
    if (text.isEmpty) return const {};
    final result = <int, int>{};

    if (RegExp(r'\d').hasMatch(text)) {
      final pair = RegExp(r'(\d+)\s*[.):\-]?\s*([A-Za-z]+)');
      final consumed = text.replaceAll(pair, '').replaceAll(RegExp(r'[\s,;]'), '');
      if (consumed.isNotEmpty) {
        throw FormatException('Could not read "$consumed". Use pairs like 1A 2B 3C.');
      }
      for (final m in pair.allMatches(text)) {
        final q = int.parse(m.group(1)!);
        if (q < 1 || q > itemCount) {
          throw FormatException('Question $q is outside 1–$itemCount.');
        }
        if (result.containsKey(q)) {
          throw FormatException('Question $q appears more than once.');
        }
        result[q] = parse(m.group(2)!);
      }
      return result;
    }

    final letters = text.replaceAll(RegExp(r'[\s,;]'), '').toUpperCase();
    if (letters.length > itemCount) {
      throw FormatException(
        '${letters.length} answers entered but the exam has $itemCount items.',
      );
    }
    for (var i = 0; i < letters.length; i++) {
      final ch = letters[i];
      if (ch == '-' || ch == '?' || ch == '_') continue;
      final index = labels.indexOf(ch);
      if (index < 0) {
        throw FormatException('"$ch" at position ${i + 1} is not a choice from A to E.');
      }
      result[i + 1] = 1 << index;
    }
    return result;
  }
}
