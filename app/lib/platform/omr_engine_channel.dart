import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/omr_reading.dart';
import '../domain/sheet_layout.dart';

/// Status of the native OMR engine (OpenCV) on this device.
class EngineInfo {
  const EngineInfo({
    required this.available,
    this.opencvVersion,
    this.error,
    this.abi,
    this.sdkInt,
    this.device,
  });

  const EngineInfo.unavailable(String reason)
      : this(available: false, error: reason);

  final bool available;
  final String? opencvVersion;
  final String? error;
  final String? abi;
  final int? sdkInt;
  final String? device;
}

/// Dart side of the `com.acekanner.app/omr` platform channel
/// (android/app/src/main/kotlin/com/acekanner/app/omr/EngineChannel.kt).
/// Corner markers seen in a live preview frame.
class MarkerFeedback {
  const MarkerFeedback({required this.ids, required this.groups, required this.centers});

  final List<int> ids;

  /// Markers found per marker group (marker ID ÷ 4): 50, 75 and 100 items of
  /// sheet design 1 (groups 0–2), design 2 (3–5) and design 3 (6–8).
  final List<int> groups;

  /// Marker centres, normalized 0..1 in the frame.
  final List<(double, double)> centers;

  static int groupFor(int itemCount) => ArucoMarkers.idsFor(itemCount).first ~/ 4;

  int _count(int group) => group < groups.length ? groups[group] : 0;

  int foundFor(int itemCount) => _count(groupFor(itemCount));

  /// The marker group clearly visible instead of the expected one, if any.
  int? _otherGroup(int itemCount) {
    final mine = groupFor(itemCount);
    if (foundFor(itemCount) >= 2) return null;
    for (var g = 0; g < groups.length; g++) {
      if (g != mine && groups[g] >= 3) return g;
    }
    return null;
  }

  /// Another template (item count) is clearly visible instead of the expected one.
  bool otherTemplateFor(int itemCount) => _otherGroup(itemCount) != null;

  /// The sheet in view is an older ACEkanner design (e.g. circle bubbles).
  bool olderDesignFor(int itemCount) {
    final g = _otherGroup(itemCount);
    return g != null && g ~/ 3 < groupFor(itemCount) ~/ 3;
  }
}

class OmrEngineChannel {
  const OmrEngineChannel();

  /// Reads one captured photo on the native worker thread. Writes the
  /// perspective-corrected sheet to [rectifiedPath].
  Future<OmrReading> analyzeSheet({
    required String imagePath,
    required SheetLayout layout,
    required String rectifiedPath,
    String preset = 'standard',
    String? customThresholds,
  }) async {
    final json = await _channel.invokeMethod<String>('analyzeSheet', {
      'imagePath': imagePath,
      'layout': jsonEncode(layout.toJson()),
      'preset': preset,
      'thresholds': customThresholds,
      'rectifiedPath': rectifiedPath,
    });
    if (json == null) throw PlatformException(code: 'omr_failed', message: 'No result from the engine');
    return OmrReading.parse(json);
  }

  /// Checks a preview frame (luminance plane). Returns null when the engine is
  /// still busy with the previous frame.
  Future<MarkerFeedback?> detectMarkers({
    required Uint8List bytes,
    required int width,
    required int height,
    required int rowStride,
  }) async {
    final map = await _channel.invokeMapMethod<String, Object?>('detectMarkers', {
      'bytes': bytes,
      'width': width,
      'height': height,
      'rowStride': rowStride,
      'maxSide': 720,
    });
    if (map == null) return null;
    final centers = (jsonDecode(map['centers'] as String) as List)
        .map((c) => ((c as List)[0] as num, c[1] as num))
        .map((c) => (c.$1.toDouble(), c.$2.toDouble()))
        .toList();
    return MarkerFeedback(
      ids: [for (final i in map['ids'] as List) i as int],
      groups: [for (final g in map['groups'] as List) g as int],
      centers: centers,
    );
  }

  static const MethodChannel _channel = MethodChannel('com.acekanner.app/omr');

  Future<EngineInfo> engineInfo() async {
    try {
      final map = await _channel.invokeMapMethod<String, Object?>('engineInfo');
      if (map == null) {
        return const EngineInfo.unavailable('No response from the engine');
      }
      return EngineInfo(
        available: map['opencvLoaded'] == true,
        opencvVersion: map['opencvVersion'] as String?,
        error: map['error'] as String?,
        abi: map['abi'] as String?,
        sdkInt: map['sdkInt'] as int?,
        device: map['device'] as String?,
      );
    } on MissingPluginException {
      return const EngineInfo.unavailable(
        'The scanner engine runs on Android phones only',
      );
    } on PlatformException catch (e) {
      return EngineInfo.unavailable(e.message ?? e.code);
    }
  }
}
