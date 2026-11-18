import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';

/// Keys of the academic calculator.
enum CalcKey { d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, backspace, save }

/// The academic keypad: exactly three columns.
///
///     7  8  9
///     4  5  6
///     1  2  3
///     ⌫  0  ✓
///
/// No operators, no decimal point and no clear key.
class AcademicKeypad extends StatelessWidget {
  const AcademicKeypad({super.key, required this.onKey, this.sound = true, this.saveEnabled = true});

  final ValueChanged<CalcKey> onKey;
  final bool sound;
  final bool saveEnabled;

  static const List<List<CalcKey>> rows = [
    [CalcKey.d7, CalcKey.d8, CalcKey.d9],
    [CalcKey.d4, CalcKey.d5, CalcKey.d6],
    [CalcKey.d1, CalcKey.d2, CalcKey.d3],
    [CalcKey.backspace, CalcKey.d0, CalcKey.save],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 14.0;
        final byWidth = (c.maxWidth - 2 * gap) / 3;
        final byHeight = (c.maxHeight - 3 * gap) / 4;
        final size = (byWidth < byHeight ? byWidth : byHeight).clamp(52.0, 112.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: gap),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final k in rows[r])
                    _KeyButton(
                      keyType: k,
                      size: size,
                      enabled: k != CalcKey.save || saveEnabled,
                      onTap: () {
                        if (sound) {
                          SystemSound.play(SystemSoundType.click);
                          HapticFeedback.lightImpact();
                        }
                        onKey(k);
                      },
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.keyType, required this.size, required this.onTap, required this.enabled});
  final CalcKey keyType;
  final double size;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isSave = keyType == CalcKey.save;
    final isBack = keyType == CalcKey.backspace;
    final bg = isSave ? (enabled ? AppColors.save : AppColors.key) : AppColors.key;
    final Widget child;
    final String semantics;
    if (isSave) {
      child = Icon(Icons.check_rounded, size: size * 0.5, color: Colors.white);
      semantics = 'Save score';
    } else if (isBack) {
      child = Icon(Icons.backspace_outlined, size: size * 0.38, color: AppColors.red);
      semantics = 'Backspace';
    } else {
      final digit = keyType.index;
      child = Text(
        '$digit',
        style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w500, color: AppColors.white, height: 1),
      );
      semantics = '$digit';
    }
    return Semantics(
      button: true,
      label: semantics,
      child: Material(
        key: ValueKey('key-${keyType.name}'),
        color: bg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: isSave ? AppColors.savePressed : AppColors.keyPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
