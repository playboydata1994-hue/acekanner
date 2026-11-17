import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/section_header.dart';
import '../../data/repositories/grading_repository.dart';
import '../../data/repositories/students_repository.dart';
import '../../domain/answer_mask.dart';
import '../../domain/grading.dart';
import 'result_widgets.dart';

enum _Filter { all, wrong, corrected }

/// One student's graded paper: score, breakdown, and question-by-question
/// verification with corrections.
class PaperResultScreen extends ConsumerStatefulWidget {
  const PaperResultScreen({super.key, required this.sheetId});

  final String sheetId;

  @override
  ConsumerState<PaperResultScreen> createState() => _PaperResultScreenState();
}

class _PaperResultScreenState extends ConsumerState<PaperResultScreen> {
  _Filter _filter = _Filter.all;

  Future<void> _correct(PaperDetail d, int q) async {
    final current = d.answers.firstWhere((a) => a.questionNo == q).finalMask ?? 0;
    final mask = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) => _CorrectSheet(question: q, current: current),
    );
    if (mask == null || mask == current) return;
    try {
      await ref.read(gradingRepositoryProvider).correctAnswers(d.sheet.id, {q: mask});
      if (mounted) showMessage(context, 'Question $q corrected and the score updated');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void _viewSheet(String path) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Scanned sheet')),
        body: InteractiveViewer(maxScale: 6, child: Center(child: Image.file(File(path)))),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(paperDetailProvider(widget.sheetId));
    return switch (detail) {
      AsyncData(:final value) when value == null =>
        Scaffold(appBar: AppBar(), body: const Center(child: Text('This paper no longer exists.'))),
      AsyncData(:final value) => _body(context, value!),
      AsyncError() => Scaffold(appBar: AppBar(), body: const Center(child: Text('Could not load this paper.'))),
      _ => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
    };
  }

  Widget _body(BuildContext context, PaperDetail d) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final student = d.student;
    final g = d.grade;
    final r = d.result;
    final corrected = {for (final a in d.answers) if (a.resolvedBy == 'instructor') a.questionNo};
    final questions = g == null
        ? const <QuestionGrade>[]
        : g.questions.where((q) => switch (_filter) {
              _Filter.all => true,
              _Filter.wrong => q.outcome == ItemOutcome.incorrect || q.outcome == ItemOutcome.multiple || q.outcome == ItemOutcome.blank,
              _Filter.corrected => corrected.contains(q.questionNo),
            }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(student == null ? 'Paper' : studentDisplayName(student), overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xxl),
        children: [
          Text(
            [
              ?student?.studentNo,
              if (d.version != null) 'Set ${d.version!.label}',
              'Scanned ${DateFormat('d MMM y, h:mm a').format(d.sheet.capturedAt)}',
            ].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Space.l),
          if (r == null || g == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.l),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top, color: colors.uncertain),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Text(
                        d.sheet.studentId == null
                            ? 'Awaiting grading: the student was not identified.'
                            : 'Awaiting grading: the answer key is not complete yet. It is graded automatically when you finish the key.',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(fmtPercent(r.percentage), style: theme.textTheme.displaySmall),
                        const SizedBox(width: Space.m),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${fmtNumber(r.earnedPoints)} / ${fmtNumber(r.possiblePoints)} points',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.s),
                    PassPill(passed: r.passed),
                    const SizedBox(height: Space.l),
                    Wrap(
                      spacing: Space.l,
                      runSpacing: Space.s,
                      children: [
                        _Count(icon: Icons.check_circle, color: colors.correct, label: 'Correct', value: r.correctCount),
                        _Count(icon: Icons.cancel, color: colors.incorrect, label: 'Wrong', value: r.incorrectCount),
                        _Count(icon: Icons.remove_circle_outline, color: colors.blank, label: 'No answer', value: r.blankCount),
                        _Count(icon: Icons.error, color: colors.incorrect, label: 'More than one', value: r.multipleCount),
                      ],
                    ),
                    const SizedBox(height: Space.m),
                    Text(
                      'Graded with answer key revision ${d.keyRevision} · '
                      'passing ${fmtNumber(d.exam.passingPercentage)}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          if (d.sheet.rectifiedImagePath != null) ...[
            const SizedBox(height: Space.m),
            OutlinedButton.icon(
              onPressed: () => _viewSheet(d.sheet.rectifiedImagePath!),
              icon: const Icon(Icons.image_outlined),
              label: const Text('View scanned sheet'),
            ),
          ],
          if (g != null) ...[
            const SectionHeader('Question by question'),
            SegmentedButton<_Filter>(
              segments: [
                const ButtonSegment(value: _Filter.all, label: Text('All')),
                const ButtonSegment(value: _Filter.wrong, label: Text('Not correct')),
                ButtonSegment(value: _Filter.corrected, label: Text('Changed (${corrected.length})')),
              ],
              selected: {_filter},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
            const SizedBox(height: Space.s),
            Text('Tap a question to correct how it was read.', style: theme.textTheme.bodySmall),
            const SizedBox(height: Space.s),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (questions.isEmpty)
                    const Padding(padding: EdgeInsets.all(Space.l), child: Text('No questions in this view.')),
                  for (var i = 0; i < questions.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _QuestionRow(
                      q: questions[i],
                      corrected: corrected.contains(questions[i].questionNo),
                      onTap: () => _correct(d, questions[i].questionNo),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.color, required this.label, required this.value});

  final IconData icon;
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({required this.q, required this.corrected, required this.onTap});

  final QuestionGrade q;
  final bool corrected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label, color) = outcomeStyle(context, q.outcome);
    final answer = q.answerMask == AnswerMask.markedWrong ? 'marked wrong' : AnswerMask.describe(q.answerMask);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
        child: Row(
          children: [
            SizedBox(width: 36, child: Text('${q.questionNo}', style: theme.textTheme.titleSmall)),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Answer $answer', style: theme.textTheme.bodyMedium),
                    TextSpan(
                      text: '   Key ${AnswerMask.format(q.correctMask)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    if (corrected)
                      TextSpan(
                        text: '   · changed by you',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                  ],
                ),
              ),
            ),
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            SizedBox(width: 92, child: Text(label, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }
}

class _CorrectSheet extends StatefulWidget {
  const _CorrectSheet({required this.question, required this.current});

  final int question;
  final int current;

  @override
  State<_CorrectSheet> createState() => _CorrectSheetState();
}

class _CorrectSheetState extends State<_CorrectSheet> {
  late int _mask = widget.current == AnswerMask.markedWrong ? 0 : widget.current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Correct question ${widget.question}', style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xs),
            const Text('Set what the student actually shaded, or mark the answer wrong. The score updates and the change is recorded.'),
            const SizedBox(height: Space.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var c = 0; c < 5; c++)
                  Semantics(
                    button: true,
                    selected: AnswerMask.has(_mask, c),
                    label: 'Choice ${AnswerMask.labels[c]}',
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => setState(() => _mask = AnswerMask.toggle(_mask, c)),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AnswerMask.has(_mask, c) ? scheme.primary : Colors.transparent,
                          border: Border.all(color: AnswerMask.has(_mask, c) ? scheme.primary : scheme.outline, width: 1.5),
                        ),
                        child: Text(
                          AnswerMask.labels[c],
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AnswerMask.has(_mask, c) ? scheme.onPrimary : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.l),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.of(context).pop(0), child: const Text('No answer')),
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(AnswerMask.markedWrong),
                    style: OutlinedButton.styleFrom(foregroundColor: context.statusColors.incorrect),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Wrong'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.s),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _mask == 0 ? null : () => Navigator.of(context).pop(_mask),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
