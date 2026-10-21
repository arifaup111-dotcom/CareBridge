import 'package:carebridge/services/appointment_schedule_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppointmentScheduleFormatter.formatTodaysAppointments', () {
    test('lists today appointments in time order with their details', () {
      final response = AppointmentScheduleFormatter.formatTodaysAppointments([
        {
          'doctor': 'Dr. Nair',
          'specialization': 'Cardiology',
          'hospital': 'City Hospital',
          'date': '21/10/2026',
          'time': '4:30 PM',
        },
        {
          'doctor': 'Dr. Kumar',
          'hospital': 'Care Clinic',
          'date': '2026-10-21',
          'time': '9:15 AM',
        },
        {'doctor': 'Dr. Future', 'date': '22/10/2026', 'time': '10:00 AM'},
      ], now: DateTime(2026, 10, 21, 8));

      expect(response, contains('At 9:15 AM, you have an appointment'));
      expect(response, contains('Dr. Kumar'));
      expect(response, contains('Care Clinic'));
      expect(response, contains('At 4:30 PM, you have an appointment'));
      expect(response, contains('Cardiology'));
      expect(response, contains('City Hospital'));
      expect(
        response.indexOf('Dr. Kumar'),
        lessThan(response.indexOf('Dr. Nair')),
      );
      expect(response, isNot(contains('Dr. Future')));
    });

    test('excludes cancelled appointments and handles an empty day', () {
      final response = AppointmentScheduleFormatter.formatTodaysAppointments([
        {
          'doctor': 'Cancelled',
          'date': '21/10/2026',
          'time': '9:15 AM',
          'status': 'cancelled',
        },
      ], now: DateTime(2026, 10, 21, 8));

      expect(response, "You don't have any appointments scheduled for today.");
    });
  });
}
