import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Bridge to Android Foreground Service for screen-off microphone and wake-word operation.
class BackgroundVoiceBridge {
  BackgroundVoiceBridge._();

  static const MethodChannel _channel = MethodChannel(
    'carebridge/voice_background',
  );
  static void Function(String wakePhrase)? onWakeWordTriggered;
  static void Function(String message)? onWakeServiceError;

  /// Initializes the platform callback listener for native wake-word triggers.
  static void initialize({
    void Function(String wakePhrase)? onWake,
    void Function(String message)? onError,
  }) {
    onWakeWordTriggered = onWake;
    onWakeServiceError = onError;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWakeWordDetected') {
        final phrase = call.arguments?['wakePhrase']?.toString() ?? 'hello mac';
        onWakeWordTriggered?.call(phrase);
      } else if (call.method == 'onWakeServiceError') {
        final message =
            call.arguments?.toString() ?? 'Wake-word listening is unavailable.';
        onWakeServiceError?.call(message);
      }
    });
    if (defaultTargetPlatform == TargetPlatform.android) {
      _registerWakeListener();
    }
  }

  static Future<void> _registerWakeListener() async {
    try {
      await _channel.invokeMethod<bool>('registerWakeWordListener');
    } on PlatformException catch (error) {
      debugPrint('Could not register the background wake listener: $error');
    }
  }

  /// Starts the Android foreground service with a persistent notification.
  /// This keeps the microphone and CPU active when the screen turns off or another app is open.
  static Future<bool> startForegroundService({
    required String wakePhrase,
  }) async {
    try {
      final ok = await _channel.invokeMethod<bool>('startForegroundVoice', {
        'wakePhrase': wakePhrase,
      });
      return ok == true;
    } on PlatformException catch (error) {
      debugPrint('Background voice service failed to start: $error');
      return false;
    }
  }

  /// Stops the Android foreground service.
  static Future<bool> stopForegroundService() async {
    try {
      final ok = await _channel.invokeMethod<bool>('stopForegroundVoice');
      return ok == true;
    } on PlatformException catch (error) {
      debugPrint('Background voice service failed to stop: $error');
      return false;
    }
  }

  /// Pauses the native background recognizer so Flutter can use the mic in foreground.
  static Future<bool> pauseForegroundVoice() async {
    try {
      final ok = await _channel.invokeMethod<bool>('pauseForegroundVoice');
      return ok == true;
    } on PlatformException catch (error) {
      debugPrint('Background voice service failed to pause: $error');
      return false;
    }
  }

  /// Resumes the native background recognizer when Flutter finishes listening.
  static Future<bool> resumeForegroundVoice() async {
    try {
      final ok = await _channel.invokeMethod<bool>('resumeForegroundVoice');
      return ok == true;
    } on PlatformException catch (error) {
      debugPrint('Background voice service failed to resume: $error');
      return false;
    }
  }

  static Future<Map<String, bool>?> foregroundVoiceState() async {
    try {
      final state = await _channel.invokeMapMethod<String, bool>(
        'getForegroundVoiceState',
      );
      return state;
    } on PlatformException catch (error) {
      debugPrint('Could not check background voice service state: $error');
      return null;
    }
  }

  /// Turns on the screen and brings CareBridge over the lock screen.
  static Future<bool> wakeScreen() async {
    try {
      final ok = await _channel.invokeMethod<bool>('wakeScreen');
      return ok == true;
    } on PlatformException catch (error) {
      debugPrint('Could not wake the screen: $error');
      return false;
    }
  }
}
