import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../data/repositories/grading_repository.dart';
import '../../data/repositories/students_repository.dart';
import '../../domain/analytics.dart';
import '../../domain/answer_mask.dart';
import 'result_widgets.dart';

/// Class results for one examination: summary, distribution, item analysis
/// and the ranked list of papers. Filters: section and exam set.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key, required this.examId});

  final String examId;

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? _sectionId;
  String? _versionId;
  bool _allItems = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(examAnalyticsProvider(widget.examId));
    return Scaffold(
      appBar: AppBar(title: const Text('Class results')),
      body: switch (data) {
        AsyncData(:final value) => _body(context, value),
        AsyncError() => const Center(child: Text('Could not load the results.')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _body(BuildContext context, ExamAnalytics a) {
    final theme = Theme.of(context);
    if (a.papers.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(Space.page),
        children: const [
          EmptyState(
            icon: Icons.insights_outlined,
            title: 'No graded papers yet',
            message: 'Results appear here as soon as papers are scanned and graded.',
          ),
        ],
      );
    }
    final multiSet = a.versions.length > 1;
    final itemVersion = _versionId ?? a.versions.first.id;
    final stats = a.stats(sectionId: _sectionId, versionId: _versionId);
    final items = a.items(itemVersion, sectionId: _sectionId);
    final scored = items.where((i) => i.scored && i.takers > 0).toList();
    final missed = [...scored]..sort((x, y) => x.difficulty.compareTo(y.difficulty));
    final papers = a.filtered(sectionId: _sectionId, versionId: _versionId)
      ..sort((x, y) => y.grade.percentage.compareTo(x.grade.percentage));

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xxl),
      children: [
        Text(a.exam.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: Space.m),
        // Filters in one row above the results.
        Wrap(
          spacing: Space.m,
          runSpacing: Space.s,
          children: [
            if (a.sections.isNotEmpty)
              _Dropdown<String?>(
                value: _sectionId,
                items: {null: 'All sections', for (final s in a.sections) s.id: s.name},
                onChanged: (v) => setState(() => _sectionId = v),
              ),
            if (multiSet)
              _Dropdown<String?>(
                value: _versionId,
                items: {null: 'All sets', for (final v in a.versions) v.id: 'Set ${v.label}'},
                onChanged: (v) => setState(() => _versionId = v),
              ),
          ],
        ),
        const SectionHeader('Summary'),
        _StatGrid(stats: stats),
        const SectionHeader('Score distribution'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.m, Space.l, Space.m, Space.s),
            child: ScoreHistogram(bins: stats.histogram, passingPercentage: a.exam.passingPercentage),
          ),
        ),
        SectionHeader(
          multiSet ? 'Most missed questions · Set ${a.versions.firstWhere((v) => v.id == itemVersion).label}' : 'Most missed questions',
        ),
        if (multiSet && _versionId == null)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s),
            child: Text(
              'Question analysis is per exam set (each set has its own key). Showing Set A; choose a set above.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < missed.length && i < (_allItems ? missed.length : 10); i++) ...[
                if (i > 0) const Divider(height: 1),
                _ItemRow(item: missed[i]),
              ],
            ],
          ),
        ),
        if (missed.length > 10)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _allItems = !_allItems),
              child: Text(_allItems ? 'Show top 10' : 'Show all ${missed.length} questions'),
            ),
          ),
        Text(
          'Correct = share of papers that got it right. Discrimination compares the top and bottom '
          '27 % of papers: near 0 or negative means the question did not separate strong from weak '
          'students. Check its wording or key.',
          style: theme.textTheme.bodySmall,
        ),
        SectionHeader('Papers · ${papers.length}'),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < papers.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  leading: SizedBox(
                    width: 28,
                    child: Text('${i + 1}', style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
                  ),
                  title: Text(papers[i].student == null ? 'Student not identified' : studentDisplayName(papers[i].student!)),
                  subtitle: Text(
                    '${fmtNumber(papers[i].grade.earned)} / ${fmtNumber(papers[i].grade.possible)} · ${fmtPercent(papers[i].grade.percentage)}',
                  ),
                  trailing: PassPill(passed: papers[i].grade.passed),
                  onTap: () => context.push('/exams/${widget.examId}/papers/${papers[i].sheetId}'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({required this.value, required this.items, required this.onChanged});

  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DropdownMenu<T>(
        initialSelection: value,
        requestFocusOnTap: false,
        dropdownMenuEntries: [
          for (final e in items.entries) DropdownMenuEntry(value: e.key, label: e.value),
        ],
        onSelected: (v) => onChanged(v as T),
      );
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final ScoreStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Papers', '${stats.count}'),
      ('Average', fmtPercent(stats.mean)),
      ('Median', fmtPercent(stats.median)),
      ('Highest', fmtPercent(stats.highest)),
      ('Lowest', fmtPercent(stats.lowest)),
      ('Passed', '${stats.passed} · ${fmtPercent(stats.passRate)}'),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth > 520 ? 3 : 2;
        final width = (c.maxWidth - (columns - 1) * Space.m) / columns;
        return Wrap(
          spacing: Space.m,
          runSpacing: Space.m,
          children: [
            for (final (label, value) in tiles)
              SizedBox(
                width: width,
                child: Card(
                  child: Semantics(
                    container: true,
                    label: '$label: $value',
                    excludeSemantics: true,
                    child: Padding(
                      padding: const EdgeInsets.all(Space.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: Space.xs),
                          Text(value, style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final ItemStat item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final d = item.discrimination;
    final weak = d != null && d < 0.2;
    final distractor = item.topDistractor;
    final choices = [
      for (var c = 0; c < 5; c++)
        '${AnswerMask.labels[c]}${AnswerMask.has(item.correctMask, c) ? '✓' : ''} ${item.choiceCounts[c]}',
      if (item.blank > 0) 'blank ${item.blank}',
      if (item.multiple > 0) 'multiple ${item.multiple}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 44, child: Text('Q${item.questionNo}', style: theme.textTheme.titleSmall)),
              Expanded(child: Meter(value: item.difficulty)),
              const SizedBox(width: Space.m),
              SizedBox(
                width: 92,
                child: Text(
                  '${(item.difficulty * 100).round()}% correct',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    'Key ${AnswerMask.format(item.correctMask)}',
                    item.difficultyLabel,
                    if (distractor != null) 'most chose ${AnswerMask.labels[distractor]}',
                    if (d != null) 'discrimination ${d.toStringAsFixed(2)}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
                Text(choices, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                if (weak)
                  Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 14, color: colors.uncertain),
                      const SizedBox(width: 4),
                      Text('Review this question', style: theme.textTheme.bodySmall),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
