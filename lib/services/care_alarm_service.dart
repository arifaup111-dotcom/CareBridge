import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'speech_output_service.dart';

class CareAlarmService {
  CareAlarmService._();

  static final CareAlarmService instance = CareAlarmService._();

  static const int _mealNotificationBaseId = 4100;
  static const int _waterNotificationBaseId = 4200;
  static const int _wakeUpNotificationId = 4300;
  static const int _exerciseNotificationId = 4301;
  static const int _trialNotificationId = 4302;
  static const int _medicineNotificationBaseId = 5000;
  static const int _appointmentNotificationBaseId = 6000;
  static const int _maxAlarmsPerType = 50;

  static const MethodChannel _timezoneChannel = MethodChannel(
    'carebridge/system',
  );

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final SpeechOutputService _speechOutput = SpeechOutputService();
  Future<void>? _initialization;

  Future<void> _initialize() {
    final pending = _initialization ??= _initializeOnce();
    return pending.catchError((Object error, StackTrace stackTrace) {
      if (identical(_initialization, pending)) _initialization = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<void> _initializeOnce() async {
    tz_data.initializeTimeZones();
    String? timeZoneId;
    try {
      timeZoneId = await _timezoneChannel.invokeMethod<String>('localTimeZone');
    } on MissingPluginException {
      final now = DateTime.now();
      final offset = now.timeZoneOffset.inMilliseconds;
      for (final location in tz.timeZoneDatabase.locations.values) {
        if (location.timeZone(now.millisecondsSinceEpoch).offset == offset) {
          timeZoneId = location.name;
          break;
        }
      }
    }
    if (timeZoneId == null || timeZoneId.isEmpty) {
      throw StateError('The device time zone could not be determined.');
    }
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneId));
    } on tz.LocationNotFoundException {
      _setLocationFromCurrentOffset();
    }

    final initialized = await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.startsWith('speech:')) {
          final text = payload.substring(7).trim();
          if (text.isNotEmpty) {
            _speechOutput.speak(text).catchError((_) {});
          }
        }
      },
    );
    if (initialized != true) {
      throw StateError('Care reminders could not initialize notifications.');
    }
  }

  /// Announces a reminder aloud using Malayalam text-to-speech.
  Future<void> speakAnnouncement(String text) async {
    try {
      await _speechOutput.speak(text);
    } catch (_) {}
  }

  // ================================================================
  // MEDICINE REMINDERS
  // ================================================================

  Future<void> scheduleMedicineReminders({
    required List<Map<String, dynamic>> medicines,
  }) async {
    await _initialize();

    // Clear previously scheduled medicine alarms
    for (var i = 0; i < _maxAlarmsPerType; i++) {
      await _notifications.cancel(_medicineNotificationBaseId + i);
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exactAlarmAllowed =
        await android?.canScheduleExactNotifications() ?? false;
    final scheduleMode = exactAlarmAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final count = medicines.length > _maxAlarmsPerType
        ? _maxAlarmsPerType
        : medicines.length;

    final now = tz.TZDateTime.now(tz.local);

    for (var index = 0; index < count; index++) {
      final med = medicines[index];
      final timeStr = (med['time'] ?? '').toString();
      final parsed = _parseTime(timeStr);
      if (parsed == null) continue;

      final name = (med['name'] ?? 'മരുന്ന്').toString();
      final dosage = (med['dosage'] ?? '').toString();
      final instruction = (med['instruction'] ?? '').toString();

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        parsed.$1,
        parsed.$2,
      );
      if (!scheduledDate.isAfter(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final body = [
        if (dosage.isNotEmpty) 'അളവ്: $dosage',
        if (instruction.isNotEmpty) instruction,
      ].join(' · ');

      await _notifications.zonedSchedule(
        _medicineNotificationBaseId + index,
        'മരുന്ന് ഓർമ്മപ്പെടുത്തൽ: $name',
        body.isEmpty ? 'മരുന്ന് കഴിക്കാനുള്ള സമയമായി.' : body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'care_medicines',
            'Medicine Reminders',
            channelDescription: 'Daily scheduled alarms for medications',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('notification'),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'speech:മരുന്ന് കഴിക്കാനുള്ള സമയമായി. $name. $dosage.',
      );
    }
  }

  // ================================================================
  // APPOINTMENT REMINDERS
  // ================================================================

  Future<void> scheduleAppointmentReminders({
    required List<Map<String, dynamic>> appointments,
  }) async {
    await _initialize();

    for (var i = 0; i < _maxAlarmsPerType; i++) {
      await _notifications.cancel(_appointmentNotificationBaseId + i);
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exactAlarmAllowed =
        await android?.canScheduleExactNotifications() ?? false;
    final scheduleMode = exactAlarmAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final count = appointments.length > _maxAlarmsPerType
        ? _maxAlarmsPerType
        : appointments.length;

    final now = tz.TZDateTime.now(tz.local);

    for (var index = 0; index < count; index++) {
      final appt = appointments[index];
      final dateStr = (appt['date'] ?? '').toString().trim();
      final timeStr = (appt['time'] ?? '').toString().trim();
      final scheduledDate = _parseDateTime(dateStr, timeStr);
      if (scheduledDate == null || !scheduledDate.isAfter(now)) continue;

      final doctor = (appt['doctor'] ?? 'ഡോക്ടർ').toString();
      final specialization = (appt['specialization'] ?? '').toString();
      final hospital = (appt['hospital'] ?? '').toString();

      final subtitle = [
        if (specialization.isNotEmpty) specialization,
        if (hospital.isNotEmpty) hospital,
      ].join(', ');

      await _notifications.zonedSchedule(
        _appointmentNotificationBaseId + index,
        'ഡോക്ടർ അപ്പോയിന്റ്മെന്റ്: $doctor',
        subtitle.isEmpty ? 'അപ്പോയിന്റ്മെന്റ് സമയമായി.' : subtitle,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'care_appointments',
            'Appointment Reminders',
            channelDescription: 'Scheduled doctor and hospital appointments',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('notification'),
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
        payload: 'speech:ഡോക്ടറെ കാണാനുള്ള അപ്പോയിന്റ്മെന്റ് സമയമായി. $doctor.',
      );
    }
  }

  // ================================================================
  // FOOD AND WATER REMINDERS
  // ================================================================

  Future<void> scheduleDailyReminders({
    required List<String> mealTimes,
    required List<String> waterTimes,
    String wakeUpTime = '7:00 AM',
    String exerciseTime = '8:00 AM',
  }) async {
    await _initialize();

    for (var index = 0; index < _maxAlarmsPerType; index++) {
      await _notifications.cancel(_mealNotificationBaseId + index);
      await _notifications.cancel(_waterNotificationBaseId + index);
    }
    await _notifications.cancel(_wakeUpNotificationId);
    await _notifications.cancel(_exerciseNotificationId);

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exactAlarmAllowed =
        await android?.canScheduleExactNotifications() ?? false;
    final scheduleMode = exactAlarmAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _scheduleGroup(
      mealTimes,
      baseId: _mealNotificationBaseId,
      title: 'ഭക്ഷണ സമയം (Meal Reminder)',
      body: 'ഭക്ഷണം കഴിക്കാനുള്ള സമയമായി.',
      speechAnnouncement: 'ഭക്ഷണം കഴിക്കാനുള്ള സമയമായി.',
      channelId: 'care_meals',
      channelName: 'Meal Reminders',
      scheduleMode: scheduleMode,
    );
    await _scheduleGroup(
      waterTimes,
      baseId: _waterNotificationBaseId,
      title: 'കുടിവെള്ള സമയം (Water Reminder)',
      body: 'വെള്ളം കുടിക്കാനുള്ള സമയമായി. ദാഹം മാറ്റൂ.',
      speechAnnouncement:
          'വെള്ളം കുടിക്കാനുള്ള സമയമായി. ദയവായി വെള്ളം കുടിക്കൂ.',
      channelId: 'care_water',
      channelName: 'Water Reminders',
      scheduleMode: scheduleMode,
    );
    await _scheduleGroup(
      [wakeUpTime],
      baseId: _wakeUpNotificationId,
      title: 'എഴുന്നേൽക്കാനുള്ള സമയമായി',
      body: 'സുപ്രഭാതം. പുതിയ ദിവസം സന്തോഷത്തോടെ ആരംഭിക്കാം.',
      speechAnnouncement:
          'സുപ്രഭാതം. എഴുന്നേൽക്കാനുള്ള സമയമായി. പുതിയ ദിവസം സന്തോഷത്തോടെ ആരംഭിക്കാം.',
      channelId: 'care_wake_up',
      channelName: 'Morning Wake-up',
      scheduleMode: scheduleMode,
    );
    await _scheduleGroup(
      [exerciseTime],
      baseId: _exerciseNotificationId,
      title: 'വ്യായാമ സമയം',
      body: 'ആരോഗ്യത്തിന് അനുയോജ്യമായ ലഘുവ്യായാമം ചെയ്യാനുള്ള സമയമായി.',
      speechAnnouncement:
          'വ്യായാമം ചെയ്യാനുള്ള സമയമായി. ആരോഗ്യത്തിന് അനുയോജ്യമായ ലഘുവ്യായാമം ചെയ്യൂ.',
      channelId: 'care_exercise',
      channelName: 'Exercise Reminders',
      scheduleMode: scheduleMode,
    );
  }

  Future<void> scheduleTrialReminder() async {
    await _initialize();
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exactAlarmAllowed =
        await android?.canScheduleExactNotifications() ?? false;
    await _notifications.zonedSchedule(
      _trialNotificationId,
      'CareBridge പരീക്ഷണ ഓർമ്മപ്പെടുത്തൽ',
      'പത്ത് മിനിറ്റ് പരീക്ഷണ ഓർമ്മപ്പെടുത്തൽ ലഭിച്ചു.',
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'care_trial',
          'Trial Reminder',
          channelDescription: 'One-time CareBridge reminder test',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: exactAlarmAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'speech:പത്ത് മിനിറ്റ് പരീക്ഷണ ഓർമ്മപ്പെടുത്തൽ ലഭിച്ചു.',
    );
  }

  Future<void> clearDailyReminders() async {
    await _initialize();
    for (var index = 0; index < _maxAlarmsPerType; index++) {
      await _notifications.cancel(_mealNotificationBaseId + index);
      await _notifications.cancel(_waterNotificationBaseId + index);
    }
    await _notifications.cancel(_wakeUpNotificationId);
    await _notifications.cancel(_exerciseNotificationId);
  }

  Future<void> clearAllReminders() async {
    await _initialize();
    await _notifications.cancelAll();
  }

  void _setLocationFromCurrentOffset() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset.inMilliseconds;
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (location.timeZone(now.millisecondsSinceEpoch).offset == offset) {
        tz.setLocalLocation(location);
        return;
      }
    }
    throw StateError('No time zone matches the device time zone offset.');
  }

  Future<void> _scheduleGroup(
    List<String> times, {
    required int baseId,
    required String title,
    required String body,
    required String speechAnnouncement,
    required String channelId,
    required String channelName,
    required AndroidScheduleMode scheduleMode,
  }) async {
    if (times.length > _maxAlarmsPerType) {
      throw ArgumentError(
        'No more than $_maxAlarmsPerType daily reminders of each type are supported.',
      );
    }

    final now = tz.TZDateTime.now(tz.local);
    for (var index = 0; index < times.length; index++) {
      final time = _parseTime(times[index]);
      if (time == null) {
        continue;
      }

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.$1,
        time.$2,
      );
      if (!scheduledDate.isAfter(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        baseId + index,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'Scheduled reminders for elderly care',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'speech:$speechAnnouncement',
      );
    }
  }

  (int, int)? _parseTime(String raw) {
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

  tz.TZDateTime? _parseDateTime(String dateStr, String timeStr) {
    final parsedTime = _parseTime(timeStr);
    if (parsedTime == null) return null;

    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {
      final parts = dateStr.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        final p1 = int.tryParse(parts[0]);
        final p2 = int.tryParse(parts[1]);
        final p3 = int.tryParse(parts[2]);
        if (p1 != null && p2 != null && p3 != null) {
          if (p1 > 1000) {
            date = DateTime(p1, p2, p3);
          } else {
            date = DateTime(p3, p2, p1);
          }
        }
      }
    }
    if (date == null) return null;

    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      parsedTime.$1,
      parsedTime.$2,
    );
  }
}
