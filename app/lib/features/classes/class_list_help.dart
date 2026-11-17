import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/roster_file.dart';

/// Saves a file where the user chooses (Android's Save dialog). Returns null
/// when the user cancels.
typedef FileSaver = Future<Uri?> Function({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
  String? dialogTitle,
});

final fileSaverProvider = Provider<FileSaver>(
  (ref) => ({required fileName, required bytes, required mimeType, dialogTitle}) => FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
        dialogTitle: dialogTitle,
      ),
);

/// The sample class list shown in the help, as spreadsheet rows (the first row
/// names the columns). A test checks that it imports exactly as shown.
const List<List<String>> sampleClassList = [
  ['Student No', 'Last Name', 'First Name', 'Middle Name'],
  ['2021-00123', 'Dela Cruz', 'Juan', 'Perez'],
  ['2021-00124', 'Santos', 'Maria Clara', 'Lopez'],
  ['2021-00125', 'Reyes', 'Jose', ''],
  ['2021-00126', 'Garcia', 'Ana', 'Mendoza'],
];

/// The same kind of list with a single name column.
const List<List<String>> sampleClassListOneName = [
  ['Student No', 'Name'],
  ['2021-00123', 'Dela Cruz, Juan P.'],
  ['2021-00124', 'Santos, Maria Clara L.'],
];

/// "?" button that shows how a class list file should look.
class ClassListHelpButton extends StatelessWidget {
  const ClassListHelpButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Sample class list',
        icon: const Icon(Icons.help_outline),
        onPressed: () => showClassListHelp(context),
      );
}

Future<void> showClassListHelp(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _ClassListHelp(),
    );

class _ClassListHelp extends StatelessWidget {
  const _ClassListHelp();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
        children: [
          Text('Sample class list', style: theme.textTheme.titleLarge),
          const SizedBox(height: Space.s),
          const Text(
            'Make a sheet in Excel or Google Sheets like this one: the first row names the '
            'columns, then one student per row.',
          ),
          const SizedBox(height: Space.l),
          const _SheetPreview(rows: sampleClassList),
          const SizedBox(height: Space.m),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Required: ', style: TextStyle(fontWeight: FontWeight.w600)),
                const TextSpan(text: 'Student No, Last Name, First Name.\n'),
                const TextSpan(text: 'Optional: ', style: TextStyle(fontWeight: FontWeight.w600)),
                const TextSpan(text: 'Middle Name, Suffix, Email.\n'),
                TextSpan(
                  text: 'The columns can be in any order.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.l),
          Text('Or one Name column', style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.s),
          const _SheetPreview(rows: sampleClassListOneName),
          const SizedBox(height: Space.s),
          Text('Write each name as "Last name, First name Middle initial".', style: theme.textTheme.bodySmall),
          const SizedBox(height: Space.l),
          Text('Tips', style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xs),
          for (final tip in const [
            'Save the file as Excel (.xlsx) or CSV. From Google Sheets: File › Download › '
                'Microsoft Excel (.xlsx).',
            'A title row above the column names (for example the subject and section) is fine.',
            'Type each student number exactly as it is on the student\'s ID. Students shade this '
                'number on the answer sheet.',
            'Rows with a missing name or student number are skipped and listed before anything '
                'is saved.',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7, right: Space.m),
                    child: Icon(Icons.circle, size: 6),
                  ),
                  Expanded(child: Text(tip, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: Space.l),
          const _SaveTemplateButton(),
          const SizedBox(height: Space.s),
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it')),
        ],
      ),
    );
  }
}

/// Rows drawn like a spreadsheet: column letters, row numbers, a shaded
/// header row. Scrolls sideways on narrow phones.
class _SheetPreview extends StatelessWidget {
  const _SheetPreview({required this.rows});

  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final body = theme.textTheme.bodySmall;
    final border = BorderSide(color: scheme.outlineVariant);
    Widget cell(String text, {TextStyle? style, Color? fill, bool center = false}) => Container(
          color: fill,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          alignment: center ? Alignment.center : Alignment.centerLeft,
          child: Text(text, style: style, softWrap: false),
        );
    final columns = rows.first.length;
    return Semantics(
      label: 'Sample spreadsheet: ${[for (final r in rows) r.where((c) => c.isNotEmpty).join(', ')].join('; ')}',
      excludeSemantics: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder(
            top: border,
            bottom: border,
            left: border,
            right: border,
            horizontalInside: border,
            verticalInside: border,
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(color: scheme.surfaceContainerHigh),
              children: [
                cell('', style: small),
                for (var c = 0; c < columns; c++) cell(String.fromCharCode(65 + c), style: small, center: true),
              ],
            ),
            for (var r = 0; r < rows.length; r++)
              TableRow(
                children: [
                  cell('${r + 1}', style: small, fill: scheme.surfaceContainerHigh, center: true),
                  for (final value in rows[r])
                    cell(
                      value,
                      style: r == 0 ? body?.copyWith(fontWeight: FontWeight.w700) : body,
                      fill: r == 0 ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Saves the empty Excel class list (column names only) to the phone.
class _SaveTemplateButton extends ConsumerStatefulWidget {
  const _SaveTemplateButton();

  @override
  ConsumerState<_SaveTemplateButton> createState() => _SaveTemplateButtonState();
}

class _SaveTemplateButtonState extends ConsumerState<_SaveTemplateButton> {
  bool _busy = false;

  /// Result shown under the button (this sheet covers the screen's messages).
  String? _note;
  bool _failed = false;

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      final uri = await ref.read(fileSaverProvider)(
        fileName: classListTemplateName,
        bytes: Uint8List.fromList(classListTemplateXlsx()),
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        dialogTitle: 'Save sample class list',
      );
      if (uri != null && mounted) {
        setState(() {
          _failed = false;
          _note = 'Saved "$classListTemplateName". Fill it in, then upload it.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _note = 'The file could not be saved. Try again, or choose another folder.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.statusColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _save,
          icon: _busy
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.download_outlined),
          label: const Text('Save sample file (Excel)'),
        ),
        const SizedBox(height: Space.xs),
        if (_note != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_failed ? Icons.error_outline : Icons.check_circle, size: 18,
                  color: _failed ? colors.incorrect : colors.correct),
              const SizedBox(width: Space.xs),
              Flexible(child: Text(_note!, style: theme.textTheme.bodySmall)),
            ],
          )
        else
          Text(
            'An empty Excel file with the column names. Save it to your phone or Google Drive, '
            'fill it in, then upload it.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
