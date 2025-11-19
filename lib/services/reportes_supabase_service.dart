import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para enviar reportes a la tabla `reportes` de Supabase.
class ReportesSupabaseService {
  ReportesSupabaseService._internal();

  static final ReportesSupabaseService instance =
  ReportesSupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Inserta un solo reporte en la tabla `reportes`.
  ///
  /// Devuelve el `id` generado en Supabase o `null` si falló.
  Future<int?> insertarReporte({
    required DateTime fecha,
    required String turno,
    required String planillero,
    required String userId,
    String? observaciones,
  }) async {
    try {
      final data = {
        'user_id': userId,
        // solo la parte de fecha para columna tipo DATE
        'fecha': fecha.toIso8601String().split('T').first,
        'turno': turno,
        'planillero': planillero,
        'observaciones': observaciones,
      };

      // `select().single()` para obtener el id insertado
      final result = await _client
          .from('reportes')
          .insert(data)
          .select('id')
          .single();

      final id = result['id'] as int?;
      debugPrint('[Supabase] Reporte insertado con id=$id');
      return id;
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[Supabase] Error Postgrest al insertar reporte: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow; // lo dejamos subir para que la UI lo pueda mostrar
    } catch (e, st) {
      debugPrint('[Supabase] Error inesperado al insertar reporte: $e\n$st');
      rethrow;
    }
  }
}
