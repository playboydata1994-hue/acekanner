import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/domain/sheet_layout.dart';
import 'package:acekanner/domain/sheet_qr.dart';

/// Answer sheets printed today must still scan years from now. This test
/// freezes sheet design 3 (circle bubbles): every printable layout and the
/// QR format. If it fails, the change would break sheets already printed:
/// keep design 3 readable and add a new design version instead.
///
/// To create the frozen file (only when design 3 is first frozen):
///   flutter test test/domain/sheet_design_compat_test.dart --dart-define=WRITE_FIXTURE=true
void main() {
  const fixture = 'test/fixtures/sheet_design3_fingerprints.json';

  Map<String, Object?> current() => {
        'formatVersion': SheetLayout.formatVersion,
        'qr': const SheetQr(examCode: 'K7M2Q9XA', itemCount: 100, idDigits: 10, setCount: 5).encode(),
        'layouts': {
          for (final items in const [50, 75, 100])
            for (var digits = 4; digits <= 12; digits++)
              for (var sets = 1; sets <= 5; sets++)
                // A fingerprint of everything the engine reads from the layout.
                '$items-$digits-$sets': sha256
                    .convert(utf8.encode(jsonEncode(SheetLayout(itemCount: items, idDigits: digits, setCount: sets).toJson())))
                    .toString(),
        },
      };

  test('sheet design 3 layouts and QR format are unchanged', () {
    final now = jsonDecode(jsonEncode(current()));
    final file = File(fixture);
    if (const bool.fromEnvironment('WRITE_FIXTURE') && !file.existsSync()) {
      file.writeAsStringSync(const JsonEncoder.withIndent(' ').convert(now));
    }
    final frozen = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    expect(now['formatVersion'], 3);
    expect(now['qr'], frozen['qr'], reason: 'the QR format of printed sheets changed');
    final layouts = (now as Map)['layouts'] as Map;
    final frozenLayouts = frozen['layouts'] as Map;
    expect(layouts.keys.toSet(), frozenLayouts.keys.toSet());
    for (final key in frozenLayouts.keys) {
      expect(layouts[key], frozenLayouts[key], reason: 'layout $key changed: printed sheets would stop scanning');
    }
  });
}
