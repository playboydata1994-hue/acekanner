import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/section_header.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/student_number.dart';
import '../../domain/validators.dart';

/// Instructor details and school information printed on sheets and reports.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _honorific = TextEditingController();
  final _email = TextEditingController();
  final _employeeNo = TextEditingController();
  final _school = TextEditingController();
  final _address = TextEditingController();
  final _department = TextEditingController();
  final _format = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  List<TextEditingController> get _all =>
      [_name, _honorific, _email, _employeeNo, _school, _address, _department, _format];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(profileRepositoryProvider);
    final p = await repo.get();
    _name.text = p?.fullName ?? '';
    _honorific.text = p?.honorific ?? '';
    _email.text = p?.email ?? '';
    _employeeNo.text = p?.employeeNo ?? '';
    _school.text = p?.schoolName ?? '';
    _address.text = p?.schoolAddress ?? '';
    _department.text = p?.department ?? '';
    _format.text = await repo.studentNoFormat();
    _format.addListener(() => setState(() {}));
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.save(
        ProfileInput(
          fullName: _name.text,
          honorific: _honorific.text,
          email: _email.text,
          employeeNo: _employeeNo.text,
          schoolName: _school.text,
          schoolAddress: _address.text,
          department: _department.text,
        ),
      );
      await repo.setStudentNoFormat(_format.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatError = StudentNumber.validateFormat(_format.text);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile and school'),
        actions: [
          TextButton(onPressed: _loading || _saving ? null : _save, child: const Text('Save')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xxl),
                children: [
                  Text(
                    'These details appear on answer sheets and reports.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SectionHeader('Instructor'),
                  Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: TextFormField(
                          controller: _honorific,
                          decoration: const InputDecoration(labelText: 'Title', hintText: 'Prof.'),
                          validator: (v) => Validators.optional(v, max: 20),
                        ),
                      ),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Full name'),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => Validators.required(v, 'your name', max: 120),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.m),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email (optional)'),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: Space.m),
                  TextFormField(
                    controller: _employeeNo,
                    decoration: const InputDecoration(labelText: 'Employee number (optional)'),
                    validator: (v) => Validators.optional(v, max: 40),
                  ),
                  const SectionHeader('School'),
                  TextFormField(
                    controller: _school,
                    decoration: const InputDecoration(labelText: 'School name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.optional(v, max: 160),
                  ),
                  const SizedBox(height: Space.m),
                  TextFormField(
                    controller: _department,
                    decoration: const InputDecoration(labelText: 'College / department'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.optional(v, max: 160),
                  ),
                  const SizedBox(height: Space.m),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'Address (optional)'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.optional(v, max: 240),
                  ),
                  const SectionHeader('Student numbers'),
                  TextFormField(
                    controller: _format,
                    decoration: InputDecoration(
                      labelText: 'Student number format',
                      helperText: formatError == null
                          ? 'Example: ${StudentNumber.example(_format.text)} · '
                              '${StudentNumber.digitsIn(_format.text)} digit columns on new sheets'
                          : null,
                      helperMaxLines: 2,
                    ),
                    validator: (v) => StudentNumber.validateFormat(v ?? ''),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'Use # for each digit, e.g. ####-##### for 2021-00123. Students '
                    'shade the digits on the sheet; numbers with letters need '
                    'personalized (QR) sheets.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: Space.xl),
                  FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
                ],
              ),
            ),
    );
  }
}
