import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Score distribution: papers per 10-point band, with the pass mark.
///
/// Single series (no legend; the section title names it). Thin columns with a
/// 4 px rounded cap and square base, 2 px gaps, hairline grid. Tap a column to
/// read its exact count; the same numbers are available as a table.
class ScoreHistogram extends StatefulWidget {
  const ScoreHistogram({super.key, required this.bins, required this.passingPercentage});

  /// 10 counts: [0–9.9, 10–19.9, …, 90–100].
  final List<int> bins;
  final double passingPercentage;

  @override
  State<ScoreHistogram> createState() => _ScoreHistogramState();
}

class _ScoreHistogramState extends State<ScoreHistogram> {
  int? _selected;
  bool _table = false;

  static String band(int i) => i == 9 ? '90–100%' : '${i * 10}–${i * 10 + 9}%';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.bins.fold(0, (a, b) => a + b);
    final selected = _selected;
    final caption = selected == null
        ? 'Tap a column to see how many papers scored in that range.'
        : '${band(selected)}: ${widget.bins[selected]} ${widget.bins[selected] == 1 ? 'paper' : 'papers'}';
    final summary = [
      for (var i = 0; i < 10; i++)
        if (widget.bins[i] > 0) '${band(i)}: ${widget.bins[i]}',
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_table)
          Table(
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth()},
            children: [
              for (var i = 9; i >= 0; i--)
                TableRow(children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(band(i))),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${widget.bins[i]}', textAlign: TextAlign.end),
                  ),
                ]),
            ],
          )
        else
          Semantics(
            label: 'Score distribution of $total papers. $summary',
            excludeSemantics: true,
            child: SizedBox(
              height: 190,
              child: LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) {
                    final layout = _HistogramLayout(constraints.biggest, widget.bins);
                    final i = layout.binAt(d.localPosition.dx);
                    setState(() => _selected = (i == _selected) ? null : i);
                  },
                  child: CustomPaint(
                    size: constraints.biggest,
                    painter: _HistogramPainter(
                      bins: widget.bins,
                      passing: widget.passingPercentage,
                      selected: selected,
                      colors: context.statusColors,
                      text: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: Space.s),
        Row(
          children: [
            Expanded(child: Text(_table ? 'Papers per score range' : caption, style: theme.textTheme.bodySmall)),
            TextButton(
              onPressed: () => setState(() => _table = !_table),
              child: Text(_table ? 'Show chart' : 'Show table'),
            ),
          ],
        ),
      ],
    );
  }
}

class _HistogramLayout {
  _HistogramLayout(this.size, this.bins);

  final Size size;
  final List<int> bins;

  static const double left = 28;
  static const double bottom = 22;
  static const double top = 18;

  double get plotWidth => size.width - left;
  double get plotHeight => size.height - bottom - top;
  double get slot => plotWidth / 10;

  int binAt(double x) => ((x - left) / slot).floor().clamp(0, 9);

  /// Clean y-axis maximum: the next "nice" number at or above the tallest bar.
  int get yMax {
    final m = bins.fold(0, max);
    if (m <= 4) return max(m, 1);
    final step = m <= 10 ? 2 : (m <= 25 ? 5 : (m <= 50 ? 10 : 20));
    return ((m + step - 1) ~/ step) * step;
  }
}

class _HistogramPainter extends CustomPainter {
  _HistogramPainter({
    required this.bins,
    required this.passing,
    required this.selected,
    required this.colors,
    required this.text,
  });

  final List<int> bins;
  final double passing;
  final int? selected;
  final AcekannerColors colors;
  final TextStyle text;

  @override
  void paint(Canvas canvas, Size size) {
    final l = _HistogramLayout(size, bins);
    final baseY = size.height - _HistogramLayout.bottom;
    final grid = Paint()
      ..color = colors.chartGrid
      ..strokeWidth = 1;

    void label(String s, Offset at, {TextAlign align = TextAlign.center}) {
      final tp = TextPainter(text: TextSpan(text: s, style: text), textDirection: TextDirection.ltr)..layout();
      final dx = switch (align) {
        TextAlign.right => at.dx - tp.width,
        TextAlign.left => at.dx,
        _ => at.dx - tp.width / 2,
      };
      tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
    }

    // Recessive grid: baseline, mid and top, with clean labels.
    final yMax = l.yMax;
    for (final v in {0, yMax ~/ 2, yMax}) {
      final y = baseY - v / yMax * l.plotHeight;
      canvas.drawLine(Offset(_HistogramLayout.left, y), Offset(size.width, y), grid);
      label('$v', Offset(_HistogramLayout.left - 6, y), align: TextAlign.right);
    }

    // Columns: <= 24 px, 2 px gaps, 4 px rounded cap, square base.
    final width = min(24.0, l.slot - 2);
    for (var i = 0; i < 10; i++) {
      final cx = _HistogramLayout.left + l.slot * (i + 0.5);
      if (bins[i] > 0) {
        final h = bins[i] / yMax * l.plotHeight;
        final rect = Rect.fromLTWH(cx - width / 2, baseY - h, width, h);
        final paint = Paint()
          ..color = selected == null || selected == i ? colors.chart : colors.chart.withValues(alpha: 0.35);
        canvas.drawRRect(
          RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(4), topRight: const Radius.circular(4)),
          paint,
        );
        if (selected == i) label('${bins[i]}', Offset(cx, baseY - h - 9));
      }
      if (i.isEven) label('${i * 10}', Offset(cx, baseY + 11));
    }

    // Pass mark: a solid hairline in the muted text color, labelled.
    final px = _HistogramLayout.left + l.plotWidth * (passing.clamp(0, 100) / 100);
    canvas.drawLine(
      Offset(px, _HistogramLayout.top - 4),
      Offset(px, baseY),
      Paint()
        ..color = text.color!
        ..strokeWidth = 1,
    );
    label('Pass ${_fmt(passing)}%', Offset(px.clamp(40, size.width - 40), 6));
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  bool shouldRepaint(covariant _HistogramPainter old) =>
      old.bins != bins || old.selected != selected || old.passing != passing || old.colors != colors;
}

/// Horizontal meter: filled share of a lighter track of the same hue.
class Meter extends StatelessWidget {
  const Meter({super.key, required this.value, this.height = 8});

  /// 0..1
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.statusColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.chartTrack),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: ColoredBox(color: c.chart),
            ),
          ],
        ),
      ),
    );
  }
}
