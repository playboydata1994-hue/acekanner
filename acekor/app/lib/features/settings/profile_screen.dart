import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/settings/settings_repository.dart';

/// Instructor and school details printed on reports.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _school = TextEditingController();
  final _address = TextEditingController();
  final _dept = TextEditingController();
  final _header = TextEditingController();
  final _footer = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    () async {
      final p = await ref.read(rosterRepositoryProvider).profile();
      final s = ref.read(appSettingsProvider);
      _name.text = p.instructorName;
      _school.text = p.schoolName;
      _address.text = p.schoolAddress;
      _dept.text = p.department;
      _header.text = s.reportHeaderLine;
      _footer.text = s.reportFooterLine;
      if (mounted) setState(() => _loaded = true);
    }();
  }

  @override
  void dispose() {
    for (final c in [_name, _school, _address, _dept, _header, _footer]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await ref
        .read(rosterRepositoryProvider)
        .saveProfile(
          instructorName: _name.text,
          schoolName: _school.text,
          schoolAddress: _address.text,
          department: _dept.text,
        );
    await ref.read(settingsRepositoryProvider).setMany({
      SettingKeys.reportHeaderLine: _header.text.trim(),
      SettingKeys.reportFooterLine: _footer.text.trim(),
    });
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instructor and school')),
      bottomNavigationBar: BottomAction(label: 'Save', onPressed: _loaded ? _save : null),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Field(controller: _name, label: 'Instructor name (e.g. Prof. Maria Santos)'),
                Field(controller: _school, label: 'School name'),
                Field(controller: _address, label: 'School address (optional)'),
                Field(controller: _dept, label: 'College / department (optional)'),
                const SectionTitle('Report headings'),
                Field(
                  controller: _header,
                  label: 'Extra heading line (optional)',
                  textCapitalization: TextCapitalization.sentences,
                ),
                Field(
                  controller: _footer,
                  label: 'Footer line (optional, e.g. "Prepared by:")',
                  textCapitalization: TextCapitalization.sentences,
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Text(
                    'These appear at the top and bottom of every PDF and Excel report.',
                    style: TextStyle(color: AppColors.muted, fontSize: 16),
                  ),
                ),
              ],
            ),
    );
  }
}
