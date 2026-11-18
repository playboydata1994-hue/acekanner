import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A file the instructor picked.
class PickedFile {
  const PickedFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// Opens Android's file picker (no storage permission needed).
Future<PickedFile?> pickFile({List<String>? extensions}) async {
  final files = await FilePicker.pickFiles(
    type: extensions == null ? FileType.any : FileType.custom,
    allowedExtensions: extensions,
  );
  if (files.isEmpty) return null;
  final f = files.first;
  return PickedFile(f.name, await f.xFile.readAsBytes());
}

/// Shares a generated file through Android's share sheet (Drive, Gmail,
/// Messenger, print…). The file is written to the app's private cache first.
Future<void> shareFile(List<int> bytes, String fileName, {required String mimeType, String? subject}) async {
  final dir = Directory(p.join((await getTemporaryDirectory()).path, 'share'));
  await dir.create(recursive: true);
  final file = File(p.join(dir.path, fileName));
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: mimeType, name: fileName)],
      subject: subject ?? fileName,
    ),
  );
}

/// Saves a generated file where the instructor chooses (Downloads, Drive…).
/// Returns false when cancelled.
Future<bool> saveFileAs(List<int> bytes, String fileName, {required String mimeType}) async {
  final uri = await FilePicker.saveFile(fileName: fileName, bytes: Uint8List.fromList(bytes), mimeType: mimeType);
  return uri != null;
}

/// "IT 101 Quiz summary" → "IT_101_Quiz_summary".
String safeFileName(String s) => s.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_').replaceAll(RegExp(r'_+'), '_');

abstract final class Mime {
  static const String pdf = 'application/pdf';
  static const String xlsx = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  static const String backup = 'application/octet-stream';
}
