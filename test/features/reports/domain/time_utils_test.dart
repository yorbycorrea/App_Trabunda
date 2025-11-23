import 'package:flutter_test/flutter_test.dart';

int calculateWorkedHours(DateTime start, DateTime end) {
  final normalizedEnd = end.isBefore(start) ? end.add(const Duration(days: 1)) : end;
  return normalizedEnd.difference(start).inHours;
}

void main() {
  group('calculateWorkedHours', () {
    test('handles same day ranges', () {
      final start = DateTime(2024, 1, 1, 8);
      final end = DateTime(2024, 1, 1, 17);

      expect(calculateWorkedHours(start, end), 9);
    });

    test('handles overnight ranges crossing midnight', () {
      final start = DateTime(2024, 1, 1, 22);
      final end = DateTime(2024, 1, 1, 6);

      expect(calculateWorkedHours(start, end), 8);
    });
  });
}
