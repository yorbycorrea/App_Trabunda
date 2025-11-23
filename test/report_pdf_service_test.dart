import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:scanner_trabunda/data/drift/app_database.dart';
import 'package:scanner_trabunda/features/pdf/data/report_pdf_service.dart';
import 'package:scanner_trabunda/features/pdf/generators/area_pdf_generator.dart';

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

class FakeGenerator implements AreaPdfGenerator {
  FakeGenerator(this.bytes);

  bool called = false;
  final Uint8List bytes;

  @override
  Future<Uint8List> build() async {
    called = true;
    return bytes;
  }
}

class FakeGeneratorFactory extends ReportPdfGeneratorFactory {
  FakeGeneratorFactory({
    required this.fileterosGenerator,
    required this.saneamientoGenerator,
  });

  final FakeGenerator fileterosGenerator;
  final FakeGenerator saneamientoGenerator;

  @override
  AreaPdfGenerator createFileteros(
    ReporteDetalle reporte,
    ReporteAreaDetalle area,
  ) {
    return fileterosGenerator;
  }

  @override
  AreaPdfGenerator createSaneamiento(
    ReporteDetalle reporte,
    ReporteAreaDetalle area,
  ) {
    return saneamientoGenerator;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('report_pdf_test');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  ReporteDetalle buildReporte(ReporteAreaDetalle area) {
    return ReporteDetalle(
      id: 1,
      fecha: DateTime(2024, 1, 1),
      turno: 'Mañana',
      planillero: 'Tester',
      areas: [area],
    );
  }

  test('generateAreaReport routes to Fileteros generator', () async {
    final fileterosGenerator = FakeGenerator(Uint8List.fromList([1, 2, 3]));
    final saneamientoGenerator = FakeGenerator(Uint8List.fromList([4, 5, 6]));

    final service = ReportPdfService(
      generatorFactory: FakeGeneratorFactory(
        fileterosGenerator: fileterosGenerator,
        saneamientoGenerator: saneamientoGenerator,
      ),
    );

    final area = ReporteAreaDetalle(
      id: 10,
      nombre: 'Fileteros',
      cantidad: 2,
      totalKilos: 5,
      cuadrillas: const [
        CuadrillaDetalle(
          id: 1,
          nombre: 'Lote 1',
          kilos: 5,
          integrantes: [IntegranteDetalle(id: 1, nombre: 'Tester', code: 'A1')],
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

    final reporte = buildReporte(area);

    final result = await service.generateAreaReport(
      reporte: reporte,
      area: area,
    );

    expect(fileterosGenerator.called, isTrue);
    expect(saneamientoGenerator.called, isFalse);
    expect(result.bytes, isNotEmpty);
    expect(result.file.existsSync(), isTrue);
  });

  test('generateAreaReport routes to Saneamiento generator', () async {
    final fileterosGenerator = FakeGenerator(Uint8List.fromList([1]));
    final saneamientoGenerator = FakeGenerator(Uint8List.fromList([9, 9, 9]));

    final service = ReportPdfService(
      generatorFactory: FakeGeneratorFactory(
        fileterosGenerator: fileterosGenerator,
        saneamientoGenerator: saneamientoGenerator,
      ),
    );

    final area = ReporteAreaDetalle(
      id: 11,
      nombre: 'Saneamiento',
      cantidad: 1,
      totalKilos: 0,
      cuadrillas: const [
        CuadrillaDetalle(
          id: 2,
          nombre: 'Equipo 1',
          kilos: 0,
          integrantes: [
            IntegranteDetalle(
              id: 2,
              nombre: 'Cleaner',
              code: 'C1',
              labores: 'Limpieza general',
              horaInicio: '06:00',
              horaFin: '14:00',
            ),
          ],
          desglose: [],
          horaInicio: '06:00',
          horaFin: '14:00',
        ),
      ],
      desglose: const [],
      horaInicio: '06:00',
      horaFin: '14:00',
    );

    final reporte = buildReporte(area);

    final result = await service.generateAreaReport(
      reporte: reporte,
      area: area,
    );

    expect(saneamientoGenerator.called, isTrue);
    expect(fileterosGenerator.called, isFalse);
    expect(result.bytes, isNotEmpty);
    expect(result.file.existsSync(), isTrue);
  });
}
