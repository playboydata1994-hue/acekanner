import 'package:flutter_test/flutter_test.dart';
import 'package:acekanner/features/scanner/capture_guide.dart';
import 'package:acekanner/platform/omr_engine_channel.dart';

/// Marker counts per group: designs 1, 2, 3 × (50, 75, 100 items).
/// [current] = the current design (3), [older] = design 1, [ovals] = design 2.
List<int> g({List<int> current = const [0, 0, 0], List<int> older = const [0, 0, 0], List<int> ovals = const [0, 0, 0]}) =>
    [...older, ...ovals, ...current];

MarkerFeedback frame({List<int>? groups, double shift = 0}) => _frame(groups ?? g(current: [4, 0, 0]), shift);

MarkerFeedback _frame(List<int> groups, double shift) => MarkerFeedback(
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
    final guide = CaptureGuide(itemCount: 50);
    expect(guide.update(frame(groups: g())).status, GuideStatus.searching);
    final partial = guide.update(frame(groups: g(current: [3, 0, 0])));
    expect(partial.status, GuideStatus.partial);
    expect(partial.message, contains('3 of 4'));
    expect(guide.update(frame(groups: g(current: [0, 0, 4]))).status, GuideStatus.otherTemplate);
  });

  test('sheets of older test designs are recognised, not treated as missing corners', () {
    final guide = CaptureGuide(itemCount: 75);
    final first = guide.update(frame(groups: g(older: [0, 4, 0])));
    expect(first.status, GuideStatus.olderDesign);
    expect(first.message, contains('print new sheets'));
    expect(guide.update(frame(groups: g(ovals: [0, 4, 0]))).status, GuideStatus.olderDesign);
    expect(MarkerFeedback.groupFor(50), 6);
    expect(MarkerFeedback.groupFor(100), 8);
  });

  test('auto-capture fires once after three steady frames, then re-arms', () {
    final guide = CaptureGuide(itemCount: 50);
    expect(guide.update(frame()).autoCapture, isFalse);
    expect(guide.update(frame(shift: 0.005)).autoCapture, isFalse);
    expect(guide.update(frame(shift: 0.008)).autoCapture, isTrue);
    expect(guide.update(frame(shift: 0.008)).autoCapture, isFalse, reason: 'fires only once');
    guide.rearm();
    expect(guide.update(frame()).autoCapture, isFalse);
    expect(guide.update(frame()).autoCapture, isFalse);
    expect(guide.update(frame()).autoCapture, isTrue);
  });

  test('movement resets the steadiness count', () {
    final guide = CaptureGuide(itemCount: 75);
    final steady = frame(groups: g(current: [0, 4, 0]));
    guide.update(steady);
    guide.update(steady);
    final moved = MarkerFeedback(ids: const [], groups: g(current: [0, 4, 0]), centers: [
      for (final c in steady.centers) (c.$1 + 0.1, c.$2),
    ]);
    expect(guide.update(moved).autoCapture, isFalse);
    expect(guide.update(moved).autoCapture, isFalse);
    expect(guide.update(moved).autoCapture, isTrue);
  });
}
