import 'package:flutter_tts/flutter_tts.dart';

import 'voice_service.dart';

class SpeechOutputService {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text) async {
    final isMalayalam = VoiceService.containsMalayalam(text);
    final language = isMalayalam ? 'ml-IN' : 'en-IN';
    final dynamic available = await _tts.isLanguageAvailable(language);
    if (available != true) {
      throw UnsupportedError(
        isMalayalam
            ? 'Malayalam voice is not installed on this phone.'
            : 'English voice is not available on this phone.',
      );
    }

    await _tts.setLanguage(language);
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
