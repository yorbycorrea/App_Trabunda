import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:scanner_trabunda/data/drift/app_database.dart';
import 'package:scanner_trabunda/features/pdf/data/pdf_storage_service.dart';
import 'package:scanner_trabunda/features/pdf/generators/area_pdf_generator.dart';
import 'package:scanner_trabunda/features/pdf/generators/fileteros_pdf_generator.dart';
import 'package:scanner_trabunda/features/pdf/generators/pdf_generator_utils.dart';
import 'package:scanner_trabunda/features/pdf/generators/saneamiento_pdf_generator.dart';

/// Resultado de la creación del PDF
class ReportPdfResult {
  final Uint8List bytes;
  final File file;
  final String filename;

  const ReportPdfResult({
    required this.bytes,
    required this.file,
    required this.filename,
  });
}

class ReportPdfGeneratorFactory {
  const ReportPdfGeneratorFactory();

  AreaPdfGenerator createFileteros(
    ReporteDetalle reporte,
    ReporteAreaDetalle area,
  ) =>
      FileterosPdfGenerator(reporte: reporte, area: area);

  AreaPdfGenerator createSaneamiento(
    ReporteDetalle reporte,
    ReporteAreaDetalle area,
  ) =>
      SaneamientoPdfGenerator(reporte: reporte, area: area);
}

class ReportPdfService {
  const ReportPdfService({
    this.generatorFactory = const ReportPdfGeneratorFactory(),
  });

  final ReportPdfGeneratorFactory generatorFactory;

  Future<ReportPdfResult> generateAreaReport({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
    int? supabaseReporteId,
  }) async {
    final selection = _selectGenerator(reporte, area);

    return _generateWithGenerator(
      reporte: reporte,
      area: area,
      supabaseReporteId: supabaseReporteId,
      generator: selection.generator,
      filenamePrefix: selection.filenamePrefix,
    );
  }

  Future<ReportPdfResult> generateRecepcionReport({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
    int? supabaseReporteId,
  }) async {
    if (!_isRecepcionArea(area)) {
      throw ArgumentError(
        'generateRecepcionReport solo funciona con área Recepción.',
      );
    }

    final elaboradoPor = reporte.planillero.trim();
    final formattedDate = formatDate(reporte.fecha);

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.2),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                buildFileterosHeader(formattedDate, reporte.turno),
                pw.SizedBox(height: 8),
                pw.Text(
                  'I.- RECEPCIÓN:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildRecepcionMainTable(area),
                pw.SizedBox(height: 10),
                buildFooterSignaturesFileteros(elaboradoPor),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await doc.save();

    final filename = _buildFilename(
      reporte,
      area,
      prefix: 'reporte_recepcion',
    );

    final file = await _persist(bytes, filename);
    final result = ReportPdfResult(bytes: bytes, file: file, filename: filename);

    if (supabaseReporteId != null) {
      try {
        await PdfStorageService.instance.subirPdfDeReporte(
          reporteId: supabaseReporteId,
          bytes: bytes,
        );
      } catch (e) {
        debugPrint('Error subiendo PDF Recepción a Supabase: $e');
      }
    }

    return result;
  }

  Future<ReportPdfResult> generateSaneamientoReport({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
    int? supabaseReporteId,
  }) async {
    if (!_isSaneamientoArea(area)) {
      throw ArgumentError(
        'generateSaneamientoReport solo funciona con área Saneamiento.',
      );
    }

    return _generateWithGenerator(
      reporte: reporte,
      area: area,
      supabaseReporteId: supabaseReporteId,
      generator: generatorFactory.createSaneamiento(reporte, area),
      filenamePrefix: 'reporte_saneamiento',
    );
  }

  Future<void> share(ReportPdfResult result) async {
    await Printing.sharePdf(
      bytes: result.bytes,
      filename: result.filename,
    );
  }

  _GeneratorSelection _selectGenerator(
    ReporteDetalle reporte,
    ReporteAreaDetalle area,
  ) {
    final normalizedArea = area.nombre.toLowerCase().trim();
    switch (normalizedArea) {
      case 'fileteros':
        return _GeneratorSelection(
          generator: generatorFactory.createFileteros(reporte, area),
          filenamePrefix: 'reporte_fileteros',
        );
      case 'saneamiento':
        return _GeneratorSelection(
          generator: generatorFactory.createSaneamiento(reporte, area),
          filenamePrefix: 'reporte_saneamiento',
        );
      default:
        throw UnsupportedError(
          'No hay generador de PDF para el área: ${area.nombre}',
        );
    }
  }

  Future<ReportPdfResult> _generateWithGenerator({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
    required int? supabaseReporteId,
    required AreaPdfGenerator generator,
    required String filenamePrefix,
  }) async {
    final bytes = await generator.build();

    final filename = _buildFilename(
      reporte,
      area,
      prefix: filenamePrefix,
    );

    final file = await _persist(bytes, filename);
    final result = ReportPdfResult(bytes: bytes, file: file, filename: filename);

    if (supabaseReporteId != null) {
      try {
        await PdfStorageService.instance.subirPdfDeReporte(
          reporteId: supabaseReporteId,
          bytes: bytes,
        );
      } catch (e) {
        debugPrint('Error subiendo PDF ${area.nombre} a Supabase: $e');
      }
    }

    return result;
  }

  pw.Widget _buildRecepcionMainTable(ReporteAreaDetalle area) {
    final rows = <pw.TableRow>[
      buildTableRow(['N°', 'CÓDIGO', 'PRODUCTO', 'TOTAL'], isHeader: true),
    ];

    double totalKilos = 0;
    const maxRows = 12;

    for (var i = 0; i < maxRows; i++) {
      if (i < area.cuadrillas.length) {
        final q = area.cuadrillas[i];
        totalKilos += q.kilos;

        rows.add(
          buildTableRow(
            [
              (i + 1).toString().padLeft(2, '0'),
              formatIntegrantesCodes(q.integrantes),
              '',
              formatLbs(toLbs(q.kilos)),
            ],
          ),
        );
      } else {
        rows.add(buildTableRow(['', '', '', '']));
      }
    }

    rows.add(
      buildTableRow(
        ['TOTAL POT.', '', '', formatLbs(toLbs(totalKilos))],
        isHeader: true,
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.0),
      },
      children: rows,
    );
  }

  String _buildFilename(
    ReporteDetalle reporte,
    ReporteAreaDetalle area, {
    String prefix = 'reporte',
  }) {
    final day = reporte.fecha.day.toString().padLeft(2, '0');
    final month = reporte.fecha.month.toString().padLeft(2, '0');
    final year = reporte.fecha.year.toString().padLeft(4, '0');
    final datePart = '$day-$month-$year';

    final areaSlug = area.nombre
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+', caseSensitive: false), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final safeArea = areaSlug.isEmpty ? 'area' : areaSlug;

    return '${prefix}_${datePart}_$safeArea.pdf';
  }

  Future<File> _persist(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  bool _isRecepcionArea(ReporteAreaDetalle area) =>
      area.nombre.toLowerCase() == 'recepción' ||
      area.nombre.toLowerCase() == 'recepcion';

  bool _isSaneamientoArea(ReporteAreaDetalle area) =>
      area.nombre.toLowerCase() == 'saneamiento';
}

class _GeneratorSelection {
  _GeneratorSelection({
    required this.generator,
    required this.filenamePrefix,
  });

  final AreaPdfGenerator generator;
  final String filenamePrefix;
}
