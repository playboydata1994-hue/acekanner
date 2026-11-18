import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Asks for a whole number between [min] and [max].
Future<int?> askNumber(
  BuildContext context, {
  required String title,
  required int initial,
  int min = 0,
  required int max,
  String? help,
}) {
  final c = TextEditingController(text: '$initial');
  String? error;
  return showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (help != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(help, style: const TextStyle(fontSize: 16)),
              ),
            TextField(
              controller: c,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
              style: const TextStyle(fontSize: 26),
              decoration: InputDecoration(errorText: error, helperText: '$min to $max'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(c.text);
              if (v == null || v < min || v > max) {
                setState(() => error = 'Enter a number from $min to $max.');
                return;
              }
              Navigator.pop(context, v);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );
}

/// Asks for a line of text.
Future<String?> askText(BuildContext context, {required String title, String initial = '', String? hint}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        style: const TextStyle(fontSize: 20),
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('OK')),
      ],
    ),
  );
}

/// Picks one of [options].
Future<T?> askChoice<T>(BuildContext context, {required String title, required Map<T, String> options, T? current}) {
  return showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        for (final e in options.entries)
          ListTile(
            leading: Icon(e.key == current ? Icons.radio_button_checked : Icons.radio_button_off),
            title: Text(e.value),
            onTap: () => Navigator.pop(context, e.key),
          ),
      ],
    ),
  );
}
