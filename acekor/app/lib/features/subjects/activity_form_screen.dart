import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_settings.dart';
import '../../app/data_providers.dart';
import '../../app/licensing_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/feedback.dart';
import '../../data/db/app_database.dart';
import '../../data/errors.dart';
import '../../data/repositories/activities_repository.dart';
import '../../domain/categories.dart';
import '../plan/paywall.dart';

/// Creates or edits a quiz, recitation or examination.
class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({super.key, this.subjectId, this.activityId, this.kind = CategoryKind.quiz});
  final String? subjectId;
  final String? activityId;
  final CategoryKind kind;

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  final _number = TextEditingController();
  final _title = TextEditingController();
  final _max = TextEditingController();
  final _remarks = TextEditingController();
  String? _categoryId;
  String? _subjectId;
  DateTime _date = DateTime.now();
  Period _period = Period.none;
  late CategoryKind _kind = widget.kind;
  bool _loaded = false;
  bool _saving = false;

  bool get _editing => widget.activityId != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = ref.read(appSettingsProvider);
    if (_editing) {
      final a = await ref.read(activitiesRepositoryProvider).activity(widget.activityId!);
      if (a == null) return;
      _subjectId = a.row.subjectId;
      _categoryId = a.row.categoryId;
      _kind = a.kind;
      _number.text = a.row.number?.toString() ?? '';
      _title.text = a.row.title;
      _max.text = '${a.maxPoints}';
      _remarks.text = a.row.remarks;
      _date = DateTime.tryParse(a.row.activityDate ?? '') ?? DateTime.now();
      _period = a.period;
    } else {
      _subjectId = widget.subjectId;
      final cats = (await ref.read(subjectsRepositoryProvider).categories())
          .where((c) => CategoryKind.parse(c.kind) == _kind)
          .toList();
      if (cats.isNotEmpty) await _applyCategory(cats.first, settings);
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _applyCategory(CategoryRow c, UserSettings settings) async {
    _categoryId = c.id;
    final kind = CategoryKind.parse(c.kind);
    var max = c.defaultMaxPoints;
    if (kind == CategoryKind.recitation && settings.recitationMethod == RecitationMethod.rating5) max = 5;
    _max.text = '$max';
    if (kind == CategoryKind.exam) {
      _number.text = '';
    } else {
      final first = kind == CategoryKind.quiz ? settings.quizFirstNumber : 1;
      final next = await ref.read(activitiesRepositoryProvider).nextNumber(_subjectId!, c.id, first: first);
      _number.text = '$next';
    }
  }

  int _maxAllowed(UserSettings s) => switch (_kind) {
    CategoryKind.quiz => s.quizMaxAllowed,
    CategoryKind.recitation => s.recitationMaxAllowed,
    CategoryKind.exam => s.examMaxAllowed,
  };

  @override
  void dispose() {
    for (final c in [_number, _title, _max, _remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final settings = ref.read(appSettingsProvider);
    final max = int.tryParse(_max.text.trim());
    final allowed = _maxAllowed(settings);
    if (max == null || max < 1) {
      showMessage(context, 'Enter the maximum points.', error: true);
      return;
    }
    if (max > allowed) {
      showMessage(context, 'The maximum for this type is $allowed points (Settings › Calculator).', error: true);
      return;
    }
    if (_categoryId == null || _subjectId == null) return;
    if (!_editing && _kind.needsMax) {
      final block = ref.read(planStatusProvider).block(_kind);
      if (block != null) {
        await showPaywall(context, block);
        return;
      }
    }
    final input = ActivityInput(
      subjectId: _subjectId!,
      categoryId: _categoryId!,
      number: int.tryParse(_number.text.trim()),
      title: _title.text,
      maxPoints: max,
      date: isoDate(_date),
      period: _period,
      remarks: _remarks.text,
    );
    setState(() => _saving = true);
    final repo = ref.read(activitiesRepositoryProvider);
    try {
      if (_editing) {
        await repo.updateActivity(widget.activityId!, input);
        if (mounted) context.pop(widget.activityId);
      } else {
        final id = await repo.createActivity(input);
        if (mounted) context.pop(id);
      }
    } on DataError catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = (ref.watch(categoriesProvider).value ?? const <CategoryRow>[])
        .where((c) => CategoryKind.parse(c.kind) == _kind || c.id == _categoryId)
        .toList();
    final settings = ref.watch(appSettingsProvider);
    final kindName = switch (_kind) {
      CategoryKind.quiz => 'quiz',
      CategoryKind.recitation => 'recitation',
      CategoryKind.exam => 'examination',
    };
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit $kindName' : 'New $kindName')),
      bottomNavigationBar: BottomAction(label: 'Save', onPressed: _saving || !_loaded ? null : _save),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (_kind == CategoryKind.exam || cats.length > 1)
                  DropdownField<String>(
                    label: 'Type',
                    value: _categoryId,
                    items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name))],
                    onChanged: (v) async {
                      final c = cats.firstWhere((x) => x.id == v);
                      if (!_editing) await _applyCategory(c, settings);
                      setState(() => _categoryId = v);
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextField(
                    controller: _number,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: _kind == CategoryKind.exam ? 'Number (optional)' : 'Number (e.g. 1 for Quiz 1)',
                    ),
                  ),
                ),
                Field(controller: _title, label: 'Title (optional, e.g. Chapter 2)'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextField(
                    controller: _max,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Maximum points (total)',
                      helperText: 'Up to ${_maxAllowed(settings)} points',
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('EEEE, MMMM d, y').format(_date)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),
                DropdownField<Period>(
                  label: 'Grading period (optional)',
                  value: _period,
                  items: [for (final p in Period.values) DropdownMenuItem(value: p, child: Text(p.label))],
                  onChanged: (v) => setState(() => _period = v ?? Period.none),
                ),
                Field(
                  controller: _remarks,
                  label: 'Remarks (optional)',
                  textCapitalization: TextCapitalization.sentences,
                ),
                if (_kind == CategoryKind.exam)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text('Examinations are a MAX feature.', style: TextStyle(color: AppColors.muted)),
                  ),
              ],
            ),
    );
  }
}
