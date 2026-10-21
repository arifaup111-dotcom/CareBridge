import 'package:flutter/foundation.dart';

class PlannedCareReminder {
  const PlannedCareReminder({
    required this.id,
    required this.type,
    required this.key,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.daily,
  });

  final int id;
  final String type;
  final String key;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final bool daily;

  Map<String, Object> toPlatformMap() => {
    'id': id,
    'type': type,
    'key': key,
    'title': title,
    'body': body,
    'year': scheduledAt.year,
    'month': scheduledAt.month,
    'day': scheduledAt.day,
    'hour': scheduledAt.hour,
    'minute': scheduledAt.minute,
    'daily': daily,
  };
}

class CareReminderPlanner {
  CareReminderPlanner._();

  static const Map<String, int> _idRanges = {
    'meal': 10000000,
    'water': 20000000,
    'wake_up': 30000000,
    'exercise': 40000000,
    'medicine': 50000000,
    'appointment': 60000000,
  };
  static const int _idRangeSize = 10000000;

  static List<PlannedCareReminder> dailyReminders({
    required List<String> mealTimes,
    required List<String> waterTimes,
    required String? wakeUpTime,
    required String? exerciseTime,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    return [
      ..._dailyGroup(
        'meal',
        mealTimes,
        title: 'ഭക്ഷണ സമയം',
        body: 'ഭക്ഷണം കഴിക്കാനുള്ള സമയമായി.',
        now: current,
      ),
      ..._dailyGroup(
        'water',
        waterTimes,
        title: 'കുടിവെള്ള സമയം',
        body: 'വെള്ളം കുടിക്കാനുള്ള സമയമായി.',
        now: current,
      ),
      if (wakeUpTime != null && wakeUpTime.trim().isNotEmpty)
        ..._dailyGroup(
          'wake_up',
          [wakeUpTime],
          title: 'എഴുന്നേൽക്കാനുള്ള സമയം',
          body: 'എഴുന്നേൽക്കാനുള്ള സമയമായി.',
          now: current,
        ),
      if (exerciseTime != null && exerciseTime.trim().isNotEmpty)
        ..._dailyGroup(
          'exercise',
          [exerciseTime],
          title: 'വ്യായാമ സമയം',
          body: 'വ്യായാമം ചെയ്യാനുള്ള സമയമായി.',
          now: current,
        ),
    ];
  }

  static List<PlannedCareReminder> medicineReminders({
    required List<Map<String, dynamic>> medicines,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final reminders = <PlannedCareReminder>[];
    for (var index = 0; index < medicines.length; index++) {
      final medicine = medicines[index];
      final name = (medicine['name'] ?? '').toString().trim();
      final timeText = (medicine['time'] ?? '').toString();
      final time = parseTime(timeText);
      if (name.isEmpty || time == null) {
        debugPrint(
          'Skipping a medicine reminder with missing or invalid data.',
        );
        continue;
      }
      final stableKey = (medicine['id'] ?? '').toString().trim();
      final key = stableKey.isEmpty ? '$name|$timeText|$index' : stableKey;
      final scheduledAt = _nextDailyTime(time, current);
      final dosage = (medicine['dosage'] ?? '').toString().trim();
      final instruction = (medicine['instruction'] ?? '').toString().trim();
      reminders.add(
        _create(
          'medicine',
          key,
          'മരുന്ന് ഓർമ്മപ്പെടുത്തൽ: $name',
          'മരുന്ന് കഴിക്കാനുള്ള സമയമായി. $name'
              '${dosage.isNotEmpty ? ', $dosage' : ''}'
              '${instruction.isNotEmpty ? '. $instruction' : ''}',
          scheduledAt,
          daily: true,
        ),
      );
    }
    return reminders;
  }

  static List<PlannedCareReminder> appointmentReminders({
    required List<Map<String, dynamic>> appointments,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final reminders = <PlannedCareReminder>[];
    for (final appointment in appointments) {
      final status = (appointment['status'] ?? '').toString().toLowerCase();
      if (appointment['cancelled'] == true ||
          appointment['canceled'] == true ||
          appointment['isCancelled'] == true ||
          appointment['deleted'] == true ||
          status == 'cancelled' ||
          status == 'canceled' ||
          status == 'deleted') {
        continue;
      }
      final appointmentAt = parseAppointmentDateTime(
        (appointment['date'] ?? '').toString(),
        (appointment['time'] ?? '').toString(),
      );
      if (appointmentAt == null) {
        debugPrint(
          'Skipping an appointment reminder with an invalid date or time.',
        );
        continue;
      }
      final reminderAt = appointmentAt.subtract(const Duration(hours: 24));
      if (!reminderAt.isAfter(current)) continue;

      final doctorText = (appointment['doctor'] ?? '').toString().trim();
      final doctor = doctorText.isEmpty ? 'ഡോക്ടർ' : doctorText;
      final place = (appointment['hospital'] ?? '').toString().trim();
      final specialization = (appointment['specialization'] ?? '')
          .toString()
          .trim();
      final time = (appointment['time'] ?? '').toString().trim();
      final details = [
        if (specialization.isNotEmpty) specialization,
        if (place.isNotEmpty) place,
        if (time.isNotEmpty) 'സമയം $time',
      ].join(', ');
      final stableKey = (appointment['id'] ?? '').toString().trim();
      if (stableKey.isEmpty) continue;
      reminders.add(
        _create(
          'appointment',
          stableKey,
          'അപ്പോയിന്റ്മെന്റ് നാളെ: $doctor',
          'നാളെ നിങ്ങൾക്ക് $doctor അപ്പോയിന്റ്മെന്റ് ഉണ്ട്.'
              '${details.isNotEmpty ? ' $details.' : ''}',
          reminderAt,
          daily: false,
        ),
      );
    }
    return reminders;
  }

  static (int, int)? parseTime(String raw) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || minute > 59) return null;

    final meridiem = (match.group(3) ?? '').toUpperCase();
    if (meridiem.isNotEmpty && (hour < 1 || hour > 12)) return null;
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    if (hour > 23) return null;
    return (hour, minute);
  }

  static DateTime? parseAppointmentDateTime(String dateText, String timeText) {
    final time = parseTime(timeText);
    if (time == null) return null;
    final date = _parseDate(dateText);
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day, time.$1, time.$2);
  }

  static DateTime? _parseDate(String raw) {
    final value = raw.trim();
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(value);
    final local = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
    final match = iso ?? local;
    if (match == null) return null;
    final year = int.tryParse(match.group(iso == null ? 3 : 1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(iso == null ? 1 : 3)!);
    if (year == null || month == null || day == null) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static List<PlannedCareReminder> _dailyGroup(
    String type,
    List<String> times, {
    required String title,
    required String body,
    required DateTime now,
  }) {
    final reminders = <PlannedCareReminder>[];
    final uniqueTimes = <String>{};
    for (final rawTime in times) {
      final parsed = parseTime(rawTime);
      if (parsed == null) {
        throw FormatException('Invalid $type reminder time: $rawTime');
      }
      final key =
          '${parsed.$1.toString().padLeft(2, '0')}:'
          '${parsed.$2.toString().padLeft(2, '0')}';
      if (!uniqueTimes.add(key)) continue;
      reminders.add(
        _create(
          type,
          key,
          title,
          body,
          _nextDailyTime(parsed, now),
          daily: true,
        ),
      );
    }
    return reminders;
  }

  static DateTime _nextDailyTime((int, int) time, DateTime now) {
    var next = DateTime(now.year, now.month, now.day, time.$1, time.$2);
    if (!next.isAfter(now)) {
      next = DateTime(now.year, now.month, now.day + 1, time.$1, time.$2);
    }
    return next;
  }

  static PlannedCareReminder _create(
    String type,
    String key,
    String title,
    String body,
    DateTime scheduledAt, {
    required bool daily,
  }) {
    final base = _idRanges[type];
    if (base == null) throw ArgumentError.value(type, 'type');
    var hash = 0x811c9dc5;
    for (final unit in '$type|$key'.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return PlannedCareReminder(
      id: base + (hash % _idRangeSize),
      type: type,
      key: key,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      daily: daily,
    );
  }
}
