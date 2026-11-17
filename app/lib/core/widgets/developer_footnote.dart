import 'package:material_ui/material_ui.dart';

import '../constants.dart';

/// Small grey developer credit: "Developed by NYE94".
class DeveloperFootnote extends StatelessWidget {
  const DeveloperFootnote({super.key, this.withAppName = false});

  /// Prefix with the app name ("ACEkanner · Developed by NYE94").
  final bool withAppName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      withAppName ? '${AppConstants.appName} · ${AppConstants.developerCredit}' : AppConstants.developerCredit,
      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      textAlign: TextAlign.center,
    );
  }
}
