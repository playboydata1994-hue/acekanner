import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/widgets/form_sheet.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/classes_repository.dart';
import '../../data/repositories/students_repository.dart';
import '../../domain/student_number.dart';
import '../../domain/validators.dart';

const List<String> commonTerms = [
  '1st Semester',
  '2nd Semester',
  'Summer',
  '1st Trimester',
  '2nd Trimester',
  '3rd Trimester',
];

/// Add or edit a subject. Returns the subject id.
Future<String?> showSubjectForm(BuildContext context, {SubjectRow? subject}) =>
    showFormSheet<String>(context, builder: (_) => _SubjectForm(subject: subject));

class _SubjectForm extends ConsumerStatefulWidget {
  const _SubjectForm({this.subject});

  final SubjectRow? subject;

  @override
  ConsumerState<_SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends ConsumerState<_SubjectForm> {
  late final _code = TextEditingController(text: widget.subject?.code);
  late final _title = TextEditingController(text: widget.subject?.title);
  late final _units = TextEditingController(
    text: widget.subject?.units == null ? '' : _num(widget.subject!.units!),
  );
  late final _description = TextEditingController(text: widget.subject?.description);

  @override
  void dispose() {
    for (final c in [_code, _title, _units, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.subject != null;
    return FormSheet<String>(
      title: editing ? 'Edit subject' : 'New subject',
      submitLabel: editing ? 'Save' : 'Add subject',
      fields: [
        TextFormField(
          controller: _code,
          decoration: const InputDecoration(labelText: 'Subject code', hintText: 'e.g. CS101'),
          textCapitalization: TextCapitalization.characters,
          validator: (v) => Validators.code(v, 'subject code'),
        ),
        TextFormField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Descriptive title', hintText: 'e.g. Programming 1'),
          textCapitalization: TextCapitalization.words,
          validator: (v) => Validators.required(v, 'title'),
        ),
        TextFormField(
          controller: _units,
          decoration: const InputDecoration(labelText: 'Units (optional)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => Validators.number(v, min: 0, max: 12, allowEmpty: true, label: 'the units'),
        ),
        TextFormField(
          controller: _description,
          decoration: const InputDecoration(labelText: 'Description (optional)'),
          maxLines: 2,
          validator: (v) => Validators.optional(v, max: 1000),
        ),
      ],
      onSubmit: () async {
        final repo = ref.read(classesRepositoryProvider);
        final input = SubjectInput(
          code: _code.text,
          title: _title.text,
          units: double.tryParse(_units.text.trim()),
          description: _description.text,
        );
        if (widget.subject == null) return repo.createSubject(input);
        await repo.updateSubject(widget.subject!.id, input);
        return widget.subject!.id;
      },
    );
  }
}

/// Add or edit a course (degree program). Returns the course id.
Future<String?> showCourseForm(BuildContext context, {CourseRow? course}) =>
    showFormSheet<String>(context, builder: (_) => _CourseForm(course: course));

class _CourseForm extends ConsumerStatefulWidget {
  const _CourseForm({this.course});

  final CourseRow? course;

  @override
  ConsumerState<_CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends ConsumerState<_CourseForm> {
  late final _code = TextEditingController(text: widget.course?.code);
  late final _name = TextEditingController(text: widget.course?.name);

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.course != null;
    return FormSheet<String>(
      title: editing ? 'Edit course' : 'New course',
      submitLabel: editing ? 'Save' : 'Add course',
      fields: [
        TextFormField(
          controller: _code,
          decoration: const InputDecoration(labelText: 'Course code', hintText: 'e.g. BSIT'),
          textCapitalization: TextCapitalization.characters,
          validator: (v) => Validators.code(v, 'course code'),
        ),
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Course name',
            hintText: 'e.g. BS Information Technology',
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) => Validators.required(v, 'course name'),
        ),
      ],
      onSubmit: () async {
        final repo = ref.read(classesRepositoryProvider);
        final input = CourseInput(code: _code.text, name: _name.text);
        if (widget.course == null) return repo.createCourse(input);
        await repo.updateCourse(widget.course!.id, input);
        return widget.course!.id;
      },
    );
  }
}

/// Add or edit a section. Returns the section id.
Future<String?> showSectionForm(BuildContext context, {SectionRow? section}) =>
    showFormSheet<String>(context, builder: (_) => _SectionForm(section: section));

class _SectionForm extends ConsumerStatefulWidget {
  const _SectionForm({this.section});

  final SectionRow? section;

  @override
  ConsumerState<_SectionForm> createState() => _SectionFormState();
}

class _SectionFormState extends ConsumerState<_SectionForm> {
  late final _name = TextEditingController(text: widget.section?.name);
  late final _schoolYear = TextEditingController(
    text: widget.section?.schoolYear ?? _currentSchoolYear(),
  );
  late String? _courseId = widget.section?.courseId;
  late int? _yearLevel = widget.section?.yearLevel;
  late String? _term = widget.section?.term;

  @override
  void dispose() {
    _name.dispose();
    _schoolYear.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider).value ?? const <CourseRow>[];
    final terms = {...commonTerms, ?_term}.toList();
    final editing = widget.section != null;
    return FormSheet<String>(
      title: editing ? 'Edit section' : 'New section',
      submitLabel: editing ? 'Save' : 'Add section',
      fields: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Section name', hintText: 'e.g. BSIT 2-A'),
          textCapitalization: TextCapitalization.characters,
          validator: (v) => Validators.required(v, 'section name', max: 60),
        ),
        DropdownButtonFormField<String?>(
          initialValue: courses.any((c) => c.id == _courseId) ? _courseId : null,
          decoration: const InputDecoration(labelText: 'Course (optional)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('None')),
            for (final c in courses)
              DropdownMenuItem(value: c.id, child: Text('${c.code} — ${c.name}', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() => _courseId = v),
        ),
        DropdownButtonFormField<int?>(
          initialValue: _yearLevel,
          decoration: const InputDecoration(labelText: 'Year level (optional)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('None')),
            for (var y = 1; y <= 6; y++)
              DropdownMenuItem(value: y, child: Text(_ordinal(y))),
          ],
          onChanged: (v) => setState(() => _yearLevel = v),
        ),
        TextFormField(
          controller: _schoolYear,
          decoration: const InputDecoration(labelText: 'School year (optional)', hintText: '2026-2027'),
          keyboardType: TextInputType.datetime,
          validator: Validators.schoolYear,
        ),
        DropdownButtonFormField<String?>(
          initialValue: _term,
          decoration: const InputDecoration(labelText: 'Term (optional)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('None')),
            for (final t in terms) DropdownMenuItem(value: t, child: Text(t)),
          ],
          onChanged: (v) => setState(() => _term = v),
        ),
      ],
      onSubmit: () async {
        final repo = ref.read(classesRepositoryProvider);
        final input = SectionInput(
          name: _name.text,
          courseId: _courseId,
          yearLevel: _yearLevel,
          schoolYear: _schoolYear.text,
          term: _term,
        );
        if (widget.section == null) return repo.createSection(input);
        await repo.updateSection(widget.section!.id, input);
        return widget.section!.id;
      },
    );
  }

  static String _currentSchoolYear() {
    final now = DateTime.now();
    // Philippine school years start around June-August.
    final start = now.month >= 6 ? now.year : now.year - 1;
    return '$start-${start + 1}';
  }
}

/// Add a student to a section, or edit a student.
Future<String?> showStudentForm(
  BuildContext context, {
  required String sectionId,
  StudentRow? student,
}) =>
    showFormSheet<String>(
      context,
      builder: (_) => _StudentForm(sectionId: sectionId, student: student),
    );

class _StudentForm extends ConsumerStatefulWidget {
  const _StudentForm({required this.sectionId, this.student});

  final String sectionId;
  final StudentRow? student;

  @override
  ConsumerState<_StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends ConsumerState<_StudentForm> {
  late final _number = TextEditingController(text: widget.student?.studentNo);
  late final _last = TextEditingController(text: widget.student?.lastName);
  late final _first = TextEditingController(text: widget.student?.firstName);
  late final _middle = TextEditingController(text: widget.student?.middleName);
  late final _suffix = TextEditingController(text: widget.student?.suffix);
  late final _email = TextEditingController(text: widget.student?.email);

  @override
  void dispose() {
    for (final c in [_number, _last, _first, _middle, _suffix, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final format = ref.watch(studentNoFormatProvider).value;
    final editing = widget.student != null;
    return FormSheet<String>(
      title: editing ? 'Edit student' : 'Add student',
      submitLabel: editing ? 'Save' : 'Add student',
      fields: [
        TextFormField(
          controller: _number,
          decoration: InputDecoration(
            labelText: 'Student number',
            hintText: format == null ? null : 'e.g. ${StudentNumber.example(format)}',
          ),
          validator: (v) => StudentNumber.validate(v ?? ''),
        ),
        TextFormField(
          controller: _last,
          decoration: const InputDecoration(labelText: 'Last name'),
          textCapitalization: TextCapitalization.words,
          validator: (v) => Validators.required(v, 'last name', max: 80),
        ),
        TextFormField(
          controller: _first,
          decoration: const InputDecoration(labelText: 'First name'),
          textCapitalization: TextCapitalization.words,
          validator: (v) => Validators.required(v, 'first name', max: 80),
        ),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _middle,
                decoration: const InputDecoration(labelText: 'Middle name'),
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.optional(v, max: 80),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _suffix,
                decoration: const InputDecoration(labelText: 'Suffix', hintText: 'Jr.'),
                validator: (v) => Validators.optional(v, max: 10),
              ),
            ),
          ],
        ),
        TextFormField(
          controller: _email,
          decoration: const InputDecoration(labelText: 'Email (optional)'),
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        ),
      ],
      onSubmit: () async {
        final repo = ref.read(studentsRepositoryProvider);
        final input = StudentInput(
          studentNo: _number.text,
          lastName: _last.text,
          firstName: _first.text,
          middleName: _middle.text,
          suffix: _suffix.text,
          email: _email.text,
        );
        if (widget.student != null) {
          await repo.updateStudent(widget.student!.id, input);
          return 'Student updated';
        }
        final result = await repo.addToSection(widget.sectionId, input);
        final name = studentDisplayName(result.student);
        return switch (result.outcome) {
          AddStudentOutcome.added => '$name added',
          AddStudentOutcome.linkedExisting =>
            '$name was already saved, so the existing record was added to this section',
          AddStudentOutcome.alreadyInSection => '$name is already in this section',
        };
      },
    );
  }
}

String _ordinal(int n) => switch (n) {
      1 => '1st year',
      2 => '2nd year',
      3 => '3rd year',
      _ => '${n}th year',
    };

String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
