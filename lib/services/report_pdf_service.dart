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
  // GENERAR PDF DE ÁREA FILETEROS
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

    // Nombre de archivo sin barras: reporte_fileteros_16-11-2025_fileteros.pdf
    final filename = _buildFilename(
      reporte,
      area,
      prefix: 'reporte_fileteros',
    );

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
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
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

    // Usamos _buildFilename para evitar caracteres inválidos
    final filename = _buildFilename(
      reporte,
      area,
      prefix: 'reporte_recepcion',
    );

    final file = await _persist(bytes, filename);

    return ReportPdfResult(bytes: bytes, file: file, filename: filename);
  }

  // ============================================================
  // GENERAR PDF DE SANEAMIENTO
  // ============================================================

  Future<ReportPdfResult> generateSaneamientoReport({
    required ReporteDetalle reporte,
    required ReporteAreaDetalle area,
  }) async {
    // El usuario logeado (planillero) es el que elabora el informe
    final elaboradoPor = reporte.planillero.trim();
    final formattedDate = _formatDate(reporte.fecha);
    final workers = _buildSaneamientoWorkers(area);

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
                _buildSaneamientoHeader(
                  area: area,
                  formattedDate: formattedDate,
                  turno: reporte.turno,
                  supervisor: elaboradoPor,
                  pageText: '1 de 1',
                ),
                pw.SizedBox(height: 12),
                _buildSaneamientoTable(workers),
                pw.SizedBox(height: 16),
                _buildFooterSignaturesSaneamiento(elaboradoPor),
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
      prefix: 'reporte_saneamiento',
    );

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

    // Páginas siguientes: Anexo de trabajadores
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
                  _headerValueRow('Código', 'TRABUNDA SAC -GG-JO-F-01'),
                  _headerValueRow('Versión', '02'),
                  _headerValueRow('Fecha Emisión', 'Octubre 2020'),
                  _headerValueRow('Página', '1 de 1'),
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
                  _labelValueRow('HORA INICIO', '_____'),
                  _labelValueRow('HORA FINAL', '_____'),
                ],
              ),
              pw.Column(
                children: [
                  _labelValueRow('FECHA', formattedDate),
                  _labelValueRow('TURNO', turno),
                ],
              ),
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
      _tableRow(['N°', 'CÓDIGO', 'PRODUCTO', 'TOTAL'], isHeader: true),
    ];

    double totalKilos = 0;
    const maxRows = 12;

    for (var i = 0; i < maxRows; i++) {
      if (i < area.cuadrillas.length) {
        final q = area.cuadrillas[i];
        totalKilos += q.kilos;

        rows.add(
          _tableRow(
            [
              (i + 1).toString().padLeft(2, '0'),
              _formatIntegrantesCodes(q.integrantes),
              '',
              _formatLbs(_toLbs(q.kilos)),
            ],
          ),
        );
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
              _fileterosCell(
                _formatLbs(_getDesgloseOrDefault(d, 'filete', c.kilos)),
              ),
              _fileterosCell(
                _formatLbs(_getDesgloseOrDefault(d, 'desu', 0)),
              ),
              _fileterosCell(
                _formatLbs(_getDesgloseOrDefault(d, 'corta', 0)),
              ),
              _fileterosCell(
                _formatLbs(_getDesgloseOrDefault(d, 'secci', 0)),
              ),
              _fileterosCell(
                _formatLbs(_getDesgloseOrDefault(d, 'repro', 0)),
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

  pw.Widget _buildFooterSignaturesSaneamiento(String elaboradoPor) {
    pw.Widget box(String label) {
      return pw.Container(
        width: 180,
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
        // Persona que elaboró el informe
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                'PERSONA QUE ELABORÓ EL INFORME: ',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  height: 20,
                  decoration: pw.BoxDecoration(
                    border: const pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.black,
                        width: 1,
                      ),
                    ),
                  ),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    elaboradoPor,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        // Firmas
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
          children: [
            box('SUPERVISOR'),
            box('PRODUCCIÓN'),
          ],
        ),
      ],
    );
  }


  // ============================================================
  // LAYOUT SANEAMIENTO
  // ============================================================

  // ============================================================
  // LAYOUT SANEAMIENTO
  // ============================================================

  pw.Widget _buildSaneamientoHeader({
    required ReporteAreaDetalle area,
    required String formattedDate,
    required String turno,
    required String supervisor,
    required String pageText,
  }) {
    const String codigoFormato = 'COD-SAN-001'; // cámbialo al código real

    pw.Widget smallInfo(String label, String value) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Primera franja: empresa + cuadro de información del formato
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TRABUNDA SAC',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'FORMATO : SANEAMIENTO',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              width: 190,
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  smallInfo('Código del formato:', codigoFormato),
                  smallInfo('Versión:', '2'),
                  smallInfo('Fecha emisión:', formattedDate),
                  smallInfo('Página:', pageText),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(height: 16, thickness: 1.1),
        // Datos del reporte
        _labelValueRow('Área:', area.nombre),
        pw.SizedBox(height: 4),
        _labelValueRow('Supervisor:', supervisor),
        pw.SizedBox(height: 4),
        _labelValueRow('Turno:', turno),
        pw.SizedBox(height: 4),
        _labelValueRow('Fecha:', formattedDate),
      ],
    );
  }

// tabla saneamiento
  pw.Widget _buildSaneamientoTable(List<_SaneamientoWorkerRow> workers) {
    final headers = [
      'ITEM',
      'CÓDIGO',
      'APELLIDOS Y NOMBRES',
      'HORA INICIAL',
      'HORA FINAL',
      'TOTAL HORAS',
      'LABORES REALIZADAS',
    ];

    final rows = <List<String>>[];

    for (var i = 0; i < workers.length; i++) {
      final w = workers[i];
      rows.add([
        '${i + 1}',
        w.codigo,
        w.nombre,
        w.horaInicio,
        w.horaFin,
        w.totalHoras,
        w.labores,
      ]);
    }

    return pw.Table.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FlexColumnWidth(0.7),
        1: const pw.FlexColumnWidth(1.0),
        2: const pw.FlexColumnWidth(2.4),
        3: const pw.FlexColumnWidth(1.1),
        4: const pw.FlexColumnWidth(1.1),
        5: const pw.FlexColumnWidth(1.1),
        6: const pw.FlexColumnWidth(2.6),
      },
      cellHeight: 24,
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
    );
  }


  List<_SaneamientoWorkerRow> _buildSaneamientoWorkers(
      ReporteAreaDetalle area,
      ) {
    final rows = <_SaneamientoWorkerRow>[];

    final horaAreaInicio = (area.horaInicio ?? '').trim();
    final horaAreaFin = (area.horaFin ?? '').trim();

    final actividadesArea = area.desglose.isNotEmpty
        ? area.desglose.map((d) => d.categoria).join(', ')
        : '';

    for (final cuadrilla in area.cuadrillas) {
      final horaCuadInicio = (cuadrilla.horaInicio ?? '').trim();
      final horaCuadFin = (cuadrilla.horaFin ?? '').trim();

      final horaInicio = horaCuadInicio.isNotEmpty ? horaCuadInicio : horaAreaInicio;
      final horaFin = horaCuadFin.isNotEmpty ? horaCuadFin : horaAreaFin;
      final totalHoras = _calculateTotalHoras(horaInicio, horaFin);

      final actividadesCuadrilla = cuadrilla.desglose.isNotEmpty
          ? cuadrilla.desglose.map((d) => d.categoria).join(', ')
          : actividadesArea;

      final actividadTexto = actividadesCuadrilla.isNotEmpty
          ? actividadesCuadrilla
          : cuadrilla.nombre;

      if (cuadrilla.integrantes.isEmpty) {
        rows.add(
          _SaneamientoWorkerRow(
            codigo: '',
            nombre: cuadrilla.nombre,
            horaInicio: horaInicio,
            horaFin: horaFin,
            totalHoras: totalHoras,
            labores: actividadTexto,
          ),
        );
      } else {
        for (final integrante in cuadrilla.integrantes) {
          rows.add(
            _SaneamientoWorkerRow(
              codigo: integrante.code ?? '',
              nombre: integrante.nombre,
              horaInicio: horaInicio,
              horaFin: horaFin,
              totalHoras: totalHoras,
              labores: actividadTexto,
            ),
          );
        }
      }
    }

    // Si no hay cuadrillas pero sí cantidad, se generan filas genéricas
    if (rows.isEmpty && area.cantidad > 0) {
      final actividadFallback =
      actividadesArea.isNotEmpty ? actividadesArea : area.nombre;

      final totalHorasArea = _calculateTotalHoras(horaAreaInicio, horaAreaFin);

      for (var i = 0; i < area.cantidad; i++) {
        rows.add(
          _SaneamientoWorkerRow(
            codigo: '',
            nombre: 'Trabajador ${i + 1}',
            horaInicio: horaAreaInicio,
            horaFin: horaAreaFin,
            totalHoras: totalHorasArea,
            labores: actividadFallback,
          ),
        );
      }
    }

    return rows;
  }


  String _formatHoraRange(String? inicio, String? fin) {
    final start = (inicio ?? '').trim();
    final end = (fin ?? '').trim();

    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return 'Fin: $end';
    if (end.isEmpty) return 'Inicio: $start';
    return '$start - $end';
  }

  String _calculateTotalHoras(String horaInicio, String horaFin) {
    final start = horaInicio.trim();
    final end = horaFin.trim();

    if (start.isEmpty || end.isEmpty) return '';

    try {
      final sParts = start.split(':');
      final eParts = end.split(':');
      if (sParts.length < 2 || eParts.length < 2) return '';

      final s = Duration(
        hours: int.parse(sParts[0]),
        minutes: int.parse(sParts[1]),
      );
      final e = Duration(
        hours: int.parse(eParts[0]),
        minutes: int.parse(eParts[1]),
      );

      final diff = e - s;
      if (diff.isNegative) return '';

      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      final hh = h.toString().padLeft(2, '0');
      final mm = m.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return '';
    }
  }



  // ============================================================
  // ANEXO TABLA DE TRABAJADORES
  // ============================================================

  List<Map<String, String>> _buildFileterosWorkers(
      ReporteAreaDetalle area,
      ) {
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
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: 9),
      border: pw.TableBorder.all(color: PdfColors.black),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
    );
  }

  // ============================================================
  // UTILITARIOS
  // ============================================================

  pw.TableRow _tableRow(List<String> cells, {bool isHeader = false}) {
    return pw.TableRow(
      decoration:
      isHeader ? pw.BoxDecoration(color: PdfColors.grey200) : null,
      children: cells
          .map(
            (c) => pw.Container(
          padding: const pw.EdgeInsets.all(4),
          alignment: pw.Alignment.center,
          child: pw.Text(
            c,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight:
              isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
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
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 9),
          ),
        ],
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
          value,
          style: pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';

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
}

class _SaneamientoWorkerRow {
  final String codigo;
  final String nombre;
  final String horaInicio;
  final String horaFin;
  final String totalHoras;
  final String labores;

  const _SaneamientoWorkerRow({
    required this.codigo,
    required this.nombre,
    required this.horaInicio,
    required this.horaFin,
    required this.totalHoras,
    required this.labores,
  });
}

