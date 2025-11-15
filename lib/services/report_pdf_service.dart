import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/app_database.dart';

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

/// Utilidad para generar el PDF oficial de un reporte.
class ReportPdfService {
  const ReportPdfService();

  Future<ReportPdfResult> generateAreaReport({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
    required String elaboradoPor,
  }) async {
    final bytes = await _buildAreaDocument(
      reporte: reporte,
      area: area,
      elaboradoPor: elaboradoPor,
    );

    final filename = _buildFilename(reporte, area);
    final file = await _persist(bytes, filename);

    return ReportPdfResult(bytes: bytes, file: file, filename: filename);
  }

  Future<void> share(ReportPdfResult result) async {
    await Printing.sharePdf(bytes: result.bytes, filename: result.filename);
  }

  Future<Uint8List> _buildAreaDocument({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
    required String elaboradoPor,
  }) async {
    final doc = pw.Document();
    final formattedDate = _formatDate(reporte.fecha);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        build: (context) {
          return [
            _buildHeader(reporte, area, formattedDate, elaboradoPor),
            pw.SizedBox(height: 16),
            _buildAreaSummary(area),
            pw.SizedBox(height: 24),
            _buildCuadrillasSection(area),
            pw.SizedBox(height: 32),
            _buildSignaturesSection(elaboradoPor),
          ];
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(
      ReporteDetalle reporte,
      ReporteAreaDetalle area,
      String formattedDate,
      String elaboradoPor,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'REPORTE DIARIO DE PRODUCCIÓN',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey700, width: 1),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          padding: const pw.EdgeInsets.all(12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow('Fecha', formattedDate),
              _infoRow('Turno', reporte.turno),
              _infoRow('Planillero', reporte.planillero),
              _infoRow('Área', area.nombre),
              _infoRow('Persona que elaboró el reporte', elaboradoPor),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildAreaSummary(ReporteAreaDetalle area) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.8),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _tableHeaderCell('Cantidad de personas'),
            _tableHeaderCell('Total kilos'),
            _tableHeaderCell('Total integrantes registrados'),
          ],
        ),
        pw.TableRow(
          children: [
            _tableCell('${area.cantidad}'),
            _tableCell('${area.totalKilos.toStringAsFixed(3)} kg'),
            _tableCell('${area.totalIntegrantes}'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCuadrillasSection(ReporteAreaDetalle area) {
    if (area.cuadrillas.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey500),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          'No hay cuadrillas registradas para esta área.',
          style: const pw.TextStyle(fontSize: 12),
        ),
      );
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _tableHeaderCell('Cuadrilla'),
          _tableHeaderCell('Horario'),
          _tableHeaderCell('Integrantes'),
          _tableHeaderCell('Kilos'),
        ],
      ),
    ];

    for (final cuadrilla in area.cuadrillas) {
      rows.add(
        pw.TableRow(
          children: [
            _tableCell(cuadrilla.nombre),
            _tableCell(_formatRange(cuadrilla.horaInicio, cuadrilla.horaFin)),
            _tableCell(_formatIntegrantes(cuadrilla.integrantes)),
            _tableCell('${cuadrilla.kilos.toStringAsFixed(3)} kg'),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detalle de cuadrillas',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.8),
          children: rows,
        ),
      ],
    );
  }

  pw.Widget _buildSignaturesSection(String elaboradoPor) {
    pw.Widget signatureBox(String label, {String? helper}) {
      return pw.Expanded(
        child: pw.Container(
          height: 100,
          margin: const pw.EdgeInsets.symmetric(horizontal: 6),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey700),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.8)),
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
              if (helper != null)
                pw.Text(
                  helper,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Firmas',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            signatureBox('Persona que elaboró el reporte', helper: elaboradoPor),
            signatureBox('Supervisor'),
            signatureBox('Jefe de planta'),
          ],
        ),
      ],
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 180,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '-' : value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _tableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  String _formatIntegrantes(List<IntegranteDetalle> integrantes) {
    if (integrantes.isEmpty) {
      return 'Sin integrantes';
    }
    return integrantes.map((i) => i.nombre).join(', ');
  }

  String _formatRange(String? start, String? end) {
    final hasStart = start != null && start.trim().isNotEmpty;
    final hasEnd = end != null && end.trim().isNotEmpty;

    if (!hasStart && !hasEnd) {
      return 'No registrado';
    }

    final startText = hasStart ? start!.trim() : '--:--';
    final endText = hasEnd ? end!.trim() : '--:--';
    return '$startText - $endText';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  String _buildFilename(ReporteDetalle reporte, ReporteAreaDetalle area) {
    final date = _formatDate(reporte.fecha).replaceAll('/', '-');
    final areaSlug = area.nombre
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+', caseSensitive: false), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    final normalized = areaSlug.isEmpty ? 'area' : areaSlug;
    return 'reporte_${date}_${normalized}.pdf';
  }

  Future<File> _persist(Uint8List bytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
