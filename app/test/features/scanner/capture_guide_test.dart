import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/features/scanner/capture_guide.dart';
import 'package:acekanner/platform/omr_engine_channel.dart';

MarkerFeedback frame({List<int> groups = const [4, 0, 0], double shift = 0}) => MarkerFeedback(
      ids: const [],
      groups: groups,
      centers: [
        (0.1 + shift, 0.1),
        (0.9 + shift, 0.1),
        (0.9 + shift, 0.9),
        (0.1 + shift, 0.9),
      ].take(groups.reduce((a, b) => a > b ? a : b)).toList(),
    );

void main() {
  test('reports missing corners and the wrong sheet type', () {
    final g = CaptureGuide(itemCount: 50);
    expect(g.update(frame(groups: [0, 0, 0])).status, GuideStatus.searching);
    final partial = g.update(frame(groups: [3, 0, 0]));
    expect(partial.status, GuideStatus.partial);
    expect(partial.message, contains('3 of 4'));
    expect(g.update(frame(groups: [0, 0, 4])).status, GuideStatus.otherTemplate);
  });

  test('auto-capture fires once after three steady frames, then re-arms', () {
    final g = CaptureGuide(itemCount: 50);
    expect(g.update(frame()).autoCapture, isFalse);
    expect(g.update(frame(shift: 0.005)).autoCapture, isFalse);
    expect(g.update(frame(shift: 0.008)).autoCapture, isTrue);
    expect(g.update(frame(shift: 0.008)).autoCapture, isFalse, reason: 'fires only once');
    g.rearm();
    expect(g.update(frame()).autoCapture, isFalse);
    expect(g.update(frame()).autoCapture, isFalse);
    expect(g.update(frame()).autoCapture, isTrue);
  });

  test('movement resets the steadiness count', () {
    final g = CaptureGuide(itemCount: 75);
    final steady = frame(groups: [0, 4, 0]);
    g.update(steady);
    g.update(steady);
    final moved = MarkerFeedback(ids: const [], groups: const [0, 4, 0], centers: [
      for (final c in steady.centers) (c.$1 + 0.1, c.$2),
    ]);
    expect(g.update(moved).autoCapture, isFalse);
    expect(g.update(moved).autoCapture, isFalse);
    expect(g.update(moved).autoCapture, isTrue);
  });
}
