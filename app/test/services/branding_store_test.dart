import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/services/branding_store.dart';
import 'package:path/path.dart' as p;

Future<Uint8List> pngOfSize(int w, int h) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xFF1D4ED8));
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<(int, int)> sizeOf(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  final size = (frame.image.width, frame.image.height);
  frame.image.dispose();
  codec.dispose();
  return size;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory base;
  late BrandingStore store;

  setUp(() {
    base = Directory.systemTemp.createTempSync('acek-branding');
    store = BrandingStore(() async => base);
  });
  tearDown(() => base.deleteSync(recursive: true));

  testWidgets('large pictures are reduced to 600 px and saved privately as PNG', (tester) async {
    await tester.runAsync(() async {
      final path = await store.saveLogo(await pngOfSize(1800, 900));
      expect(p.isWithin(p.join(base.path, 'branding'), path), isTrue);
      expect(p.extension(path), '.png');
      final saved = await store.read(path);
      expect(await sizeOf(saved!), (600, 300));

      // The sample seal (480 px) is kept at its size.
      final seal = await store.saveLogo(File('test/assets/sample_logo.png').readAsBytesSync());
      expect(await sizeOf((await store.read(seal))!), (480, 480));
    });
  });

  testWidgets('unreadable files are refused; delete only touches the branding folder', (tester) async {
    await tester.runAsync(() async {
      await expectLater(store.saveLogo(Uint8List.fromList(List.filled(64, 7))), throwsFormatException);
      await expectLater(store.saveLogo(Uint8List(0)), throwsFormatException);

      final outside = File(p.join(base.path, 'scans', 'keep.jpg'))..createSync(recursive: true);
      await store.delete(outside.path);
      expect(outside.existsSync(), isTrue);

      final path = await store.saveLogo(await pngOfSize(100, 100));
      await store.delete(path);
      expect(File(path).existsSync(), isFalse);
      expect(await store.read(path), isNull);
      expect(await store.read(null), isNull);
    });
  });
}
