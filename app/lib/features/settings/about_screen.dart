import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/bootstrap.dart';
import '../../app/providers.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/acekanner_logo.dart';
import '../../core/widgets/info_row.dart';
import '../../core/widgets/section_header.dart';
import '../../data/db/app_database.dart';
import '../../platform/omr_engine_channel.dart';

final packageInfoProvider =
    FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

final engineInfoProvider = FutureProvider<EngineInfo>(
  (ref) => ref.watch(omrEngineChannelProvider).engineInfo(),
);

/// Version information and live status of storage encryption and the scanner
/// engine on this phone.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final info = ref.watch(packageInfoProvider).value;
    final engine = ref.watch(engineInfoProvider);
    final boot = ref.watch(bootstrapControllerProvider).value;
    final cipher = boot is BootstrapReady ? boot.cipherVersion : null;

    return Scaffold(
      appBar: AppBar(title: const Text('About ACEkanner')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          children: [
            const SizedBox(height: Space.xl),
            const Center(child: AcekannerLogo(size: 72)),
            const SizedBox(height: Space.m),
            const Center(child: AcekannerWordmark(fontSize: 28)),
            const SizedBox(height: Space.xs),
            Center(
              child: Text(
                info == null
                    ? ''
                    : 'Version ${info.version} (build ${info.buildNumber})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: Space.s),
            Center(
              child: Text(
                'Offline examination scanner and grader for college instructors.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SectionHeader('This phone'),
            Card(
              child: Column(
                children: [
                  InfoRow(
                    label: 'Data storage',
                    value: cipher != null
                        ? 'Encrypted (SQLCipher $cipher)'
                        : 'Not encrypted (development build)',
                  ),
                  const InfoRow(
                    label: 'Database schema',
                    value: 'Version ${AppDatabase.currentSchemaVersion}',
                  ),
                  InfoRow(
                    label: 'Scanner engine',
                    value: switch (engine) {
                      AsyncData(:final value) when value.available =>
                        'Ready (OpenCV ${value.opencvVersion})',
                      AsyncData(:final value) =>
                        'Unavailable: ${value.error ?? 'unknown error'}',
                      AsyncError(:final error) => 'Unavailable: $error',
                      _ => 'Checking…',
                    },
                  ),
                  if (engine.value?.device != null)
                    InfoRow(
                      label: 'Device',
                      value: '${engine.value!.device} · '
                          '${engine.value!.abi} · Android API ${engine.value!.sdkInt}',
                    ),
                  InfoRow(
                    label: 'Package',
                    value: info?.packageName ?? '—',
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xl),
            Center(
              child: Text(
                '© ${DateTime.now().year} ACEkanner',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: Space.xxl),
          ],
        ),
      ),
    );
  }
}
