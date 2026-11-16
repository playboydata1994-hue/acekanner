import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Stores the school logo printed on answer sheets, inside the app's private
/// storage (`<app support>/branding`). Pictures are reduced to at most
/// [maxSide] pixels and saved as PNG, so a large phone photo does not bloat
/// every printed PDF.
class BrandingStore {
  BrandingStore(this._base);

  static const int maxSide = 600;
  static const int maxSourceBytes = 15 * 1024 * 1024;

  final Future<Directory> Function() _base;

  Future<Directory> _dir() async => Directory(p.join((await _base()).path, 'branding'));

  /// Normalizes [source] (PNG, JPEG, WebP, …) and saves it. Returns the path.
  /// Throws [FormatException] when the file is not a readable picture.
  Future<String> saveLogo(Uint8List source) async {
    if (source.isEmpty || source.length > maxSourceBytes) {
      throw const FormatException('Choose a picture smaller than 15 MB.');
    }
    final png = await normalize(source);
    final dir = await _dir();
    await dir.create(recursive: true);
    final name = 'logo-${sha256.convert(png).toString().substring(0, 16)}.png';
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(png, flush: true);
    return file.path;
  }

  /// Decodes, shrinks to [maxSide] and re-encodes as PNG.
  static Future<Uint8List> normalize(Uint8List source) async {
    final ui.Codec codec;
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(source);
      codec = await ui.instantiateImageCodecWithSize(
        buffer,
        getTargetSize: (w, h) {
          final longest = w > h ? w : h;
          if (longest <= maxSide) return ui.TargetImageSize(width: w, height: h);
          final scale = maxSide / longest;
          return ui.TargetImageSize(width: (w * scale).round(), height: (h * scale).round());
        },
      );
    } catch (_) {
      throw const FormatException('That file is not a picture ACEkanner can read. Use a PNG or JPEG.');
    }
    try {
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      if (data == null) throw const FormatException('Could not convert the picture.');
      return data.buffer.asUint8List();
    } finally {
      codec.dispose();
    }
  }

  /// Reads a stored logo; null when missing or unreadable.
  Future<Uint8List?> read(String? path) async {
    if (path == null) return null;
    final file = File(path);
    try {
      return await file.exists() ? await file.readAsBytes() : null;
    } on FileSystemException {
      return null;
    }
  }

  /// Deletes a stored logo. Only files inside the branding folder are touched.
  Future<void> delete(String? path) async {
    if (path == null) return;
    final dir = await _dir();
    if (!p.isWithin(dir.path, path)) return;
    try {
      await File(path).delete();
    } on FileSystemException {
      // Already gone.
    }
  }
}
