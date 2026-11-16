import 'package:flutter/services.dart';

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
class OmrEngineChannel {
  const OmrEngineChannel();

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
