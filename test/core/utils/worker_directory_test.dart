import 'package:flutter_test/flutter_test.dart';

/// Simple helper to find a worker by name inside a directory map.
String? findWorker(Map<String, String> directory, String query) {
  return directory[query];
}

void main() {
  group('findWorker', () {
    test('returns the worker id when present', () {
      final workers = <String, String>{
        'alice': 'worker-001',
        'bob': 'worker-002',
        'charlie': 'worker-003',
      };

      final result = findWorker(workers, 'bob');

      expect(result, equals('worker-002'));
    });

    test('returns null when worker is missing', () {
      final workers = <String, String>{'alice': 'worker-001'};

      final result = findWorker(workers, 'david');

      expect(result, isNull);
    });
  });
}
