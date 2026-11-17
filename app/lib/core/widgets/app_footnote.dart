import 'package:material_ui/material_ui.dart';

import '../constants.dart';
import 'acekanner_logo.dart';

/// Small ACEkanner logo and name, at the end of the Home screen.
class AppFootnote extends StatelessWidget {
  const AppFootnote({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: AppConstants.appName,
        excludeSemantics: true,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AcekannerLogo(size: 20),
            SizedBox(width: 6),
            AcekannerWordmark(fontSize: 14),
          ],
        ),
      );
}
