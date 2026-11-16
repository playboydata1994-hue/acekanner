import 'package:material_ui/material_ui.dart';

import '../theme/spacing.dart';
import 'feedback.dart';

/// Opens a bottom-sheet form. Returns what [FormSheet.onSubmit] returned, or
/// null when dismissed.
Future<T?> showFormSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: builder,
  );
}

/// Layout and submit handling shared by every small form: title, fields,
/// inline error and a primary button. Keeps the button above the keyboard.
class FormSheet<T> extends StatefulWidget {
  const FormSheet({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.fields,
    required this.onSubmit,
  });

  final String title;
  final String submitLabel;

  /// Built inside a [Form]; use TextFormField validators.
  final List<Widget> fields;

  /// Saves the data and returns the value the sheet closes with. Throwing a
  /// DataException shows its message inside the sheet.
  final Future<T> Function() onSubmit;

  @override
  State<FormSheet<T>> createState() => _FormSheetState<T>();
}

class _FormSheetState<T> extends State<FormSheet<T>> {
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.onSubmit();
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: Space.l),
              for (final field in widget.fields) ...[
                field,
                const SizedBox(height: Space.m),
              ],
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: Space.m),
              ],
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.submitLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
