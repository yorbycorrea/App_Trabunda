import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:scanner_trabunda/data/drift/app_database.dart';

String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

pw.TableRow buildTableRow(List<String> cells, {bool isHeader = false}) {
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
                fontSize: isHeader ? 9 : 5,
                fontWeight:
                    isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        )
        .toList(),
  );
}

String formatIntegrantesCodes(List<IntegranteDetalle> list) {
  final codes = list
      .map((e) => e.code ?? '')
      .where((e) => e.trim().isNotEmpty)
      .toList();
  return codes.join(', ');
}

String formatLbs(double lbs) {
  if (lbs <= 0 || lbs.isNaN) return '';
  return lbs.toStringAsFixed(2);
}

double toLbs(double kilos) => kilos * 2.20462;

pw.Widget headerValueRow(String label, String value) {
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

pw.Widget labelValueRow(String label, String value) {
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
