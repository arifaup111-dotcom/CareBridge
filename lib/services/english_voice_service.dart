import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class EnglishVoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  static const MethodChannel _backgroundChannel = MethodChannel(
    'carebridge/voice_background',
  );
  bool _initialized = false;
  bool _androidServiceRunning = false;
  bool _androidRecognitionPaused = false;
  void Function(String text, bool isFinal)? _onResult;
  void Function(String message, bool isPermanent)? _onError;

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get isListening => isAndroid
      ? _androidServiceRunning && !_androidRecognitionPaused
      : _speech.isListening;

  Future<bool> initialize({
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function(String message, bool isPermanent) onError,
  }) async {
    if (!_initialized) {
      _onResult = onResult;
      _onError = onError;
      if (isAndroid) {
        _backgroundChannel.setMethodCallHandler((call) async {
          if (call.method == 'onVoiceTranscript') {
            final text = call.arguments?.toString() ?? '';
            if (text.isNotEmpty) _onResult?.call(text, true);
          } else if (call.method == 'onVoiceServiceError') {
            _androidServiceRunning = false;
            _androidRecognitionPaused = false;
            final details = Map<Object?, Object?>.from(call.arguments as Map);
            _onError?.call(
              details['message']?.toString() ?? 'Voice service failed.',
              details['permanent'] == true,
            );
          }
        });
        _initialized = true;
      } else {
        _initialized = await _speech.initialize(
          onStatus: onStatus,
          onError: (error) => onError(error.errorMsg, error.permanent),
        );
        if (!_initialized) return false;
      }
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1);
      await _tts.awaitSpeakCompletion(true);
    }
    return _initialized;
  }

  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!_initialized || isListening) return;
    if (isAndroid) {
      _onResult = onResult;
      try {
        if (_androidServiceRunning) {
          await resumeListening();
        } else {
          await _backgroundChannel.invokeMethod<void>('startVoiceListening');
          _androidServiceRunning = true;
          _androidRecognitionPaused = false;
        }
      } catch (error) {
        _onError?.call('Could not start Android voice listening: $error', true);
        rethrow;
      }
      return;
    }
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) =>
          onResult(result.recognizedWords, result.finalResult),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        localeId: 'en_US',
        pauseFor: const Duration(seconds: 2),
        listenFor: const Duration(seconds: 45),
        partialResults: false,
        cancelOnError: false,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_initialized && isAndroid) {
      await _backgroundChannel.invokeMethod<void>('stopVoiceListening');
      _androidServiceRunning = false;
      _androidRecognitionPaused = false;
    } else if (_initialized && _speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> pauseListening() async {
    if (!_initialized || !isAndroid || !_androidServiceRunning) return;
    if (_androidRecognitionPaused) return;
    await _backgroundChannel.invokeMethod<void>('pauseVoiceListening');
    _androidRecognitionPaused = true;
  }

  Future<void> resumeListening() async {
    if (!_initialized || !isAndroid || !_androidServiceRunning) return;
    if (!_androidRecognitionPaused) return;
    await _backgroundChannel.invokeMethod<void>('resumeVoiceListening');
    _androidRecognitionPaused = false;
  }

  Future<void> speak(String text) async {
    final resumeAfterSpeech = isAndroid && _androidServiceRunning;
    if (resumeAfterSpeech) {
      await pauseListening();
    } else if (!isAndroid) {
      await stopListening();
    }
    try {
      await _tts.speak(text);
    } finally {
      if (resumeAfterSpeech && _initialized) {
        await resumeListening();
      }
    }
  }

  Future<void> stopSpeaking() => _tts.stop();

  Future<void> dispose() async {
    if (_initialized) {
      if (isAndroid) {
        await stopListening();
      } else {
        await _speech.cancel();
      }
      await _tts.stop();
    }
  }
}
