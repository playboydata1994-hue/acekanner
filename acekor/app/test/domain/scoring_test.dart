import 'package:acekor/domain/scoring/percent.dart';
import 'package:acekor/domain/scoring/ratio.dart';
import 'package:acekor/domain/scoring/score_entry.dart';
import 'package:flutter_test/flutter_test.dart';

ScoreEntry type(ScoreEntry e, String digits) {
  for (final d in digits.split('')) {
    e = e.press(int.parse(d)).entry;
  }
  return e;
}

void main() {
  group('percentage', () {
    test('owner examples', () {
      expect(scoreText(42, 50), '42/50');
      expect(scorePercentText(42, 50), '84%');
      expect(scorePercentText(35, 40), '87.50%');
      expect(scorePercentText(8, 10), '80%');
    });
    test('edges and rounding', () {
      expect(scorePercentText(0, 50), '0%');
      expect(scorePercentText(50, 50), '100%');
      expect(scorePercentText(1, 3), '33.33%');
      expect(scorePercentText(2, 3), '66.67%');
      expect(scorePercentText(1, 8), '12.50%');
      expect(scorePercentText(1, 200), '0.50%');
      expect(scorePercentText(1, 1000), '0.10%');
      expect(scorePercentText(999, 1000), '99.90%');
      // 1/16 = 6.25 exactly; 1/400 = 0.25.
      expect(scorePercentText(1, 16), '6.25%');
      expect(formatBp(7500), '75%');
      expect(formatBp(3750), '37.50%');
    });
    test('half-up at the second decimal', () {
      // 0.125 % → 0.13 %
      expect(formatPercent(Ratio.of(1, 8)), '0.13%');
      expect(Ratio.of(149, 2).roundHalfUp(), 75); // 74.5 → 75
      expect(Ratio.of(1489, 20).roundHalfUp(), 74); // 74.45 → 74
    });
  });

  group('keypad entry', () {
    test('multi-digit', () {
      final e = type(const ScoreEntry.empty(50), '42');
      expect(e.value, 42);
      expect(e.digits, '42');
    });
    test('refuses a score above the maximum and keeps the old value', () {
      var e = type(const ScoreEntry.empty(50), '4');
      final r = e.press(2);
      expect(r.rejected, isNull);
      e = r.entry;
      final over = e.press(0); // 420 > 50
      expect(over.rejected, EntryRejection.aboveMaximum);
      expect(over.entry.value, 42);
      expect(const ScoreEntry.empty(50).press(9).entry.press(9).rejected, EntryRejection.aboveMaximum);
    });
    test('exactly the maximum is allowed', () {
      expect(type(const ScoreEntry.empty(50), '50').value, 50);
      expect(type(const ScoreEntry.empty(1000), '1000').value, 1000);
    });
    test('leading zero is replaced', () {
      var e = type(const ScoreEntry.empty(50), '0');
      expect(e.value, 0);
      e = e.press(7).entry;
      expect(e.digits, '7');
      expect(type(const ScoreEntry.empty(50), '00').digits, '0');
    });
    test('backspace', () {
      var e = type(const ScoreEntry.empty(50), '42');
      e = e.backspace().entry;
      expect(e.value, 4);
      e = e.backspace().entry;
      expect(e.isEmpty, isTrue);
      expect(e.value, isNull);
      final r = e.backspace();
      expect(r.rejected, EntryRejection.empty);
      expect(r.entry.isEmpty, isTrue);
    });
    test('changing the activity keeps a score that still fits', () {
      final e = type(const ScoreEntry.empty(50), '42');
      expect(e.withMaximum(100).value, 42);
      expect(e.withMaximum(40).isEmpty, isTrue);
    });
  });
}
