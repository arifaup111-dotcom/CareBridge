enum VoiceIntent {
  emergency,
  medicineScheduleRequested,
  appointmentScheduleRequested,
  breakfastCompleted,
  lunchCompleted,
  dinnerCompleted,
  medicineTaken,
  mealCompleted,
  waterCompleted,
  exerciseCompleted,
  reminderCompleted,
  stop,
  unknown,
}

class VoiceIntentRouter {
  VoiceIntentRouter._();

  static const String defaultWakePhrase = 'Sara';
  static const String defaultEmergencyPhrase = 'emergency help';

  static const List<String> builtInEmergencyPhrases = [
    'emergency help',
    'emergency sos',
    'call for help',
    'please call my emergency contact',
  ];

  static String? commandAfterWakePhrase(
    String text, {
    String wakePhrase = defaultWakePhrase,
  }) {
    final normalizedText = normalize(text);
    final normalizedWakePhrase = normalize(wakePhrase);
    if (normalizedText.isEmpty || normalizedWakePhrase.isEmpty) return null;

    final wakePhrases = normalizedWakePhrase == 'sara'
        ? const ['sara', 'sarah']
        : [normalizedWakePhrase];
    for (final phrase in wakePhrases) {
      final wakePattern = RegExp('^${RegExp.escape(phrase)}(?:\\s+|\$)');
      if (wakePattern.hasMatch(normalizedText)) {
        return normalizedText.replaceFirst(wakePattern, '').trim();
      }
    }
    return null;
  }

  static String? commandForConversation(
    String text, {
    required bool conversationActive,
    String wakePhrase = defaultWakePhrase,
  }) {
    if (conversationActive) {
      final normalizedText = normalize(text);
      return normalizedText.isEmpty ? null : normalizedText;
    }
    return commandAfterWakePhrase(text, wakePhrase: wakePhrase);
  }

  static bool isEmergencyPhrase(String text, {String? customPhrase}) {
    final normalizedText = normalize(text);
    if (normalizedText.isEmpty) return false;

    final phrases = <String>[
      ...builtInEmergencyPhrases,
      if (customPhrase != null && customPhrase.trim().isNotEmpty) customPhrase,
    ];
    return phrases.any((phrase) => containsPhrase(normalizedText, phrase));
  }

  static VoiceIntent classify(String text) {
    final normalized = normalize(text);
    if (normalized.isEmpty) return VoiceIntent.unknown;

    if (RegExp(
      r'\b(?:stop|stop listening|cancel|goodbye|that is all)\b',
    ).hasMatch(normalized)) {
      return VoiceIntent.stop;
    }

    final medicineMentioned = RegExp(
      r'\b(?:medicines?|medications?|pills?|tablets?)\b',
    ).hasMatch(normalized);
    final medicineCompleted = RegExp(
      r'\b(?:had|have had|took|have taken|taken|finished|done|completed|complete)\b',
    ).hasMatch(normalized);
    if (medicineMentioned && medicineCompleted) {
      return VoiceIntent.medicineTaken;
    }

    final medicineScheduleRequested =
        medicineMentioned &&
        RegExp(
          r'\b(?:what|which|list|show|tell me|today|schedule|time|dosage|dose)\b',
        ).hasMatch(normalized);
    if (medicineScheduleRequested) {
      return VoiceIntent.medicineScheduleRequested;
    }

    final appointmentMentioned = RegExp(
      r'\b(?:appointments?|doctor|hospital|clinic)\b',
    ).hasMatch(normalized);
    final appointmentScheduleRequested =
        appointmentMentioned &&
        RegExp(
          r'\b(?:what|which|list|show|tell me|when|today|tomorrow|next|schedule|time)\b',
        ).hasMatch(normalized);
    if (appointmentScheduleRequested) {
      return VoiceIntent.appointmentScheduleRequested;
    }

    final exerciseMentioned = RegExp(
      r'\b(?:exercise|exercised|workout|worked out|walk|walked)\b',
    ).hasMatch(normalized);
    final completionMentioned = RegExp(
      r'\b(?:done|completed|complete|finished|did|had|exercised)\b',
    ).hasMatch(normalized);
    if (exerciseMentioned && completionMentioned) {
      return VoiceIntent.exerciseCompleted;
    }

    final mealCompletion = RegExp(
      r'\b(?:had|have had|ate|have eaten|eaten|finished|done|completed|complete)\b',
    ).hasMatch(normalized);
    if (mealCompletion) {
      if (RegExp(r'\b(?:breakfast|morning meal)\b').hasMatch(normalized)) {
        return VoiceIntent.breakfastCompleted;
      }
      if (RegExp(r'\b(?:lunch|midday meal)\b').hasMatch(normalized)) {
        return VoiceIntent.lunchCompleted;
      }
      if (RegExp(r'\b(?:dinner|supper|evening meal)\b').hasMatch(normalized)) {
        return VoiceIntent.dinnerCompleted;
      }
    }

    if (RegExp(r'\b(?:water|drink|drank|drunk)\b').hasMatch(normalized) &&
        RegExp(
          r'\b(?:had|have had|drank|have drunk|drunk|finished|done|completed|complete)\b',
        ).hasMatch(normalized)) {
      return VoiceIntent.waterCompleted;
    }

    final mealMentioned = RegExp(
      r'\b(?:food|meal|breakfast|lunch|dinner|ate|eaten)\b',
    ).hasMatch(normalized);
    final mealCompleted = RegExp(
      r'\b(?:had|have had|ate|have eaten|eaten|finished|done|completed|complete)\b',
    ).hasMatch(normalized);
    if (mealMentioned && mealCompleted) return VoiceIntent.mealCompleted;

    if (RegExp(
      r'\b(?:done|completed|complete|finished|i did it|i had it|i have had it|i took it|i finished it)\b',
    ).hasMatch(normalized)) {
      return VoiceIntent.reminderCompleted;
    }

    return VoiceIntent.unknown;
  }

  static String normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool containsPhrase(String normalizedText, String phrase) {
    final normalizedPhrase = normalize(phrase);
    if (normalizedPhrase.isEmpty) return false;
    return RegExp(
      '(^|\\s)${RegExp.escape(normalizedPhrase)}(\\s|\$)',
    ).hasMatch(normalizedText);
  }
}
