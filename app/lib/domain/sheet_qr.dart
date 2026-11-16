import 'sheet_layout.dart';

/// Contents of the QR code printed on every answer sheet.
///
/// `ACK1|<exam code>|<items>|<id digits>|<sets>|G` on a generic sheet (may be
/// photocopied), or `…|P<sheet code>` on a personalized sheet, where the sheet
/// code identifies one student's paper.
class SheetQr {
  const SheetQr({
    required this.examCode,
    required this.itemCount,
    required this.idDigits,
    required this.setCount,
    this.sheetCode,
  });

  static const String prefix = 'ACK${SheetLayout.formatVersion}';

  final String examCode;
  final int itemCount;
  final int idDigits;
  final int setCount;

  /// Set only on personalized sheets.
  final String? sheetCode;

  bool get personalized => sheetCode != null;

  String encode() => [
        prefix,
        examCode,
        '$itemCount',
        '$idDigits',
        '$setCount',
        sheetCode == null ? 'G' : 'P$sheetCode',
      ].join('|');

  /// Parses a decoded QR string; returns null when it is not an ACEkanner code.
  static SheetQr? tryParse(String? text) {
    if (text == null) return null;
    final parts = text.trim().split('|');
    if (parts.length != 6 || parts[0] != prefix) return null;
    final items = int.tryParse(parts[2]);
    final digits = int.tryParse(parts[3]);
    final sets = int.tryParse(parts[4]);
    if (items == null || digits == null || sets == null) return null;
    final kind = parts[5];
    String? sheet;
    if (kind.startsWith('P') && kind.length > 1) {
      sheet = kind.substring(1);
    } else if (kind != 'G') {
      return null;
    }
    return SheetQr(
      examCode: parts[1],
      itemCount: items,
      idDigits: digits,
      setCount: sets,
      sheetCode: sheet,
    );
  }
}
