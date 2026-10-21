import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'care_reminder_planner.dart';

class CareAlarmService {
  CareAlarmService._();

  static final CareAlarmService instance = CareAlarmService._();

  static const int _trialNotificationId = 4302;
  static const int _mealNotificationBaseId = 4100;
  static const int _waterNotificationBaseId = 4200;
  static const int _wakeUpNotificationId = 4300;
  static const int _exerciseNotificationId = 4301;
  static const int _medicineNotificationBaseId = 5000;
  static const int _appointmentNotificationBaseId = 6000;
  static const int _legacyAlarmsPerType = 50;

  static const MethodChannel _timezoneChannel = MethodChannel(
    'carebridge/system',
  );
  static const MethodChannel _announcementChannel = MethodChannel(
    'carebridge/reminder_announcements',
  );

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
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
    );
    if (initialized != true) {
      throw StateError('Care reminders could not initialize notifications.');
    }
  }

  Future<bool> requestExactAlarmPermission() async {
    await _initialize();
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    if (await android.canScheduleExactNotifications() ?? false) return true;
    await android.requestExactAlarmsPermission();
    return await android.canScheduleExactNotifications() ?? false;
  }

  Future<void> scheduleAllReminders({
    required List<String> mealTimes,
    required List<String> waterTimes,
    required String? wakeUpTime,
    required String? exerciseTime,
    required List<Map<String, dynamic>> medicines,
    required List<Map<String, dynamic>> appointments,
  }) async {
    await _initialize();
    final now = DateTime.now();
    final reminders = <PlannedCareReminder>[
      ...CareReminderPlanner.dailyReminders(
        mealTimes: mealTimes,
        waterTimes: waterTimes,
        wakeUpTime: wakeUpTime,
        exerciseTime: exerciseTime,
        now: now,
      ),
      ...CareReminderPlanner.medicineReminders(medicines: medicines, now: now),
      ...CareReminderPlanner.appointmentReminders(
        appointments: appointments,
        now: now,
      ),
    ];

    await _cancelPreviousReminders();
    final scheduleMode = await _androidScheduleMode();
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      await _announcementChannel.invokeMethod<void>('syncReminderAlarms', {
        'reminders': reminders
            .map((reminder) => reminder.toPlatformMap())
            .toList(),
      });
      return;
    }

    for (final reminder in reminders) {
      await _notifications.zonedSchedule(
        reminder.id,
        reminder.title,
        reminder.body,
        tz.TZDateTime.from(reminder.scheduledAt, tz.local),
        NotificationDetails(iOS: const DarwinNotificationDetails()),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: reminder.daily
            ? DateTimeComponents.time
            : null,
        payload: 'carebridge:${reminder.type}:${reminder.key}',
      );
    }
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exactAlarmAllowed =
        await android?.canScheduleExactNotifications() ?? false;
    return exactAlarmAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _cancelPreviousReminders() async {
    final pending = await _notifications.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload?.startsWith('carebridge:') == true) {
        await _notifications.cancel(request.id);
      }
    }
    for (final base in [
      _mealNotificationBaseId,
      _waterNotificationBaseId,
      _wakeUpNotificationId,
      _exerciseNotificationId,
      _medicineNotificationBaseId,
      _appointmentNotificationBaseId,
    ]) {
      final length =
          base == _wakeUpNotificationId || base == _exerciseNotificationId
          ? 1
          : _legacyAlarmsPerType;
      for (var index = 0; index < length; index++) {
        await _notifications.cancel(base + index);
      }
    }
  }

  Future<void> clearCareReminders() async {
    await _initialize();
    await _cancelPreviousReminders();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _announcementChannel.invokeMethod<void>('syncReminderAlarms', {
        'reminders': const <Map<String, Object>>[],
      });
    }
  }

  Future<void> scheduleTrialReminder() async {
    await _initialize();
    await _notifications.cancel(_trialNotificationId);
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
      androidScheduleMode: await _androidScheduleMode(),
    );
  }

  Future<void> clearAllReminders() async {
    await _initialize();
    await _notifications.cancelAll();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _announcementChannel.invokeMethod<void>('syncReminderAlarms', {
        'reminders': const <Map<String, Object>>[],
      });
    }
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
}
