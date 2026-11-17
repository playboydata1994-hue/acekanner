import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';

/// Plain-language privacy summary (RA 10173), with a link to the full policy.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(legalLinksProvider);
    const sections = <(String, String)>[
      (
        'Student records stay on your phone',
        'Names, student IDs, scores, grades and reports are stored only on this phone, in an encrypted database '
            '(AES-256, key in the Android Keystore). ACEKOR never uploads them.',
      ),
      (
        'What the licensing server receives',
        'Only to run the free trial and subscriptions: your Google account identity (via sign-in), a random ID for this '
            'installation, your Google Play purchase tokens and the trial dates. Never any student information.',
      ),
      (
        'Backups',
        'A backup is a file protected by a password you choose. It is saved or shared only where you decide '
            '(for example Google Drive or a flash drive). Without the password it cannot be opened.',
      ),
      (
        'Sharing reports',
        'PDF and Excel reports are created on the phone. They leave it only when you share or save them.',
      ),
      (
        'Your control',
        'You can export and delete your records at any time. Uninstalling the app or clearing its data erases records that are not backed up. '
            'You can delete your licensing account from Settings › Subscription.',
      ),
      (
        'Data Privacy Act',
        'As the instructor you are the personal information controller of your students\' records under the Data Privacy Act of 2012 (RA 10173). '
            'ACEKOR helps you protect them: encryption, optional PIN or fingerprint lock, and no automatic uploads.',
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final (title, body) in sections) ...[
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(fontSize: 17, height: 1.45)),
            const SizedBox(height: 20),
          ],
          if (links.privacyPolicyUri != null)
            OutlinedButton.icon(
              onPressed: () => launchUrl(links.privacyPolicyUri!, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Full privacy policy'),
            ),
          if (links.termsUri != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => launchUrl(links.termsUri!, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Terms of use'),
            ),
          ],
        ],
      ),
    );
  }
}
