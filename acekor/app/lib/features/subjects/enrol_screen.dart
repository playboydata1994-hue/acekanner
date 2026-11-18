import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/util/text.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';

/// Adds students to a subject: a whole section at once, or one by one.
class EnrolScreen extends ConsumerStatefulWidget {
  const EnrolScreen({super.key, required this.subjectId});
  final String subjectId;

  @override
  ConsumerState<EnrolScreen> createState() => _EnrolScreenState();
}

class _EnrolScreenState extends ConsumerState<EnrolScreen> {
  final Set<String> _picked = {};
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(sectionsProvider).value ?? const [];
    final all = ref.watch(allStudentsProvider).value ?? const [];
    final enrolled = {for (final s in ref.watch(enrolledProvider(widget.subjectId)).value ?? const []) s.id};
    final repo = ref.read(subjectsRepositoryProvider);
    final candidates = all.where((s) => !enrolled.contains(s.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Add students')),
      bottomNavigationBar: _picked.isEmpty
          ? null
          : BottomAction(
              label: 'Add ${_picked.length} student${_picked.length == 1 ? '' : 's'}',
              onPressed: () async {
                final n = await repo.enrolStudents(widget.subjectId, _picked.toList());
                setState(_picked.clear);
                if (context.mounted) showMessage(context, 'Added $n student${n == 1 ? '' : 's'}.');
              },
            ),
      body: ListenableBuilder(
        listenable: _query,
        builder: (context, _) {
          final q = foldForSearch(_query.text.trim());
          final shown = candidates
              .where(
                (s) =>
                    q.isEmpty ||
                    foldForSearch('${s.row.firstName} ${s.row.lastName} ${s.row.studentNo ?? ''}').contains(q),
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (sections.isNotEmpty) ...[
                const SectionTitle('Add a whole section'),
                for (final s in sections)
                  ListTile(
                    leading: const Icon(Icons.groups_outlined, color: AppColors.teal),
                    title: Text(s.name),
                    subtitle: Text('${s.studentCount} students'),
                    trailing: TextButton(
                      onPressed: () async {
                        final n = await repo.enrolSection(widget.subjectId, s.id);
                        if (context.mounted) {
                          showMessage(
                            context,
                            n == 0
                                ? 'Everyone in ${s.name} is already in this class.'
                                : 'Added $n student${n == 1 ? '' : 's'} from ${s.name}.',
                          );
                        }
                      },
                      child: const Text('Add all'),
                    ),
                  ),
              ],
              const SectionTitle('Or choose students'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _query,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search'),
                ),
              ),
              if (candidates.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Every student on the phone is already in this class.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              for (final s in shown)
                CheckboxListTile(
                  value: _picked.contains(s.id),
                  title: Text(s.formal),
                  subtitle: Text(
                    [
                      if (s.row.studentNo != null) s.row.studentNo!,
                      if (s.sectionName != null) s.sectionName!,
                    ].join(' · '),
                  ),
                  onChanged: (v) => setState(() => v! ? _picked.add(s.id) : _picked.remove(s.id)),
                ),
            ],
          );
        },
      ),
    );
  }
}
