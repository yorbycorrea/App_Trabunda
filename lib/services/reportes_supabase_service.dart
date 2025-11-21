import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reporte_remoto.dart';

/// Servicio para enviar reportes a la tabla `reportes` de Supabase.
class ReportesSupabaseService {
  ReportesSupabaseService._internal();

  static final ReportesSupabaseService instance =
  ReportesSupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene reportes (con áreas y cuadrillas) filtrados por usuario,
  /// fecha exacta y turno.
  Future<List<ReporteRemoto>> listarReportes({
    required String userId,
    DateTime? fecha,
    String? turno,
  }) async {
    try {
      final query = _client.from('reportes').select('''
            id,
            fecha,
            turno,
            planillero,
            user_id,
            observaciones,
            reporte_areas (
              id,
              reporte_id,
              area_nombre,
              cantidad,
              hora_inicio,
              hora_fin,
              cuadrillas (
                id,
                reporte_area_id,
                nombre,
                hora_inicio,
                hora_fin,
                kilos,
                integrantes (
                  id,
                  cuadrilla_id,
                  code,
                  nombre,
                  hora_inicio,
                  hora_fin,
                  horas,
                  labores
                )
              )
            )
          ''');

      query.eq('user_id', userId);

      if (fecha != null) {
        final formatted = fecha.toIso8601String().split('T').first;
        query.eq('fecha', formatted);
      }

      if (turno != null && turno.isNotEmpty) {
        query.eq('turno', turno);
      }

      final response = await query.order('fecha', ascending: false);

      if (response is! List) {
        return const [];
      }

      return response
          .whereType<Map<String, dynamic>>()
          .map(ReporteRemoto.fromMap)
          .toList();
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[Supabase] Error Postgrest al listar reportes: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint('[Supabase] Error inesperado al listar reportes: $e\n$st');
      rethrow;
    }
  }

  /// Inserta un solo reporte en la tabla `reportes`.
  ///
  /// Devuelve el `id` generado en Supabase o `null` si falló.
  Future<int> insertarReporte({
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
      if (id == null) {
        throw const FormatException('Respuesta sin id al insertar reporte');
      }

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
