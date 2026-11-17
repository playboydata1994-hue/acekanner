import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/spacing.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/students_repository.dart';

/// Opens the student list of an examination (search by name or number, or all
/// students) and returns the chosen student.
Future<StudentRow?> pickStudent(
  BuildContext context, {
  required List<StudentRow> roster,
  required String detected,
  Set<String> withPaper = const {},
}) =>
    showModalBottomSheet<StudentRow>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => StudentPicker(roster: roster, detected: detected, withPaper: withPaper),
    );

/// Search list of students, used when a paper's student is chosen by hand.
class StudentPicker extends ConsumerStatefulWidget {
  const StudentPicker({super.key, required this.roster, required this.detected, this.withPaper = const {}});

  /// Students in the examination's sections.
  final List<StudentRow> roster;

  /// Student number shaded on the paper ('' when none).
  final String detected;

  /// Students who already have a saved paper for this examination.
  final Set<String> withPaper;

  @override
  ConsumerState<StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends ConsumerState<StudentPicker> {
  final _query = TextEditingController();
  List<StudentRow>? _others;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _searchAll() async {
    final found = await ref.read(studentsRepositoryProvider).search(_query.text);
    if (mounted) setState(() => _others = found);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final roster = widget.roster
        .where((s) => q.isEmpty || studentDisplayName(s).toLowerCase().contains(q) || s.studentNoKey.contains(q))
        .toList();
    final list = _others ?? roster;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: TextField(
                controller: _query,
                decoration: InputDecoration(
                  hintText: 'Search name or number',
                  prefixIcon: const Icon(Icons.search),
                  helperText: widget.detected.isEmpty ? null : 'Shaded on the paper: ${widget.detected}',
                ),
                onChanged: (_) => setState(() => _others = null),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _searchAll,
                child: Text(_others == null ? 'Search all students' : 'Showing all students'),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('No matching students.'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) => ListTile(
                        title: Text(studentDisplayName(list[i])),
                        subtitle: Text(
                          widget.withPaper.contains(list[i].id) ? '${list[i].studentNo} · has a paper' : list[i].studentNo,
                        ),
                        onTap: () => Navigator.of(context).pop(list[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
