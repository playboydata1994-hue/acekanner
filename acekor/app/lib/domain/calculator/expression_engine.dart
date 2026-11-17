/// The mini calculator's arithmetic: + − × ÷, parentheses, decimals and %.
///
/// Percent follows phone-calculator rules:
/// * `a + b%` and `a − b%` add or subtract b percent *of a* (200 + 10% = 220);
/// * anywhere else `b%` means b ÷ 100 (50 × 10% = 5).
///
/// Unclosed parentheses are closed automatically. The input uses the display
/// symbols × ÷ − (ASCII * / - are also accepted).
library;

class CalcError implements Exception {
  const CalcError(this.message);
  final String message;

  @override
  String toString() => message;
}

class ExpressionEngine {
  const ExpressionEngine();

  /// Evaluates [input]. Throws [CalcError] for invalid input or ÷ 0.
  double evaluate(String input) {
    final tokens = _tokenize(input);
    if (tokens.isEmpty) throw const CalcError('Nothing to calculate');
    final parser = _Parser(tokens);
    final value = parser.parseExpression().value;
    if (!parser.atEnd) throw const CalcError('Invalid format');
    if (value.isNaN || value.isInfinite) throw const CalcError("Can't divide by 0");
    return value;
  }

  /// Result for the live preview, or null while the input is incomplete.
  String? preview(String input) {
    try {
      if (!_hasOperator(input)) return null;
      return format(evaluate(input));
    } on CalcError {
      return null;
    }
  }

  static bool _hasOperator(String s) => RegExp(r'[+×÷*/%−-]').hasMatch(s.replaceFirst(RegExp(r'^[−-]'), ''));

  /// Up to 12 significant digits, no trailing zeros, no "-0", thousands
  /// separators not added (the display adds none either).
  static String format(double value) {
    if (value == 0) return '0';
    if (value.abs() >= 1e15 || value.abs() < 1e-9) {
      return value.toStringAsExponential(8).replaceFirst(RegExp(r'\.?0+e'), 'e');
    }
    var s = value.toStringAsPrecision(12);
    if (s.contains('e')) s = double.parse(s).toString();
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s == '-0' ? '0' : s;
  }

  static List<_Tok> _tokenize(String input) {
    final out = <_Tok>[];
    var i = 0;
    final s = input.replaceAll(' ', '').replaceAll(',', '');
    while (i < s.length) {
      final c = s[i];
      if (RegExp(r'[0-9.]').hasMatch(c)) {
        final start = i;
        while (i < s.length && RegExp(r'[0-9.]').hasMatch(s[i])) {
          i++;
        }
        final text = s.substring(start, i);
        if ('.'.allMatches(text).length > 1) throw const CalcError('Invalid format');
        final v = double.tryParse(text == '.' ? '' : text);
        if (v == null) throw const CalcError('Invalid format');
        out.add(_Tok.number(v));
        continue;
      }
      final op = switch (c) {
        '+' => '+',
        '-' || '−' => '-',
        '*' || '×' => '*',
        '/' || '÷' => '/',
        '%' => '%',
        '(' => '(',
        ')' => ')',
        _ => throw CalcError('Unknown symbol $c'),
      };
      out.add(_Tok.op(op));
      i++;
    }
    return out;
  }
}

class _Tok {
  _Tok.number(this.value) : op = null;
  _Tok.op(this.op) : value = 0;
  final String? op;
  final double value;
  bool get isNumber => op == null;
}

class _Term {
  const _Term(this.value, {this.percentOf});
  final double value;

  /// Set when the term is exactly `b%`: the b, for the "a + b%" rule.
  final double? percentOf;
}

class _Parser {
  _Parser(this.tokens);
  final List<_Tok> tokens;
  int pos = 0;

  bool get atEnd => pos >= tokens.length;
  _Tok? get _peek => atEnd ? null : tokens[pos];
  bool _isOp(String op) => _peek != null && _peek!.op == op;

  _Term parseExpression() {
    var left = parseTerm().value;
    while (_isOp('+') || _isOp('-')) {
      final op = tokens[pos++].op;
      if (atEnd) throw const CalcError('Invalid format');
      final right = parseTerm();
      final amount = right.percentOf != null ? left * right.percentOf! / 100 : right.value;
      left = op == '+' ? left + amount : left - amount;
    }
    return _Term(left);
  }

  _Term parseTerm() {
    var first = parseFactor();
    var value = first.value;
    var single = true;
    while (_isOp('*') || _isOp('/')) {
      single = false;
      final op = tokens[pos++].op;
      if (atEnd) throw const CalcError('Invalid format');
      final right = parseFactor().value;
      if (op == '/') {
        if (right == 0) throw const CalcError("Can't divide by 0");
        value = value / right;
      } else {
        value = value * right;
      }
    }
    return single ? first : _Term(value);
  }

  _Term parseFactor() {
    if (_isOp('-')) {
      pos++;
      final inner = parseFactor();
      return _Term(-inner.value, percentOf: inner.percentOf == null ? null : -inner.percentOf!);
    }
    if (_isOp('+')) {
      pos++;
      return parseFactor();
    }
    return parsePostfix();
  }

  _Term parsePostfix() {
    var value = parsePrimary();
    double? percentOf;
    while (_isOp('%')) {
      pos++;
      percentOf = percentOf == null ? value : null;
      value = value / 100;
    }
    // Implicit multiplication: "2(3)" or "(2)(3)".
    if (_isOp('(') || (_peek?.isNumber ?? false)) {
      final right = parsePostfix();
      return _Term(value * right.value);
    }
    return _Term(value, percentOf: percentOf);
  }

  double parsePrimary() {
    final t = _peek;
    if (t == null) throw const CalcError('Invalid format');
    if (t.isNumber) {
      pos++;
      return t.value;
    }
    if (t.op == '(') {
      pos++;
      if (_isOp(')')) throw const CalcError('Invalid format');
      final v = parseExpression().value;
      if (_isOp(')')) {
        pos++;
      } else if (!atEnd) {
        throw const CalcError('Invalid format');
      }
      return v;
    }
    throw const CalcError('Invalid format');
  }
}
