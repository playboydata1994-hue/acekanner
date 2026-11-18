import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/scan_repository.dart';
import '../../data/repositories/students_repository.dart';
import '../../domain/answer_mask.dart';
import '../../domain/grading.dart';
import '../../domain/omr_reading.dart';
import '../results/result_widgets.dart';

/// Quick check result over the camera: which examination the sheet belongs
/// to, the student, the score with that examination's answer key and the
/// answers. Nothing is saved and no scan is counted.
class QuickCheckCard extends ConsumerStatefulWidget {
  const QuickCheckCard({
    super.key,
    required this.scanContext,
    required this.reading,
    required this.onNext,
    this.onChangeExam,
  });

  final ScanContext scanContext;
  final OmrSheetReading reading;
  final VoidCallback onNext;

  /// Set for a blank sheet (printed without an examination): checks the next
  /// sheets with another examination.
  final VoidCallback? onChangeExam;

  @override
  ConsumerState<QuickCheckCard> createState() => _QuickCheckCardState();
}

class _QuickCheckCardState extends ConsumerState<QuickCheckCard> {
  StudentRow? _student;
  GradeResult? _grade;
  bool _loaded = false;
  bool _showAnswers = false;

  ScanContext get ctx => widget.scanContext;
  OmrSheetReading get reading => widget.reading;
  int get _used => ctx.exam.scoredItems;
  int get _unclear => reading.flaggedWithin(_used);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final match = await ref.read(scanRepositoryProvider).identify(ctx, reading);
      final version = versionFromReading(ctx, reading);
      GradeResult? g;
      if (version != null) {
        // Unclear answers count as no answer in a quick check.
        final answers = reading.initialAnswers(_used).map((q, m) => MapEntry(q, m ?? 0));
        g = await ref.read(gradingRepositoryProvider).preview(ctx.exam.id, version, answers);
      }
      if (!mounted) return;
      setState(() {
        _student = match.student;
        _grade = g;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final version = ctx.versions.where((v) => v.id == versionFromReading(ctx, reading)).firstOrNull;
    final g = _grade;
    final number = reading.studentNumber;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(Radii.l),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.s),
        child: !_loaded
            ? const SizedBox(height: 96, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'QUICK CHECK · NOT SAVED',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: Space.xs),
                  if (widget.onChangeExam != null)
                    Text('Blank sheet · checked with', style: theme.textTheme.bodySmall),
                  Text(ctx.exam.title, style: theme.textTheme.titleMedium),
                  Text(
                    [
                      'Code ${ctx.exam.shortCode}',
                      if (ctx.exam.examDate != null) 'given ${DateFormat('d MMM y').format(ctx.exam.examDate!)}',
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (widget.onChangeExam != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: widget.onChangeExam,
                        child: const Text('Use another examination'),
                      ),
                    ),
                  const Divider(height: Space.l),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _student == null ? 'Student not identified' : studentDisplayName(_student!),
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              [
                                _student?.studentNo ?? (number.isEmpty ? 'no number shaded' : 'shaded $number'),
                                version == null ? 'set not clear' : 'Set ${version.label}',
                              ].join(' · '),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (g != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(fmtPercent(g.percentage), style: theme.textTheme.headlineSmall),
                            Text('${fmtNumber(g.earned)} / ${fmtNumber(g.possible)}', style: theme.textTheme.bodySmall),
                          ],
                        ),
                    ],
                  ),
                  if (g == null)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.xs),
                      child: Text(
                        version == null
                            ? 'No score: the exam set was not shaded clearly.'
                            : 'No score: this examination\'s answer key is not finished.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: Space.s),
                  Wrap(
                    spacing: Space.s,
                    runSpacing: Space.xs,
                    children: [
                      if (g != null) ...[
                        StatusPill(label: '${g.correct} CORRECT', color: colors.correct, icon: Icons.check),
                        StatusPill(label: '${g.incorrect + g.multiple} WRONG', color: colors.incorrect, icon: Icons.close),
                      ],
                      if (_unclear > 0)
                        StatusPill(label: '$_unclear UNCLEAR', color: colors.uncertain, icon: Icons.flag_outlined),
                    ],
                  ),
                  if (_unclear > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.xs),
                      child: Text(
                        'Unclear answers are counted as no answer in a quick check.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  if (ref.read(scanRepositoryProvider).sheetNote(ctx, reading) case final note?)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.xs),
                      child: Text(note, style: theme.textTheme.bodySmall),
                    ),
                  TextButton.icon(
                    onPressed: () => setState(() => _showAnswers = !_showAnswers),
                    icon: Icon(_showAnswers ? Icons.expand_less : Icons.expand_more),
                    label: Text(_showAnswers ? 'Hide answers' : 'Show answers'),
                  ),
                  if (_showAnswers) _Answers(reading: reading, grade: g, used: _used),
                  const SizedBox(height: Space.s),
                  FilledButton.icon(
                    onPressed: widget.onNext,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Next sheet'),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'To save papers and results, open the examination and scan from there.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.s),
                ],
              ),
      ),
    );
  }
}

/// Question-by-question: what was read, the key and the outcome.
class _Answers extends StatelessWidget {
  const _Answers({required this.reading, required this.grade, required this.used});

  final OmrSheetReading reading;
  final GradeResult? grade;
  final int used;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final graded = {for (final q in grade?.questions ?? const <QuestionGrade>[]) q.questionNo: q};
    return Column(
      children: [
        for (var i = 0; i < reading.questions.length && i < used; i++)
          Builder(builder: (context) {
            final q = i + 1;
            final r = reading.questions[i];
            final g = graded[q];
            final read = (r.state == MarkState.uncertain ? '?' : AnswerMask.describe(r.mask)) +
                (r.crossed == 0 ? '' : ' (${AnswerMask.format(r.crossed)} crossed out)');
            final (icon, color) = switch (g?.outcome) {
              ItemOutcome.correct || ItemOutcome.bonus => (Icons.check, colors.correct),
              ItemOutcome.incorrect || ItemOutcome.multiple => (Icons.close, colors.incorrect),
              ItemOutcome.blank => (Icons.remove, colors.blank),
              ItemOutcome.dropped => (Icons.block, theme.disabledColor),
              null => (Icons.help_outline, colors.uncertain),
            };
            return Semantics(
              label: 'Question $q: read $read${g == null ? '' : ', key ${AnswerMask.format(g.correctMask)}'}',
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(width: 36, child: Text('$q', style: theme.textTheme.labelMedium)),
                    Expanded(child: Text('Read $read', style: theme.textTheme.bodySmall)),
                    if (g != null)
                      Expanded(child: Text('Key ${AnswerMask.format(g.correctMask)}', style: theme.textTheme.bodySmall)),
                    Icon(icon, size: 16, color: color),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
