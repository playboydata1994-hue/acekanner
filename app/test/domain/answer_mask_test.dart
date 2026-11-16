import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/domain/answer_mask.dart';

void main() {
  test('bits, toggling, counting and formatting', () {
    expect(AnswerMask.bit(0), 1);
    expect(AnswerMask.bit(4), 16);
    expect(() => AnswerMask.bit(5), throwsRangeError);
    final ac = AnswerMask.toggle(AnswerMask.toggle(0, 0), 2);
    expect(ac, 5);
    expect(AnswerMask.count(ac), 2);
    expect(AnswerMask.format(ac), 'A/C');
    expect(AnswerMask.format(0), '');
    expect(AnswerMask.isValid(31), isTrue);
    expect(AnswerMask.isValid(32), isFalse);
  });

  test('parse accepts letters with separators, rejects others', () {
    expect(AnswerMask.parse('a'), 1);
    expect(AnswerMask.parse('A/C'), 5);
    expect(AnswerMask.parse('b, e'), 18);
    expect(() => AnswerMask.parse('F'), throwsFormatException);
  });

  group('parseSequence', () {
    test('plain letters fill from question 1; dashes skip', () {
      expect(
        AnswerMask.parseSequence('AB-d e', itemCount: 50),
        {1: 1, 2: 2, 4: 8, 5: 16},
      );
    });

    test('numbered pairs in any style', () {
      expect(
        AnswerMask.parseSequence('1A, 2. b 3) C 10-AE', itemCount: 50),
        {1: 1, 2: 2, 3: 4, 10: 17},
      );
    });

    test('too many answers, bad letters and bad numbers are errors', () {
      expect(
        () => AnswerMask.parseSequence('A' * 51, itemCount: 50),
        throwsFormatException,
      );
      expect(() => AnswerMask.parseSequence('ABX', itemCount: 50), throwsFormatException);
      expect(() => AnswerMask.parseSequence('51A', itemCount: 50), throwsFormatException);
      expect(() => AnswerMask.parseSequence('1A 1B', itemCount: 50), throwsFormatException);
      expect(() => AnswerMask.parseSequence('1A ??', itemCount: 50), throwsFormatException);
    });

    test('empty input sets nothing', () {
      expect(AnswerMask.parseSequence('   ', itemCount: 50), isEmpty);
    });
  });
}
