import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

abstract class PdfStorageService {
  Future<void> save(String filename, List<int> bytes);
}

class MockPdfStorageService extends Mock implements PdfStorageService {}

class ReportPdfService {
  ReportPdfService(this.storageService);

  final PdfStorageService storageService;

  Future<String> generateAreaReport(String area) async {
    final fileName = 'report-${area.toLowerCase()}.pdf';
    await storageService.save(fileName, <int>[]);
    return fileName;
  }
}

void main() {
  group('ReportPdfService', () {
    late MockPdfStorageService storageService;
    late ReportPdfService pdfService;

    setUp(() {
      storageService = MockPdfStorageService();
      pdfService = ReportPdfService(storageService);
    });

    test('creates filename based on area name', () async {
      when(() => storageService.save('report-zona norte.pdf', <int>[]))
          .thenAnswer((_) async {});

      final fileName = await pdfService.generateAreaReport('Zona Norte');

      expect(fileName, 'report-zona norte.pdf');
      verify(() => storageService.save('report-zona norte.pdf', <int>[])).called(1);
    });
  });
}
