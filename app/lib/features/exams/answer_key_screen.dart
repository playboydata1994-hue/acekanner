import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/answer_key_repository.dart';
import '../../domain/answer_mask.dart';
import '../../domain/validators.dart';

/// Enter or correct the answer key of one exam set.
class AnswerKeyScreen extends ConsumerStatefulWidget {
  const AnswerKeyScreen({super.key, required this.versionId});

  final String versionId;

  @override
  ConsumerState<AnswerKeyScreen> createState() => _AnswerKeyScreenState();
}

class _AnswerKeyScreenState extends ConsumerState<AnswerKeyScreen> {
  AnswerKeyData? _data;
  List<KeyItem> _saved = const [];
  List<KeyItem> _items = const [];

  /// Questions where the instructor allowed more than one accepted answer.
  final Set<int> _multi = {};
  String? _error;
  bool _saving = false;

  bool get _dirty => !_listEquals(_items, _saved);

  int get _completeCount => _items.where((i) => i.isComplete).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(answerKeyRepositoryProvider).load(widget.versionId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _saved = data.items;
        _items = [...data.items];
        _multi
          ..clear()
          ..addAll(data.items.where((i) => AnswerMask.count(i.mask) > 1).map((i) => i.questionNo));
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  void _replace(int questionNo, KeyItem item) =>
      setState(() => _items = [..._items]..[questionNo - 1] = item);

  void _tapChoice(KeyItem item, int choice) {
    final bit = AnswerMask.bit(choice);
    final mask = _multi.contains(item.questionNo)
        ? item.mask ^ bit
        : (item.mask == bit ? 0 : bit);
    _replace(item.questionNo, item.copyWith(mask: mask));
  }

  Future<void> _quickEntry() async {
    final itemCount = _items.length;
    final parsed = await showDialog<Map<int, int>>(
      context: context,
      builder: (_) => _QuickEntryDialog(itemCount: itemCount),
    );
    if (parsed == null || parsed.isEmpty) return;
    setState(() {
      _items = [
        for (final i in _items)
          parsed.containsKey(i.questionNo) ? i.copyWith(mask: parsed[i.questionNo]) : i,
      ];
      for (final e in parsed.entries) {
        if (AnswerMask.count(e.value) > 1) _multi.add(e.key);
      }
    });
    if (mounted) showMessage(context, '${parsed.length} answers filled in. Review them, then save.');
  }

  Future<void> _pointsForAll() async {
    final first = _items.firstOrNull;
    final result = await showDialog<(double, double)>(
      context: context,
      builder: (_) => _PointsDialog(
        title: 'Points for every question',
        points: first?.points ?? 1,
        negative: first?.negativePoints ?? 0,
      ),
    );
    if (result == null) return;
    setState(() {
      _items = [for (final i in _items) i.copyWith(points: result.$1, negativePoints: result.$2)];
    });
  }

  Future<void> _rowAction(KeyItem item, _RowAction action) async {
    switch (action) {
      case _RowAction.toggleMulti:
        setState(() {
          if (_multi.remove(item.questionNo)) {
            // Back to one answer: keep the first accepted choice only.
            final mask = item.mask;
            final keep = mask == 0 ? 0 : mask & -mask;
            _items = [..._items]..[item.questionNo - 1] = item.copyWith(mask: keep);
          } else {
            _multi.add(item.questionNo);
          }
        });
      case _RowAction.normal:
        _replace(item.questionNo, item.copyWith(mode: KeyItemMode.normal));
      case _RowAction.bonus:
        _replace(item.questionNo, item.copyWith(mode: KeyItemMode.bonus));
      case _RowAction.dropped:
        _replace(item.questionNo, item.copyWith(mode: KeyItemMode.dropped));
      case _RowAction.points:
        final result = await showDialog<(double, double)>(
          context: context,
          builder: (_) => _PointsDialog(
            title: 'Question ${item.questionNo} points',
            points: item.points,
            negative: item.negativePoints,
          ),
        );
        if (result != null) {
          _replace(item.questionNo, item.copyWith(points: result.$1, negativePoints: result.$2));
        }
    }
  }

  Future<void> _save() async {
    final data = _data;
    if (data == null || _saving || !_dirty) return;
    String? note;
    if (data.hasFinalizedPapers) {
      note = await showDialog<String>(context: context, builder: (_) => const _ChangeNoteDialog());
      if (note == null) return;
    }
    setState(() => _saving = true);
    try {
      final result = await ref.read(answerKeyRepositoryProvider).save(
            widget.versionId,
            _items,
            changeNote: note,
          );
      if (!mounted) return;
      showMessage(
        context,
        result.newRevision ? 'Saved as revision ${result.revision}' : 'Answer key saved',
      );
      await _load();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await confirmAction(
      context,
      title: 'Discard changes?',
      message: 'Your changes to this answer key have not been saved.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (leave && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data == null ? 'Answer key' : 'Answer key · Set ${data.version.label}'),
              if (data != null)
                Text(
                  data.exam.title,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _dirty && !_saving ? _save : null,
              child: const Text('Save'),
            ),
          ],
        ),
        body: _error != null
            ? Center(child: Text(_error!))
            : data == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      _Header(
                        complete: _completeCount,
                        total: _items.length,
                        revisionNotice: data.hasFinalizedPapers
                            ? 'Papers were already scanned. Saving creates revision '
                                '${data.key.revision + 1} and asks for the reason.'
                            : null,
                        onQuickEntry: _quickEntry,
                        onPoints: _pointsForAll,
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: _items.length,
                          itemExtent: 64,
                          itemBuilder: (context, i) => _KeyRow(
                            item: _items[i],
                            allowMultiple: _multi.contains(_items[i].questionNo),
                            defaultPoints: _items.first.points,
                            onChoice: (c) => _tapChoice(_items[i], c),
                            onAction: (a) => _rowAction(_items[i], a),
                          ),
                        ),
                      ),
                    ],
                  ),
        floatingActionButton: data != null && _dirty
            ? FloatingActionButton.extended(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save key'),
              )
            : null,
      ),
    );
  }

  static bool _listEquals(List<KeyItem> a, List<KeyItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.complete,
    required this.total,
    required this.onQuickEntry,
    required this.onPoints,
    this.revisionNotice,
  });

  final int complete;
  final int total;
  final String? revisionNotice;
  final VoidCallback onQuickEntry;
  final VoidCallback onPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$complete of $total answers set', style: theme.textTheme.titleMedium),
          const SizedBox(height: Space.s),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: total == 0 ? 0 : complete / total, minHeight: 6),
          ),
          if (revisionNotice != null) ...[
            const SizedBox(height: Space.s),
            Text(revisionNotice!, style: TextStyle(color: context.statusColors.uncertain)),
          ],
          const SizedBox(height: Space.m),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onQuickEntry,
                  icon: const Icon(Icons.keyboard_outlined),
                  label: const Text('Quick entry'),
                ),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPoints,
                  icon: const Icon(Icons.scoreboard_outlined),
                  label: const Text('Points'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _RowAction { toggleMulti, normal, bonus, dropped, points }

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.item,
    required this.allowMultiple,
    required this.defaultPoints,
    required this.onChoice,
    required this.onAction,
  });

  final KeyItem item;
  final bool allowMultiple;
  final double defaultPoints;
  final ValueChanged<int> onChoice;
  final ValueChanged<_RowAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    final note = [
      if (item.mode == KeyItemMode.bonus) 'Bonus',
      if (item.mode == KeyItemMode.dropped) 'Dropped',
      if (allowMultiple) 'Multiple answers',
      if (item.points != defaultPoints) '${_fmt(item.points)} pts',
      if (item.negativePoints > 0) '−${_fmt(item.negativePoints)}',
    ].join(' · ');
    final incomplete = !item.isComplete;
    return Padding(
      padding: const EdgeInsets.only(left: Space.s),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.questionNo}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: incomplete ? colors.uncertain : null,
                  ),
                ),
                if (note.isNotEmpty)
                  Text(
                    item.mode == KeyItemMode.normal ? '•' : item.mode[0].toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(color: colors.premium),
                  ),
              ],
            ),
          ),
          // Scales down only on very narrow screens (under ~330 dp).
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var c = 0; c < AnswerMask.labels.length; c++)
                    _Bubble(
                      label: AnswerMask.labels[c],
                      selected: AnswerMask.has(item.mask, c),
                      dimmed: item.mode == KeyItemMode.dropped,
                      semanticsLabel: 'Question ${item.questionNo}, choice ${AnswerMask.labels[c]}',
                      onTap: () => onChoice(c),
                    ),
                ],
              ),
            ),
          ),
          PopupMenuButton<_RowAction>(
            tooltip: note.isEmpty ? 'Question ${item.questionNo} options' : note,
            icon: Icon(Icons.more_vert, color: note.isEmpty ? null : colors.premium),
            onSelected: onAction,
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: _RowAction.toggleMulti,
                checked: allowMultiple,
                child: const Text('Accept more than one answer'),
              ),
              const PopupMenuDivider(),
              CheckedPopupMenuItem(
                value: _RowAction.normal,
                checked: item.mode == KeyItemMode.normal,
                child: const Text('Normal question'),
              ),
              CheckedPopupMenuItem(
                value: _RowAction.bonus,
                checked: item.mode == KeyItemMode.bonus,
                child: const Text('Bonus: everyone gets the points'),
              ),
              CheckedPopupMenuItem(
                value: _RowAction.dropped,
                checked: item.mode == KeyItemMode.dropped,
                child: const Text('Drop: exclude from scoring'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: _RowAction.points, child: Text('Points…')),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// One A–E bubble, sized for thumbs (44 dp touch target).
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.label,
    required this.selected,
    required this.dimmed,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool dimmed;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = selected ? scheme.primary : Colors.transparent;
    final border = selected ? scheme.primary : scheme.outline;
    return Semantics(
      label: semanticsLabel,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox.square(
          dimension: 46,
          child: Center(
            child: Opacity(
              opacity: dimmed ? 0.4 : 1,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: fill,
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickEntryDialog extends StatefulWidget {
  const _QuickEntryDialog({required this.itemCount});

  final int itemCount;

  @override
  State<_QuickEntryDialog> createState() => _QuickEntryDialogState();
}

class _QuickEntryDialogState extends State<_QuickEntryDialog> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _apply() {
    try {
      final parsed = AnswerMask.parseSequence(_text.text, itemCount: widget.itemCount);
      Navigator.of(context).pop(parsed);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type the answers in order (spaces are ignored, “-” skips a '
              'question), or as numbered pairs.\n\n'
              'Examples:  ABCDA EBCDA …   or   1A 2B 3C 10AC',
            ),
            const SizedBox(height: Space.m),
            TextField(
              controller: _text,
              autofocus: true,
              maxLines: 4,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Ea-e0-9\s,;.):\-?_]'))],
              decoration: InputDecoration(
                hintText: 'ABCDA EBCDA …',
                errorText: _error,
                errorMaxLines: 3,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _apply, child: const Text('Fill in')),
      ],
    );
  }
}

class _PointsDialog extends StatefulWidget {
  const _PointsDialog({required this.title, required this.points, required this.negative});

  final String title;
  final double points;
  final double negative;

  @override
  State<_PointsDialog> createState() => _PointsDialogState();
}

class _PointsDialogState extends State<_PointsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _points = TextEditingController(text: _fmt(widget.points));
  late final _negative = TextEditingController(text: _fmt(widget.negative));

  @override
  void dispose() {
    _points.dispose();
    _negative.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _points,
              decoration: const InputDecoration(labelText: 'Points if correct'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => Validators.number(v, min: 0, max: 100, label: 'the points'),
            ),
            const SizedBox(height: Space.m),
            TextFormField(
              controller: _negative,
              decoration: const InputDecoration(
                labelText: 'Deduction if wrong',
                helperText: '0 = no negative marking',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => Validators.number(v, min: 0, max: 100, label: 'the deduction'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              (double.parse(_points.text.trim()), double.parse(_negative.text.trim())),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _ChangeNoteDialog extends StatefulWidget {
  const _ChangeNoteDialog();

  @override
  State<_ChangeNoteDialog> createState() => _ChangeNoteDialogState();
}

class _ChangeNoteDialogState extends State<_ChangeNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Why is the key changing?'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _note,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'e.g. Item 12 also accepts C'),
          validator: (v) => Validators.required(v, 'reason', max: 500),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) Navigator.of(context).pop(_note.text.trim());
          },
          child: const Text('Save revision'),
        ),
      ],
    );
  }
}
