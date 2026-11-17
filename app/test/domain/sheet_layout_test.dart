import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/domain/sheet_layout.dart';
import 'package:acekanner/domain/sheet_qr.dart';

/// Layouts the Kotlin engine tests use (omr_engine/src/test/resources/layouts).
final Map<String, SheetLayout> engineFixtures = {
  'ack3-50-d10-s1': SheetLayout(itemCount: 50),
  'ack3-75-d9-s2': SheetLayout(itemCount: 75, idDigits: 9, setCount: 2),
  'ack3-100-d12-s5': SheetLayout(itemCount: 100, idDigits: 12, setCount: 5),
};

void main() {
  const quiet = 10 / 6; // one marker cell of white space around each marker

  for (final items in [50, 75, 100]) {
    for (final digits in [4, 10, 12]) {
      for (final sets in [1, 4, 5]) {
        test('$items items, $digits digits, $sets sets: geometry is valid', () {
          final l = SheetLayout(itemCount: items, idDigits: digits, setCount: sets);
          expect(l.questions, hasLength(items));
          expect(l.idColumns, hasLength(digits));
          expect(l.setBubbles, hasLength(sets == 1 ? 0 : sets));

          // Every oval as (centre, half-width, half-height).
          final ovals = <(Mm, double, double)>[
            for (final q in l.questions)
              for (final b in q) (b, SheetLayout.bubbleRx, SheetLayout.bubbleRy),
            for (final c in l.idColumns)
              for (final b in c) (b, SheetLayout.idBubbleRx, SheetLayout.idBubbleRy),
            for (final b in l.setBubbles) (b, SheetLayout.bubbleRx, SheetLayout.bubbleRy),
          ];

          for (final (p, rx, ry) in ovals) {
            // Inside the frame.
            expect(p.x - rx, greaterThanOrEqualTo(0));
            expect(p.y - ry, greaterThanOrEqualTo(0));
            expect(p.x + rx, lessThanOrEqualTo(SheetLayout.frameWidth));
            expect(p.y + ry, lessThanOrEqualTo(SheetLayout.frameHeight));
            // Clear of every marker and its quiet zone.
            for (final o in l.markerOrigins) {
              final inside = p.x + rx > o.x - quiet &&
                  p.x - rx < o.x + SheetLayout.markerSize + quiet &&
                  p.y + ry > o.y - quiet &&
                  p.y - ry < o.y + SheetLayout.markerSize + quiet;
              expect(inside, isFalse, reason: 'bubble $p touches a marker');
            }
            // Clear of the QR code.
            const q = SheetLayout.qr;
            final inQr = p.x + rx > q.left && p.x - rx < q.left + q.width && p.y + ry > q.top && p.y - ry < q.top + q.height;
            expect(inQr, isFalse, reason: 'bubble $p overlaps the QR code');
          }

          // No two ovals overlap: at least 1 mm apart horizontally or vertically
          // (the engine samples just outside each ring when aligning).
          for (var i = 0; i < ovals.length; i++) {
            for (var j = i + 1; j < ovals.length; j++) {
              final (a, arx, ary) = ovals[i];
              final (b, brx, bry) = ovals[j];
              final gapX = (a.x - b.x).abs() - arx - brx;
              final gapY = (a.y - b.y).abs() - ary - bry;
              expect(gapX >= 1.0 || gapY >= 1.0, isTrue, reason: '$a and $b too close');
            }
          }

          // Answer area below the header; ID grid and set row inside it.
          for (final q in l.questions) {
            expect(q.first.y - SheetLayout.bubbleRy, greaterThan(SheetLayout.headerBottom));
          }
          for (final c in l.idColumns) {
            expect(c.last.y + SheetLayout.idBubbleRy, lessThan(SheetLayout.headerBottom));
            expect(c.first.x + SheetLayout.idBubbleRx, lessThan(SheetLayout.qr.left - 2));
          }
        });
      }
    }
  }

  test('questions run top to bottom, then left to right', () {
    final l = SheetLayout(itemCount: 100);
    expect(l.questions[0][0].y, l.questions[25][0].y);
    expect(l.questions[24][0].y, greaterThan(l.questions[0][0].y));
    expect(l.questions[25][0].x, greaterThan(l.questions[24][4].x));
    expect(l.questions[0][1].x - l.questions[0][0].x, closeTo(SheetLayout.choicePitch, 1e-9));
  });

  test('marker IDs identify the template', () {
    expect(ArucoMarkers.idsFor(50), [24, 25, 26, 27]);
    expect(ArucoMarkers.idsFor(75), [28, 29, 30, 31]);
    expect(ArucoMarkers.idsFor(100), [32, 33, 34, 35]);
    expect(ArucoMarkers.bits, hasLength(36));
    expect(() => ArucoMarkers.idsFor(60), throwsArgumentError);
    expect(() => SheetLayout(itemCount: 50, setCount: 6), throwsArgumentError);
    // Rows of 2-4 sets keep their printed position; five sets start further left.
    expect(SheetLayout(itemCount: 50, setCount: 4).setBubbles.first.x, SheetLayout.setFirstX);
    expect(SheetLayout(itemCount: 50, setCount: 5).setBubbles.map((b) => b.x).toList(),
        [for (var i = 0; i < 5; i++) SheetLayout.setFirstX5 + i * SheetLayout.choicePitch]);
    expect(ArucoMarkers.bits.every((b) => RegExp(r'^[01]{16}$').hasMatch(b)), isTrue);
  });

  test('QR payload round-trips', () {
    const generic = SheetQr(examCode: 'K7M2Q9XA', itemCount: 75, idDigits: 9, setCount: 2);
    expect(generic.encode(), 'ACK3|K7M2Q9XA|75|9|2|G');
    final parsed = SheetQr.tryParse(generic.encode())!;
    expect(parsed.examCode, 'K7M2Q9XA');
    expect(parsed.personalized, isFalse);

    const personal = SheetQr(examCode: 'K7M2Q9XA', itemCount: 50, idDigits: 10, setCount: 1, sheetCode: 'S3CR3T00');
    expect(SheetQr.tryParse(personal.encode())!.sheetCode, 'S3CR3T00');

    expect(SheetQr.tryParse('https://example.com'), isNull);
    expect(SheetQr.tryParse('ACK3|X|50|10|1|Z'), isNull);
    expect(SheetQr.tryParse('ACK2|K7M2Q9XA|50|10|1|G'), isNull);
    expect(SheetQr.isOlderDesign('ACK1|K7M2Q9XA|50|10|1|G'), isTrue);
    expect(SheetQr.isOlderDesign('ACK2|K7M2Q9XA|50|10|1|G'), isTrue);
    expect(SheetQr.isOlderDesign(generic.encode()), isFalse);
    expect(SheetQr.tryParse(null), isNull);
  });

  test('engine layout fixtures are up to date', () {
    final dir = Directory('../omr_engine/src/test/resources/layouts');
    final export = Platform.environment['ACEK_EXPORT_FIXTURES'] == '1';
    for (final MapEntry(:key, :value) in engineFixtures.entries) {
      final file = File('${dir.path}/$key.json');
      final json = value.toJsonString();
      if (export) {
        dir.createSync(recursive: true);
        file.writeAsStringSync(json);
      }
      expect(file.existsSync(), isTrue, reason: 'Run with ACEK_EXPORT_FIXTURES=1 to create $key.json');
      expect(file.readAsStringSync(), json, reason: '$key.json is stale; re-export with ACEK_EXPORT_FIXTURES=1');
    }
  });
}
