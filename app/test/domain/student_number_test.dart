import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/domain/short_code.dart';
import 'package:acekanner/domain/student_number.dart';
import 'package:acekanner/domain/validators.dart';

void main() {
  test('normalizes to upper-case letters and digits', () {
    expect(StudentNumber.normalize(' 2021-00123 '), '202100123');
    expect(StudentNumber.normalize('c-21.0045'), 'C210045');
  });

  test('validates student numbers', () {
    expect(StudentNumber.validate('2021-00123'), isNull);
    expect(StudentNumber.validate(''), isNotNull);
    expect(StudentNumber.validate('2021_00123'), isNotNull);
    expect(StudentNumber.validate('1' * 31), isNotNull);
  });

  test('shadeable only when digits fit the grid', () {
    expect(StudentNumber.isShadeable('202100123', gridDigits: 10), isTrue);
    expect(StudentNumber.isShadeable('C210045', gridDigits: 10), isFalse);
    expect(StudentNumber.isShadeable('12345678901', gridDigits: 10), isFalse);
  });

  test('school formats', () {
    expect(StudentNumber.validateFormat('####-#####'), isNull);
    expect(StudentNumber.digitsIn('####-#####'), 9);
    expect(StudentNumber.validateFormat('###'), isNotNull);
    expect(StudentNumber.validateFormat('####-AAAA'), isNotNull);
    expect(StudentNumber.applyFormat('202100123', '####-#####'), '2021-00123');
    expect(StudentNumber.applyFormat('2021', '####-#####'), '2021');
  });

  test('short codes use the Crockford alphabet', () {
    final code = ShortCode.generate();
    expect(code, hasLength(8));
    expect(ShortCode.isValid(code), isTrue);
    expect(ShortCode.isValid('ABCDEFGI'), isFalse); // I is excluded
  });

  test('validators', () {
    expect(Validators.required('  ', 'title'), 'Enter the title');
    expect(Validators.required('Midterm', 'title'), isNull);
    expect(Validators.email('a@b.co'), isNull);
    expect(Validators.email('nope'), isNotNull);
    expect(Validators.email(''), isNull);
    expect(Validators.number('75', min: 0, max: 100), isNull);
    expect(Validators.number('101', min: 0, max: 100), isNotNull);
    expect(Validators.schoolYear('2026-2027'), isNull);
    expect(Validators.schoolYear('2026-2028'), isNotNull);
    expect(Validators.code('CS 101', 'code'), isNull);
    expect(Validators.code('CS#101', 'code'), isNotNull);
  });
}
