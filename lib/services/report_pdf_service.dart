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
    try {
      final bytes = await _buildAreaDocument(
        reporte: reporte,
        area: area,
        elaboradoPor: elaboradoPor,
      );

      final filename = _buildFilename(reporte, area);
      final file = await _persist(bytes, filename);

      return ReportPdfResult(bytes: bytes, file: file, filename: filename);
    } catch (e, st) {
      // Para ver el error real en consola
      print('ERROR generando PDF: $e');
      print(st);
      rethrow;
    }
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

    // Si es área de fileteros, usamos layout especial.
    // Si algo falla, usamos el layout enmarcado normal.
    late final pw.Widget content;
    if (_isFileterosArea(area)) {
      try {
        content = _buildFileterosLayout(
          reporte: reporte,
          area: area,
          formattedDate: formattedDate,
          elaboradoPor: elaboradoPor,
        );
      } catch (e, st) {
        print('ERROR en _buildFileterosLayout: $e');
        print(st);
        content = _buildFramedLayout(
          reporte: reporte,
          area: area,
          formattedDate: formattedDate,
          elaboradoPor: elaboradoPor,
        );
      }
    } else {
      content = _buildFramedLayout(
        reporte: reporte,
        area: area,
        formattedDate: formattedDate,
        elaboradoPor: elaboradoPor,
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [content],
      ),
    );

    return doc.save();
  }

  // =========================
  // LAYOUT GENERAL (otras áreas)
  // =========================

  pw.Widget _buildFramedLayout({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
    required String formattedDate,
    required String elaboradoPor,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.2),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildTopHeader(reporte, area, formattedDate),
          pw.SizedBox(height: 8),
          _buildReceptionAndAprovechamiento(area),
          pw.SizedBox(height: 10),
          _buildFileteoSection(area),
          pw.SizedBox(height: 12),
          _buildFooterSignatures(elaboradoPor),
        ],
      ),
    );
  }

  pw.Widget _buildTopHeader(
      ReporteDetalle reporte,
      ReporteAreaDetalle area,
      String formattedDate,
      ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 140,
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _labelValueRow('HORA INICIO', area.horaInicio ?? ''),
              pw.Divider(height: 6, thickness: 1),
              _labelValueRow('HORA FINAL', area.horaFin ?? ''),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Container(
                padding:
                const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TRABUNDA SAC',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'FORMATO',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  area.nombre.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.Container(
          width: 140,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _headerValueRow('FECHA', formattedDate),
              _headerValueRow('TURNO', reporte.turno),
              _headerValueRow('PÁGINA', '1 de 1'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildReceptionAndAprovechamiento(ReporteAreaDetalle area) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _buildRecepcionTable(area)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _buildAprovechamientoTable(area)),
      ],
    );
  }

  pw.Widget _buildRecepcionTable(ReporteAreaDetalle area) {
    final rows = <pw.TableRow>[
      _tableRow(['HORA', 'LOTE N°', 'LBS'], isHeader: true),
    ];

    for (final cuadrilla in area.cuadrillas) {
      rows.add(
        _tableRow([
          _formatRange(cuadrilla.horaInicio, cuadrilla.horaFin),
          cuadrilla.nombre,
          _formatLbs(_toLbs(cuadrilla.kilos)),
        ]),
      );
    }

    while (rows.length < 8) {
      rows.add(_tableRow(['', '', '']));
    }

    rows.add(
      _tableRow(
        [
          '',
          'TOTAL LBS',
          _formatLbs(_toLbs(area.totalKilos)),
        ],
        isHeader: true,
      ),
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('RECEPCIÓN'),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1.2),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1),
            },
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            children: rows,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAprovechamientoTable(ReporteAreaDetalle area) {
    final rows = <pw.TableRow>[
      _tableRow(['CÓDIGO', 'LBS'], isHeader: true),
    ];

    for (final desglose in area.desglose) {
      rows.add(
        _tableRow([
          desglose.categoria,
          _formatLbs(_toLbs(desglose.kilos)),
        ]),
      );
    }

    while (rows.length < 8) {
      rows.add(_tableRow(['', '']));
    }

    final totalKilos =
    area.desglose.fold<double>(0, (sum, d) => sum + d.kilos);

    rows.add(
      _tableRow(
        [
          'TOTAL LBS',
          _formatLbs(_toLbs(totalKilos)),
        ],
        isHeader: true,
      ),
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('APROVECHAMIENTO'),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1.3),
              1: pw.FlexColumnWidth(1),
            },
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            children: rows,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFileteoSection(ReporteAreaDetalle area) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 3, child: _buildFileteoTable(area)),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            children: [
              _buildClasificadoTable(area),
              pw.SizedBox(height: 8),
              _buildCodificadoTable(area),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  // LAYOUT ESPECIAL FILETEROS
  // =========================

  pw.Widget _buildFileterosLayout({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
    required String formattedDate,
    required String elaboradoPor,
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
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              'II.- FILETEROS:',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          _buildFileterosTable(area),
          pw.SizedBox(height: 12),
          _buildFooterSignaturesFileteros(elaboradoPor),
        ],
      ),
    );
  }

  /// Cabecera específica para el formato de FILETEROS
  pw.Widget _buildFileterosHeader(String formattedDate, String turno) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Fila principal del encabezado
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // TRABUNDA SAC
            pw.Container(
              width: 160,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Text(
                'TRABUNDA SAC',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            // FORMATO + título
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        'FORMATO',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text(
                        'RECEPCION Y FILETEADO',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Código / Versión / Fecha Emisión / Página
            pw.Container(
              width: 170,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _headerValueRow(
                    'Código',
                    'TRABUNDA SAC -GG-JO-F-01',
                  ),
                  _headerValueRow('Versión', '02'),
                  _headerValueRow('Fecha de Emisión', 'Octubre 2020'),
                  _headerValueRow('Página', '1 de 1'),
                ],
              ),
            ),
          ],
        ),

        // Fila con HORA INICIO / HORA FINAL / FECHA / TURNO
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          padding:
          const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _labelValueRow('HORA INICIO', '_____'),
                  pw.SizedBox(height: 4),
                  _labelValueRow('HORA FINAL', '_____'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _labelValueRow('FECHA', formattedDate),
                  pw.SizedBox(height: 4),
                  _labelValueRow('TURNO', turno),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFileterosTable(ReporteAreaDetalle area) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          _fileterosCellWidget('', isHeader: true),
          _fileterosCellWidget('CODIGO', isHeader: true),
          _fileterosCellWidget('FILETEADO', isHeader: true),
          _fileterosCellWidget('DESUÑADO', isHeader: true),
          _fileterosCellWidget('CORT/ALETA', isHeader: true),
          _fileterosCellWidget('SECCIONADO', isHeader: true),
          _fileterosCellWidget('REPRODUCTOR', isHeader: true),
        ],
      ),
    ];

    final maxRows = 25;
    final totals = _calculateFileterosTotals(area);

    for (var i = 0; i < maxRows; i++) {
      if (i < area.cuadrillas.length) {
        final cuadrilla = area.cuadrillas[i];
        final desglose = cuadrilla.desglose;
        rows.add(
          pw.TableRow(
            children: [
              _fileterosCellWidget((i + 1).toString().padLeft(2, '0')),
              _fileterosCellWidget(
                _formatIntegrantesCodes(cuadrilla.integrantes),
              ),
              _fileterosCellWidget(
                _formatLbs(
                  _getDesgloseOrDefault(
                    desglose,
                    'filete',
                    cuadrilla.kilos,
                  ),
                ),
              ),
              _fileterosCellWidget(
                _formatLbs(
                  _getDesgloseOrDefault(desglose, 'desu', 0),
                ),
              ),
              _fileterosCellWidget(
                _formatLbs(
                  _getDesgloseOrDefault(desglose, 'corta', 0),
                ),
              ),
              _fileterosCellWidget(
                _formatLbs(
                  _getDesgloseOrDefault(desglose, 'secci', 0),
                ),
              ),
              _fileterosCellWidget(
                _formatLbs(
                  _getDesgloseOrDefault(desglose, 'repro', 0),
                ),
              ),
            ],
          ),
        );
      } else {
        rows.add(
          pw.TableRow(
            children: List.generate(
              7,
                  (_) => _fileterosCellWidget(''),
            ),
          ),
        );
      }
    }

    rows.add(
      pw.TableRow(
        children: [
          _fileterosCellWidget('TOTAL POT.', isHeader: true),
          _fileterosCellWidget('', isHeader: true),
          _fileterosCellWidget(
            _formatLbs(totals['fileteado']!),
            isHeader: true,
          ),
          _fileterosCellWidget(
            _formatLbs(totals['desunado']!),
            isHeader: true,
          ),
          _fileterosCellWidget(
            _formatLbs(totals['cortaleta']!),
            isHeader: true,
          ),
          _fileterosCellWidget(
            _formatLbs(totals['seccionado']!),
            isHeader: true,
          ),
          _fileterosCellWidget(
            _formatLbs(totals['reproductor']!),
            isHeader: true,
          ),
        ],
      ),
    );

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1),
        6: pw.FlexColumnWidth(1),
      },
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      children: rows,
    );
  }

  // Pie de firmas usado por las demás áreas (no fileteros).
  // Reutiliza el mismo diseño que el de Fileteros.
  pw.Widget _buildFooterSignatures(String elaboradoPor) {
    return _buildFooterSignaturesFileteros(elaboradoPor);
  }

  pw.Widget _buildFooterSignaturesFileteros(String elaboradoPor) {
    pw.Widget signatureBox(String label) {
      return pw.Expanded(
        child: pw.Container(
          height: 60,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 6),
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
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          alignment: pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
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
                  margin: const pw.EdgeInsets.only(left: 4),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Text(
                    elaboradoPor.isEmpty ? '' : elaboradoPor,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.Row(
          children: [
            signatureBox('JEFE DE TURNO'),
            signatureBox('PLANILLERO'),
            signatureBox('SUPERVISOR DE ÁREA'),
          ],
        ),
        pw.Container(
          padding:
          const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Text(
            'Documento controlado Prohibida su reproducción sin la autorización de TRABUNDA SAC',
            style: const pw.TextStyle(fontSize: 7),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  // =========================
  // TABLAS OTRAS SECCIONES
  // =========================

  pw.Widget _buildFileteoTable(ReporteAreaDetalle area) {
    final rows = <pw.TableRow>[
      _tableRow(
        [
          'CÓDIGO',
          'FILETEADO',
          'DESMUSADO',
          'CONTROL MEC.',
          'APROVECHAMIENTO',
          'PRODUCTO',
        ],
        isHeader: true,
      ),
    ];

    for (final cuadrilla in area.cuadrillas) {
      final desglose = cuadrilla.desglose;
      rows.add(
        _tableRow([
          _formatIntegrantesCodes(cuadrilla.integrantes),
          _formatLbs(
            _getDesgloseOrDefault(desglose, 'filete', cuadrilla.kilos),
          ),
          _formatLbs(_getDesgloseOrDefault(desglose, 'desm', 0)),
          _formatLbs(_getDesgloseOrDefault(desglose, 'control', 0)),
          _formatLbs(_getDesgloseOrDefault(desglose, 'aprove', 0)),
          _formatLbs(_getDesgloseOrDefault(desglose, 'producto', 0)),
        ]),
      );
    }

    while (rows.length < 12) {
      rows.add(
        _tableRow(['', '', '', '', '', '']),
      );
    }

    final totals = _calculateFileteoTotals(area);

    rows.add(
      _tableRow(
        [
          'TOTAL',
          _formatLbs(totals['fileteado']!),
          _formatLbs(totals['desmusado']!),
          _formatLbs(totals['control']!),
          _formatLbs(totals['aprove']!),
          _formatLbs(totals['producto']!),
        ],
        isHeader: true,
      ),
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('FILETEO'),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1.3),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1),
              5: pw.FlexColumnWidth(1),
            },
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            children: rows,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClasificadoTable(ReporteAreaDetalle area) {
    final rows = <pw.TableRow>[
      _tableRow(['CÓDIGO', 'LBS'], isHeader: true),
    ];

    final clasificados = area.desglose
        .where(
          (d) =>
      d.categoria.toLowerCase().contains('clasi') ||
          d.categoria.toLowerCase().contains('aleta'),
    )
        .toList();

    for (final desglose in clasificados) {
      rows.add(
        _tableRow([
          desglose.categoria,
          _formatLbs(_toLbs(desglose.kilos)),
        ]),
      );
    }

    while (rows.length < 8) {
      rows.add(_tableRow(['', '']));
    }

    final total = clasificados.fold<double>(0, (sum, d) => sum + d.kilos);

    rows.add(
      _tableRow(
        [
          'TOTAL',
          _formatLbs(_toLbs(total)),
        ],
        isHeader: true,
      ),
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('CLASIFICADO / ALETA'),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1.4),
              1: pw.FlexColumnWidth(1),
            },
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            children: rows,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCodificadoTable(ReporteAreaDetalle area) {
    final rows = <pw.TableRow>[
      _tableRow(['CÓDIGO', 'MÁQUINA', 'LBS'], isHeader: true),
    ];

    final codificados = area.desglose
        .where((d) => d.categoria.toLowerCase().contains('manual'))
        .toList();

    for (final desglose in codificados) {
      rows.add(
        _tableRow([
          desglose.categoria,
          'MANUAL',
          _formatLbs(_toLbs(desglose.kilos)),
        ]),
      );
    }

    while (rows.length < 8) {
      rows.add(_tableRow(['', '', '']));
    }

    final total = codificados.fold<double>(0, (sum, d) => sum + d.kilos);

    rows.add(
      _tableRow(
        [
          'TOTAL',
          '',
          _formatLbs(_toLbs(total)),
        ],
        isHeader: true,
      ),
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('CODIFICADO MANUAL'),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1.1),
              1: pw.FlexColumnWidth(1.1),
              2: pw.FlexColumnWidth(1),
            },
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            children: rows,
          ),
        ],
      ),
    );
  }

  // =========================
  // UTILIDADES DE DIBUJO
  // =========================

  pw.TableRow _tableRow(List<String> values, {bool isHeader = false}) {
    return pw.TableRow(
      children: [
        for (final value in values)
          pw.Container(
            padding:
            const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            alignment: pw.Alignment.center,
            constraints: const pw.BoxConstraints(minHeight: 18),
            color: isHeader ? PdfColors.grey200 : null,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
      ],
    );
  }

  pw.Widget _fileterosCellWidget(String value, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      alignment: pw.Alignment.center,
      constraints: const pw.BoxConstraints(minHeight: 18),
      color: isHeader ? PdfColors.grey200 : null,
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _labelValueRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          value.isEmpty ? '-' : value,
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  pw.Widget _headerValueRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 8.5),
          ),
        ],
      ),
    );
  }

  // =========================
  // LÓGICA DE NEGOCIO
  // =========================

  String _formatIntegrantesCodes(List<IntegranteDetalle> integrantes) {
    if (integrantes.isEmpty) return '-';
    return integrantes
        .map((i) => (i.code ?? '').isNotEmpty ? i.code!.trim() : '--')
        .join(', ');
  }

  double _getDesgloseOrDefault(
      List<CategoriaDesglose> desglose,
      String match,
      double fallbackKilos,
      ) {
    final kilos = _extractDesgloseKilos(desglose, match);
    return _toLbs(kilos > 0 ? kilos : fallbackKilos);
  }

  double _extractDesgloseKilos(List<CategoriaDesglose> desglose, String match) {
    final lower = match.toLowerCase();
    for (final item in desglose) {
      if (item.categoria.toLowerCase().contains(lower)) {
        return item.kilos;
      }
    }
    return 0;
  }

  Map<String, double> _calculateFileteoTotals(ReporteAreaDetalle area) {
    double sumFileteado = 0;
    double sumDesmusado = 0;
    double sumControl = 0;
    double sumAprove = 0;
    double sumProducto = 0;

    for (final cuadrilla in area.cuadrillas) {
      final desglose = cuadrilla.desglose;
      sumFileteado +=
          _getDesgloseOrDefault(desglose, 'filete', cuadrilla.kilos);
      sumDesmusado += _getDesgloseOrDefault(desglose, 'desm', 0);
      sumControl += _getDesgloseOrDefault(desglose, 'control', 0);
      sumAprove += _getDesgloseOrDefault(desglose, 'aprove', 0);
      sumProducto += _getDesgloseOrDefault(desglose, 'producto', 0);
    }

    return {
      'fileteado': sumFileteado,
      'desmusado': sumDesmusado,
      'control': sumControl,
      'aprove': sumAprove,
      'producto': sumProducto,
    };
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

  // Manejo robusto de valores inválidos/infinito
  String _formatLbs(double lbs) {
    if (lbs == 0 || lbs.isNaN || lbs.isInfinite) {
      return '';
    }
    return lbs.toStringAsFixed(2);
  }

  double _toLbs(double kilos) => kilos * 2.20462;

  // 🔹 AHORA SOLO ES FILETEROS EXACTO
  bool _isFileterosArea(ReporteAreaDetalle area) {
    final normalized = area.nombre.toLowerCase().trim();
    return normalized == 'fileteros';
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
