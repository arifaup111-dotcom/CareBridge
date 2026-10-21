import 'package:carebridge/services/medicine_schedule_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicineScheduleFormatter.formatDailySchedule', () {
    test('speaks each medicine with its time and dosage in time order', () {
      final response = MedicineScheduleFormatter.formatDailySchedule([
        {'name': 'Vitamin D', 'dosage': 'one capsule', 'time': '8:30 PM'},
        {'name': 'Metformin', 'dosage': '500 mg', 'time': '08:00 AM'},
      ]);

      expect(response, contains('At 8:00 AM, take Metformin, 500 mg.'));
      expect(response, contains('At 8:30 PM, take Vitamin D, one capsule.'));
      expect(
        response.indexOf('Metformin'),
        lessThan(response.indexOf('Vitamin D')),
      );
    });

    test('handles missing fields and an empty schedule clearly', () {
      expect(
        MedicineScheduleFormatter.formatDailySchedule([
          {'time': '12:00 PM'},
        ]),
        contains('At 12:00 PM, take your medicine, dosage not recorded.'),
      );
      expect(
        MedicineScheduleFormatter.formatDailySchedule([]),
        contains("don't have any medicines listed"),
      );
    });
  });
}
