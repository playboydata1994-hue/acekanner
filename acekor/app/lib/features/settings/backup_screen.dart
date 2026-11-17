import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../../app/bootstrap.dart';
import '../../app/licensing_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/backup/backup_service.dart';
import '../../data/settings/settings_repository.dart';
import '../../services/files.dart';
import '../calculator/calculator_controller.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider), clock: ref.watch(clockProvider)),
);

final _countsProvider = FutureProvider.autoDispose<Map<String, int>>(
  (ref) => ref.watch(backupServiceProvider).currentCounts(),
);

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  Future<String?> _askPassword({required bool twice}) async {
    final a = TextEditingController();
    final b = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(twice ? 'Backup password' : 'Password of this backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (twice)
                const Text(
                  'The backup is locked with this password. Without it the backup cannot be restored — write it down.',
                  style: TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: a,
                autofocus: true,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (twice) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: b,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Type it again'),
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error!, style: const TextStyle(color: AppColors.red)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (twice && a.text.length < 6) {
                  setState(() => error = 'Use at least 6 characters.');
                  return;
                }
                if (twice && a.text != b.text) {
                  setState(() => error = 'The passwords do not match.');
                  return;
                }
                Navigator.pop(context, a.text);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final password = await _askPassword(twice: true);
    if (password == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final version = (await ref.read(packageInfoProvider.future)).version;
      final bytes = await ref.read(backupServiceProvider).create(password, appVersion: version);
      final name = 'ACEKOR-backup-${DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now())}.${BackupService.extension}';
      if (!mounted) return;
      final how = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(name), subtitle: Text('${(bytes.length / 1024).toStringAsFixed(1)} KB · encrypted')),
              ListTile(
                leading: const Icon(Icons.save_alt, color: AppColors.teal),
                title: const Text('Save to the phone or a drive'),
                onTap: () => Navigator.pop(context, 'save'),
              ),
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.teal),
                title: const Text('Share (Google Drive, email…)'),
                onTap: () => Navigator.pop(context, 'share'),
              ),
            ],
          ),
        ),
      );
      if (how == null) return;
      if (how == 'save') {
        if (!await saveFileAs(bytes, name, mimeType: Mime.backup)) return;
      } else {
        await shareFile(bytes, name, mimeType: Mime.backup, subject: 'ACEKOR backup');
      }
      await ref
          .read(settingsRepositoryProvider)
          .setString(SettingKeys.lastBackupAt, '${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) showMessage(context, 'Backup created: $name');
    } catch (e) {
      if (mounted) showMessage(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Keeps a copy of the current (encrypted) database before a restore.
  Future<void> _safetyCopy() async {
    final boot = ref.read(bootstrapControllerProvider).value;
    if (boot is! BootstrapReady) return;
    final db = ref.read(databaseProvider);
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    final file = boot.databaseFile;
    if (!await file.exists()) return;
    final stamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    await file.copy(p.join(file.parent.path, 'acekor.before-restore-$stamp.db'));
    final old =
        file.parent
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith('acekor.before-restore-'))
            .toList()
          ..sort((a, b) => b.path.compareTo(a.path));
    for (final f in old.skip(2)) {
      await f.delete();
    }
  }

  Future<void> _restore() async {
    final picked = await pickFile();
    if (picked == null || !mounted) return;
    final service = ref.read(backupServiceProvider);
    final Uint8List bytes = picked.bytes;
    BackupHeader header;
    try {
      header = service.readHeader(bytes);
    } on BackupException catch (e) {
      showMessage(context, e.message, error: true);
      return;
    }
    final password = await _askPassword(twice: false);
    if (password == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final contents = await service.open(bytes, password);
      if (!mounted) return;
      final ok = await confirm(
        context,
        title: 'Restore this backup?',
        message:
            '${picked.name}\n'
            'Made ${DateFormat('MMMM d, y – h:mm a').format(header.created.toLocal())} · ${(bytes.length / 1024).toStringAsFixed(1)} KB\n\n'
            '${contents.count('students')} students · ${contents.count('subjects')} subjects · '
            '${contents.count('activities')} activities · ${contents.count('scores')} scores\n\n'
            'ALL records now on this phone will be REPLACED by the backup. A safety copy of the current records is kept on the phone.',
        confirmLabel: 'Replace and restore',
        destructive: true,
      );
      if (!ok) return;
      await _safetyCopy();
      await service.restore(contents);
      ref.invalidate(calculatorProvider);
      if (mounted) showMessage(context, 'Backup restored.');
    } on BackupException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } catch (e) {
      if (mounted) showMessage(context, 'The backup could not be restored ($e). Nothing was changed.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
      ref.invalidate(_countsProvider);
    }
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    final problems = await ref.read(databaseProvider).integrityProblems();
    if (!mounted) return;
    setState(() => _busy = false);
    showMessage(
      context,
      problems.isEmpty ? 'Database check passed: everything is in order.' : 'Problem found: ${problems.first}',
      error: problems.isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = ref.watch(appSettingsProvider).lastBackupAt;
    final counts = ref.watch(_countsProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup and restore')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber, color: AppColors.amber, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your records are stored only on this phone. Uninstalling ACEKOR or clearing its data erases them. '
                    'Make a backup regularly and keep it somewhere safe (Google Drive, email, flash drive).',
                    style: TextStyle(fontSize: 16, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Last backup'),
            subtitle: Text(last == null ? 'Never' : DateFormat('MMMM d, y – h:mm a').format(last)),
          ),
          if (counts != null)
            ListTile(
              title: const Text('On this phone'),
              subtitle: Text(
                '${counts['students']} students · ${counts['subjects']} subjects · '
                '${counts['activities']} activities · ${counts['scores']} scores',
              ),
            ),
          const SectionTitle('Backup'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilledButton.icon(
              onPressed: _busy ? null : _create,
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Create backup'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Includes students, subjects, sections, grading set-up, all scores and their history, and settings. '
              'The file is encrypted with your backup password.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          const SectionTitle('Restore'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore),
              label: const Text('Restore from a backup file'),
            ),
          ),
          const SectionTitle('Database'),
          ListTile(
            leading: const Icon(Icons.health_and_safety_outlined, color: AppColors.teal),
            title: const Text('Check the database'),
            subtitle: const Text('Integrity and link check'),
            onTap: _busy ? null : _check,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
