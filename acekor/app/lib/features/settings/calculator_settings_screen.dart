import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_settings.dart';
import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/dialogs.dart';
import '../../data/db/app_database.dart';
import '../../data/settings/settings_repository.dart';
import '../../domain/categories.dart';
import '../calculator/class_picker.dart';

/// Calculator, quiz, recitation, examination and general settings. All are
/// saved on the phone.
class CalculatorSettingsScreen extends ConsumerWidget {
  const CalculatorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final repo = ref.read(settingsRepositoryProvider);
    final subjects = ref.read(subjectsRepositoryProvider);
    final cats = ref.watch(categoriesProvider).value ?? const <CategoryRow>[];
    CategoryRow? cat(String id) => cats.where((c) => c.id == id).firstOrNull;
    final quiz = cat(CategoryCatalog.quiz);
    final rec = cat(CategoryCatalog.recitation);
    final exams = cats.where((c) => CategoryKind.parse(c.kind) == CategoryKind.exam).toList();

    Future<void> setCatMax(CategoryRow c, int maxAllowed) async {
      final v = await askNumber(
        context,
        title: 'Default ${c.name.toLowerCase()} points',
        initial: c.defaultMaxPoints,
        min: 1,
        max: maxAllowed,
      );
      if (v != null) await subjects.updateCategory(c.id, defaultMax: v);
    }

    Future<void> setInt(String key, String title, int current, int min, int max) async {
      final v = await askNumber(context, title: title, initial: current, min: min, max: max);
      if (v != null) await repo.setInt(key, v);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calculator settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionTitle('Quiz settings'),
          if (quiz != null)
            ListTile(
              title: const Text('Default quiz points'),
              subtitle: const Text('Total for a new quiz'),
              trailing: Text('${quiz.defaultMaxPoints}', style: const TextStyle(fontSize: 20)),
              onTap: () => setCatMax(quiz, s.quizMaxAllowed),
            ),
          ListTile(
            title: const Text('Maximum quiz points'),
            subtitle: const Text('Largest total a quiz may have'),
            trailing: Text('${s.quizMaxAllowed}', style: const TextStyle(fontSize: 20)),
            onTap: () => setInt(SettingKeys.quizMaxAllowed, 'Maximum quiz points', s.quizMaxAllowed, 1, 1000),
          ),
          ListTile(
            title: const Text('Default quiz number'),
            subtitle: const Text('Numbering starts at'),
            trailing: Text('${s.quizFirstNumber}', style: const TextStyle(fontSize: 20)),
            onTap: () => setInt(SettingKeys.quizFirstNumber, 'First quiz number', s.quizFirstNumber, 1, 999),
          ),
          SwitchListTile(
            title: const Text('Automatic percentage'),
            subtitle: const Text('Show the percentage under the score'),
            value: s.showPercent,
            onChanged: (v) => repo.setBool(SettingKeys.showPercent, v),
          ),
          SwitchListTile(
            title: const Text('Ask before replacing a saved score'),
            subtitle: const Text('Default save behavior'),
            value: s.confirmReplace,
            onChanged: (v) => repo.setBool(SettingKeys.confirmReplace, v),
          ),
          const SectionTitle('Recitation settings'),
          if (rec != null)
            ListTile(
              title: const Text('Default recitation points'),
              trailing: Text('${rec.defaultMaxPoints}', style: const TextStyle(fontSize: 20)),
              onTap: () => setCatMax(rec, s.recitationMaxAllowed),
            ),
          ListTile(
            title: const Text('Maximum recitation points'),
            trailing: Text('${s.recitationMaxAllowed}', style: const TextStyle(fontSize: 20)),
            onTap: () =>
                setInt(SettingKeys.recitationMaxAllowed, 'Maximum recitation points', s.recitationMaxAllowed, 1, 1000),
          ),
          ListTile(
            title: const Text('Recitation scoring method'),
            subtitle: Text(s.recitationMethod.label),
            onTap: () async {
              final v = await askChoice(
                context,
                title: 'Recitation scoring',
                options: {for (final m in RecitationMethod.values) m: m.label},
                current: s.recitationMethod,
              );
              if (v != null) await repo.setString(SettingKeys.recitationMethod, v.code);
            },
          ),
          const SectionTitle('Examination settings · MAX'),
          for (final c in exams)
            ListTile(
              title: Text('${c.name} points'),
              trailing: Text('${c.defaultMaxPoints}', style: const TextStyle(fontSize: 20)),
              onTap: () => setCatMax(c, s.examMaxAllowed),
            ),
          ListTile(
            title: const Text('Maximum examination points'),
            trailing: Text('${s.examMaxAllowed}', style: const TextStyle(fontSize: 20)),
            onTap: () => setInt(SettingKeys.examMaxAllowed, 'Maximum examination points', s.examMaxAllowed, 1, 1000),
          ),
          const SectionTitle('General settings'),
          ListTile(
            title: const Text('Default subject and class'),
            subtitle: const Text('Used by the calculator'),
            trailing: const ClassChip(),
            onTap: () => showClassPicker(context),
          ),
          ListTile(
            title: const Text('Academic year'),
            subtitle: Text(s.academicYear.isEmpty ? 'Not set' : s.academicYear),
            onTap: () async {
              final v = await askText(context, title: 'Academic year', initial: s.academicYear, hint: '2026-2027');
              if (v != null) await repo.setString(SettingKeys.academicYear, v);
            },
          ),
          ListTile(
            title: const Text('Semester'),
            subtitle: Text(s.semester.isEmpty ? 'Not set' : s.semester),
            onTap: () async {
              final v = await askChoice(
                context,
                title: 'Semester',
                current: s.semester,
                options: const {
                  '1st Semester': '1st Semester',
                  '2nd Semester': '2nd Semester',
                  'Summer': 'Summer',
                  '1st Trimester': '1st Trimester',
                  '2nd Trimester': '2nd Trimester',
                  '3rd Trimester': '3rd Trimester',
                },
              );
              if (v != null) await repo.setString(SettingKeys.semester, v);
            },
          ),
          ListTile(
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
          SwitchListTile(
            title: const Text('Calculator sound'),
            subtitle: const Text('Click and vibration on each key'),
            value: s.sound,
            onChanged: (v) => repo.setBool(SettingKeys.sound, v),
          ),
          SwitchListTile(
            title: const Text('Confirmation message'),
            subtitle: const Text('Show "Saved: …" after each save'),
            value: s.confirmMessage,
            onChanged: (v) => repo.setBool(SettingKeys.confirmMessage, v),
          ),
          SwitchListTile(
            title: const Text('Continuous-entry mode'),
            subtitle: const Text('After saving, go to the next student without a score'),
            value: s.continuousEntry,
            onChanged: (v) => repo.setBool(SettingKeys.continuousEntry, v),
          ),
        ],
      ),
    );
  }
}
