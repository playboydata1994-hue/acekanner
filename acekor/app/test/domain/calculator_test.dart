import 'package:acekor/domain/calculator/expression_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const e = ExpressionEngine();
  String calc(String s) => ExpressionEngine.format(e.evaluate(s));

  test('operator precedence and parentheses', () {
    expect(calc('2+3×4'), '14');
    expect(calc('(2+3)×4'), '20');
    expect(calc('10÷4'), '2.5');
    expect(calc('7−10'), '-3');
    expect(calc('−5+2'), '-3');
    expect(calc('2×(3+4'), '14'); // closed automatically
    expect(calc('2(3)'), '6');
  });
  test('decimals without floating-point noise', () {
    expect(calc('0.1+0.2'), '0.3');
    expect(calc('1.5×4'), '6');
    expect(calc('1÷3'), '0.333333333333');
  });
  test('percent', () {
    expect(calc('50%'), '0.5');
    expect(calc('200+10%'), '220');
    expect(calc('200−10%'), '180');
    expect(calc('50×10%'), '5');
    expect(calc('42÷50×100'), '84');
  });
  test('errors', () {
    expect(() => e.evaluate('5÷0'), throwsA(isA<CalcError>()));
    expect(() => e.evaluate('5+'), throwsA(isA<CalcError>()));
    expect(() => e.evaluate('1..2'), throwsA(isA<CalcError>()));
    expect(() => e.evaluate(''), throwsA(isA<CalcError>()));
    expect(() => e.evaluate('()'), throwsA(isA<CalcError>()));
  });
  test('preview only once there is an operation', () {
    expect(e.preview('12'), isNull);
    expect(e.preview('12+3'), '15');
    expect(e.preview('12+'), isNull);
    expect(e.preview('-5'), isNull);
  });
}
