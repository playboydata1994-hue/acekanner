import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/licensing_providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/repositories/scores_repository.dart';
import '../../domain/categories.dart';
import '../../domain/grading/grading_engine.dart';
import '../../domain/scoring/percent.dart';

/// A subject's records: weighted grades, activity results and class summary.
class GradebookScreen extends ConsumerStatefulWidget {
  const GradebookScreen({super.key, required this.subjectId});
  final String subjectId;

  @override
  ConsumerState<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends ConsumerState<GradebookScreen> {
  String? _sectionId;

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(gradebookProvider((subjectId: widget.subjectId, sectionId: _sectionId)));
    final all = ref.watch(enrolledProvider(widget.subjectId)).value ?? const [];
    final sectionNames = <String, String>{
      for (final s in all)
        if (s.row.sectionId != null) s.row.sectionId!: s.sectionName ?? '',
    };
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(book.value?.subject.code ?? 'Records'),
          actions: [
            IconButton(
              tooltip: 'Reports',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => context.push(Routes.reports),
            ),
          ],
          bottom: const TabBar(
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'Grades'),
              Tab(text: 'Activities'),
              Tab(text: 'Summary'),
            ],
          ),
        ),
        body: AsyncView(
          value: book,
          builder: (b) {
            if (b == null) return const Center(child: Text('Subject not found.'));
            final chips = sectionNames.length > 1
                ? SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: const Text('All sections'),
                            selected: _sectionId == null,
                            onSelected: (_) => setState(() => _sectionId = null),
                          ),
                        ),
                        for (final e in sectionNames.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(e.value),
                              selected: _sectionId == e.key,
                              onSelected: (_) => setState(() => _sectionId = e.key),
                            ),
                          ),
                      ],
                    ),
                  )
                : null;
            return TabBarView(
              children: [
                _GradesTab(book: b, header: chips),
                _ActivitiesTab(book: b, header: chips),
                _SummaryTab(book: b, header: chips),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GradesTab extends StatelessWidget {
  const _GradesTab({required this.book, this.header});
  final Gradebook book;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        ?header,
        if (!book.engine.weightsValid)
          ListTile(
            leading: const Icon(Icons.warning_amber, color: AppColors.amber),
            title: const Text('Grading weights are not 100%'),
            subtitle: const Text('Set them in the subject\'s Grading tab to compute weighted grades.'),
            onTap: () => context.push(Routes.grading(book.subject.id)),
          ),
        if (book.students.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No students in this class.', style: TextStyle(color: AppColors.muted)),
          ),
        for (final s in book.students) _StudentGradeTile(book: book, studentId: s.id),
      ],
    );
  }
}

class _StudentGradeTile extends StatelessWidget {
  const _StudentGradeTile({required this.book, required this.studentId});
  final Gradebook book;
  final String studentId;

  @override
  Widget build(BuildContext context) {
    final s = book.students.firstWhere((x) => x.id == studentId);
    final g = book.grades[studentId]!;
    return ExpansionTile(
      title: Text(s.formal, style: const TextStyle(fontSize: 18)),
      subtitle: Text(
        g.percent == null
            ? 'No grade yet'
            : '${g.complete ? 'Final' : 'Running'} · ${g.componentsCounted}/${g.componentsWeighted} components'
                  '${g.missingCount > 0 ? ' · ${g.missingCount} missing' : ''}',
      ),
      trailing: g.percent == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatPercent(g.percent!), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                if (g.equivalent != null)
                  Text(
                    g.equivalent!.grade,
                    style: TextStyle(fontSize: 16, color: g.passed == false ? AppColors.red : AppColors.teal),
                  ),
              ],
            ),
      children: [
        for (final c in g.categories.where((c) => c.hasActivities || c.counts))
          ListTile(
            dense: true,
            title: Text('${c.category.name} · ${formatBp(c.category.weightBp)}', style: const TextStyle(fontSize: 16)),
            subtitle: Text(
              c.hasActivities
                  ? '${c.earned}/${c.possible} points · ${c.activityCount} activit${c.activityCount == 1 ? 'y' : 'ies'}'
                        '${c.missingCount > 0 ? ' · ${c.missingCount} missing' : ''}'
                  : 'No activities yet',
            ),
            trailing: c.percent == null
                ? null
                : Text(
                    '${formatPercent(c.percent!)}${c.contribution == null || !c.counts ? '' : '  →  ${formatPercent(c.contribution!).replaceAll('%', '')}'}',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        TextButton(onPressed: () => context.push(Routes.student(studentId)), child: const Text('Open student record')),
      ],
    );
  }
}

class _ActivitiesTab extends StatelessWidget {
  const _ActivitiesTab({required this.book, this.header});
  final Gradebook book;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        ?header,
        for (final k in CategoryKind.values) ...[
          if (book.activities.any((a) => a.kind == k))
            SectionTitle(switch (k) {
              CategoryKind.quiz => 'Quizzes',
              CategoryKind.recitation => 'Recitations',
              CategoryKind.exam => 'Examinations',
            }),
          for (final a in book.activities.where((a) => a.kind == k))
            Builder(
              builder: (context) {
                final st = book.stats(a);
                return ListTile(
                  title: Text(a.label),
                  subtitle: Text(
                    '${st.recorded}/${st.total} recorded'
                    '${st.highest == null ? '' : ' · high ${st.highest} · low ${st.lowest}'}',
                  ),
                  trailing: Text(
                    st.average == null ? '—' : formatPercent(st.average!),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  onTap: () => context.push(Routes.activity(a.id)),
                );
              },
            ),
          if (k == CategoryKind.recitation && book.activities.any((a) => a.kind == k))
            _AccumulatedRecitation(book: book),
        ],
        if (book.activities.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No activities yet.', style: TextStyle(color: AppColors.muted)),
          ),
      ],
    );
  }
}

/// Accumulated recitation points and average per student.
class _AccumulatedRecitation extends StatelessWidget {
  const _AccumulatedRecitation({required this.book});
  final Gradebook book;

  @override
  Widget build(BuildContext context) {
    final recs = book.activities.where((a) => a.kind == CategoryKind.recitation).toList();
    final possible = recs.fold(0, (s, a) => s + a.maxPoints);
    return ExpansionTile(
      leading: const Icon(Icons.functions, color: AppColors.teal),
      title: const Text('Accumulated recitation scores'),
      subtitle: Text('${recs.length} recitations · $possible points possible'),
      children: [
        for (final s in book.students)
          Builder(
            builder: (context) {
              final earned = recs.fold(0, (sum, a) => sum + (book.scoreOf(s.id, a.id) ?? 0));
              return ListTile(
                dense: true,
                title: Text(s.formal, style: const TextStyle(fontSize: 16)),
                trailing: Text(
                  '$earned/$possible  ${possible == 0 ? '' : scorePercentText(earned, possible)}',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  const _SummaryTab({required this.book, this.header});
  final Gradebook book;
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMax = ref.watch(planStatusProvider).hasMax;
    final grades = book.grades.values.where((g) => g.percent != null).toList();
    final passed = grades.where((g) => g.passed == true).length;
    final failed = grades.where((g) => g.passed == false).length;
    final dist = <String, int>{};
    for (final g in grades) {
      final e = g.equivalent?.grade;
      if (e != null) dist[e] = (dist[e] ?? 0) + 1;
    }
    final avg = book.classAverage;
    final sorted = [...grades]..sort((a, b) => b.percent!.compareTo(a.percent!));
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        ?header,
        ListTile(
          title: const Text('Class average'),
          trailing: Text(
            avg == null ? '—' : formatPercent(avg),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        ListTile(
          title: const Text('Students with a grade'),
          trailing: Text('${grades.length}/${book.students.length}', style: const TextStyle(fontSize: 18)),
        ),
        if (book.scale != null) ...[
          ListTile(
            title: const Text('Passed'),
            trailing: Text('$passed', style: const TextStyle(fontSize: 18, color: AppColors.save)),
          ),
          ListTile(
            title: const Text('Failed'),
            trailing: Text('$failed', style: const TextStyle(fontSize: 18, color: AppColors.red)),
          ),
        ],
        ListTile(
          title: const Text('Combining activities'),
          subtitle: Text(CombineMethod.parse(book.subject.combineMethod).label),
        ),
        const SectionTitle('Analytics · MAX'),
        if (!hasMax)
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Grade distribution, highest and lowest grades'),
            subtitle: const Text('Part of MAX'),
            onTap: () => context.push(Routes.plan),
          )
        else ...[
          if (sorted.isNotEmpty) ...[
            ListTile(
              title: const Text('Highest grade'),
              trailing: Text(formatPercent(sorted.first.percent!), style: const TextStyle(fontSize: 18)),
            ),
            ListTile(
              title: const Text('Lowest grade'),
              trailing: Text(formatPercent(sorted.last.percent!), style: const TextStyle(fontSize: 18)),
            ),
          ],
          if (dist.isNotEmpty)
            for (final e in (dist.entries.toList()..sort((a, b) => a.key.compareTo(b.key))))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(e.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: e.value / grades.length,
                        minHeight: 18,
                        borderRadius: BorderRadius.circular(9),
                        color: AppColors.teal,
                        backgroundColor: AppColors.key,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text('${e.value}', textAlign: TextAlign.end, style: const TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
        ],
      ],
    );
  }
}
