// lib/services/pdf_storage_service.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfStorageService {
  PdfStorageService._();
  static final PdfStorageService instance = PdfStorageService._();

  static const String _bucketName = 'reports_pdf'; // el nombre que creaste en Storage

  SupabaseClient get _client => Supabase.instance.client;

  /// Sube el PDF al bucket y actualiza la fila correspondiente en `reportes`.
  ///
  /// [reporteId] = id de la tabla `public.reportes` en Supabase.
  Future<void> subirPdfDeReporte({
    required int reporteId,
    required Uint8List bytes,
  }) async {
    final path = 'reportes/$reporteId/reporte_$reporteId.pdf';

    // 1) Subir PDF a Storage
    await _client.storage.from(_bucketName).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        upsert: true, // si ya existe, lo reemplaza
      ),
    );

    // 2) Obtener URL (si el bucket es público)
    final publicUrl = _client.storage.from(_bucketName).getPublicUrl(path);

    // 3) Actualizar la tabla `reportes`
    await _client
        .from('reportes')
        .update({
      'pdf_path': path,
      'pdf_url': publicUrl,
      'pdf_generated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', reporteId);
  }
}
