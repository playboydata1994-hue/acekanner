import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/feedback.dart';
import '../../domain/calculator/expression_engine.dart';

/// Editing rules of the full calculator's input line (pure, unit-tested).
class CalcInput {
  const CalcInput([this.text = '', this.justEvaluated = false]);

  final String text;

  /// The text is a result just produced by "=": a digit starts over.
  final bool justEvaluated;

  static const String ops = '+−×÷';
  bool get _endsWithOp => text.isNotEmpty && ops.contains(text[text.length - 1]);
  bool get _endsWithDigit => text.isNotEmpty && RegExp(r'[0-9.]$').hasMatch(text);
  bool get _endsWithClose => text.endsWith(')') || text.endsWith('%');
  int get _open => '('.allMatches(text).length - ')'.allMatches(text).length;

  CalcInput digit(String d) {
    if (justEvaluated) return CalcInput(d);
    if (_endsWithClose) return CalcInput('$text×$d');
    // "0" then "5" → "5" (but keep "10", "0.")
    final m = RegExp(r'(^|[^0-9.])0$').firstMatch(text);
    if (m != null && d != '.') return CalcInput(text.substring(0, text.length - 1) + d);
    return CalcInput(text + d);
  }

  CalcInput dot() {
    if (justEvaluated) return const CalcInput('0.');
    final segment = RegExp(r'[0-9.]*$').firstMatch(text)!.group(0)!;
    if (segment.contains('.')) return this;
    if (segment.isEmpty) return CalcInput('${_endsWithClose ? '$text×' : text}0.');
    return CalcInput('$text.');
  }

  CalcInput op(String o) {
    if (text.isEmpty) return o == '−' ? const CalcInput('−') : this;
    if (text.endsWith('(')) return o == '−' ? CalcInput('$text−') : this;
    if (_endsWithOp) {
      if (text.length == 1) return this;
      return CalcInput(text.substring(0, text.length - 1) + o);
    }
    if (text.endsWith('.')) return CalcInput('${text}0$o');
    return CalcInput(text + o);
  }

  CalcInput percent() => (_endsWithDigit || text.endsWith(')')) && !text.endsWith('.') ? CalcInput('$text%') : this;

  /// One key for "(" and ")", like phone calculators.
  CalcInput paren() {
    if (justEvaluated) return CalcInput('$text×(');
    if (text.isEmpty || _endsWithOp || text.endsWith('(')) return CalcInput('$text(');
    if (_open > 0) return CalcInput('$text)');
    return CalcInput('$text×(');
  }

  /// +/- : toggles the sign of the last number ("12" ↔ "(−12").
  CalcInput negate() {
    final m = RegExp(r'(\(−)?([0-9.]+%?)$').firstMatch(text);
    if (m == null) return text.isEmpty || _endsWithOp ? CalcInput('$text(−') : this;
    final start = text.substring(0, m.start);
    if (m.group(1) != null) return CalcInput('$start${m.group(2)}');
    return CalcInput('$start(−${m.group(2)}');
  }

  CalcInput backspace() =>
      text.isEmpty || justEvaluated ? const CalcInput() : CalcInput(text.substring(0, text.length - 1));

  CalcInput clear() => const CalcInput();

  /// Inserts a number from the history.
  CalcInput insert(String number) {
    final n = number.startsWith('-') ? '(−${number.substring(1)}' : number;
    if (text.isEmpty || justEvaluated) return CalcInput(n);
    if (_endsWithOp || text.endsWith('(')) return CalcInput(text + n);
    return CalcInput('$text×$n');
  }
}

/// A separate full-screen calculator. Its results are never saved as
/// academic records.
class MiniCalculatorScreen extends ConsumerStatefulWidget {
  const MiniCalculatorScreen({super.key});

  @override
  ConsumerState<MiniCalculatorScreen> createState() => _MiniCalculatorScreenState();
}

class _MiniCalculatorScreenState extends ConsumerState<MiniCalculatorScreen> {
  static const _engine = ExpressionEngine();
  CalcInput _input = const CalcInput();
  String? _error;
  bool _history = false;

  void _set(CalcInput next) => setState(() {
    _input = next;
    _error = null;
  });

  void _tap(String key) {
    if (ref.read(appSettingsProvider).sound) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    }
    switch (key) {
      case 'C':
        _set(_input.clear());
      case '()':
        _set(_input.paren());
      case '%':
        _set(_input.percent());
      case '+/-':
        _set(_input.negate());
      case '.':
        _set(_input.dot());
      case '=':
        _equals();
      case '⌫':
        _set(_input.backspace());
      case '+' || '−' || '×' || '÷':
        _set(CalcInput(_input.text).op(key));
      default:
        _set(_input.digit(key));
    }
  }

  Future<void> _equals() async {
    final text = _input.text;
    if (text.isEmpty) return;
    try {
      final result = ExpressionEngine.format(_engine.evaluate(text));
      setState(() {
        _input = CalcInput(result, true);
        _error = null;
      });
      if (text != result) await ref.read(calcHistoryRepositoryProvider).add(text, result);
    } on CalcError catch (e) {
      setState(() => _error = e.message);
    }
  }

  String? get _result => _input.justEvaluated ? _input.text : _engine.preview(_input.text);

  void _copy() {
    final value = _result ?? (_input.text.isEmpty ? null : _input.text);
    if (value == null) return;
    Clipboard.setData(ClipboardData(text: value.replaceAll('−', '-')));
    showMessage(context, 'Copied $value');
  }

  @override
  Widget build(BuildContext context) {
    final preview = _input.justEvaluated ? null : _engine.preview(_input.text);
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Calculator'),
        leading: IconButton(
          tooltip: 'Back to the academic calculator',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: GestureDetector(
                onLongPress: _copy,
                child: Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _input.text.isEmpty ? '0' : _input.text,
                          key: const ValueKey('mini-expression'),
                          style: TextStyle(
                            fontSize: _input.justEvaluated ? 72 : 56,
                            color: _input.justEvaluated ? AppColors.teal : AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: Text(
                          _error ?? (preview ?? ''),
                          key: const ValueKey('mini-preview'),
                          style: TextStyle(fontSize: 30, color: _error != null ? AppColors.red : AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: _history ? 'Keypad' : 'History',
                    iconSize: 28,
                    onPressed: () => setState(() => _history = !_history),
                    icon: Icon(_history ? Icons.dialpad : Icons.history, color: AppColors.white),
                  ),
                  IconButton(
                    tooltip: 'Copy result',
                    iconSize: 26,
                    onPressed: _copy,
                    icon: const Icon(Icons.copy_rounded, color: AppColors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const ValueKey('mini-backspace'),
                    tooltip: 'Backspace',
                    iconSize: 28,
                    onPressed: () => _tap('⌫'),
                    icon: const Icon(Icons.backspace_outlined, color: AppColors.red),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 7,
              child: _history ? _HistoryPanel(onPick: (r) => _set(_input.insert(r))) : _Keys(onTap: _tap),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keys extends StatelessWidget {
  const _Keys({required this.onTap});
  final ValueChanged<String> onTap;

  static const rows = [
    ['C', '()', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['+/-', '0', '.', '='],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final w = (c.maxWidth - 32 - 3 * gap) / 4;
        final h = (c.maxHeight - 24 - 4 * gap) / 5;
        final size = (w < h ? w : h).clamp(44.0, 96.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final row in rows)
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final k in row) _key(k, size)]),
            ],
          ),
        );
      },
    );
  }

  Widget _key(String k, double size) {
    final isEq = k == '=';
    final isOp = '÷×−+'.contains(k) && k.length == 1;
    final color = k == 'C'
        ? AppColors.red
        : (isOp || k == '()' || k == '%')
        ? AppColors.teal
        : AppColors.white;
    return Material(
      key: ValueKey('mini-$k'),
      color: isEq ? AppColors.save : AppColors.key,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(k),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              k,
              style: TextStyle(
                fontSize: size * (k.length > 1 ? 0.3 : 0.4),
                color: isEq ? Colors.white : color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryPanel extends ConsumerWidget {
  const _HistoryPanel({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(calcHistoryProvider).value ?? const [];
    if (items.isEmpty) {
      return const Center(
        child: Text('No history yet', style: TextStyle(fontSize: 18, color: AppColors.muted)),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            reverse: true,
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final h = items[i];
              return ListTile(
                title: Text(
                  h.expression,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.muted),
                ),
                subtitle: Text(
                  '= ${h.result}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 26, color: AppColors.teal),
                ),
                onTap: () => onPick(h.result),
              );
            },
          ),
        ),
        TextButton.icon(
          onPressed: () => ref.read(calcHistoryRepositoryProvider).clear(),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Clear history'),
        ),
      ],
    );
  }
}
