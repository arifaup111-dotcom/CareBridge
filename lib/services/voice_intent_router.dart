/// Voice intents used by the Elder Dashboard.
///
/// Data intents are deliberately separated from navigation intents. When an
/// elder asks a question such as "ഇന്ന് ഏത് മരുന്നാണ്?", CareBridge should
/// read the relevant Firestore data instead of merely opening a screen or
/// sending the question to Gemini.
/// Voice intents used by the Elder Dashboard.
///
/// Data intents are deliberately separated from navigation intents. When an
/// elder asks a question such as "ഇന്ന് ഏത് മരുന്നാണ്?", CareBridge should
/// read the relevant Firestore data instead of merely opening a screen or
/// sending the question to Gemini.
enum VoiceIntentType {
  emergency,
  medicineToday,
  appointmentToday,
  careReminders,
  openMedicines,
  openAppointments,
  openReminders,
  chat,
}

class VoiceIntentRouter {
  VoiceIntentRouter._();

  /// Matches the elder's chosen assistant name at the beginning of speech.
  static String? commandAfterWakeWord(
    String rawText, {
    String assistantName = 'Care',
  }) {
    final normalized = rawText.trim().replaceAll(RegExp(r'\s+'), ' ');
    final namePattern = RegExp.escape(
      assistantName.trim(),
    ).replaceAll(' ', r'\s+');
    if (namePattern.isEmpty) return null;
    final match = RegExp(
      r'^(?:(?:hey|hi|hello|ഹലോ|ഹെലോ)\s+)?' +
          namePattern +
          r'(?:\b|[\s,.:!?-]|$)\s*[,.:!?-]*\s*',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (match == null) return null;
    return normalized.substring(match.end).trim();
  }

  /// Checks if the phrase is specifically the emergency wake command:
  /// "Hello Mac Emergency", "Mac Emergency", "Care Emergency", "ഹലോ മാക് എമർജൻസി", etc.
  static bool isCareEmergencyCommand(String rawText) {
    final lower = rawText.trim().toLowerCase();
    return RegExp(
          r'^(?:(?:hello\s+)?(?:mac|mack|mark|mike|care)|(?:ഹലോ\s+)?(?:മാക്|മാക്ക്|കെയർ|കേർ))\s*(?:emergency|എമർജൻസി|സഹായം|രക്ഷിക്കൂ)',
          caseSensitive: false,
        ).hasMatch(lower) ||
        RegExp(
          r'(?:hello\s+)?(?:mac|care)\s+emergency',
          caseSensitive: false,
        ).hasMatch(lower);
  }

  static const List<String> _emergencyKeywords = [
    // English
    'help',
    'emergency',
    'sos',
    'save me',
    'rescue me',
    'call my daughter',
    'call my son',
    'call family',
    'call emergency',
    'call doctor',
    'call ambulance',
    'i am hurt',
    'i fell',
    'i have fallen',
    "can't breathe",
    'cannot breathe',
    'chest pain',
    'heart attack',
    'feeling dizzy',
    'fainting',
    'care emergency',
    'hello mac emergency',
    'mac emergency',
    // Malayalam (formal, colloquial, slang)
    'സഹായം',
    'സഹായിക്കൂ',
    'സഹായിക്കണം',
    'സഹായിക്കണേ',
    'എന്നെ സഹായിക്കൂ',
    'എന്നെ സഹായിക്കണം',
    'രക്ഷിക്കൂ',
    'രക്ഷിക്കണം',
    'രക്ഷിക്കണേ',
    'എന്നെ രക്ഷിക്കൂ',
    'എന്നെ രക്ഷിക്കണം',
    'എമർജൻസി',
    'കെയർ എമർജൻസി',
    'ഹലോ മാക് എമർജൻസി',
    'മാക് എമർജൻസി',
    'അടിയന്തര സഹായം',
    'അപകടം',
    'ആപത്ത്',
    'വീണു',
    'വീണുപോയി',
    'താഴെ വീണു',
    'നെഞ്ചുവേദന',
    'നെഞ്ച് വേദന',
    'ശ്വാസം മുട്ടുന്നു',
    'ശ്വാസമില്ല',
    'തല കറങ്ങുന്നു',
    'തലകറക്കം',
    'ബോധം പോകുന്നു',
    'വയ്യ',
    'വയ്യാണ്ടായി',
    'സുഖമില്ല',
    'ആശുപത്രിയിൽ കൊണ്ടുപോകൂ',
    'ആംബുലൻസ് വിളിക്ക്',
    'വിളിക്കൂ',
    'മകളെ വിളിക്ക്',
    'മകനെ വിളിക്ക്',
    'വീട്ടുകാരെ വിളിക്ക്',
  ];

  static const List<String> _medicineKeywords = [
    // English / Manglish
    'medicine',
    'medicines',
    'medication',
    'medications',
    'pill',
    'pills',
    'tablet',
    'tablets',
    'capsule',
    'dose',
    'dosage',
    'syrup',
    'marunnu',
    'gulika',
    // Malayalam (formal, colloquial, slang)
    'മരുന്ന്',
    'മരുന്നുകൾ',
    'മരുന്നിന്റെ',
    'മരുന്നിന്',
    'മരുന്നിനെ',
    'മരുന്ന് എപ്പോഴാണ്',
    'മരുന്ന് കഴിച്ചോ',
    'മരുന്ന് എടുക്കണം',
    'മരുന്ന് കുടിക്കണം',
    'ഗുളിക',
    'ഗുളികകൾ',
    'ഗുളിക എപ്പോഴാ',
    'ടാബ്‌ലെറ്റ്',
    'ക്യാപ്സ്യൂൾ',
    'സിറപ്പ്',
    'മരുന്ന് സമയം',
  ];

  static const List<String> _appointmentKeywords = [
    // English / Manglish
    'appointment',
    'appointments',
    'appoinment',
    'appoinments',
    'appointement',
    'consultation',
    'consult',
    'checkup',
    'doctor appointment',
    'doctor appointments',
    "doctor's appointment",
    'doctor visit',
    'see a doctor',
    'see doctor',
    'dr appointment',
    'hospital appointment',
    'clinic appointment',
    'hospital visit',
    'doctore kaanan',
    'doctorine kaanan',
    'doctor kaanan',
    'doctor appointment undo',
    'doctor appointment unda',
    'doctor eppozha',
    // Malayalam (formal, colloquial)
    'അപ്പോയിന്റ്മെന്റ്',
    'അപ്പോയിന്റ്മെന്റുകൾ',
    'അപ്പോയിന്റ്മെന്റ് ഉണ്ടാ',
    'അപ്പോയിന്റ്മെന്റ് ഉണ്ടോ',
    'ഡോക്ടറുടെ',
    'ഡോക്ടറെ കാണാൻ',
    'ഡോക്ടറെ കാണണം',
    'ഡോക്ടറെ കാണിക്കണം',
    'ഡോക്ടറെ കാണേണ്ട',
    'ഡോക്ടറെ കാണാനുള്ള',
    'ഡോക്ടറെ കാണിക്കാനുണ്ടോ',
    'ഡോക്ടർ എപ്പോഴാ',
    'ആശുപത്രി',
    'ഹോസ്പിറ്റൽ',
    'ക്ലിനിക്ക്',
    'കൺസൾട്ടേഷൻ',
    'കൺസൾട്ടേഷന്',
    'ചെക്കപ്പ്',
    'പരിശോധന',
  ];

  static const List<String> _reminderKeywords = [
    // English / Manglish
    'reminder',
    'reminders',
    'remind me',
    'schedule',
    'food',
    'meal',
    'meals',
    'eat',
    'breakfast',
    'lunch',
    'dinner',
    'water',
    'drink',
    'hydrate',
    'bhakshanam',
    'vellam',
    'oonu',
    'chaaya',
    // Malayalam (formal, colloquial)
    'ഓർമ്മപ്പെടുത്തൽ',
    'ഓർമ്മിപ്പിക്കൂ',
    'ഓർമ്മിപ്പിക്കണം',
    'ഭക്ഷണം',
    'ഭക്ഷണ സമയം',
    'കഴിക്കാൻ',
    'കഴിക്കണം',
    'കഴിക്കേണ്ടത്',
    'ഊണ്',
    'പ്രാതൽ',
    'ഉച്ചഭക്ഷണം',
    'രാത്രി ഭക്ഷണം',
    'ബ്രേക്ക്ഫാസ്റ്റ്',
    'ലഞ്ച്',
    'ഡിന്നർ',
    'വിശക്കുന്നു',
    'വിശപ്പ്',
    'ചായ',
    'കഞ്ഞി',
    'വെള്ളം',
    'വെള്ളം കുടിക്കണം',
    'വെള്ളം കുടിക്കാൻ',
    'വെള്ളം കുടിക്കേണ്ട സമയം',
    'ദാഹിക്കുന്നു',
    'ദാഹം',
    'കുടിവെള്ളം',
  ];

  static VoiceIntentType detect(
    String rawText, {
    List<String> customEmergencyPhrases = const [],
  }) {
    final text = rawText.trim();
    if (text.isEmpty) return VoiceIntentType.chat;

    // Check specific "Care Emergency" pattern first
    if (isCareEmergencyCommand(text)) {
      return VoiceIntentType.emergency;
    }

    final lower = text.toLowerCase();

    // Emergency always wins. Custom phrase is checked first so the elder's
    // chosen rescue word is treated exactly like the built-in SOS words.
    if (_matchesAny(lower, text, customEmergencyPhrases) ||
        _matchesAny(lower, text, _emergencyKeywords)) {
      return VoiceIntentType.emergency;
    }

    // Medicine questions: read today's medicine schedule
    if (_matchesAny(lower, text, _medicineKeywords)) {
      return VoiceIntentType.medicineToday;
    }

    // Doctor/appointment/consultation questions: read appointment info
    if (_matchesAny(lower, text, _appointmentKeywords)) {
      return VoiceIntentType.appointmentToday;
    }

    // Food, water, and general care reminders
    if (_matchesAny(lower, text, _reminderKeywords)) {
      return VoiceIntentType.careReminders;
    }

    return VoiceIntentType.chat;
  }

  static bool _matchesAny(
    String lowerText,
    String originalText,
    List<String> keywords,
  ) {
    for (final keyword in keywords) {
      final k = keyword.trim();
      if (k.isEmpty) continue;
      if (lowerText.contains(k.toLowerCase()) || originalText.contains(k)) {
        return true;
      }
    }
    return false;
  }
}
