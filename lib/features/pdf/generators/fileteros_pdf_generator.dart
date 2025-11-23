import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:scanner_trabunda/data/drift/app_database.dart';

import 'package:scanner_trabunda/features/pdf/generators/area_pdf_generator.dart';
import 'package:scanner_trabunda/features/pdf/generators/pdf_generator_utils.dart';

class FileterosPdfGenerator implements AreaPdfGenerator {
  FileterosPdfGenerator({
    required this.reporte,
    required this.area,
  });

  final ReporteDetalle reporte;
  final ReporteAreaDetalle area;

  @override
  Future<Uint8List> build() async {
    final elaboradoPor = reporte.planillero.trim();
    final formattedDate = formatDate(reporte.fecha);

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => _buildFileterosLayout(
          reporte: reporte,
          area: area,
          elaboradoPor: elaboradoPor,
          formattedDate: formattedDate,
        ),
      ),
    );

    final workers = _buildFileterosWorkers(area);

    if (workers.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Text(
              'ANEXO I - DETALLE DE FILETEROS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildFileterosAnnexTable(workers),
          ],
        ),
      );
    }

    return doc.save();
  }

  pw.Widget _buildFileterosLayout({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
    required String elaboradoPor,
    required String formattedDate,
  }) {
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
            'II.- FILETEROS (RESUMEN POR CUADRILLA):',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          _buildFileterosSummaryTable(area),
          pw.SizedBox(height: 12),
          pw.Text(
            'Nota: El detalle completo aparece en el ANEXO I.',
            style: pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 12),
          buildFooterSignaturesFileteros(elaboradoPor),
        ],
      ),
    );
  }

  Map<String, double> _calculateFileterosTotals(ReporteAreaDetalle area) {
    double sumFileteado = 0;
    double sumDesunado = 0;
    double sumCortaleta = 0;
    double sumSeccionado = 0;
    double sumReproductor = 0;

    for (final cuadrilla in area.cuadrillas) {
      final desglose = cuadrilla.desglose;

      sumFileteado +=
          _getDesgloseOrDefault(desglose, 'filete', cuadrilla.kilos);
      sumDesunado += _getDesgloseOrDefault(desglose, 'desu', 0);
      sumCortaleta += _getDesgloseOrDefault(desglose, 'corta', 0);
      sumSeccionado += _getDesgloseOrDefault(desglose, 'secci', 0);
      sumReproductor += _getDesgloseOrDefault(desglose, 'repro', 0);
    }

    return {
      'fileteado': sumFileteado,
      'desunado': sumDesunado,
      'cortaleta': sumCortaleta,
      'seccionado': sumSeccionado,
      'reproductor': sumReproductor,
    };
  }

  pw.Widget _buildFileterosSummaryTable(ReporteAreaDetalle area) {
    final rows = <pw.TableRow>[];

    rows.add(
      pw.TableRow(
        children: [
          _fileterosCell('N°', true),
          _fileterosCell('CUADRILLA', true),
          _fileterosCell('TRAB.', true),
          _fileterosCell('FILETEADO', true),
          _fileterosCell('DESUÑADO', true),
          _fileterosCell('CORT/ALETA', true),
          _fileterosCell('SECCIONADO', true),
          _fileterosCell('REPRODUCTOR', true),
        ],
      ),
    );

    const maxRows = 25;
    final totals = _calculateFileterosTotals(area);

    for (var i = 0; i < maxRows; i++) {
      if (i < area.cuadrillas.length) {
        final c = area.cuadrillas[i];
        final d = c.desglose;

        rows.add(
          pw.TableRow(
            children: [
              _fileterosCell((i + 1).toString().padLeft(2, '0')),
              _fileterosCell(c.nombre),
              _fileterosCell(c.integrantes.length.toString()),
              _fileterosCell(
                formatLbs(_getDesgloseOrDefault(d, 'filete', c.kilos)),
              ),
              _fileterosCell(
                formatLbs(_getDesgloseOrDefault(d, 'desu', 0)),
              ),
              _fileterosCell(
                formatLbs(_getDesgloseOrDefault(d, 'corta', 0)),
              ),
              _fileterosCell(
                formatLbs(_getDesgloseOrDefault(d, 'secci', 0)),
              ),
              _fileterosCell(
                formatLbs(_getDesgloseOrDefault(d, 'repro', 0)),
              ),
            ],
          ),
        );
      } else {
        rows.add(
          pw.TableRow(
            children: List.generate(8, (_) => _fileterosCell('')),
          ),
        );
      }
    }

    rows.add(
      pw.TableRow(
        children: [
          _fileterosCell('TOTAL POT.', true),
          _fileterosCell('', true),
          _fileterosCell('', true),
          _fileterosCell(formatLbs(totals['fileteado']!), true),
          _fileterosCell(formatLbs(totals['desunado']!), true),
          _fileterosCell(formatLbs(totals['cortaleta']!), true),
          _fileterosCell(formatLbs(totals['seccionado']!), true),
          _fileterosCell(formatLbs(totals['reproductor']!), true),
        ],
      ),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(1.6),
        2: pw.FlexColumnWidth(0.8),
        3: pw.FlexColumnWidth(1.0),
        4: pw.FlexColumnWidth(1.0),
        5: pw.FlexColumnWidth(1.0),
        6: pw.FlexColumnWidth(1.0),
        7: pw.FlexColumnWidth(1.0),
      },
      children: rows,
    );
  }

  pw.Widget _buildFileterosAnnexTable(List<Map<String, String>> workers) {
    return pw.Table.fromTextArray(
      headers: ['N°', 'CÓDIGO', 'NOMBRE', 'CUADRILLA'],
      data: List.generate(workers.length, (i) {
        final w = workers[i];
        return [
          '${i + 1}',
          w['codigo'] ?? '',
          w['nombre'] ?? '',
          w['cuadrilla'] ?? '',
        ];
      }),
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 9),
      border: pw.TableBorder.all(color: PdfColors.black),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
    );
  }

  pw.Widget _fileterosCell(String text, [bool header = false]) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      color: header ? PdfColors.grey200 : null,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  List<Map<String, String>> _buildFileterosWorkers(ReporteAreaDetalle area) {
    final result = <Map<String, String>>[];

    for (final c in area.cuadrillas) {
      for (final t in c.integrantes) {
        result.add({
          'codigo': t.code ?? '',
          'nombre': t.nombre,
          'cuadrilla': c.nombre,
        });
      }
    }

    return result;
  }

  double _getDesgloseOrDefault(
    List<CategoriaDesglose> desglose,
    String match,
    double fallback,
  ) {
    final kg = desglose.firstWhere(
      (e) => e.categoria.toLowerCase().contains(match.toLowerCase()),
      orElse: () => CategoriaDesglose(categoria: '', kilos: 0),
    );
    return kg.kilos == 0 ? fallback : kg.kilos;
  }
}

pw.Widget buildFileterosHeader(String formattedDate, String turno) {
  return pw.Column(
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 100,
            height: 100,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Text(
              'LOGO',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 200,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'FORMATO',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'RECEPCION Y FILETEADO',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 170,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: pw.Column(
              children: [
                headerValueRow('Código', 'TRABUNDA SAC -GG-JO-F-01'),
                headerValueRow('Versión', '02'),
                headerValueRow('Fecha Emisión', 'Octubre 2020'),
                headerValueRow('Página', '1 de 1'),
              ],
            ),
          ),
        ],
      ),
      pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              children: [
                labelValueRow('HORA INICIO', '_____'),
                labelValueRow('HORA FINAL', '_____'),
              ],
            ),
            pw.Column(
              children: [
                labelValueRow('FECHA', formattedDate),
                labelValueRow('TURNO', turno),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget buildFooterSignaturesFileteros(String elaboradoPor) {
  pw.Widget box(String label) {
    return pw.Container(
      width: 170,
      height: 60,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(height: 1, color: PdfColors.black),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  return pw.Column(
    children: [
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black),
        ),
        child: pw.Row(
          children: [
            pw.Text(
              'PERSONA QUE ELABORÓ EL REPORTE: ',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Expanded(
              child: pw.Container(
                height: 20,
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColors.black,
                      width: 1,
                    ),
                  ),
                ),
                child: pw.Text(elaboradoPor),
              ),
            ),
          ],
        ),
      ),
      pw.Row(
        children: [
          box('JEFE DE TURNO'),
          box('PLANILLERO'),
          box('SUPERVISOR DE ÁREA'),
        ],
      ),
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black),
        ),
        child: pw.Text(
          'Documento controlado. Prohibida su reproducción sin autorización.',
          style: pw.TextStyle(fontSize: 7),
        ),
      ),
    ],
  );
}
