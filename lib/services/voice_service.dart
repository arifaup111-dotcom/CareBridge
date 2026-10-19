import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';

import 'permission_service.dart';

/// What the voice engine is doing right now.
///
/// The elder dashboard maps these straight onto the microphone card so
/// the elder always knows whether CareBridge is listening, thinking or
/// speaking.
enum VoiceState { idle, listening, processing, speaking, unavailable }

/// Shared speech-to-text / text-to-speech engine for CareBridge.
///
/// Why this is a service and not inline dashboard code:
///   * the Family dashboard will need the same engine later,
///   * Malayalam support has to be probed at runtime rather than
///     assumed, and that probing logic should live in one place.
///
/// Malayalam handling in short:
///   STT - many Indian devices ship Malayalam recognition, many do not.
///         We ask the engine for its locale list and only use "ml_IN"
///         if it is actually there. Otherwise we fall back to en_IN so
///         the elder still gets something rather than silence.
///   TTS - same idea, via isLanguageAvailable("ml-IN").
///
/// Nothing here throws at the caller. Every failure becomes a state
/// change plus a human-readable message, because the PRD requires the
/// app to stay usable when a voice service is unavailable.
class VoiceService {
  // ================================================================
  // ENGINES
  // ================================================================

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  // ================================================================
  // LOCALE CONSTANTS
  // ================================================================

  static const String malayalamStt = 'ml_IN';
  static const String indianEnglishStt = 'en_IN';
  static const String usEnglishStt = 'en_US';

  static const String malayalamTts = 'ml-IN';
  static const String indianEnglishTts = 'en-IN';
  static const String usEnglishTts = 'en-US';

  // ================================================================
  // CAPABILITY FLAGS (filled during initialize)
  // ================================================================

  bool _initialized = false;
  bool _sttAvailable = false;
  bool _malayalamSttAvailable = false;
  bool _malayalamTtsAvailable = false;

  /// The locale id actually used for listening. Malayalam when the
  /// device supports it, otherwise the best English fallback found.
  String _activeSttLocale = usEnglishStt;
  String? _malayalamSttLocale;
  String? _englishSttLocale;
  String? _requestedSttLocale;
  bool _malayalamLocaleRejected = false;

  bool get isInitialized => _initialized;
  bool get isSttAvailable => _sttAvailable;
  bool get isMalayalamSttAvailable => _malayalamSttAvailable;
  bool get isMalayalamTtsAvailable => _malayalamTtsAvailable;
  String get activeSttLocale => _activeSttLocale;
  String get englishWakeLocale => _englishSttLocale ?? _activeSttLocale;
  String get wakeWordLocale =>
      _malayalamSttAvailable && !_malayalamLocaleRejected
      ? _malayalamSttLocale!
      : englishWakeLocale;
  String get commandLocale =>
      _malayalamSttAvailable && !_malayalamLocaleRejected
      ? _malayalamSttLocale!
      : _activeSttLocale;

  // ================================================================
  // LIVE STATE
  // ================================================================

  VoiceState _state = VoiceState.idle;
  VoiceState get state => _state;

  bool get isListening => _state == VoiceState.listening;
  bool get isSpeaking => _state == VoiceState.speaking;

  String _lastWords = '';
  String get lastWords => _lastWords;

  // ================================================================
  // CALLBACKS - the dashboard supplies these
  // ================================================================

  /// Fires on every state change so the UI can rebuild.
  void Function(VoiceState state)? onStateChanged;

  /// Fires on every partial result while the elder is still speaking.
  void Function(String text)? onPartialResult;

  /// Fires once, with the finished sentence, when the elder stops.
  void Function(String text)? onFinalResult;

  /// Fires with a message already written for an elderly reader.
  /// Malayalam when Malayalam is available, English otherwise.
  void Function(String message)? onError;

  void _setState(VoiceState next) {
    if (_state == next) return;
    _state = next;
    onStateChanged?.call(next);
  }

  // ================================================================
  // INITIALIZATION
  // ================================================================

  /// Prepares both engines and works out what this device can do.
  ///
  /// Safe to call more than once - repeat calls return the cached
  /// result instead of re-probing.
  Future<bool> initialize() async {
    if (_initialized) return _sttAvailable;

    final micGranted = await PermissionService.requestMicrophone();
    if (!micGranted) {
      _sttAvailable = false;
      _initialized = true;
      _setState(VoiceState.unavailable);
      onError?.call(
        'മൈക്രോഫോൺ അനുമതി ആവശ്യമാണ്. Settings തുറന്ന് അനുമതി നൽകുക.',
      );
      // TTS may still work without the microphone, so keep going.
      await _initializeTts();
      return false;
    }

    await _initializeStt();
    await _initializeTts();

    _initialized = true;
    return _sttAvailable;
  }

  // ----------------------------------------------------------------
  // SPEECH TO TEXT
  // ----------------------------------------------------------------

  Future<void> _initializeStt() async {
    try {
      _sttAvailable = await _speech.initialize(
        onStatus: _handleSttStatus,
        onError: _handleSttError,
        debugLogging: kDebugMode,
      );

      if (!_sttAvailable) {
        _setState(VoiceState.unavailable);
        onError?.call(
          'ഈ ഫോണിൽ ശബ്ദ തിരിച്ചറിയൽ ലഭ്യമല്ല. ബട്ടണുകൾ ഉപയോഗിക്കാം.',
        );
        return;
      }

      await _resolveSttLocale();
    } catch (e) {
      _sttAvailable = false;
      _setState(VoiceState.unavailable);
      debugPrint('VoiceService: STT init failed -> $e');
      onError?.call('ശബ്ദ സേവനം ആരംഭിക്കാൻ കഴിഞ്ഞില്ല.');
    }
  }

  /// Asks the engine which locales it has, then picks the best one.
  ///
  /// This is the part that was missing before. Hardcoding "ml_IN" on a
  /// device without Malayalam recognition makes listen() return empty
  /// results forever with no error at all.
  Future<void> _resolveSttLocale() async {
    try {
      final locales = await _speech.locales();
      final ids = locales
          .map((locale) => locale.localeId.replaceAll('-', '_'))
          .toList();

      debugPrint('VoiceService: ${ids.length} STT locales available');

      for (final locale in locales) {
        if (_malayalamSttLocale == null &&
            isMalayalamLocaleId(locale.localeId)) {
          _malayalamSttLocale = locale.localeId;
        }
        if (_englishSttLocale == null &&
            _localeLanguageCode(locale.localeId) == 'en') {
          _englishSttLocale = locale.localeId;
        }
      }

      if (_malayalamSttLocale != null) {
        _malayalamSttAvailable = true;
        _activeSttLocale = _malayalamSttLocale!;
      } else if (_englishSttLocale != null) {
        _malayalamSttAvailable = false;
        _activeSttLocale = _englishSttLocale!;
      } else {
        // Fall back to whatever the system default is.
        final systemLocale = await _speech.systemLocale();
        _malayalamSttAvailable = false;
        _activeSttLocale = systemLocale?.localeId ?? usEnglishStt;
        if (isMalayalamLocaleId(_activeSttLocale)) {
          _malayalamSttLocale = _activeSttLocale;
          _malayalamSttAvailable = true;
        }
      }

      debugPrint(
        'VoiceService: STT locale = $_activeSttLocale '
        '(Malayalam available: $_malayalamSttAvailable)',
      );
    } catch (e) {
      debugPrint('VoiceService: locale probe failed -> $e');
      _activeSttLocale = usEnglishStt;
      _malayalamSttAvailable = false;
    }
  }

  // ----------------------------------------------------------------
  // TEXT TO SPEECH
  // ----------------------------------------------------------------

  Future<void> _initializeTts() async {
    try {
      // Speaking slowly matters a great deal for elderly listeners.
      await _tts.setSpeechRate(0.42);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);

      // Probe Malayalam. Returns false on devices whose TTS engine has
      // no Malayalam voice installed, which is common.
      final dynamic result = await _tts.isLanguageAvailable(malayalamTts);
      _malayalamTtsAvailable = result == true;

      debugPrint(
        'VoiceService: Malayalam TTS available = $_malayalamTtsAvailable',
      );

      await _tts.setLanguage(
        _malayalamTtsAvailable ? malayalamTts : indianEnglishTts,
      );

      _tts.setCompletionHandler(() {
        if (_state == VoiceState.speaking) _setState(VoiceState.idle);
      });

      _tts.setCancelHandler(() {
        if (_state == VoiceState.speaking) _setState(VoiceState.idle);
      });

      _tts.setErrorHandler((message) {
        debugPrint('VoiceService: TTS error -> $message');
        if (_state == VoiceState.speaking) _setState(VoiceState.idle);
      });
    } catch (e) {
      debugPrint('VoiceService: TTS init failed -> $e');
      _malayalamTtsAvailable = false;
    }
  }

  // ================================================================
  // LISTENING
  // ================================================================

  /// Starts listening. Stops any ongoing speech first so the microphone
  /// does not pick up CareBridge's own voice.
  Future<void> startListening({
    Duration listenFor = const Duration(seconds: 35),
    Duration pauseFor = const Duration(seconds: 5),
    String? localeId,
    bool useDictationMode = true,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    if (!_sttAvailable) {
      onError?.call('ശബ്ദ തിരിച്ചറിയൽ ലഭ്യമല്ല.');
      return;
    }

    if (_speech.isListening) return;

    await stopSpeaking();

    _lastWords = '';
    _requestedSttLocale = localeId ?? _activeSttLocale;
    _setState(VoiceState.listening);

    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;

          if (result.finalResult) {
            _setState(VoiceState.processing);
            if (_lastWords.trim().isNotEmpty) {
              onFinalResult?.call(_lastWords.trim());
            } else {
              _setState(VoiceState.processing);
              onError?.call('ഒന്നും കേൾക്കാനായില്ല. വീണ്ടും ശ്രമിക്കൂ.');
              _setState(VoiceState.idle);
            }
          } else {
            onPartialResult?.call(_lastWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: useDictationMode
              ? stt.ListenMode.dictation
              : stt.ListenMode.confirmation,
          localeId: _requestedSttLocale,
          listenFor: listenFor,
          pauseFor: pauseFor,
        ),
      );
    } catch (e) {
      debugPrint('VoiceService: listen failed -> $e');
      _setState(VoiceState.idle);
      onError?.call('ശബ്ദം കേൾക്കാൻ കഴിഞ്ഞില്ല. വീണ്ടും ശ്രമിക്കൂ.');
    }
  }

  /// Stops listening and hands over whatever was captured.
  Future<void> stopListening() async {
    if (!_speech.isListening) {
      _setState(VoiceState.idle);
      return;
    }

    await _speech.stop();

    final captured = _lastWords.trim();
    if (captured.isNotEmpty) {
      _setState(VoiceState.processing);
      onFinalResult?.call(captured);
    } else {
      _setState(VoiceState.idle);
    }
  }

  /// Throws away whatever was captured. Used when the elder taps away.
  Future<void> cancelListening() async {
    if (_speech.isListening) await _speech.cancel();
    _lastWords = '';
    _setState(VoiceState.idle);
  }

  void _handleSttStatus(String status) {
    debugPrint('VoiceService: STT status -> $status');

    if (status == 'notListening' && _state == VoiceState.listening) {
      _setState(VoiceState.processing);
    }

    if (status == 'done' && _state == VoiceState.listening) {
      _setState(VoiceState.idle);
    }
  }

  void _handleSttError(SpeechRecognitionError error) {
    debugPrint('VoiceService: STT error -> ${error.errorMsg}');
    _setState(VoiceState.processing);

    // These strings come from the Android SpeechRecognizer.
    switch (error.errorMsg) {
      case 'error_no_match':
      case 'error_speech_timeout':
        onError?.call('ഒന്നും കേൾക്കാനായില്ല. വീണ്ടും ശ്രമിക്കൂ.');
        break;
      case 'error_network':
      case 'error_network_timeout':
        onError?.call('ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിക്കുക.');
        break;
      case 'error_permission':
        onError?.call('മൈക്രോഫോൺ അനുമതി ആവശ്യമാണ്.');
        break;
      case 'error_language_unavailable':
      case 'error_language_not_supported':
      case 'error_locale_not_supported':
        final requestedLocale = _requestedSttLocale
            ?.replaceAll('-', '_')
            .toLowerCase();
        if (requestedLocale != null && isMalayalamLocaleId(requestedLocale)) {
          _malayalamLocaleRejected = true;
          _malayalamSttAvailable = false;
          _activeSttLocale = _englishSttLocale ?? usEnglishStt;
          onError?.call(
            'ഈ ഫോണിൽ മലയാളം ശബ്ദ തിരിച്ചറിയൽ ലഭ്യമല്ല. മലയാളം ഭാഷാ പാക്ക് ഇൻസ്റ്റാൾ ചെയ്യുക; താൽക്കാലികമായി ഇംഗ്ലീഷ് ഉപയോഗിക്കാം.',
          );
        } else {
          onError?.call('ശബ്ദം തിരിച്ചറിയാൻ കഴിഞ്ഞില്ല. വീണ്ടും ശ്രമിക്കൂ.');
        }
        break;
      case 'error_busy':
        onError?.call('ഒരു നിമിഷം കാത്തിരിക്കൂ, വീണ്ടും ശ്രമിക്കൂ.');
        break;
      default:
        onError?.call('ശബ്ദം തിരിച്ചറിയാൻ കഴിഞ്ഞില്ല. വീണ്ടും ശ്രമിക്കൂ.');
    }
    _setState(VoiceState.idle);
  }

  // ================================================================
  // SPEAKING
  // ================================================================

  /// Speaks [text], choosing the voice from the script of the text
  /// itself rather than from an app-wide setting.
  ///
  /// When the text is Malayalam but the device has no Malayalam voice,
  /// we do not read it out in the wrong accent - [onError] fires
  /// instead so the dashboard can leave the answer on screen.
  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await stopSpeaking();

    final wantsMalayalam = containsMalayalam(trimmed);

    if (wantsMalayalam && !_malayalamTtsAvailable) {
      debugPrint('VoiceService: Malayalam text but no Malayalam voice');
      _setState(VoiceState.idle);
      onError?.call(
        'Malayalam voice is not installed on this phone. '
        'The answer is shown on screen.',
      );
      return;
    }

    try {
      await _tts.setLanguage(wantsMalayalam ? malayalamTts : _englishVoice());

      _setState(VoiceState.speaking);
      await _tts.speak(trimmed);

      // awaitSpeakCompletion(true) means speak() returns when finished,
      // but the completion handler may have already reset the state.
      if (_state == VoiceState.speaking) _setState(VoiceState.idle);
    } catch (e) {
      debugPrint('VoiceService: speak failed -> $e');
      _setState(VoiceState.idle);
    }
  }

  String _englishVoice() =>
      _malayalamTtsAvailable ? indianEnglishTts : usEnglishTts;

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('VoiceService: stop failed -> $e');
    }
    if (_state == VoiceState.speaking) _setState(VoiceState.idle);
  }

  // ================================================================
  // HELPERS
  // ================================================================

  /// True when [text] contains any character in the Malayalam Unicode
  /// block (U+0D00 to U+0D7F).
  static bool containsMalayalam(String text) {
    return RegExp(r'[\u0D00-\u0D7F]').hasMatch(text);
  }

  static bool isMalayalamLocaleId(String localeId) =>
      _localeLanguageCode(localeId) == 'ml';

  static String _localeLanguageCode(String localeId) =>
      localeId.trim().toLowerCase().split(RegExp(r'[-_]')).first;

  /// A short line the dashboard can show under the microphone so the
  /// elder is not left guessing why Malayalam is not working.
  String capabilityNote() {
    if (!_sttAvailable) {
      return 'Voice input is not available on this phone.';
    }
    if (_malayalamSttAvailable && _malayalamTtsAvailable) {
      return 'മലയാളത്തിൽ സംസാരിക്കാം.';
    }
    if (_malayalamSttAvailable && !_malayalamTtsAvailable) {
      return 'മലയാളം കേൾക്കാം, പക്ഷേ മറുപടി സ്ക്രീനിൽ വായിക്കണം.';
    }
    return 'Malayalam is not installed on this phone. English works.';
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  Future<void> dispose() async {
    onStateChanged = null;
    onPartialResult = null;
    onFinalResult = null;
    onError = null;

    try {
      await _speech.cancel();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
