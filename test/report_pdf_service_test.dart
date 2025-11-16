import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:scanner_trabunda/data/app_database.dart';
import 'package:scanner_trabunda/services/report_pdf_service.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  FakePathProviderPlatform(this.tempDir);

  final Directory tempDir;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }
    return tempDir.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const service = ReportPdfService();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('report_pdf_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('generateAreaReport produces a PDF and persists the file', () async {
    final area = ReporteAreaDetalle(
      id: 10,
      nombre: 'Área de prueba',
      cantidad: 2,
      totalKilos: 5,
      cuadrillas: const [
        CuadrillaDetalle(
          id: 1,
          nombre: 'Lote 1',
          kilos: 5,
          integrantes: [IntegranteDetalle(id: 1, nombre: 'Tester')],
          desglose: [CategoriaDesglose(categoria: 'A', kilos: 5)],
          horaInicio: '08:00',
          horaFin: '10:00',
        ),
      ],
      desglose: const [
        CategoriaDesglose(categoria: 'TOTAL', personas: 2, kilos: 5),
      ],
      horaInicio: '08:00',
      horaFin: '10:00',
    );

    final reporte = ReporteDetalle(
      id: 1,
      fecha: DateTime(2024, 1, 1),
      turno: 'Mañana',
      planillero: 'Tester',
      areas: [area],
    );

    ReportPdfResult result;

    try {
      result = await service.generateAreaReport(
        reporte: reporte,
        area: area,
        elaboradoPor: 'QA Tester',
      );
    } on Exception catch (e) {
      fail('Error accediendo a documentos o escribiendo archivo: $e');
    }

    expect(result.bytes, isNotEmpty);
    expect(result.file.existsSync(), isTrue);
  });
}