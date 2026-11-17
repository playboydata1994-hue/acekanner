import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// The ACEKOR mark: a round teal-green key with a check, like the save key.
class AcekorMark extends StatelessWidget {
  const AcekorMark({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.save, shape: BoxShape.circle),
      child: Icon(Icons.check_rounded, color: Colors.white, size: size * 0.6),
    );
  }
}

/// "ACEKOR" with "Calculator" underneath.
class AcekorWordmark extends StatelessWidget {
  const AcekorWordmark({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'ACEKOR',
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 4, color: AppColors.white),
        ),
        Text(
          'CALCULATOR',
          style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w600, letterSpacing: 6, color: AppColors.teal),
        ),
      ],
    );
  }
}
