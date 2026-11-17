import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/bootstrap.dart';
import '../../app/licensing_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/logo.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider).value;
    final boot = ref.watch(bootstrapControllerProvider).value;
    final cipher = boot is BootstrapReady ? boot.cipherVersion : null;
    return Scaffold(
      appBar: AppBar(title: const Text('About ACEKOR')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: AcekorMark(size: 72)),
          const SizedBox(height: 16),
          const Center(child: AcekorWordmark(size: 28)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Version ${info?.version ?? '…'} (${info?.buildNumber ?? '…'})',
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'An offline academic score calculator and student performance recorder for college instructors: '
            'search a student, type the score, save.',
            style: TextStyle(fontSize: 17, height: 1.4),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: AppColors.teal),
            title: const Text('Encrypted storage'),
            subtitle: Text(
              cipher == null ? 'Not encrypted (test environment)' : 'SQLCipher $cipher · key in Android Keystore',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.wifi_off, color: AppColors.teal),
            title: Text('Works offline'),
            subtitle: Text('Scores, records, reports and backups never need the internet.'),
          ),
          const ListTile(
            leading: Icon(Icons.text_fields, color: AppColors.teal),
            title: Text('Font'),
            subtitle: Text('Roboto, Apache License 2.0'),
          ),
          TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'ACEKOR Calculator',
              applicationVersion: info?.version,
            ),
            child: const Text('Open-source licenses'),
          ),
        ],
      ),
    );
  }
}
