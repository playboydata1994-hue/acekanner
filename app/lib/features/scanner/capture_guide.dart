import '../../platform/omr_engine_channel.dart';

enum GuideStatus {
  /// No corner markers in view.
  searching,

  /// Some, not all, of this examination's markers are visible.
  partial,

  /// Markers of a different answer-sheet template are visible.
  otherTemplate,

  /// An older ACEkanner sheet design (circle bubbles) is visible.
  olderDesign,

  /// All four markers visible and steady.
  ready,
}

class GuideState {
  const GuideState(this.status, this.cornersFound, {this.autoCapture = false});

  final GuideStatus status;
  final int cornersFound;

  /// True once: the moment auto-capture should fire.
  final bool autoCapture;

  String get message => switch (status) {
        GuideStatus.searching => 'Fit the whole answer sheet in the frame',
        GuideStatus.partial => '$cornersFound of 4 corners found — move back a little',
        GuideStatus.otherTemplate => 'This answer sheet is a different type than this examination',
        GuideStatus.olderDesign => 'This is an older ACEkanner sheet design — print new sheets',
        GuideStatus.ready => 'All corners found — hold steady',
      };
}

/// Turns live marker feedback into guidance and decides when to auto-capture:
/// all four markers of an accepted sheet size in [stableFrames] consecutive
/// frames whose centres moved less than [maxMovement] (fraction of the
/// frame) between frames.
class CaptureGuide {
  CaptureGuide({required int itemCount, this.stableFrames = 3, this.maxMovement = 0.015})
      : itemCounts = [itemCount];

  /// Accepts any of [itemCounts] (e.g. every sheet size big enough for the
  /// examination, or every size when the examination is not known yet).
  CaptureGuide.forCounts(this.itemCounts, {this.stableFrames = 3, this.maxMovement = 0.015})
      : assert(itemCounts.isNotEmpty);

  final List<int> itemCounts;
  final int stableFrames;
  final double maxMovement;

  int _steady = 0;
  List<(double, double)>? _last;
  bool _fired = false;

  GuideState update(MarkerFeedback f) {
    final found = itemCounts.map(f.foundFor).reduce((a, b) => a > b ? a : b);
    final other = f.otherGroupBesides(itemCounts);
    if (other != null) {
      _reset();
      return GuideState(
        MarkerFeedback.isOlderDesignGroup(other) ? GuideStatus.olderDesign : GuideStatus.otherTemplate,
        found,
      );
    }
    if (found < 4) {
      _reset();
      return GuideState(found == 0 ? GuideStatus.searching : GuideStatus.partial, found);
    }
    final centers = [...f.centers]..sort((a, b) => (a.$1 + a.$2).compareTo(b.$1 + b.$2));
    final moved = _last == null || _last!.length != centers.length
        ? double.infinity
        : [
            for (var i = 0; i < centers.length; i++)
              (centers[i].$1 - _last![i].$1).abs() + (centers[i].$2 - _last![i].$2).abs(),
          ].reduce((a, b) => a > b ? a : b);
    _last = centers;
    _steady = moved <= maxMovement ? _steady + 1 : 1;
    final fire = !_fired && _steady >= stableFrames;
    if (fire) _fired = true;
    return GuideState(GuideStatus.ready, 4, autoCapture: fire);
  }

  /// Call after a capture completes so the next paper can auto-capture.
  void rearm() => _reset();

  void _reset() {
    _steady = 0;
    _last = null;
    _fired = false;
  }
}
