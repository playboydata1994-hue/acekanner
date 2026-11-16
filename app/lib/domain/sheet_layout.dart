import 'dart:convert';

/// A point in millimetres in the answer-sheet frame: origin at the outer
/// top-left corner of the top-left marker, x to the right, y downwards.
class Mm {
  const Mm(this.x, this.y);

  final double x;
  final double y;

  List<double> toJson() => [_r(x), _r(y)];

  @override
  String toString() => 'Mm($x, $y)';
}

class MmRect {
  const MmRect(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  Map<String, double> toJson() => {'x': _r(left), 'y': _r(top), 'w': _r(width), 'h': _r(height)};
}

double _r(double v) => (v * 1000).roundToDouble() / 1000;

/// OpenCV `DICT_4X4_50` markers used in the sheet corners.
///
/// Inner 4×4 bits (row by row, 1 = white) for IDs 0–11, extracted from OpenCV
/// itself (omr_engine/src/test/.../ArucoDictionaryTest.kt verifies them).
abstract final class ArucoMarkers {
  static const List<String> bits = [
    '1011010100110010', // 0
    '0000111110011010', // 1
    '0011001100101101', // 2
    '1001100101000110', // 3
    '0101010010011110', // 4
    '0111100111001101', // 5
    '1001111000101110', // 6
    '1100010011110010', // 7
    '1111111011011010', // 8
    '1100111101010110', // 9
    '1111100110010001', // 10
    '0001000110100111', // 11
    '0000111010110111', // 12
    '0010101000001111', // 13
    '0010010010110001', // 14
    '0010011000111110', // 15
    '0100011001100101', // 16
    '0110011000000000', // 17
    '0110110001011110', // 18
    '0111011010101111', // 19
    '1000011010001011', // 20
    '1011000000101011', // 21
    '1100110011010101', // 22
    '1101110110000010', // 23
  ];

  /// Marker IDs (top-left, top-right, bottom-right, bottom-left) for each
  /// template of the current sheet design. Reading the IDs tells the engine
  /// which template and design it sees and how the photo is rotated.
  /// Design 1 (circles, IDs 0–11) is retired: the engine rejects those sheets
  /// with "older sheet design" instead of misreading them.
  static List<int> idsFor(int itemCount) => switch (itemCount) {
        50 => const [12, 13, 14, 15],
        75 => const [16, 17, 18, 19],
        100 => const [20, 21, 22, 23],
        _ => throw ArgumentError('Unsupported item count $itemCount'),
      };
}

/// Exact geometry of an ACEkanner answer sheet.
///
/// Every sheet uses the same 190 × 250 mm frame, centred on A4, Letter or
/// 8.5×13 in paper, so recognition is independent of the paper size. The PDF
/// generator draws from this class and the OMR engine reads [toJson]; a test
/// keeps the engine's copies (omr_engine/src/test/resources/layouts) in sync.
class SheetLayout {
  SheetLayout._({
    required this.itemCount,
    required this.idDigits,
    required this.setCount,
    required this.markerIds,
    required this.markerOrigins,
    required this.columnLeft,
    required this.questions,
    required this.idColumns,
    required this.setBubbles,
  });

  /// Builds the layout for an examination.
  factory SheetLayout({required int itemCount, int idDigits = 10, int setCount = 1}) {
    if (idDigits < 4 || idDigits > 12) throw ArgumentError('idDigits must be 4–12');
    if (setCount < 1 || setCount > 4) throw ArgumentError('setCount must be 1–4');
    final ids = ArucoMarkers.idsFor(itemCount);

    // Answer columns of 25 rows, centred horizontally.
    final columns = (itemCount / rowsPerColumn).ceil();
    final pitch = switch (columns) { 2 => 72.0, 3 => 60.0, _ => 47.0 };
    const columnWidth = numberWidth + 4 * choicePitch + bubbleRx;
    final total = (columns - 1) * pitch + columnWidth;
    final left = (frameWidth - total) / 2;
    final columnLeft = [for (var c = 0; c < columns; c++) left + c * pitch];

    final questions = <List<Mm>>[];
    for (var q = 0; q < itemCount; q++) {
      final col = q ~/ rowsPerColumn;
      final row = q % rowsPerColumn;
      final y = firstRowY + row * rowPitch;
      questions.add([
        for (var c = 0; c < 5; c++) Mm(columnLeft[col] + numberWidth + c * choicePitch, y),
      ]);
    }

    final idColumns = [
      for (var i = 0; i < idDigits; i++)
        [for (var d = 0; d < 10; d++) Mm(idFirstX + i * idPitch, idFirstY + d * idRowPitch)],
    ];

    final setBubbles = setCount == 1
        ? const <Mm>[]
        : [for (var i = 0; i < setCount; i++) Mm(setFirstX + i * choicePitch, setY)];

    return SheetLayout._(
      itemCount: itemCount,
      idDigits: idDigits,
      setCount: setCount,
      markerIds: ids,
      markerOrigins: const [
        Mm(0, 0),
        Mm(frameWidth - markerSize, 0),
        Mm(frameWidth - markerSize, frameHeight - markerSize),
        Mm(0, frameHeight - markerSize),
      ],
      columnLeft: columnLeft,
      questions: questions,
      idColumns: idColumns,
      setBubbles: setBubbles,
    );
  }

  /// Bumped whenever geometry changes; printed sheets carry it in the QR and
  /// in their marker IDs. 2 = board-exam style oval bubbles.
  static const int formatVersion = 2;

  static const double frameWidth = 190;
  static const double frameHeight = 250;
  static const double markerSize = 10;

  /// Resolution of the corrected image the engine works on.
  static const int pxPerMm = 8;

  /// Answer ovals: 5.0 × 3.2 mm (half-axes), like board-exam answer sheets.
  static const double bubbleRx = 2.5;
  static const double bubbleRy = 1.6;

  /// Student-number ovals: 4.2 × 2.8 mm.
  static const double idBubbleRx = 2.1;
  static const double idBubbleRy = 1.4;
  static const int rowsPerColumn = 25;
  static const double rowPitch = 6.4;
  static const double choicePitch = 6.8;
  static const double firstRowY = 79;

  /// From a column's left edge to its first bubble centre (room for "100").
  static const double numberWidth = 10.5;

  static const double idFirstX = 98.5;
  static const double idPitch = 5.4;
  static const double idFirstY = 27;
  static const double idRowPitch = 4.4;
  static const double idBoxTop = 18.5;
  static const double idBoxSize = 4.4;

  static const MmRect qr = MmRect(163, 16, 25, 25);
  static const double setFirstX = 165.3;
  static const double setY = 51.5;

  /// Bottom of the header area (a rule is printed here).
  static const double headerBottom = 72;

  final int itemCount;
  final int idDigits;
  final int setCount;

  /// TL, TR, BR, BL.
  final List<int> markerIds;
  final List<Mm> markerOrigins;
  final List<double> columnLeft;

  /// questions[q][choice] for q = 0..itemCount-1, choice = 0..4 (A–E).
  final List<List<Mm>> questions;

  /// idColumns[column][digit], digit = 0..9.
  final List<List<Mm>> idColumns;

  /// Set A–D bubbles; empty when the examination has a single set.
  final List<Mm> setBubbles;

  String get templateId => 'ack$formatVersion-$itemCount';

  Map<String, Object?> toJson() => {
        'format': formatVersion,
        'template': templateId,
        'items': itemCount,
        'choices': 5,
        'idDigits': idDigits,
        'sets': setCount,
        'frame': {'w': frameWidth, 'h': frameHeight},
        'pxPerMm': pxPerMm,
        'markers': {
          'dictionary': 'DICT_4X4_50',
          'size': markerSize,
          'ids': markerIds,
          'origins': [for (final o in markerOrigins) o.toJson()],
        },
        'qr': qr.toJson(),
        'bubble': {'rx': bubbleRx, 'ry': bubbleRy},
        'idBubble': {'rx': idBubbleRx, 'ry': idBubbleRy},
        'questions': [
          for (final q in questions) [for (final b in q) b.toJson()],
        ],
        'idColumns': [
          for (final c in idColumns) [for (final b in c) b.toJson()],
        ],
        'setBubbles': [for (final b in setBubbles) b.toJson()],
      };

  String toJsonString() => const JsonEncoder.withIndent(' ').convert(toJson());
}
