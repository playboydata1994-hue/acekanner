import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/licensing/license_status.dart';
import '../plan/plan_widgets.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_pill.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/scan_repository.dart';
import '../../data/repositories/students_repository.dart';
import '../../domain/answer_mask.dart';
import '../../domain/omr_reading.dart';
import '../../domain/sheet_layout.dart';

/// Shows a scanned paper next to what was read, lets the instructor resolve
/// flagged answers and confirm the student, then saves it. Returns true when
/// saved.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({
    super.key,
    required this.context,
    required this.reading,
    required this.rectifiedImage,
    this.sessionId,
  });

  final ScanContext context;
  final OmrSheetReading reading;
  final File rectifiedImage;
  final String? sessionId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  StudentRow? _student;
  IdentifiedBy _by = IdentifiedBy.none;
  AnswerSheetRow? _existing;
  String? _versionId;
  late final Map<int, int?> _answers;
  final Set<int> _overridden = {};
  bool _onlyFlagged = false;
  bool _overlay = true;
  bool _saving = false;

  ScanContext get ctx => widget.context;
  OmrSheetReading get reading => widget.reading;

  @override
  void initState() {
    super.initState();
    _answers = {
      for (var i = 0; i < reading.questions.length; i++)
        i + 1: reading.questions[i].state == MarkState.uncertain ? null : reading.questions[i].mask,
    };
    if (ctx.versions.length == 1) {
      _versionId = ctx.versions.single.id;
    } else if (reading.set?.state == MarkState.answered) {
      final index = _bitIndex(reading.set!.mask);
      if (index < ctx.versions.length) _versionId = ctx.versions[index].id;
    }
    _identify();
  }

  Future<void> _identify() async {
    final match = await ref.read(scanRepositoryProvider).identify(ctx, reading);
    if (!mounted) return;
    setState(() {
      _student = match.student;
      _by = match.by;
    });
    await _checkExisting();
  }

  Future<void> _checkExisting() async {
    final s = _student;
    final existing = s == null ? null : await ref.read(scanRepositoryProvider).existingPaper(ctx.exam.id, s.id);
    if (mounted) setState(() => _existing = existing);
  }

  int get _unresolved => _answers.values.where((v) => v == null).length;

  String? get _blocker {
    if (_student == null) return 'Choose the student';
    if (_versionId == null) return 'Choose the exam set';
    if (_unresolved > 0) return 'Decide $_unresolved flagged ${_unresolved == 1 ? 'answer' : 'answers'}';
    return null;
  }

  Future<void> _chooseStudent() async {
    final chosen = await showModalBottomSheet<StudentRow>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _StudentPicker(roster: ctx.roster, detected: reading.studentNumber),
    );
    if (chosen == null) return;
    setState(() {
      _student = chosen;
      _by = IdentifiedBy.instructor;
    });
    await _checkExisting();
  }

  Future<void> _editAnswer(int q) async {
    final g = reading.questions[q - 1];
    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AnswerPicker(question: q, reading: g, current: _answers[q]),
    );
    if (result == null) return;
    setState(() {
      _answers[q] = result;
      _overridden.add(q);
    });
  }

  Future<void> _save() async {
    if (_blocker != null || _saving) return;
    if (_existing != null) {
      final ok = await confirmAction(
        context,
        title: 'Replace the earlier paper?',
        message: 'A paper for ${studentDisplayName(_student!)} was already saved for this '
            'examination. The new scan replaces it; the earlier one is kept in the history.',
        confirmLabel: 'Replace',
      );
      if (!ok) return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(scanRepositoryProvider).save(
            ReviewedSheet(
              examId: ctx.exam.id,
              versionId: _versionId!,
              reading: reading,
              finalMasks: {for (final e in _answers.entries) e.key: e.value!},
              overridden: _overridden,
              rectifiedImage: widget.rectifiedImage,
              studentId: _student!.id,
              sessionId: widget.sessionId,
              replaceSheetId: _existing?.id,
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ScanLimitException catch (e) {
      if (mounted) await showScanBlocked(context, e.block);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _discard() async {
    final ok = await confirmAction(
      context,
      title: 'Discard this scan?',
      message: 'Nothing is saved and no scan is counted. You can scan the paper again.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (ok && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final flagged = reading.flaggedCount;
    final blocker = _blocker;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _discard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Check the scan'),
          actions: [
            IconButton(
              tooltip: _overlay ? 'Hide marks' : 'Show marks',
              icon: Icon(_overlay ? Icons.layers : Icons.layers_outlined),
              onPressed: () => setState(() => _overlay = !_overlay),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, 120),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.m),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 460),
                child: AspectRatio(
                  aspectRatio: SheetLayout.frameWidth / SheetLayout.frameHeight,
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(widget.rectifiedImage, fit: BoxFit.fill),
                        if (_overlay)
                          CustomPaint(
                            painter: _OverlayPainter(
                              layout: ctx.layout,
                              answers: _answers,
                              reading: reading,
                              answered: theme.colorScheme.primary,
                              flagged: colors.uncertain,
                              multiple: colors.incorrect,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              'Pinch to zoom. Circles show what was read.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SectionHeader('Student'),
            Card(
              child: ListTile(
                leading: Icon(
                  _student == null ? Icons.person_search_outlined : Icons.person_outline,
                  color: _student == null ? colors.uncertain : null,
                ),
                title: Text(_student == null ? 'Student not identified' : studentDisplayName(_student!)),
                subtitle: Text(switch (_by) {
                  IdentifiedBy.qrCode => '${_student!.studentNo} · from the QR code',
                  IdentifiedBy.studentNumber => '${_student!.studentNo} · from the shaded number',
                  IdentifiedBy.instructor => '${_student!.studentNo} · chosen by you',
                  IdentifiedBy.none => reading.studentNumber.isEmpty
                      ? 'No student number was shaded'
                      : 'Shaded number ${reading.studentNumber} is not in your class lists',
                }),
                trailing: TextButton(
                  onPressed: _chooseStudent,
                  child: Text(_student == null ? 'Choose' : 'Change'),
                ),
              ),
            ),
            if (_existing != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.s),
                child: Text(
                  'This student already has a saved paper. Saving replaces it.',
                  style: TextStyle(color: colors.uncertain),
                ),
              ),
            if (ctx.versions.length > 1) ...[
              const SectionHeader('Exam set'),
              SegmentedButton<String>(
                segments: [
                  for (final v in ctx.versions) ButtonSegment(value: v.id, label: Text('Set ${v.label}')),
                ],
                selected: {?_versionId},
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _versionId = s.firstOrNull),
              ),
              if (reading.set?.state != MarkState.answered)
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Text(
                    'The set was not shaded clearly. Choose it from the paper.',
                    style: TextStyle(color: colors.uncertain),
                  ),
                ),
            ],
            SectionHeader(
              flagged == 0 ? 'Answers' : 'Answers · $flagged flagged',
            ),
            Row(
              children: [
                if (_unresolved > 0)
                  StatusPill(label: '$_unresolved TO DECIDE', color: colors.uncertain, icon: Icons.flag_outlined)
                else
                  StatusPill(label: 'ALL READ', color: colors.correct, icon: Icons.check),
                const Spacer(),
                FilterChip(
                  label: const Text('Flagged only'),
                  selected: _onlyFlagged,
                  onSelected: flagged == 0 ? null : (v) => setState(() => _onlyFlagged = v),
                ),
              ],
            ),
            const SizedBox(height: Space.s),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (var q = 1; q <= reading.questions.length; q++)
                  if (!_onlyFlagged || reading.questions[q - 1].state == MarkState.uncertain)
                    _AnswerTile(
                      question: q,
                      state: reading.questions[q - 1].state,
                      answer: _answers[q],
                      edited: _overridden.contains(q),
                      onTap: () => _editAnswer(q),
                    ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (blocker != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s),
                    child: Text(blocker, style: TextStyle(color: colors.uncertain)),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: _saving ? null : _discard, child: const Text('Discard')),
                    ),
                    const SizedBox(width: Space.m),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: blocker == null && !_saving ? _save : null,
                        child: const Text('Save paper'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static int _bitIndex(int mask) {
    for (var i = 0; i < 8; i++) {
      if (mask == 1 << i) return i;
    }
    return 99;
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.question,
    required this.state,
    required this.answer,
    required this.edited,
    required this.onTap,
  });

  final int question;
  final MarkState state;
  final int? answer;
  final bool edited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final unresolved = answer == null;
    final text = unresolved ? '?' : (answer == 0 ? '—' : AnswerMask.format(answer!));
    final color = unresolved
        ? colors.uncertain
        : (answer != null && AnswerMask.count(answer!) > 1 ? colors.incorrect : theme.colorScheme.onSurface);
    return Semantics(
      button: true,
      label: 'Question $question: ${unresolved ? 'needs your decision' : (answer == 0 ? 'no answer' : text)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.s),
        child: Container(
          width: 62,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: unresolved ? colors.uncertain.withValues(alpha: 0.12) : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Radii.s),
            border: Border.all(
              color: unresolved
                  ? colors.uncertain
                  : edited
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
              width: unresolved || edited ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text('$question', style: theme.textTheme.labelSmall),
              Text(text, style: theme.textTheme.titleMedium?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerPicker extends StatefulWidget {
  const _AnswerPicker({required this.question, required this.reading, required this.current});

  final int question;
  final GroupReading reading;
  final int? current;

  @override
  State<_AnswerPicker> createState() => _AnswerPickerState();
}

class _AnswerPickerState extends State<_AnswerPicker> {
  late int _mask = widget.current ?? (widget.reading.state == MarkState.uncertain ? widget.reading.mask : 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.reading;
    final read = switch (r.state) {
      MarkState.answered => 'Read as ${AnswerMask.format(r.mask)}${r.erasure ? ' (a lighter mark was ignored)' : ''}',
      MarkState.blank => 'Read as no answer',
      MarkState.multiple => 'Read as more than one answer (${AnswerMask.format(r.mask)})',
      MarkState.uncertain => r.mask == 0
          ? 'Unclear marks: look at the paper and decide'
          : 'Unclear: ${AnswerMask.format(r.mask)} looks most likely. Check the paper.',
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${widget.question}', style: theme.textTheme.titleLarge),
            const SizedBox(height: Space.xs),
            Text(read),
            const SizedBox(height: Space.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var c = 0; c < 5; c++)
                  _ChoiceButton(
                    label: AnswerMask.labels[c],
                    selected: AnswerMask.has(_mask, c),
                    darkness: r.scores[c],
                    onTap: () => setState(() => _mask = AnswerMask.toggle(_mask, c)),
                  ),
              ],
            ),
            const SizedBox(height: Space.s),
            Text(
              'Bars show how dark each bubble was. Select one answer, or more than one if the student shaded several.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: Space.l),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(0),
                    child: const Text('No answer'),
                  ),
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  child: FilledButton(
                    onPressed: _mask == 0 ? null : () => Navigator.of(context).pop(_mask),
                    child: const Text('Use this answer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.selected, required this.darkness, required this.onTap});

  final String label;
  final bool selected;
  final double darkness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Choice $label',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scheme.primary : Colors.transparent,
                border: Border.all(color: selected ? scheme.primary : scheme.outline, width: 1.5),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: darkness.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(color: scheme.onSurface, borderRadius: BorderRadius.circular(3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentPicker extends ConsumerStatefulWidget {
  const _StudentPicker({required this.roster, required this.detected});

  final List<StudentRow> roster;
  final String detected;

  @override
  ConsumerState<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends ConsumerState<_StudentPicker> {
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
                        subtitle: Text(list[i].studentNo),
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

/// Rings what was read on the corrected sheet image.
class _OverlayPainter extends CustomPainter {
  _OverlayPainter({
    required this.layout,
    required this.answers,
    required this.reading,
    required this.answered,
    required this.flagged,
    required this.multiple,
  });

  final SheetLayout layout;
  final Map<int, int?> answers;
  final OmrSheetReading reading;
  final Color answered;
  final Color flagged;
  final Color multiple;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / SheetLayout.frameWidth;
    final sy = size.height / SheetLayout.frameHeight;
    final ringW = (SheetLayout.bubbleRx + 0.9) * 2 * sx;
    final ringH = (SheetLayout.bubbleRy + 0.9) * 2 * sy;
    for (var q = 0; q < layout.questions.length; q++) {
      final row = layout.questions[q];
      final a = answers[q + 1];
      final isFlagged = reading.questions[q].state == MarkState.uncertain;
      if (isFlagged) {
        final left = (row.first.x - SheetLayout.bubbleRx - 1) * sx;
        final top = (row.first.y - SheetLayout.bubbleRy - 1.2) * sy;
        final right = (row.last.x + SheetLayout.bubbleRx + 1) * sx;
        final bottom = (row.first.y + SheetLayout.bubbleRy + 1.2) * sy;
        canvas.drawRRect(
          RRect.fromLTRBR(left, top, right, bottom, Radius.circular(3 * sx)),
          Paint()
            ..color = flagged.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
      }
      if (a == null || a == 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AnswerMask.count(a) > 1 ? multiple : answered;
      for (var c = 0; c < 5; c++) {
        if (AnswerMask.has(a, c)) {
          canvas.drawOval(Rect.fromCenter(center: Offset(row[c].x * sx, row[c].y * sy), width: ringW, height: ringH), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) => true;
}
