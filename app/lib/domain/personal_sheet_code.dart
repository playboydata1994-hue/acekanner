import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'short_code.dart';

/// Code printed in the QR of a personalized sheet, identifying one student's
/// paper for one examination. Deterministic, so re-printing gives the same
/// code and scanning can identify the student without a stored lookup.
String personalSheetCode(String examId, String studentId) {
  final digest = sha256.convert(utf8.encode('acekanner-sheet|$examId|$studentId')).bytes;
  final out = StringBuffer();
  for (var i = 0; i < 10; i++) {
    out.write(ShortCode.alphabet[digest[i] % ShortCode.alphabet.length]);
  }
  return out.toString();
}
