import 'package:material_ui/material_ui.dart';

import '../theme/spacing.dart';

/// Title above a group of content.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.padding});

  final String title;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding ??
          const EdgeInsets.only(top: Space.xl, bottom: Space.s),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
