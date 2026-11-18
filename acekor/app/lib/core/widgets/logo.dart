import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// The ACEkor logo: a clipboard holding a grading sheet with checked rows
/// and a score bar. Same drawing as the launcher icon (acekor/tools/brand.py).
class AcekorMark extends StatelessWidget {
  const AcekorMark({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ACEkor logo',
      image: true,
      child: CustomPaint(size: Size.square(size), painter: const _ClipboardPainter()),
    );
  }
}

class _ClipboardPainter extends CustomPainter {
  const _ClipboardPainter();

  static const Color deep = Color(0xFF0A6B54);
  static const Color paper = Color(0xFFF5F8F7);
  static const Color clip = Color(0xFF9FB1AB);
  static const Color line = Color(0xFFAEBDB8);
  static const Color track = Color(0xFFDDE6E3);

  @override
  void paint(Canvas canvas, Size size) {
    // The drawing spans x 29-79 and y 20-87 of a 108 box; fit that area.
    const left = 29.0, top = 20.0, w = 50.0, h = 67.0;
    final s = size.height / h < size.width / w ? size.height / h : size.width / w;
    canvas.save();
    canvas.translate((size.width - w * s) / 2 - left * s, (size.height - h * s) / 2 - top * s);
    canvas.scale(s);

    void rrect(double x, double y, double rw, double rh, double r, Color c) =>
        canvas.drawRRect(RRect.fromLTRBR(x, y, x + rw, y + rh, Radius.circular(r)), Paint()..color = c);

    rrect(29, 25, 50, 62, 7, deep);
    rrect(34, 32, 40, 50, 3.5, paper);
    rrect(43, 20, 22, 11, 4, clip);
    canvas.drawCircle(const Offset(54, 24.5), 2.4, Paint()..color = deep);
    final check = Paint()
      ..color = AppColors.save
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final ry in const [42.0, 52.0, 62.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(39.5, ry)
          ..lineTo(42, ry + 2.5)
          ..lineTo(46.5, ry - 2.5),
        check,
      );
      rrect(50, ry - 2, 19, 4, 2, line);
    }
    rrect(39, 71, 30, 5, 2.5, track);
    rrect(39, 71, 25, 5, 2.5, AppColors.teal);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "ACEkor" with "GRADING SHEET" underneath.
class AcekorWordmark extends StatelessWidget {
  const AcekorWordmark({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ACEkor',
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.white),
        ),
        Text(
          'GRADING SHEET',
          style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700, letterSpacing: 5, color: AppColors.teal),
        ),
      ],
    );
  }
}
