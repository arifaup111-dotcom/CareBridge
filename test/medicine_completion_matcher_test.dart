import 'package:carebridge/services/medicine_completion_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicineCompletionMatcher', () {
    final medicines = [
      {'id': 'azithromycin', 'name': 'Azithromycin', 'time': '12:00 PM'},
      {'id': 'vitamin', 'name': 'Vitamin D', 'time': '8:00 AM'},
      {'id': 'second-noon', 'name': 'Other medicine', 'time': '12:00 PM'},
    ];

    test('matches a spoken scheduled time including noon', () {
      expect(
        MedicineCompletionMatcher.findBySpokenTime(
          medicines: medicines,
          spokenText: 'I had my 12 PM medicine',
        ).map((medicine) => medicine['id']),
        ['azithromycin', 'second-noon'],
      );
      expect(
        MedicineCompletionMatcher.findBySpokenTime(
          medicines: medicines,
          spokenText: 'I took my medicine at noon',
        ).map((medicine) => medicine['id']),
        ['azithromycin', 'second-noon'],
      );
    });

    test('matches a spoken medicine name', () {
      expect(
        MedicineCompletionMatcher.findBySpokenName(
          medicines: medicines,
          spokenText: 'I had Azithromycin',
        ).single['id'],
        'azithromycin',
      );
    });

    test('does not guess a medicine for an unmatched time', () {
      expect(
        MedicineCompletionMatcher.findBySpokenTime(
          medicines: medicines,
          spokenText: 'I had my 7 PM medicine',
        ),
        isEmpty,
      );
    });
  });
}
