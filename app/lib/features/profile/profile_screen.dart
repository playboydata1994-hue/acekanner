import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/section_header.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/student_number.dart';
import '../../domain/validators.dart';
import '../../services/branding_store.dart';

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

  /// Logo shown in the form; [_logoChanged] means Save must store or clear it.
  Uint8List? _logo;
  bool _logoChanged = false;
  bool _pickingLogo = false;

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
    _logo = await ref.read(brandingStoreProvider).read(p?.logoPath);
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
      if (_logoChanged) {
        final store = ref.read(brandingStoreProvider);
        final path = _logo == null ? null : await store.saveLogo(_logo!);
        final previous = await repo.setLogoPath(path);
        if (previous != path) await store.delete(previous);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLogo() async {
    if (_pickingLogo) return;
    setState(() => _pickingLogo = true);
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return;
      final bytes = await file.xFile.readAsBytes();
      if (bytes.length > BrandingStore.maxSourceBytes) {
        throw const FormatException('Choose a picture smaller than 15 MB.');
      }
      final png = await BrandingStore.normalize(bytes);
      if (mounted) {
        setState(() {
          _logo = png;
          _logoChanged = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      e is FormatException ? showMessage(context, e.message) : showError(context, e);
    } finally {
      if (mounted) setState(() => _pickingLogo = false);
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
                  const SizedBox(height: Space.l),
                  _LogoField(
                    logo: _logo,
                    busy: _pickingLogo,
                    onPick: _pickLogo,
                    onRemove: () => setState(() {
                      _logo = null;
                      _logoChanged = true;
                    }),
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

/// Optional school logo, printed on answer sheets when switched on there.
class _LogoField extends StatelessWidget {
  const _LogoField({required this.logo, required this.busy, required this.onPick, required this.onRemove});

  final Uint8List? logo;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(4),
          child: logo == null
              ? Icon(Icons.image_outlined, color: theme.colorScheme.onSurfaceVariant)
              : Image.memory(logo!, fit: BoxFit.contain, semanticLabel: 'School logo'),
        ),
        const SizedBox(width: Space.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('School logo (optional)', style: theme.textTheme.titleSmall),
              Text('Printed at the top of answer sheets.', style: theme.textTheme.bodySmall),
              Wrap(
                spacing: Space.s,
                children: [
                  TextButton(
                    onPressed: busy ? null : onPick,
                    child: Text(logo == null ? 'Add logo' : 'Change'),
                  ),
                  if (logo != null) TextButton(onPressed: busy ? null : onRemove, child: const Text('Remove')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
