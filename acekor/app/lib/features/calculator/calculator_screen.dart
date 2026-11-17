import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/feedback.dart';
import '../../domain/scoring/percent.dart';
import '../../domain/scoring/score_entry.dart';
import '../plan/paywall.dart';
import 'activity_picker.dart';
import 'calculator_controller.dart';
import 'class_picker.dart';
import 'keypad.dart';
import 'student_search_panel.dart';

/// The home page: the academic scoring calculator.
///
/// OPEN THE APP → SEARCH STUDENT → ENTER SCORE → SAVE.
class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searching = false;
  bool _saving = false;

  /// Brief "SAVED" flash under the percentage.
  bool _flash = false;
  Timer? _flashTimer;

  /// Brief red flash when a key is refused (score above the maximum).
  bool _refused = false;
  Timer? _refusedTimer;

  /// Inline message above the score. Never covers the keypad (a bottom
  /// message bar would hide ⌫ 0 ✓ while the instructor keeps typing).
  _Note? _note;
  Timer? _noteTimer;

  void _say(
    String text, {
    bool error = false,
    String? actionLabel,
    VoidCallback? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _noteTimer?.cancel();
    setState(() => _note = _Note(text, error: error, actionLabel: actionLabel, action: action));
    _noteTimer = Timer(duration, () {
      if (mounted) setState(() => _note = null);
    });
  }

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() => _searching = _searchFocus.hasFocus));
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _flashTimer?.cancel();
    _refusedTimer?.cancel();
    _noteTimer?.cancel();
    super.dispose();
  }

  CalculatorController get _ctrl => ref.read(calculatorProvider.notifier);

  void _closeSearch() {
    _search.clear();
    _searchFocus.unfocus();
  }

  void _refuse(String message) {
    HapticFeedback.heavyImpact();
    setState(() => _refused = true);
    _refusedTimer?.cancel();
    _refusedTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _refused = false);
    });
    _say(message, error: true, duration: const Duration(seconds: 2));
  }

  Future<void> _onKey(CalcKey key) async {
    if (_searching) _closeSearch();
    final state = ref.read(calculatorProvider);
    switch (key) {
      case CalcKey.backspace:
        _ctrl.backspace();
      case CalcKey.save:
        await _save();
      default:
        final r = _ctrl.press(key.index);
        if (r == EntryRejection.aboveMaximum) {
          _refuse('The maximum is ${state.maxPoints} points.');
        }
    }
  }

  Future<void> _save({bool replaceConfirmed = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final r = await _ctrl.save(replaceConfirmed: replaceConfirmed);
      if (!mounted) return;
      switch (r) {
        case NeedSubject():
          _say('Choose a class (subject) first.');
          await showClassPicker(context);
        case NeedActivity():
          _say('Choose the quiz, recitation or examination first.');
          await showActivityPicker(context);
        case NeedStudent():
          _say('Search and select a student first.');
          _searchFocus.requestFocus();
        case NeedScore():
          _refuse('Type the score on the keypad first.');
        case PlanLocked(:final block):
          await showPaywall(
            context,
            block,
            notify: (t, {bool error = false}) => _say(t, error: error, duration: const Duration(seconds: 4)),
          );
        case ConfirmReplace(:final previous, :final points):
          final s = ref.read(calculatorProvider);
          final ok = await confirm(
            context,
            title: 'Replace saved score?',
            message:
                '${s.student?.natural} already has $previous/${s.maxPoints} in ${s.activity?.label}.\n\n'
                'Replace it with $points/${s.maxPoints}?',
            confirmLabel: 'Replace',
          );
          if (ok && mounted) {
            setState(() => _saving = false);
            await _save(replaceConfirmed: true);
          }
        case Saved saved:
          _showSaved(saved);
        case SaveFailed(:final message):
          _say(message, error: true, duration: const Duration(seconds: 4));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSaved(Saved saved) {
    final settings = ref.read(appSettingsProvider);
    setState(() => _flash = true);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _flash = false);
    });
    if (!settings.confirmMessage) return;
    final pct = scorePercentText(saved.points, saved.maxPoints);
    final replaced = saved.previous == null ? '' : ' (was ${saved.previous})';
    final next = saved.nextStudentName != null
        ? '\nNext: ${saved.nextStudentName}'
        : (saved.classDone ? '\nEveryone in the class list has a score.' : '');
    _say(
      'Saved ${saved.points}/${saved.maxPoints} ($pct) · ${saved.studentName}$replaced$next',
      duration: const Duration(seconds: 5),
      actionLabel: 'UNDO',
      action: () {
        _ctrl.undo(saved);
        setState(() => _note = null);
      },
    );
  }

  Future<void> _editQuickMax() async {
    final current = ref.read(calculatorProvider).quickMax;
    final controller = TextEditingController(text: '$current');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Total points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For quick computing without an activity. Choose an activity to save scores.',
              style: TextStyle(fontSize: 16, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(controller.text)), child: const Text('OK')),
        ],
      ),
    );
    if (value != null && value >= 1 && value <= 1000) await _ctrl.setQuickMax(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorProvider);
    final settings = ref.watch(appSettingsProvider);
    // Keep the activity fresh when it is edited elsewhere.
    ref.listen(activitiesProvider(state.subjectId ?? '-'), (_, next) {
      final a = state.activity;
      if (a == null) return;
      final fresh = next.value?.where((x) => x.id == a.id).firstOrNull;
      if (fresh == null || fresh.maxPoints != a.maxPoints || fresh.label != a.label) {
        _ctrl.refreshActivity();
      }
    });

    return PopScope(
      canPop: !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _searching) _closeSearch();
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(onMenu: () => context.push(Routes.menu)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: _SearchField(controller: _search, focus: _searchFocus, onClear: _closeSearch),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _StudentLine(onTapEmpty: () => _searchFocus.requestFocus()),
                        _ActivityLine(onTap: () => showActivityPicker(context)),
                        Expanded(
                          flex: 5,
                          child: _ScoreDisplay(
                            state: state,
                            showPercent: settings.showPercent,
                            flash: _flash,
                            refused: _refused,
                            onTapTotal: state.activity == null ? _editQuickMax : null,
                            note: _note == null ? null : _NoteBar(note: _note!),
                          ),
                        ),
                        Expanded(
                          flex: 8,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: AcademicKeypad(onKey: _onKey, sound: settings.sound, saveEnabled: !_saving),
                          ),
                        ),
                      ],
                    ),
                    if (_searching)
                      Positioned.fill(
                        child: StudentSearchPanel(
                          query: _search,
                          onSelected: (s) {
                            _closeSearch();
                            _ctrl.selectStudent(s);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.onMenu});
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            iconSize: 30,
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded, color: AppColors.white),
          ),
          const Expanded(child: ClassChip()),
          IconButton(
            tooltip: 'Calculator',
            iconSize: 28,
            onPressed: () => context.push(Routes.miniCalculator),
            icon: const Icon(Icons.calculate_outlined, color: AppColors.white),
          ),
          IconButton(
            tooltip: 'Calculator settings',
            iconSize: 28,
            onPressed: () => context.push(Routes.calculatorSettings),
            icon: const Icon(Icons.settings_outlined, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.focus, required this.onClear});
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('student-search'),
      controller: controller,
      focusNode: focus,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 19, color: AppColors.white),
      cursorColor: AppColors.teal,
      decoration: InputDecoration(
        hintText: 'Search student name or ID',
        hintStyle: const TextStyle(fontSize: 18, color: AppColors.muted),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 28),
        suffixIcon: ListenableBuilder(
          listenable: Listenable.merge([controller, focus]),
          builder: (context, _) => focus.hasFocus
              ? IconButton(
                  tooltip: 'Close search',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                )
              : const SizedBox.shrink(),
        ),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
      ),
    );
  }
}

class _StudentLine extends ConsumerWidget {
  const _StudentLine({required this.onTapEmpty});
  final VoidCallback onTapEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(calculatorProvider.select((s) => s.student));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: student == null ? onTapEmpty : null,
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'STUDENT: ',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    TextSpan(
                      text: student == null ? 'none selected' : student.natural.toUpperCase(),
                      style: TextStyle(color: student == null ? AppColors.faint : AppColors.white),
                    ),
                  ],
                ),
                key: const ValueKey('student-line'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
            ),
          ),
          if (student != null)
            IconButton(
              tooltip: 'Clear student',
              onPressed: () => ref.read(calculatorProvider.notifier).clearStudent(),
              icon: const Icon(Icons.close_rounded, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

class _ActivityLine extends ConsumerWidget {
  const _ActivityLine({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(calculatorProvider.select((s) => s.activity));
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 12, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                activity?.heading ?? 'CHOOSE ACTIVITY',
                key: const ValueKey('activity-line'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: activity == null ? AppColors.teal : AppColors.white,
                ),
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: AppColors.teal, size: 32),
          ],
        ),
      ),
    );
  }
}

/// "42/50" with "84%" directly underneath. Nothing else.
class _ScoreDisplay extends StatelessWidget {
  const _ScoreDisplay({
    required this.state,
    required this.showPercent,
    required this.flash,
    required this.refused,
    required this.onTapTotal,
    this.note,
  });

  final CalcState state;
  final bool showPercent;
  final bool flash;
  final bool refused;
  final VoidCallback? onTapTotal;

  /// Message shown in a slot of its own under the percentage, so it never
  /// covers the score or the keypad.
  final Widget? note;

  static const double noteSlot = 76;

  @override
  Widget build(BuildContext context) {
    final value = state.entry.value;
    final max = state.maxPoints;
    final empty = value == null;
    final scoreColor = refused ? AppColors.red : (empty ? AppColors.faint : AppColors.white);
    final percent = empty ? '' : scorePercentText(value, max);
    return LayoutBuilder(
      builder: (context, c) {
        final big = ((c.maxHeight - noteSlot) * 0.56).clamp(36.0, 112.0);
        final mid = (big * 0.55).clamp(28.0, 64.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onTapTotal,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${empty ? 0 : value}/$max',
                    key: const ValueKey('score-display'),
                    style: TextStyle(
                      fontSize: big,
                      fontWeight: FontWeight.w400,
                      color: scoreColor,
                      height: 1.05,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: mid * 1.25,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: flash
                      ? Row(
                          key: const ValueKey('saved-flash'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.save, size: mid * 0.85),
                            const SizedBox(width: 10),
                            Text(
                              'SAVED',
                              style: TextStyle(fontSize: mid * 0.8, fontWeight: FontWeight.w800, color: AppColors.save),
                            ),
                          ],
                        )
                      : Text(
                          showPercent ? percent : '',
                          key: const ValueKey('percent-display'),
                          style: TextStyle(
                            fontSize: mid,
                            fontWeight: FontWeight.w500,
                            color: AppColors.teal,
                            height: 1.1,
                          ),
                        ),
                ),
              ),
              SizedBox(
                height: noteSlot,
                child: Center(
                  child:
                      note ??
                      (state.showingSaved && !flash
                          ? const Text(
                              'saved score · type to change',
                              style: TextStyle(fontSize: 16, color: AppColors.muted),
                            )
                          : (state.activity == null
                                ? const Text(
                                    'tap the total to change it',
                                    style: TextStyle(fontSize: 15, color: AppColors.faint),
                                  )
                                : null)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Note {
  const _Note(this.text, {this.error = false, this.actionLabel, this.action});
  final String text;
  final bool error;
  final String? actionLabel;
  final VoidCallback? action;
}

class _NoteBar extends StatelessWidget {
  const _NoteBar({required this.note});
  final _Note note;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('calc-note'),
      color: note.error ? const Color(0xFF3A1513) : const Color(0xFF0E2E25),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        child: Row(
          children: [
            Icon(
              note.error ? Icons.info_outline : Icons.check_circle_outline,
              color: note.error ? AppColors.red : AppColors.save,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                note.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, color: AppColors.white, height: 1.3),
              ),
            ),
            if (note.action != null)
              TextButton(
                onPressed: note.action,
                child: Text(
                  note.actionLabel ?? 'OK',
                  style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
