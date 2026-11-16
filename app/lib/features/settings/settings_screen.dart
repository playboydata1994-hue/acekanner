import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/router.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/section_header.dart';

/// Settings hub. Items are added here as each feature ships.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final format = ref.watch(studentNoFormatProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          children: [
            const SectionHeader('Instructor'),
            _Group(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Profile and school'),
                  subtitle: Text(
                    profile == null
                        ? 'Not set up yet'
                        : [profile.fullName, ?profile.schoolName].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openProfile(context),
                ),
                const Divider(indent: Space.l, endIndent: Space.l),
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: const Text('Student number format'),
                  subtitle: Text(format ?? '…'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openProfile(context),
                ),
              ],
            ),
            const SectionHeader('Help'),
            _Group(
              children: [
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Introduction'),
                  subtitle: const Text('How ACEkanner works, sheets, plans'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.replayOnboarding),
                ),
              ],
            ),
            const SectionHeader('Privacy and security'),
            _Group(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy and your data'),
                  subtitle: const Text('What is stored, where, and who can see it'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.privacy),
                ),
              ],
            ),
            const SectionHeader('About'),
            _Group(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About ACEkanner'),
                  subtitle: const Text('Version, storage and scanner status'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.about),
                ),
                const Divider(indent: Space.l, endIndent: Space.l),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Open-source licenses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'ACEkanner',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.xxl),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );
}

Future<void> _openProfile(BuildContext context) async {
  final saved = await context.push<bool>(Routes.profile);
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profile saved')));
  }
}
