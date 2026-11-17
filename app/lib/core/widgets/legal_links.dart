import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import 'feedback.dart';

/// "Privacy policy" and "Terms of use" links to the public pages. Shows only
/// the links whose address was set at build time, and nothing when none is.
class LegalLinksRow extends ConsumerWidget {
  const LegalLinksRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(legalLinksProvider);
    final items = [
      ('Privacy policy', links.privacyPolicyUri),
      ('Terms of use', links.termsUri),
    ].where((e) => e.$2 != null).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      children: [
        for (final (label, uri) in items)
          TextButton.icon(
            onPressed: () => _open(context, uri!),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(label),
          ),
      ],
    );
  }

  static Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showMessage(context, 'Open ${uri.toString()} in your browser.');
  }
}
