import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/report_pdf_service.dart';


/// ===============================================================
///  MODELO DE CADA TRABAJADOR (Apoyo por Horas)
/// ===============================================================
class ApoyoHorasItem {
  final String area;
  final String codigo;
  final String nombre;
  final String horaInicio;
  final String horaFin;
  final double horas;
  final String? tarea;

  ApoyoHorasItem({
    required this.area,
    required this.codigo,
    required this.nombre,
    required this.horaInicio,
    required this.horaFin,
    required this.horas,
    this.tarea,
  });
}

/// ===============================================================
///  GENERADOR DEL PDF — FORMATO EXACTO GG-JO-F-15
/// ===============================================================
class ApoyosHorasPdfGenerator {
  Future<ReportPdfResult> generateApoyosHorasReport({
    required DateTime fecha,
    required String turno,
    required String planillero,
    required String jefeTurno,
    required String supervisor,
    required List<ApoyoHorasItem> items,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(16),
        build: (context) => [
          _buildHeader(fecha),
          pw.SizedBox(height: 10),
          _buildSectionTitle('PERSONAL POR HORAS – APOYOS'),
          pw.SizedBox(height: 8),
          _buildInfoTable(fecha, turno, planillero, jefeTurno, supervisor),
          pw.SizedBox(height: 16),
          _buildApoyosTable(items),
          pw.SizedBox(height: 16),
          _buildFirmas(planillero, jefeTurno, supervisor),
        ],
      ),
    );

    // ===== GUARDAR EL PDF EN ARCHIVOS =====
    final directory = await getApplicationDocumentsDirectory();
    final filename =
        'APOYOS_HORAS_${fecha.toIso8601String().replaceAll(":", "-")}.pdf';
    final file = File(p.join(directory.path, filename));
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);

    return ReportPdfResult(
      bytes: Uint8List.fromList(bytes),
      file: file,
      filename: filename,
    );
  }

  /// ===============================================================
  /// ENCABEZADO — IGUAL AL FORMATO ORIGINAL GG-JO-F-15
  /// ===============================================================
  pw.Widget _buildHeader(DateTime fecha) {
    final dateStr =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TRABUNDA SAC',
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text('Código: GG-JO-F-15'),
                pw.Text('Versión: 02'),
                pw.Text('Fecha emisión: Octubre 2020'),
              ],
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Center(
              child: pw.Text(
                'PERSONAL POR HORAS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Fecha: $dateStr',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ===============================================================
  /// SUBTÍTULO
  /// ===============================================================
  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// ===============================================================
  /// TABLA DE INFORMACIÓN GENERAL
  /// ===============================================================
  pw.Widget _buildInfoTable(
      DateTime fecha,
      String turno,
      String planillero,
      String jefeTurno,
      String supervisor,
      ) {
    final f =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        _rowInfo('Fecha', f),
        _rowInfo('Turno', turno),
        _rowInfo('Planillero', planillero),
        _rowInfo('Jefe de turno', jefeTurno),
        _rowInfo('Supervisor', supervisor),
      ],
    );
  }

  pw.TableRow _rowInfo(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(label,
              style:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  /// ===============================================================
  /// TABLA PRINCIPAL DE APOYOS — EXACTA AL FORMATO
  /// ===============================================================
  pw.Widget _buildApoyosTable(List<ApoyoHorasItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // AREA
        1: const pw.FlexColumnWidth(2), // CÓDIGO
        2: const pw.FlexColumnWidth(4), // NOMBRE
        3: const pw.FlexColumnWidth(2), // HORA INICIO
        4: const pw.FlexColumnWidth(2), // HORA FIN
        5: const pw.FlexColumnWidth(2), // HORAS
        6: const pw.FlexColumnWidth(3), // TAREA / AREA
      },
      children: [
        // CABECERA EXACTA DEL FORMATO
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _cellHeader('AREA'),
            _cellHeader('CÓDIGO'),
            _cellHeader('NOMBRE DEL TRABAJADOR'),
            _cellHeader('H_INI'),
            _cellHeader('H_FIN'),
            _cellHeader('HRS'),
            _cellHeader('TAREA / AREA'),
          ],
        ),

        // FILAS
        for (final i in items) _buildItemRow(i),
      ],
    );
  }

  pw.TableRow _buildItemRow(ApoyoHorasItem i) {
    return pw.TableRow(
      children: [
        _cell(i.area),
        _cell(i.codigo),
        _cell(i.nombre),
        _cell(i.horaInicio),
        _cell(i.horaFin),
        _cell(i.horas.toStringAsFixed(2)),
        _cell(i.tarea ?? ''),
      ],
    );
  }

  pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// ===============================================================
  /// FIRMAS — EXACTO AL BLOQUE FINAL DEL GG-JO-F-15
  /// ===============================================================
  pw.Widget _buildFirmas(
      String planillero,
      String jefeTurno,
      String supervisor,
      ) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 18),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _firmaBlock('Planillero', planillero),
            _firmaBlock('Jefe de turno', jefeTurno),
            _firmaBlock('Supervisor', supervisor),
          ],
        ),
      ],
    );
  }

  pw.Widget _firmaBlock(String cargo, String nombre) {
    return pw.Container(
      width: 150,
      child: pw.Column(
        children: [
          pw.Text(cargo,
              style:
              pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 30),
          pw.Container(
            height: 1,
            color: PdfColors.black,
          ),
          pw.Text(nombre, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
