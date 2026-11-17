import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// What the white ACEkanner mark is drawn on.
enum LogoBackground {
  /// Brand-blue rounded square (the app icon).
  tile,

  /// No background: the mark alone, for a blue surface drawn elsewhere
  /// (e.g. the round Scan button).
  none,
}

/// The ACEkanner mark: a scanner viewfinder around a shaded answer bubble
/// with a check. Same geometry as the launcher icon (108-unit grid).
class AcekannerLogo extends StatelessWidget {
  const AcekannerLogo({super.key, this.size = 48, this.background = LogoBackground.tile});

  final double size;
  final LogoBackground background;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ACEkanner logo',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _LogoPainter(background)),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter(this.background);

  final LogoBackground background;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 108;
    if (background == LogoBackground.tile) {
      final tile = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * 0.22),
      );
      canvas.drawRRect(tile, Paint()..color = BrandColors.blue);
    }

    // Mark scaled up within the tile (matches the store icon proportions).
    canvas.save();
    const markScale = 1.3;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(markScale);
    canvas.translate(-size.width / 2, -size.height / 2);

    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final brackets = Path()
      ..moveTo(32 * s, 43 * s)
      ..lineTo(32 * s, 32 * s)
      ..lineTo(43 * s, 32 * s)
      ..moveTo(65 * s, 32 * s)
      ..lineTo(76 * s, 32 * s)
      ..lineTo(76 * s, 43 * s)
      ..moveTo(76 * s, 65 * s)
      ..lineTo(76 * s, 76 * s)
      ..lineTo(65 * s, 76 * s)
      ..moveTo(43 * s, 76 * s)
      ..lineTo(32 * s, 76 * s)
      ..lineTo(32 * s, 65 * s);
    canvas.drawPath(brackets, white);
    canvas.drawCircle(p(54, 54), 13 * s, Paint()..color = Colors.white);
    final check = Path()
      ..moveTo(47.5 * s, 54.5 * s)
      ..lineTo(52 * s, 59 * s)
      ..lineTo(61 * s, 50 * s);
    canvas.drawPath(
      check,
      Paint()
        ..color = BrandColors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => oldDelegate.background != background;
}

/// "ACEkanner" wordmark: bold brand-blue "ACE" + regular "kanner".
class AcekannerWordmark extends StatelessWidget {
  const AcekannerWordmark({super.key, this.fontSize = 22});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = TextStyle(fontSize: fontSize, letterSpacing: -0.3, height: 1.1);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'ACE',
            style: base.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.primary,
            ),
          ),
          TextSpan(
            text: 'kanner',
            style: base.copyWith(
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
      semanticsLabel: 'ACEkanner',
    );
  }
}
