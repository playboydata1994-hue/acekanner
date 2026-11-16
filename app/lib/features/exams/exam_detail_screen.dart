import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/data_providers.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/info_row.dart';
import '../../core/widgets/section_header.dart';
import '../../data/repositories/scan_repository.dart';
import '../../data/repositories/students_repository.dart';
import '../../data/repositories/exams_repository.dart';
import 'exam_widgets.dart';

/// One examination: status, answer keys per set, and settings.
class ExamDetailScreen extends ConsumerWidget {
  const ExamDetailScreen({super.key, required this.examId});

  final String examId;

  Future<void> _trash(BuildContext context, WidgetRef ref, ExamDetail d) async {
    final ok = await confirmAction(
      context,
      title: 'Delete examination?',
      message: '“${d.exam.title}” moves to Recently deleted, where you can restore it.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(examsRepositoryProvider).moveToTrash(examId);
    if (context.mounted) {
      showMessage(context, 'Moved to Recently deleted');
      context.go('/exams');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(examDetailProvider(examId));
    return switch (detail) {
      AsyncData(:final value) when value == null || value.exam.deletedAt != null => Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('This examination was deleted.')),
        ),
      AsyncData(:final value) => _DetailBody(detail: value!, onTrash: () => _trash(context, ref, value)),
      AsyncError() => Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Could not load this examination.')),
        ),
      _ => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
    };
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.onTrash});

  final ExamDetail detail;
  final VoidCallback onTrash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exam = detail.exam;
    final colors = context.statusColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Examination'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final saved = await context.push<bool>('/exam-editor/${exam.id}');
              if (saved == true && context.mounted) showMessage(context, 'Examination saved');
            },
          ),
          PopupMenuButton<int>(
            tooltip: 'More',
            onSelected: (_) => onTrash(),
            itemBuilder: (_) => const [PopupMenuItem(value: 0, child: Text('Delete'))],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, Space.xxl),
        children: [
          Text(exam.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Space.xs),
          Text(
            [
              if (detail.subject != null) '${detail.subject!.code} — ${detail.subject!.title}',
              formatExamDate(exam.examDate),
            ].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: Space.m),
          Wrap(
            spacing: Space.m,
            runSpacing: Space.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ExamStatusPill(status: exam.status),
              Text('Code ${exam.shortCode}', style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: Space.l),
          if (!detail.keysComplete)
            _Banner(
              color: colors.uncertain,
              icon: Icons.edit_note,
              text: 'Enter the answer key for '
                  '${detail.versions.length == 1 ? 'this examination' : 'every set'} to finish setting it up.',
            )
          else
            _Banner(
              color: colors.correct,
              icon: Icons.check_circle_outline,
              text: 'Answer key complete.',
            ),
          SectionHeader(detail.versions.length == 1 ? 'Answer key' : 'Answer keys'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < detail.versions.length; i++) ...[
                  if (i > 0) const Divider(indent: Space.l, endIndent: Space.l),
                  _KeyTile(status: detail.versions[i]),
                ],
              ],
            ),
          ),
          SectionHeader('Papers · ${detail.paperCount}'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/sheets/${exam.id}'),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Answer sheets'),
                ),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push('/scan/${exam.id}'),
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Scan papers'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.m),
          _PapersList(examId: exam.id),
          const SectionHeader('Details'),
          Card(
            child: Column(
              children: [
                InfoRow(label: 'Items', value: '${exam.itemCount} (choices A–E)'),
                InfoRow(
                  label: 'Sets',
                  value: detail.versions.length == 1 ? 'One set (A)' : setsLabel(detail.versions.length),
                ),
                InfoRow(
                  label: 'Sections',
                  value: detail.sections.isEmpty ? 'None assigned' : detail.sections.map((s) => s.name).join(', '),
                ),
                InfoRow(label: 'Passing', value: '${_fmt(exam.passingPercentage)}%'),
                InfoRow(
                  label: 'Two or more shaded',
                  value: exam.multipleMarkPolicy == MultipleMarkPolicy.zero
                      ? 'Scores zero'
                      : 'Counts as a wrong answer',
                ),
                InfoRow(label: 'Totals below zero', value: exam.allowNegativeTotal ? 'Allowed' : 'Not allowed'),
                InfoRow(label: 'Student number', value: '${exam.studentIdDigits} digits'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _PapersList extends ConsumerWidget {
  const _PapersList({required this.examId});

  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papers = ref.watch(scannedPapersProvider(examId));
    final theme = Theme.of(context);
    return switch (papers) {
      AsyncData(:final value) when value.isEmpty => Text(
          'No papers scanned yet. Print answer sheets, give the examination, then scan each paper.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      AsyncData(:final value) => Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < value.length; i++) ...[
                if (i > 0) const Divider(indent: Space.l, endIndent: Space.l),
                _PaperTile(paper: value[i]),
              ],
            ],
          ),
        ),
      AsyncError() => const Text('Could not load the papers.'),
      _ => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
    };
  }
}

class _PaperTile extends StatelessWidget {
  const _PaperTile({required this.paper});

  final ScannedPaper paper;

  @override
  Widget build(BuildContext context) {
    final s = paper.student;
    final sheet = paper.sheet;
    return ListTile(
      leading: CircleAvatar(child: Text(paper.versionLabel ?? '?')),
      title: Text(s == null ? 'Student not identified' : studentDisplayName(s)),
      subtitle: Text(
        [
          s?.studentNo ?? sheet.detectedStudentNo ?? 'no number',
          if (sheet.flaggedCount > 0) '${sheet.flaggedCount} reviewed',
          sheet.status == 'finalized' ? 'Graded' : 'Awaiting grading',
        ].join(' · '),
      ),
    );
  }
}

class _KeyTile extends StatelessWidget {
  const _KeyTile({required this.status});

  final VersionKeyStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.statusColors;
    return ListTile(
      leading: CircleAvatar(child: Text(status.version.label)),
      title: Text('Set ${status.version.label}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${status.completeCount} of ${status.itemTotal} answers set'
            '${status.revision > 1 ? ' · revision ${status.revision}' : ''}',
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: status.itemTotal == 0 ? 0 : status.completeCount / status.itemTotal,
              minHeight: 6,
              color: status.isComplete ? colors.correct : null,
            ),
          ),
        ],
      ),
      trailing: Icon(
        status.isComplete ? Icons.check_circle : Icons.chevron_right,
        color: status.isComplete ? colors.correct : null,
      ),
      onTap: () => context.push('/answer-key/${status.version.id}'),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.text});

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(Space.m),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Radii.m),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: Space.m),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
