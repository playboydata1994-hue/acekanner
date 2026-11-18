import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/licensing_providers.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/repositories/subjects_repository.dart';
import '../../domain/grading/grading_engine.dart';
import '../../domain/scoring/percent.dart';

/// Weights (must total 100%), how activities combine, and the grade scale.
class GradingScreen extends ConsumerStatefulWidget {
  const GradingScreen({super.key, required this.subjectId});
  final String subjectId;

  @override
  ConsumerState<GradingScreen> createState() => _GradingScreenState();
}

class _GradingScreenState extends ConsumerState<GradingScreen> {
  final Map<String, TextEditingController> _fields = {};
  List<WeightView> _weights = const [];
  CombineMethod _method = CombineMethod.totalPoints;
  String? _scaleId;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(subjectsRepositoryProvider);
    final subject = await repo.subject(widget.subjectId);
    final weights = await repo.weights(widget.subjectId);
    if (!mounted || subject == null) return;
    setState(() {
      _weights = weights;
      for (final w in weights) {
        _fields[w.category.id] = TextEditingController(text: w.weightBp == 0 ? '' : _pctText(w.weightBp))
          ..addListener(() => setState(() {}));
      }
      _method = CombineMethod.parse(subject.combineMethod);
      _scaleId = subject.gradeScaleId;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _pctText(int bp) => bp % 100 == 0 ? '${bp ~/ 100}' : (bp / 100).toStringAsFixed(2);

  /// "30" → 3000; "12.5" → 1250; invalid → null.
  static int? _parse(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    final v = double.tryParse(t);
    if (v == null || v < 0 || v > 100) return null;
    return (v * 100).round();
  }

  int get _total => _fields.values.fold(0, (s, c) => s + (_parse(c.text) ?? 0));

  Future<void> _save() async {
    final weights = <String, int>{};
    for (final e in _fields.entries) {
      final bp = _parse(e.value.text);
      if (bp == null) {
        showMessage(context, 'Each weight must be a number from 0 to 100.', error: true);
        return;
      }
      weights[e.key] = bp;
    }
    final repo = ref.read(subjectsRepositoryProvider);
    final active = await repo.saveWeights(widget.subjectId, weights);
    await repo.setCombineMethod(widget.subjectId, _method.code);
    await repo.setScale(widget.subjectId, _scaleId);
    if (!mounted) return;
    if (active) {
      context.pop();
    } else {
      showMessage(
        context,
        'Saved as a draft: the weights total ${formatBp(_total)}. Grades are computed when they total exactly 100%.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMax = ref.watch(planStatusProvider).hasMax;
    final scales = ref.watch(scalesProvider).value ?? const [];
    final total = _total;
    return Scaffold(
      appBar: AppBar(title: const Text('Grading')),
      bottomNavigationBar: BottomAction(label: 'Save', onPressed: _loaded ? _save : null),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (total == 10000 ? AppColors.save : AppColors.amber).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        total == 10000 ? Icons.check_circle : Icons.warning_amber,
                        color: total == 10000 ? AppColors.save : AppColors.amber,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'TOTAL ${formatBp(total)}${total == 10000 ? '' : ' — must be 100%'}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionTitle('Weights (%)'),
                for (final w in _weights)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            w.category.name + (w.kind.needsMax ? '  ·  MAX' : ''),
                            style: TextStyle(fontSize: 18, color: w.kind.needsMax && !hasMax ? AppColors.muted : null),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            controller: _fields[w.category.id],
                            enabled: !w.kind.needsMax || hasMax || (_parse(_fields[w.category.id]!.text) ?? 0) > 0,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              LengthLimitingTextInputFormatter(6),
                            ],
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontSize: 20),
                            decoration: const InputDecoration(suffixText: '%', hintText: '0'),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!hasMax)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(
                      'Examination weights are part of MAX. With PRO, the grade is computed from quizzes and recitations.',
                      style: TextStyle(fontSize: 15, color: AppColors.muted),
                    ),
                  ),
                const SectionTitle('Combining several activities'),
                RadioGroup<CombineMethod>(
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                  child: const Column(
                    children: [
                      RadioListTile(
                        value: CombineMethod.totalPoints,
                        title: Text('Total points'),
                        subtitle: Text('8/10 and 45/50 → 53/60 = 88.33%'),
                      ),
                      RadioListTile(
                        value: CombineMethod.averagePercent,
                        title: Text('Average of percentages'),
                        subtitle: Text('80% and 90% → 85%'),
                      ),
                    ],
                  ),
                ),
                const SectionTitle('Grade scale'),
                DropdownField<String?>(
                  label: 'Grade equivalents',
                  value: scales.any((s) => s.row.id == _scaleId) ? _scaleId : null,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None (percentage only)')),
                    for (final s in scales) DropdownMenuItem(value: s.row.id, child: Text(s.row.name)),
                  ],
                  onChanged: (v) => setState(() => _scaleId = v),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.push(Routes.scales),
                      child: const Text('Manage grade scales'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
