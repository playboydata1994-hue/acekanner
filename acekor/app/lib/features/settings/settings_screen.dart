import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/licensing_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/settings/settings_repository.dart';
import '../plan/plan_text.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final plan = ref.watch(planStatusProvider);
    final repo = ref.read(settingsRepositoryProvider);
    ListTile link(IconData icon, String title, String route, {String? subtitle}) => ListTile(
      leading: Icon(icon, color: AppColors.teal),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
    final lastBackup = s.lastBackupAt;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionTitle('Account'),
          link(Icons.badge_outlined, 'Instructor and school', Routes.profile),
          link(Icons.workspace_premium_outlined, 'Subscription', Routes.plan, subtitle: planSummary(plan)),
          const SectionTitle('Academic settings'),
          link(Icons.people_alt_outlined, 'Student roster', Routes.students),
          link(Icons.menu_book_outlined, 'Subjects', Routes.subjects),
          link(Icons.groups_outlined, 'Sections', Routes.sections),
          link(
            Icons.calculate_outlined,
            'Quiz, recitation and examination settings',
            Routes.calculatorSettings,
            subtitle: [
              if (s.academicYear.isNotEmpty) s.academicYear,
              if (s.semester.isNotEmpty) s.semester,
            ].join(' · '),
          ),
          link(Icons.category_outlined, 'Examination categories', Routes.categories),
          link(Icons.grading_outlined, 'Grade scales', Routes.scales),
          const SectionTitle('Application settings'),
          ListTile(
            leading: const Icon(Icons.format_size, color: AppColors.teal),
            title: const Text('Text size'),
            subtitle: Text(s.textSize.label),
            onTap: () async {
              final v = await askChoice(
                context,
                title: 'Text size',
                current: s.textSize,
                options: {for (final t in TextSize.values) t: t.label},
              );
              if (v != null) await repo.setString(SettingKeys.textSize, v.code);
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined, color: AppColors.teal),
            title: const Text('Dark mode'),
            subtitle: Text(switch (s.themeMode) {
              ThemeMode.light => 'Off (light screens; the calculator stays dark)',
              ThemeMode.system => 'Follow the phone',
              _ => 'On',
            }),
            onTap: () async {
              final v = await askChoice(
                context,
                title: 'Dark mode',
                current: s.raw[SettingKeys.themeMode] ?? 'dark',
                options: const {'dark': 'On', 'light': 'Off', 'system': 'Follow the phone'},
              );
              if (v != null) await repo.setString(SettingKeys.themeMode, v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined, color: AppColors.teal),
            title: const Text('Calculator sound'),
            value: s.sound,
            onChanged: (v) => repo.setBool(SettingKeys.sound, v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.chat_bubble_outline, color: AppColors.teal),
            title: const Text('Confirmation messages'),
            value: s.confirmMessage,
            onChanged: (v) => repo.setBool(SettingKeys.confirmMessage, v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined, color: AppColors.teal),
            title: const Text('Reminder one day before expiry'),
            subtitle: const Text('The 5-day reminder is always on'),
            value: s.oneDayReminder,
            onChanged: (v) => repo.setBool(SettingKeys.oneDayReminder, v),
          ),
          link(Icons.lock_outline, 'App lock (PIN, fingerprint)', Routes.lock, subtitle: s.lockEnabled ? 'On' : 'Off'),
          link(
            Icons.backup_outlined,
            'Backup and restore',
            Routes.backup,
            subtitle: lastBackup == null ? 'No backup yet' : 'Last backup ${DateFormat('MMM d, y').format(lastBackup)}',
          ),
          link(Icons.ios_share, 'Data export (PDF, Excel)', Routes.reports),
          link(Icons.privacy_tip_outlined, 'Privacy policy', Routes.privacy),
          link(Icons.info_outline, 'About ACEKOR', Routes.about),
        ],
      ),
    );
  }
}
