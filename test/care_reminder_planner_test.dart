import 'package:carebridge/services/care_reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CareReminderPlanner.dailyReminders', () {
    test('schedules all daily care categories in device-local time', () {
      final now = DateTime(2026, 10, 21, 7, 30);
      final reminders = CareReminderPlanner.dailyReminders(
        mealTimes: ['8:00 AM'],
        waterTimes: ['9:00 AM'],
        wakeUpTime: '7:00 AM',
        exerciseTime: '10:00 AM',
        now: now,
      );

      expect(reminders.map((item) => item.type), [
        'meal',
        'water',
        'wake_up',
        'exercise',
      ]);
      expect(reminders[0].scheduledAt, DateTime(2026, 10, 21, 8));
      expect(reminders[2].scheduledAt, DateTime(2026, 10, 22, 7));
      expect(reminders[0].body, 'ഭക്ഷണം കഴിക്കാനുള്ള സമയമായി.');
      expect(reminders[1].body, 'വെള്ളം കുടിക്കാനുള്ള സമയമായി.');
      expect(reminders[2].body, 'എഴുന്നേൽക്കാനുള്ള സമയമായി.');
      expect(reminders[3].body, 'വ്യായാമം ചെയ്യാനുള്ള സമയമായി.');
      expect(reminders.every((item) => item.daily), isTrue);
      expect(reminders.every((item) => item.body.isNotEmpty), isTrue);
    });

    test('validates daily times and avoids duplicate times', () {
      expect(
        () => CareReminderPlanner.dailyReminders(
          mealTimes: ['25:61'],
          waterTimes: [],
          wakeUpTime: '7:00 AM',
          exerciseTime: '8:00 AM',
          now: DateTime(2026),
        ),
        throwsFormatException,
      );

      final reminders = CareReminderPlanner.dailyReminders(
        mealTimes: ['8:00 AM', '08:00'],
        waterTimes: [],
        wakeUpTime: '7:00 AM',
        exerciseTime: '8:00 AM',
        now: DateTime(2026),
      );
      expect(reminders.where((item) => item.type == 'meal'), hasLength(1));
    });

    test('does not schedule unset wake-up or exercise times', () {
      final reminders = CareReminderPlanner.dailyReminders(
        mealTimes: [],
        waterTimes: [],
        wakeUpTime: null,
        exerciseTime: null,
        now: DateTime(2026, 10, 21, 7),
      );

      expect(reminders, isEmpty);
    });
  });

  group('CareReminderPlanner.medicineReminders', () {
    test('schedules each medicine at its own time with a stable ID', () {
      final medicines = [
        {'id': 'medicine-a', 'name': 'A', 'time': '8:00 AM'},
        {'id': 'medicine-b', 'name': 'B', 'time': '8:30 PM'},
      ];
      final now = DateTime(2026, 10, 21, 7);
      final first = CareReminderPlanner.medicineReminders(
        medicines: medicines,
        now: now,
      );
      final reordered = CareReminderPlanner.medicineReminders(
        medicines: medicines.reversed.toList(),
        now: now,
      );

      expect(first.map((item) => item.scheduledAt), [
        DateTime(2026, 10, 21, 8),
        DateTime(2026, 10, 21, 20, 30),
      ]);
      expect(
        first.firstWhere((item) => item.key == 'medicine-a').id,
        reordered.firstWhere((item) => item.key == 'medicine-a').id,
      );
    });
  });

  group('CareReminderPlanner.appointmentReminders', () {
    test('schedules a one-time reminder exactly 24 hours before', () {
      final reminders = CareReminderPlanner.appointmentReminders(
        appointments: [
          {
            'id': 'appointment-1',
            'doctor': 'Dr. Kumar',
            'hospital': 'City Hospital',
            'date': '22/10/2026',
            'time': '10:30 AM',
          },
        ],
        now: DateTime(2026, 10, 21, 9),
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.scheduledAt, DateTime(2026, 10, 21, 10, 30));
      expect(reminders.single.daily, isFalse);
      expect(reminders.single.body, contains('സമയം 10:30 AM'));
    });

    test('keeps the same alarm ID when an appointment is edited', () {
      final beforeEdit = CareReminderPlanner.appointmentReminders(
        appointments: [
          {
            'id': 'appointment-1',
            'doctor': 'Dr. Kumar',
            'date': '22/10/2026',
            'time': '10:30 AM',
          },
        ],
        now: DateTime(2026, 10, 21, 9),
      ).single;
      final afterEdit = CareReminderPlanner.appointmentReminders(
        appointments: [
          {
            'id': 'appointment-1',
            'doctor': 'Dr. Kumar',
            'date': '23/10/2026',
            'time': '11:00 AM',
          },
        ],
        now: DateTime(2026, 10, 21, 9),
      ).single;

      expect(afterEdit.id, beforeEdit.id);
      expect(afterEdit.scheduledAt, DateTime(2026, 10, 22, 11));
    });

    test('skips past, cancelled, and invalid appointments', () {
      final reminders = CareReminderPlanner.appointmentReminders(
        appointments: [
          {'id': 'past', 'date': '20/10/2026', 'time': '10:30 AM'},
          {
            'id': 'cancelled',
            'date': '22/10/2026',
            'time': '10:30 AM',
            'status': 'cancelled',
          },
          {'id': 'invalid', 'date': '31/02/2026', 'time': '10:30 AM'},
        ],
        now: DateTime(2026, 10, 21),
      );
      expect(reminders, isEmpty);
    });
  });
}
