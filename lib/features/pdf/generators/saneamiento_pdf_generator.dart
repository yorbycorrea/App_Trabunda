import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:scanner_trabunda/data/drift/app_database.dart';

import 'package:scanner_trabunda/features/pdf/generators/area_pdf_generator.dart';
import 'package:scanner_trabunda/features/pdf/generators/pdf_generator_utils.dart';

class SaneamientoPdfGenerator implements AreaPdfGenerator {
  SaneamientoPdfGenerator({
    required this.reporte,
    required this.area,
  });

  final ReporteDetalle reporte;
  final ReporteAreaDetalle area;

  @override
  Future<Uint8List> build() async {
    final elaboradoPor = reporte.planillero.trim();
    final formattedDate = formatDate(reporte.fecha);
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

    return doc.save();
  }

  pw.Widget _buildSaneamientoHeader({
    required ReporteAreaDetalle area,
    required String formattedDate,
    required String turno,
    required String supervisor,
    required String pageText,
  }) {
    const String codigoFormato = 'COD-SAN-001';

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
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 120,
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
            pw.Expanded(
              child: pw.Container(
                height: 100,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PROGRAMA SEMANAL DE LIMPIEZA Y SANEAMIENTO',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    smallInfo('Área:', area.nombre),
                    smallInfo('Supervisor:', supervisor),
                    smallInfo('Turno:', turno),
                    smallInfo('Fecha:', formattedDate),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Container(
              width: 130,
              padding: const pw.EdgeInsets.all(8),
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
        labelValueRow('Área:', area.nombre),
        pw.SizedBox(height: 4),
        labelValueRow('Supervisor:', supervisor),
        pw.SizedBox(height: 4),
        labelValueRow('Turno:', turno),
        pw.SizedBox(height: 4),
        labelValueRow('Fecha:', formattedDate),
      ],
    );
  }

  pw.Widget _buildSaneamientoTable(List<_SaneamientoWorkerRow> workers) {
    final headers = [
      'Nº',
      'CÓDIGO',
      'APELLIDOS Y NOMBRES',
      'H.Ini',
      'H.Fin',
      'Tot. Hrs',
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
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 6),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FlexColumnWidth(0.4),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(3.2),
        3: const pw.FlexColumnWidth(0.6),
        4: const pw.FlexColumnWidth(0.6),
        5: const pw.FlexColumnWidth(0.7),
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

    for (final cuadrilla in area.cuadrillas) {
      if (cuadrilla.integrantes.isEmpty) continue;

      for (final integrante in cuadrilla.integrantes) {
        final hi = (integrante.horaInicio ?? '').trim();
        final hf = (integrante.horaFin ?? '').trim();

        String totalHoras;
        if (integrante.horas != null) {
          final d = Duration(
            minutes: (integrante.horas! * 60).round(),
          );
          final h = d.inHours;
          final m = d.inMinutes % 60;
          totalHoras =
              '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
        } else {
          totalHoras = _calculateTotalHoras(hi, hf);
        }

        final nombreUpper = (integrante.nombre).toUpperCase();

        final rawLabores = (integrante.labores == null ||
                integrante.labores!.trim().isEmpty)
            ? 'Saneamiento'
            : integrante.labores!.trim();

        final laboresUpper = rawLabores.toUpperCase();

        rows.add(
          _SaneamientoWorkerRow(
            codigo: integrante.code ?? '',
            nombre: nombreUpper,
            horaInicio: hi,
            horaFin: hf,
            totalHoras: totalHoras,
            labores: laboresUpper,
          ),
        );
      }
    }

    return rows;
  }

  // TODO: reutilizar cuando el PDF de saneamiento requiera mostrar rangos.
  // ignore: unused_element
  String _formatHoraRange(String? inicio, String? fin) {
    final start = (inicio ?? '').trim();
    final end = (fin ?? '').trim();

    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return 'Fin: $end';
    if (end.isEmpty) return 'Inicio: $start';
    // TODO: reutilizar cuando el PDF de saneamiento requiera mostrar rangos.
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
}

class _SaneamientoWorkerRow {
  const _SaneamientoWorkerRow({
    required this.codigo,
    required this.nombre,
    required this.horaInicio,
    required this.horaFin,
    required this.totalHoras,
    required this.labores,
  });

  final String codigo;
  final String nombre;
  final String horaInicio;
  final String horaFin;
  final String totalHoras;
  final String labores;
}
