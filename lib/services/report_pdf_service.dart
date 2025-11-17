import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/app_database.dart';

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

class ReportPdfService {
  const ReportPdfService();

  // ============================================================
  // GENERAR PDF DE AREA FILETEROS
  // ============================================================

  Future<ReportPdfResult> generateAreaReport({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
  }) async {
    if (!_isFileterosArea(area)) {
      throw ArgumentError(
        'Solo se permite generar PDF para el área Fileteros.',
      );
    }

    final elaboradoPor = reporte.planillero.trim();
    final bytes = await _buildFileterosDocument(reporte, area, elaboradoPor);

    final filename = _buildFilename(reporte, area);
    final file = await _persist(bytes, filename);

    return ReportPdfResult(bytes: bytes, file: file, filename: filename);
  }

  Future<void> share(ReportPdfResult result) async {
    await Printing.sharePdf(
      bytes: result.bytes,
      filename: result.filename,
    );
  }

  // ============================================================
  // GENERAR PDF DE RECEPCIÓN
  // ============================================================

  Future<ReportPdfResult> generateRecepcionReport({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
  }) async {
    if (!_isRecepcionArea(area)) {
      throw ArgumentError(
        'generateRecepcionReport solo funciona con área Recepción.',
      );
    }

    final elaboradoPor = reporte.planillero.trim();
    final formattedDate = _formatDate(reporte.fecha);

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
                _buildFileterosHeader(formattedDate, reporte.turno),
                pw.SizedBox(height: 8),
                pw.Text(
                  'I.- RECEPCIÓN:',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 6),
                _buildRecepcionMainTable(area),
                pw.SizedBox(height: 10),
                _buildFooterSignaturesFileteros(elaboradoPor),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await doc.save();
    final filename = 'reporte_recepcion_${_formatDate(reporte.fecha)}.pdf';
    final file = await _persist(bytes, filename);

    return ReportPdfResult(bytes: bytes, file: file, filename: filename);
  }

  // ============================================================
  // DOCUMENTO FILETEROS (RESUMEN + ANEXO)
  // ============================================================

  Future<Uint8List> _buildFileterosDocument(
      ReporteDetalle reporte,
      ReporteAreaDetalle area,
      String elaboradoPor,
      ) async {
    final doc = pw.Document();
    final formattedDate = _formatDate(reporte.fecha);

    // Página 1: resumen por cuadrilla
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

    // Página 2: Anexo de trabajadores
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
                  fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildFileterosAnnexTable(workers),
          ],
        ),
      );
    }

    return doc.save();
  }

  // ------------------------------------------------------------
  // Totales para el resumen de FILETEROS
  // ------------------------------------------------------------
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


  // ============================================================
  // LAYOUT FILETEROS RESUMEN
  // ============================================================

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
          _buildFileterosHeader(formattedDate, reporte.turno),
          pw.SizedBox(height: 8),
          pw.Text(
            'II.- FILETEROS (RESUMEN POR CUADRILLA):',
            style:
            pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          _buildFileterosSummaryTable(area),
          pw.SizedBox(height: 12),
          pw.Text(
            'Nota: El detalle completo aparece en el ANEXO I.',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 12),
          _buildFooterSignaturesFileteros(elaboradoPor),
        ],
      ),
    );
  }

  // ============================================================
  // CABECERA GENERAL
  // ============================================================

  pw.Widget _buildFileterosHeader(String formattedDate, String turno) {
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
                  border: pw.Border.all(color: PdfColors.black)),
              child: pw.Text('LOGO',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(width: 8),
            pw.Container(
              width: 200,
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black)),
              child: pw.Column(children: [
                pw.Text('FORMATO',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('RECEPCION Y FILETEADO',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
            pw.SizedBox(width: 8),
            pw.Container(
              width: 170,
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black)),
              child: pw.Column(children: [
                _headerValueRow('Código', 'TRABUNDA SAC -GG-JO-F-01'),
                _headerValueRow('Versión', '02'),
                _headerValueRow('Fecha Emisión', 'Octubre 2020'),
                _headerValueRow('Página', '1 de 1'),
              ]),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(children: [
                _labelValueRow('HORA INICIO', '_____'),
                _labelValueRow('HORA FINAL', '_____'),
              ]),
              pw.Column(children: [
                _labelValueRow('FECHA', formattedDate),
                _labelValueRow('TURNO', turno),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TABLA RECEPCIÓN OFICIAL
  // ============================================================

  pw.Widget _buildRecepcionMainTable(ReporteAreaDetalle area) {
    final rows = <pw.TableRow>[
      _tableRow(['N°', 'CÓDIGO', 'PRODUCTO', 'TOTAL'], isHeader: true)
    ];

    double totalKilos = 0;
    const maxRows = 12;

    for (var i = 0; i < maxRows; i++) {
      if (i < area.cuadrillas.length) {
        final q = area.cuadrillas[i];
        totalKilos += q.kilos;

        rows.add(_tableRow([
          (i + 1).toString().padLeft(2, '0'),
          _formatIntegrantesCodes(q.integrantes),
          '',
          _formatLbs(_toLbs(q.kilos)),
        ]));
      } else {
        rows.add(_tableRow(['', '', '', '']));
      }
    }

    rows.add(
      _tableRow(
        ['TOTAL POT.', '', '', _formatLbs(_toLbs(totalKilos))],
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

  // ============================================================
  // TABLA RESUMEN CUADRILLAS FILETEROS
  // ============================================================

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
              _fileterosCell(_formatLbs(_getDesgloseOrDefault(d, 'filete', c.kilos))),
              _fileterosCell(_formatLbs(_getDesgloseOrDefault(d, 'desu', 0))),
              _fileterosCell(_formatLbs(_getDesgloseOrDefault(d, 'corta', 0))),
              _fileterosCell(_formatLbs(_getDesgloseOrDefault(d, 'secci', 0))),
              _fileterosCell(_formatLbs(_getDesgloseOrDefault(d, 'repro', 0))),
            ],
          ),
        );
      } else {
        rows.add(pw.TableRow(children: List.generate(8, (_) => _fileterosCell(''))));
      }
    }

    rows.add(
      pw.TableRow(
        children: [
          _fileterosCell('TOTAL POT.', true),
          _fileterosCell('', true),
          _fileterosCell('', true),
          _fileterosCell(_formatLbs(totals['fileteado']!), true),
          _fileterosCell(_formatLbs(totals['desunado']!), true),
          _fileterosCell(_formatLbs(totals['cortaleta']!), true),
          _fileterosCell(_formatLbs(totals['seccionado']!), true),
          _fileterosCell(_formatLbs(totals['reproductor']!), true),
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

  // ============================================================
  // PIE DE FIRMAS
  // ============================================================

  pw.Widget _buildFooterSignaturesFileteros(String elaboradoPor) {
    pw.Widget box(String label) {
      return pw.Container(
        width: 170,
        height: 60,
        decoration:
        pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(height: 1, color: PdfColors.black),
            pw.SizedBox(height: 4),
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
    }

    return pw.Column(children: [
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black)),
        child: pw.Row(children: [
          pw.Text(
            'PERSONA QUE ELABORÓ EL REPORTE: ',
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Expanded(
            child: pw.Container(
              height: 20,
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                ),
              ),
              child: pw.Text(elaboradoPor),
            ),
          ),
        ]),
      ),
      pw.Row(children: [
        box('JEFE DE TURNO'),
        box('PLANILLERO'),
        box('SUPERVISOR DE ÁREA'),
      ]),
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black)),
        child: pw.Text(
          'Documento controlado. Prohibida su reproducción sin autorización.',
          style: const pw.TextStyle(fontSize: 7),
        ),
      ),
    ]);
  }

  // ============================================================
  // ANEXO TABLA DE TRABAJADORES
  // ============================================================

  List<Map<String, String>> _buildFileterosWorkers(
      ReporteAreaDetalle area) {
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
      headerStyle:
      pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 9),
      border: pw.TableBorder.all(color: PdfColors.black),
      headerDecoration:
      const pw.BoxDecoration(color: PdfColors.grey200),
    );
  }

  // ============================================================
  // UTILITARIOS
  // ============================================================

  pw.TableRow _tableRow(List<String> cells, {bool isHeader = false}) {
    return pw.TableRow(
      decoration:
      isHeader ? const pw.BoxDecoration(color: PdfColors.grey200) : null,
      children: cells
          .map(
            (c) => pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.center,
          child: pw.Text(
            c,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isHeader
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  String _formatIntegrantesCodes(List<IntegranteDetalle> list) {
    final codes = list
        .map((e) => e.code ?? '')
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return codes.join(', ');
  }

  double _getDesgloseOrDefault(
      List<CategoriaDesglose> desglose, String match, double fallback) {
    final kg = desglose.firstWhere(
          (e) => e.categoria.toLowerCase().contains(match.toLowerCase()),
      orElse: () => CategoriaDesglose(categoria: '', kilos: 0),
    );
    return kg.kilos == 0 ? fallback : kg.kilos;
  }

  String _formatLbs(double lbs) {
    if (lbs <= 0 || lbs.isNaN) return '';
    return lbs.toStringAsFixed(2);
  }

  double _toLbs(double kilos) => kilos * 2.20462;

  bool _isFileterosArea(ReporteAreaDetalle area) =>
      area.nombre.toLowerCase() == 'fileteros';

  bool _isRecepcionArea(ReporteAreaDetalle area) =>
      area.nombre.toLowerCase() == 'recepción' ||
          area.nombre.toLowerCase() == 'recepcion';

  pw.Widget _headerValueRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _labelValueRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style:
            pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';

  String _buildFilename(ReporteDetalle r, ReporteAreaDetalle a) {
    final date = _formatDate(r.fecha).replaceAll('/', '-');
    final area = a.nombre.toLowerCase().replaceAll(' ', '_');
    return 'reporte_${date}_$area.pdf';
  }

  Future<File> _persist(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
