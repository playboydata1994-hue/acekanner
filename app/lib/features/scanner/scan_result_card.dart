import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/scan_repository.dart';
import '../../data/repositories/students_repository.dart';
import '../../domain/grading.dart';
import '../../domain/licensing/license_status.dart';
import '../../domain/omr_reading.dart';
import '../plan/plan_widgets.dart';
import '../results/result_widgets.dart';
import 'review_screen.dart';

/// Floats over the camera after a sheet is read: who it is, the set, the
/// score and anything that needs a decision. "Confirm" saves the paper and
/// scanning continues; it is blocked while answers are flagged, the student
/// is not identified or the set is unclear, which must be fixed in "Review".
class ScanResultCard extends ConsumerStatefulWidget {
  const ScanResultCard({
    super.key,
    required this.scanContext,
    required this.reading,
    required this.rectifiedImage,
    this.sessionId,
    required this.onFinished,
  });

  final ScanContext scanContext;
  final OmrSheetReading reading;
  final File rectifiedImage;
  final String? sessionId;

  /// Called once: true when the paper was saved, false when it was discarded.
  final ValueChanged<bool> onFinished;

  @override
  ConsumerState<ScanResultCard> createState() => _ScanResultCardState();
}

class _ScanResultCardState extends ConsumerState<ScanResultCard> {
  StudentMatch? _match;
  AnswerSheetRow? _existing;
  GradeResult? _grade;
  bool _loaded = false;
  bool _busy = false;

  ScanContext get ctx => widget.scanContext;
  OmrSheetReading get reading => widget.reading;
  String? get _versionId => versionFromReading(ctx, reading);
  int get _flagged => reading.flaggedCount;
  int get _multiple => reading.questions.where((q) => q.state == MarkState.multiple).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final scans = ref.read(scanRepositoryProvider);
      final match = await scans.identify(ctx, reading);
      final existing = match.student == null ? null : await scans.existingPaper(ctx.exam.id, match.student!.id);
      GradeResult? g;
      final version = _versionId;
      if (version != null && _flagged == 0) {
        g = await ref.read(gradingRepositoryProvider).preview(ctx.exam.id, version, {
          for (var i = 0; i < reading.questions.length; i++) i + 1: reading.questions[i].mask,
        });
      }
      if (!mounted) return;
      setState(() {
        _match = match;
        _existing = existing;
        _grade = g;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  /// What must be fixed in Review before the paper can be confirmed here.
  List<String> get _blockers {
    final number = reading.studentNumber;
    return [
      if (_match?.student == null)
        number.isEmpty
            ? 'No student number was shaded'
            : number.contains('?')
                ? 'Student number $number is not clear'
                : 'Student number $number is not in your class lists',
      if (_versionId == null) 'The exam set was not shaded clearly',
      if (_flagged > 0) '$_flagged flagged ${_flagged == 1 ? 'answer needs' : 'answers need'} your decision',
    ];
  }

  Future<void> _confirm() async {
    final student = _match?.student;
    final version = _versionId;
    if (_busy || student == null || version == null || _flagged > 0) return;
    if (_existing != null) {
      final ok = await confirmAction(
        context,
        title: 'Replace the earlier paper?',
        message: 'A paper for ${studentDisplayName(student)} was already saved for this examination. '
            'This scan replaces it; the earlier one is kept in the history.',
        confirmLabel: 'Replace',
      );
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(scanRepositoryProvider).save(
            ReviewedSheet(
              examId: ctx.exam.id,
              versionId: version,
              reading: reading,
              finalMasks: {for (var i = 0; i < reading.questions.length; i++) i + 1: reading.questions[i].mask},
              overridden: const {},
              rectifiedImage: widget.rectifiedImage,
              studentId: student.id,
              sessionId: widget.sessionId,
              replaceSheetId: _existing?.id,
            ),
          );
      widget.onFinished(true);
    } on ScanLimitException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        await showScanBlocked(context, e.block);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, e);
      }
    }
  }

  Future<void> _review() async {
    if (_busy) return;
    setState(() => _busy = true);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScaffoldMessenger(
          child: ReviewScreen(
            context: ctx,
            reading: reading,
            rectifiedImage: widget.rectifiedImage,
            sessionId: widget.sessionId,
          ),
        ),
      ),
    );
    widget.onFinished(saved == true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final student = _match?.student;
    final version = ctx.versions.where((v) => v.id == _versionId).firstOrNull;
    final blockers = _loaded ? _blockers : const <String>[];
    final g = _grade;
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        student == null ? Icons.person_search_outlined : Icons.person_outline,
                        color: student == null ? colors.uncertain : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student == null ? 'Student not identified' : studentDisplayName(student),
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              [
                                student?.studentNo ?? (reading.studentNumber.isEmpty ? 'no number' : reading.studentNumber),
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
                        _flagged > 0
                            ? 'Score: after the flagged answers are decided.'
                            : version == null
                                ? 'Score: after the exam set is chosen.'
                                : 'Score: after the answer key is finished.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: Space.s),
                  Wrap(
                    spacing: Space.s,
                    runSpacing: Space.xs,
                    children: [
                      if (_flagged > 0)
                        StatusPill(label: '$_flagged FLAGGED', color: colors.uncertain, icon: Icons.flag_outlined)
                      else
                        StatusPill(label: 'ALL ANSWERS READ', color: colors.correct, icon: Icons.check),
                      if (_multiple > 0)
                        StatusPill(label: '$_multiple DOUBLE-SHADED', color: colors.incorrect, icon: Icons.error_outline),
                    ],
                  ),
                  if (_existing != null && student != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.s),
                      child: Text(
                        'This student already has a saved paper. Confirming replaces it.',
                        style: theme.textTheme.bodySmall?.copyWith(color: colors.uncertain),
                      ),
                    ),
                  if (blockers.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: Space.m),
                      padding: const EdgeInsets.all(Space.m),
                      decoration: BoxDecoration(
                        color: colors.uncertain.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Radii.m),
                        border: Border.all(color: colors.uncertain.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fix in Review before the next sheet:', style: theme.textTheme.titleSmall),
                          for (final b in blockers)
                            Padding(
                              padding: const EdgeInsets.only(top: Space.xs),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.flag_outlined, size: 16, color: colors.uncertain),
                                  const SizedBox(width: Space.s),
                                  Expanded(child: Text(b, style: theme.textTheme.bodyMedium)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: Space.m),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _review,
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Review'),
                        ),
                      ),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy || blockers.isNotEmpty ? null : _confirm,
                          icon: _busy
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check),
                          label: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => widget.onFinished(false),
                    child: const Text('Discard and scan again'),
                  ),
                ],
              ),
      ),
    );
  }
}
