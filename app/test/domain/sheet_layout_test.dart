import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/domain/sheet_layout.dart';
import 'package:acekanner/domain/sheet_qr.dart';

/// Layouts the Kotlin engine tests use (omr_engine/src/test/resources/layouts).
final Map<String, SheetLayout> engineFixtures = {
  'ack1-50-d10-s1': SheetLayout(itemCount: 50),
  'ack1-75-d9-s2': SheetLayout(itemCount: 75, idDigits: 9, setCount: 2),
  'ack1-100-d12-s4': SheetLayout(itemCount: 100, idDigits: 12, setCount: 4),
};

void main() {
  const quiet = 10 / 6; // one marker cell of white space around each marker

  for (final items in [50, 75, 100]) {
    for (final digits in [4, 10, 12]) {
      for (final sets in [1, 4]) {
        test('$items items, $digits digits, $sets sets: geometry is valid', () {
          final l = SheetLayout(itemCount: items, idDigits: digits, setCount: sets);
          expect(l.questions, hasLength(items));
          expect(l.idColumns, hasLength(digits));
          expect(l.setBubbles, hasLength(sets == 1 ? 0 : sets));

          final circles = <(Mm, double)>[
            for (final q in l.questions)
              for (final b in q) (b, SheetLayout.bubbleRadius),
            for (final c in l.idColumns)
              for (final b in c) (b, SheetLayout.idBubbleRadius),
            for (final b in l.setBubbles) (b, SheetLayout.bubbleRadius),
          ];

          for (final (p, r) in circles) {
            // Inside the frame.
            expect(p.x - r, greaterThanOrEqualTo(0));
            expect(p.y - r, greaterThanOrEqualTo(0));
            expect(p.x + r, lessThanOrEqualTo(SheetLayout.frameWidth));
            expect(p.y + r, lessThanOrEqualTo(SheetLayout.frameHeight));
            // Clear of every marker and its quiet zone.
            for (final o in l.markerOrigins) {
              final inside = p.x + r > o.x - quiet &&
                  p.x - r < o.x + SheetLayout.markerSize + quiet &&
                  p.y + r > o.y - quiet &&
                  p.y - r < o.y + SheetLayout.markerSize + quiet;
              expect(inside, isFalse, reason: 'bubble $p touches a marker');
            }
            // Clear of the QR code.
            const q = SheetLayout.qr;
            final inQr = p.x + r > q.left && p.x - r < q.left + q.width && p.y + r > q.top && p.y - r < q.top + q.height;
            expect(inQr, isFalse, reason: 'bubble $p overlaps the QR code');
          }

          // No two bubbles overlap; answer bubbles keep a 1.5 mm gap.
          for (var i = 0; i < circles.length; i++) {
            for (var j = i + 1; j < circles.length; j++) {
              final (a, ra) = circles[i];
              final (b, rb) = circles[j];
              final d = sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
              expect(d - ra - rb, greaterThanOrEqualTo(0.5), reason: '$a and $b too close');
            }
          }

          // Answer area below the header; ID grid and set row inside it.
          for (final q in l.questions) {
            expect(q.first.y - SheetLayout.bubbleRadius, greaterThan(SheetLayout.headerBottom));
          }
          for (final c in l.idColumns) {
            expect(c.last.y + SheetLayout.idBubbleRadius, lessThan(SheetLayout.headerBottom));
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
    expect(ArucoMarkers.idsFor(50), [0, 1, 2, 3]);
    expect(ArucoMarkers.idsFor(75), [4, 5, 6, 7]);
    expect(ArucoMarkers.idsFor(100), [8, 9, 10, 11]);
    expect(() => ArucoMarkers.idsFor(60), throwsArgumentError);
    expect(ArucoMarkers.bits.every((b) => RegExp(r'^[01]{16}$').hasMatch(b)), isTrue);
  });

  test('QR payload round-trips', () {
    const generic = SheetQr(examCode: 'K7M2Q9XA', itemCount: 75, idDigits: 9, setCount: 2);
    expect(generic.encode(), 'ACK1|K7M2Q9XA|75|9|2|G');
    final parsed = SheetQr.tryParse(generic.encode())!;
    expect(parsed.examCode, 'K7M2Q9XA');
    expect(parsed.personalized, isFalse);

    const personal = SheetQr(examCode: 'K7M2Q9XA', itemCount: 50, idDigits: 10, setCount: 1, sheetCode: 'S3CR3T00');
    expect(SheetQr.tryParse(personal.encode())!.sheetCode, 'S3CR3T00');

    expect(SheetQr.tryParse('https://example.com'), isNull);
    expect(SheetQr.tryParse('ACK1|X|50|10|1|Z'), isNull);
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
