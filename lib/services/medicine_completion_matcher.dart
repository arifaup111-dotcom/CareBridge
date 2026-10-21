import 'care_reminder_planner.dart';
import 'voice_intent_router.dart';

class MedicineCompletionMatcher {
  MedicineCompletionMatcher._();

  static List<Map<String, dynamic>> findBySpokenName({
    required List<Map<String, dynamic>> medicines,
    required String spokenText,
  }) {
    final normalizedSpeech = VoiceIntentRouter.normalize(spokenText);
    return medicines.where((medicine) {
      final name = VoiceIntentRouter.normalize(
        (medicine['name'] ?? '').toString(),
      );
      return name.isNotEmpty && normalizedSpeech.contains(name);
    }).toList();
  }

  static List<Map<String, dynamic>> findBySpokenTime({
    required List<Map<String, dynamic>> medicines,
    required String spokenText,
  }) {
    final time = _spokenTime(spokenText);
    if (time == null) return const [];

    return medicines.where((medicine) {
      final scheduled = CareReminderPlanner.parseTime(
        (medicine['time'] ?? '').toString(),
      );
      return scheduled != null &&
          scheduled.$1 == time.$1 &&
          scheduled.$2 == time.$2;
    }).toList();
  }

  static (int, int)? _spokenTime(String text) {
    final normalized = VoiceIntentRouter.normalize(text);
    if (RegExp(r'\bnoon\b').hasMatch(normalized)) return (12, 0);
    if (RegExp(r'\bmidnight\b').hasMatch(normalized)) return (0, 0);

    final match = RegExp(
      r'\b(\d{1,2})(?::(\d{2}))?\s*(a\s*m|p\s*m)\b',
    ).firstMatch(normalized);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '00');
    if (hour == null ||
        minute == null ||
        hour < 1 ||
        hour > 12 ||
        minute > 59) {
      return null;
    }
    final isPm = match.group(3)!.startsWith('p');
    return (hour == 12 ? (isPm ? 12 : 0) : hour + (isPm ? 12 : 0), minute);
  }
}
