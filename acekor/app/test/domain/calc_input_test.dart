import 'package:acekor/domain/calculator/expression_engine.dart';
import 'package:acekor/features/mini_calculator/mini_calculator_screen.dart';
import 'package:flutter_test/flutter_test.dart';

CalcInput type(String keys) {
  var c = const CalcInput();
  for (final k in keys.split(' ')) {
    c = switch (k) {
      '()' => c.paren(),
      '%' => c.percent(),
      '.' => c.dot(),
      '+/-' => c.negate(),
      '⌫' => c.backspace(),
      '+' || '−' || '×' || '÷' => c.op(k),
      _ => c.digit(k),
    };
  }
  return c;
}

void main() {
  test('input rules', () {
    expect(type('1 2 + 3').text, '12+3');
    expect(type('1 + ×').text, '1×'); // operator replaced
    expect(type('0 5').text, '5');
    expect(type('. 5').text, '0.5');
    expect(type('1 . . 5').text, '1.5');
    expect(type('() 2 + 3 () × 4').text, '(2+3)×4');
    expect(type('2 ()').text, '2×(');
    expect(type('1 2 +/-').text, '(−12');
    expect(type('1 2 +/- +/-').text, '12');
    expect(type('5 0 %').text, '50%');
    expect(type('1 2 ⌫').text, '1');
    expect(const ExpressionEngine().evaluate(type('() 2 + 3 () × 4').text), 20);
  });
  test('history insert', () {
    expect(const CalcInput('3+').insert('-2').text, '3+(−2');
    expect(const CalcInput('3').insert('5').text, '3×5');
  });
}
