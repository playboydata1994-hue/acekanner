import 'dart:convert';

import 'package:acekanner/domain/omr_reading.dart';
import 'package:acekanner/domain/sheet_layout.dart';

/// Builds an engine JSON result like the native engine returns.
String engineJson({
  required List<int> masks,
  Set<int> uncertain = const {},
  Set<int> blank = const {},
  Set<int> multiple = const {},
  String studentNumber = '202100123',
  bool clear = true,
  int? setMask,
  String? qr,
  Map<int, int> crossed = const {},
}) {
  Map<String, Object?> group(int mask, String state, [int crossedMask = 0]) => {
        'state': state,
        'mask': mask,
        'scores': [for (var i = 0; i < 5; i++) (mask >> i) & 1 == 1 ? 0.95 : 0.01],
        'confidence': state == 'uncertain' ? 0.2 : 0.97,
        'erasure': false,
        'crossed': crossedMask,
      };
  return jsonEncode({
    'ok': true,
    'engineVersion': '1.0.0',
    'template': 'ack${SheetLayout.formatVersion}-${masks.length}',
    'questions': [
      for (var i = 0; i < masks.length; i++)
        group(
          masks[i],
          uncertain.contains(i + 1)
              ? 'uncertain'
              : (blank.contains(i + 1) ? 'blank' : (multiple.contains(i + 1) ? 'multiple' : 'answered')),
          crossed[i + 1] ?? 0,
        ),
    ],
    'idColumns': const [],
    'studentNumber': studentNumber,
    'studentNumberClear': clear,
    'set': setMask == null ? null : group(setMask, 'answered'),
    'qr': qr,
    'quality': {'edgeWidthMm': 0.25, 'contrast': 200, 'glare': 0, 'reprojectionMm': 0.2, 'brightness': 220, 'score': 0.95},
    'rotation': 0,
    'flagged': uncertain.length,
    'elapsedMs': 120,
  });
}

OmrSheetReading reading({
  required List<int> masks,
  Set<int> uncertain = const {},
  Set<int> blank = const {},
  Set<int> multiple = const {},
  String studentNumber = '202100123',
  bool clear = true,
  int? setMask,
  String? qr,
  Map<int, int> crossed = const {},
}) =>
    OmrReading.parse(engineJson(
      masks: masks,
      uncertain: uncertain,
      blank: blank,
      multiple: multiple,
      studentNumber: studentNumber,
      clear: clear,
      setMask: setMask,
      qr: qr,
      crossed: crossed,
    )) as OmrSheetReading;
