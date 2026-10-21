import 'care_reminder_planner.dart';

class MedicineScheduleFormatter {
  MedicineScheduleFormatter._();

  static String formatDailySchedule(List<Map<String, dynamic>> medicines) {
    if (medicines.isEmpty) {
      return "You don't have any medicines listed in today's care plan. "
          'Please ask your family to add them if needed.';
    }

    final sorted = [...medicines]
      ..sort((a, b) {
        final first = CareReminderPlanner.parseTime(
          (a['time'] ?? '').toString(),
        );
        final second = CareReminderPlanner.parseTime(
          (b['time'] ?? '').toString(),
        );
        if (first == null) return second == null ? 0 : 1;
        if (second == null) return -1;
        final timeOrder = (first.$1 * 60 + first.$2).compareTo(
          second.$1 * 60 + second.$2,
        );
        if (timeOrder != 0) return timeOrder;
        return (a['name'] ?? '').toString().compareTo(
          (b['name'] ?? '').toString(),
        );
      });

    final details = sorted
        .map((medicine) {
          final rawTime = (medicine['time'] ?? '').toString().trim();
          final time = _formatTime(rawTime);
          final name = (medicine['name'] ?? '').toString().trim();
          final dosage = (medicine['dosage'] ?? '').toString().trim();
          final description = name.isEmpty ? 'your medicine' : name;
          final dosageText = dosage.isEmpty ? 'dosage not recorded' : dosage;
          return 'At $time, take $description, $dosageText.';
        })
        .join(' ');

    return "Here are your medicines scheduled for today. $details";
  }

  static String _formatTime(String rawTime) {
    final parsed = CareReminderPlanner.parseTime(rawTime);
    if (parsed == null) {
      return rawTime.isEmpty ? 'a time not recorded' : rawTime;
    }
    final hour = parsed.$1 % 12 == 0 ? 12 : parsed.$1 % 12;
    final minute = parsed.$2.toString().padLeft(2, '0');
    final period = parsed.$1 < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
