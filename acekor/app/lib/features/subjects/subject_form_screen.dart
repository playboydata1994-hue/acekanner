import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/errors.dart';
import '../../data/repositories/subjects_repository.dart';
import '../calculator/calculator_controller.dart';

class SubjectFormScreen extends ConsumerStatefulWidget {
  const SubjectFormScreen({super.key, this.subjectId});
  final String? subjectId;

  @override
  ConsumerState<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends ConsumerState<SubjectFormScreen> {
  final _code = TextEditingController();
  final _title = TextEditingController();
  final _ay = TextEditingController();
  final _sem = TextEditingController();
  bool _saving = false;

  bool get _editing => widget.subjectId != null;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _ay.text = settings.academicYear;
    _sem.text = settings.semester;
    if (_editing) {
      ref.read(subjectsRepositoryProvider).subject(widget.subjectId!).then((s) {
        if (s == null || !mounted) return;
        setState(() {
          _code.text = s.code;
          _title.text = s.title;
          _ay.text = s.academicYear;
          _sem.text = s.semester;
        });
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_code, _title, _ay, _sem]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final input = SubjectInput(code: _code.text, title: _title.text, academicYear: _ay.text, semester: _sem.text);
    final repo = ref.read(subjectsRepositoryProvider);
    try {
      if (_editing) {
        await repo.updateSubject(widget.subjectId!, input);
        if (mounted) context.pop();
      } else {
        final id = await repo.createSubject(input);
        // The new subject becomes the calculator's class when none is set.
        if (ref.read(calculatorProvider).subjectId == null) {
          await ref.read(calculatorProvider.notifier).selectClass(id);
        }
        if (mounted) context.pushReplacement(Routes.subject(id));
      }
    } on DataError catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit subject' : 'New subject')),
      bottomNavigationBar: BottomAction(label: 'Save', onPressed: _saving ? null : _save),
      body: ListView(
        children: [
          Field(
            controller: _code,
            label: 'Subject code (e.g. IT 101)',
            autofocus: !_editing,
            textCapitalization: TextCapitalization.characters,
          ),
          Field(controller: _title, label: 'Descriptive title (optional)'),
          Field(controller: _ay, label: 'Academic year (e.g. 2026-2027)'),
          Field(controller: _sem, label: 'Semester (e.g. 1st Semester)'),
          if (!_editing)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'A new subject starts with these weights: Quizzes 30%, Recitation 20%, Midterm 20%, Final 20%, '
                'Practical 10%, and the 1.00–5.00 grade scale. You can change both in the subject\'s Grading tab.',
                style: TextStyle(fontSize: 16, height: 1.4, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
