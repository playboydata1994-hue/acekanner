import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/errors.dart';
import '../../domain/grading/default_scale.dart';
import '../../domain/grading/grade_scale.dart';
import '../../domain/scoring/percent.dart';

class ScalesScreen extends ConsumerWidget {
  const ScalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grade scales')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.newScale),
        icon: const Icon(Icons.add),
        label: const Text('New scale'),
      ),
      body: AsyncView(
        value: ref.watch(scalesProvider),
        builder: (scales) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                'A scale turns the final percentage into your school\'s grade (e.g. 85% → 2.00). '
                'Each subject chooses its scale in its Grading tab.',
                style: TextStyle(fontSize: 16, color: AppColors.muted),
              ),
            ),
            for (final s in scales)
              ListTile(
                title: Text(s.row.name),
                subtitle: Text(
                  '${s.items.length} grades · passing ${formatBp(s.row.passingBp)}'
                  '${s.row.builtIn ? ' · built-in (editing makes a copy)' : ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.scale(s.row.id)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row {
  _Row(int minBp, String grade, String remark)
    : min = TextEditingController(text: minBp % 100 == 0 ? '${minBp ~/ 100}' : (minBp / 100).toStringAsFixed(2)),
      grade = TextEditingController(text: grade),
      remark = TextEditingController(text: remark);
  final TextEditingController min;
  final TextEditingController grade;
  final TextEditingController remark;
}

/// Creates or edits a grade scale (a built-in scale is copied, never changed).
class ScaleEditScreen extends ConsumerStatefulWidget {
  const ScaleEditScreen({super.key, this.scaleId});
  final String? scaleId;

  @override
  ConsumerState<ScaleEditScreen> createState() => _ScaleEditScreenState();
}

class _ScaleEditScreenState extends ConsumerState<ScaleEditScreen> {
  final _name = TextEditingController();
  final _passing = TextEditingController(text: '75');
  bool _round = true;
  bool _builtIn = false;
  List<_Row> _rows = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    () async {
      final s = await ref.read(subjectsRepositoryProvider).scale(widget.scaleId ?? DefaultScale.id);
      if (s != null) {
        _builtIn = s.row.builtIn;
        _name.text = widget.scaleId == null ? 'My scale' : (s.row.builtIn ? '${s.row.name} (copy)' : s.row.name);
        _passing.text = s.row.passingBp % 100 == 0 ? '${s.row.passingBp ~/ 100}' : (s.row.passingBp / 100).toString();
        _round = s.row.roundBeforeLookup;
        _rows = [for (final i in s.items) _Row(i.minBp, i.grade, i.remark)];
      }
      if (mounted) setState(() => _loaded = true);
    }();
  }

  int? _bp(String t) {
    final v = double.tryParse(t.trim());
    if (v == null || v < 0 || v > 100) return null;
    return (v * 100).round();
  }

  Future<void> _save() async {
    final items = <ScaleItem>[];
    for (final r in _rows) {
      final bp = _bp(r.min.text);
      if (bp == null) {
        showMessage(context, 'Each "from %" must be 0 to 100.', error: true);
        return;
      }
      items.add(ScaleItem(bp, r.grade.text.trim(), r.remark.text.trim()));
    }
    final passing = _bp(_passing.text);
    if (passing == null) {
      showMessage(context, 'Passing percentage must be 0 to 100.', error: true);
      return;
    }
    final problems = GradeScale.validate(items);
    if (problems.isNotEmpty) {
      showMessage(context, problems.first, error: true);
      return;
    }
    try {
      await ref
          .read(subjectsRepositoryProvider)
          .saveScale(id: widget.scaleId, name: _name.text, passingBp: passing, roundBeforeLookup: _round, items: items);
      if (mounted) context.pop();
    } on DataError catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scaleId == null ? 'New scale' : (_builtIn ? 'Copy scale' : 'Edit scale')),
        actions: [
          if (widget.scaleId != null && !_builtIn)
            IconButton(
              tooltip: 'Delete scale',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'Delete this scale?',
                  message: 'Subjects using it switch to the default 1.00–5.00 scale.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (!ok) return;
                await ref.read(subjectsRepositoryProvider).deleteScale(widget.scaleId!);
                if (context.mounted) context.pop();
              },
            ),
        ],
      ),
      bottomNavigationBar: BottomAction(label: 'Save', onPressed: _loaded ? _save : null),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Field(controller: _name, label: 'Scale name'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextField(
                    controller: _passing,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Passing percentage', suffixText: '%'),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Round to a whole number first'),
                  subtitle: const Text('74.5% → 75% before looking up the grade'),
                  value: _round,
                  onChanged: (v) => setState(() => _round = v),
                ),
                const SectionTitle('Grades (from % and up)'),
                for (var i = 0; i < _rows.length; i++)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 84,
                          child: TextField(
                            controller: _rows[i].min,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                            decoration: const InputDecoration(labelText: 'from %'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _rows[i].grade,
                            decoration: const InputDecoration(labelText: 'grade'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _rows[i].remark,
                            decoration: const InputDecoration(labelText: 'remark'),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove row',
                          onPressed: () => setState(() => _rows.removeAt(i)),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _rows.add(_Row(0, '', ''))),
                      icon: const Icon(Icons.add),
                      label: const Text('Add grade'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
