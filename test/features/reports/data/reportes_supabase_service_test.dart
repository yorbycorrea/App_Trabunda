import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

abstract class SupabaseClient {
  Future<void> post(String url, {Map<String, dynamic>? body});
}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class ReportesSupabaseService {
  ReportesSupabaseService(this._client, {required this.baseUrl});

  final SupabaseClient _client;
  final String baseUrl;

  Future<void> fetchReports() async {
    await _client.post('$baseUrl/reports');
  }
}

void main() {
  group('ReportesSupabaseService', () {
    late MockSupabaseClient client;
    late ReportesSupabaseService service;

    setUp(() {
      client = MockSupabaseClient();
      service = ReportesSupabaseService(client, baseUrl: 'https://example.supabase.co');
    });

    test('sends request to reports endpoint', () async {
      when(() => client.post('https://example.supabase.co/reports', body: null))
          .thenAnswer((_) async {});

      await service.fetchReports();

      verify(() => client.post('https://example.supabase.co/reports', body: null)).called(1);
    });
  });
}
