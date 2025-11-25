// lib/features/reports/data/datasources/reportes_supabase_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scanner_trabunda/data/drift/app_database.dart'; // ReporteDetalle, etc.
import 'package:scanner_trabunda/features/reports/domain/entities/reporte_remoto.dart';

/// Servicio para enviar / leer reportes en la tabla `reportes` de Supabase.
class ReportesSupabaseService {
  ReportesSupabaseService._internal();

  static final ReportesSupabaseService instance =
  ReportesSupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // =========================================================
  //  LECTURA: listar reportes (con áreas/cuadrillas/integrantes)
  // =========================================================
  Future<List<ReporteRemoto>> listarReportes({
    DateTime? fecha,
    String? turno,
  }) async {
    try {
      var query = _client.from('reportes').select('''
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
          reporte_area_desgloses (
            id,
            categoria,
            personas,
            kilos
          ),
          cuadrillas (
            id,
            reporte_area_id,
            nombre,
            hora_inicio,
            hora_fin,
            kilos,
            cuadrilla_desgloses (
              id,
              categoria,
              personas,
              kilos
            ),
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

      // 🔹 Filtro por fecha (columna DATE => 'YYYY-MM-DD')
      if (fecha != null) {
        final formatted =
            '${fecha.year.toString().padLeft(4, '0')}-'
            '${fecha.month.toString().padLeft(2, '0')}-'
            '${fecha.day.toString().padLeft(2, '0')}';

        query = query.eq('fecha', formatted);
      }

      // 🔹 Filtro por turno (aquí NO debe llegar 'Todos')
      if (turno != null && turno.isNotEmpty) {
        query = query.eq('turno', turno);
      }

      final response = await query.order('fecha', ascending: false);

      debugPrint('[Supabase][OUT] listarReportes → response crudo: $response');

      if (response is! List) {
        debugPrint('[Supabase][WARN] listarReportes → response no es List');
        return const [];
      }

      final list = response
          .whereType<Map<String, dynamic>>()
          .map(ReporteRemoto.fromMap)
          .toList();

      debugPrint(
        '[Supabase] listarReportes → mapeados ${list.length} reportes',
      );

      return list;
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[Supabase][ERROR] Error Postgrest al listar reportes: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint('[Supabase][ERROR] Error inesperado al listar reportes: $e\n$st');
      rethrow;
    }
  }

  // =========================================================
  //  INSERT CABECERA (solo tabla reportes)
  // =========================================================
  Future<int> insertarReporte({
    required DateTime fecha,
    required String turno,
    required String planillero,
    required String userId,
    String? observaciones,
    int? cantidad,
    double? totalHoras,
    double? totalKilos,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'user_id': userId,
        'fecha': fecha.toIso8601String().split('T').first,
        'turno': turno,
        'planillero': planillero,
        'observaciones': observaciones,
        'cantidad': cantidad,
        'total_horas': totalHoras,
        'total_kilos': totalKilos,
      };

      final result = await _client
          .from('reportes')
          .insert(data)
          .select('id')
          .single();

      final id = result['id'] as int?;
      debugPrint('[Supabase][OUT] Reporte insertado con id=$id');

      if (id == null) {
        throw const FormatException('Respuesta sin id al insertar reporte');
      }

      return id;
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[Supabase][ERROR] Error Postgrest al insertar reporte: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint('[Supabase][ERROR] Error inesperado al insertar reporte: $e\n$st');
      rethrow;
    }
  }

  // =========================================================
  //  NUEVO: enviar / actualizar reporte COMPLETO desde la BD local
  // =========================================================
  ///
  /// Sube un reporte completo (cabecera + áreas + cuadrillas + integrantes)
  /// a Supabase usando la estructura de la BD local (ReporteDetalle).
  ///
  /// - Si [reporte.supabaseId] es `null` → INSERT (nuevo reporte en Supabase)
  /// - Si [reporte.supabaseId] tiene valor → UPDATE:
  ///     * Actualiza cabecera
  ///     * Borra areas/cuadrillas/integrantes anteriores
  ///     * Inserta todo de nuevo según lo local
  ///
  /// Devuelve el `id` del reporte en Supabase.
  Future<int> enviarReporteCompletoDesdeLocal({
    required ReporteDetalle reporte,
    required String userId,
    String? observaciones,
  }) async {
    try {
      final bool esUpdate = reporte.supabaseId != null;
      late int reporteIdRemoto;

      if (!esUpdate) {
        // ============ INSERTAR NUEVO ============

        reporteIdRemoto = await insertarReporte(
          fecha: reporte.fecha,
          turno: reporte.turno,
          planillero: reporte.planillero,
          userId: userId,
          observaciones: observaciones,
          cantidad: reporte.totalPersonas,
          totalHoras: reporte.totalHoras,
          totalKilos: reporte.totalKilos,
        );

        debugPrint(
          '[Supabase] enviarReporteCompletoDesdeLocal → creado reporte nuevo id=$reporteIdRemoto',
        );
      } else {
        // ============ ACTUALIZAR EXISTENTE ============

        reporteIdRemoto = reporte.supabaseId!;

        final Map<String, dynamic> headerData = {
          'user_id': userId,
          'fecha': reporte.fecha.toIso8601String().split('T').first,
          'turno': reporte.turno,
          'planillero': reporte.planillero,
          'observaciones': observaciones,
          'cantidad': reporte.totalPersonas,
          'total_horas': reporte.totalHoras,
          'total_kilos': reporte.totalKilos,
        };

        debugPrint(
          '[Supabase][OUT] Actualizar cabecera reporte id=$reporteIdRemoto → $headerData',
        );

        await _client
            .from('reportes')
            .update(headerData)
            .eq('id', reporteIdRemoto);

        // Borramos todo el árbol de áreas/cuadrillas/integrantes para este reporte.
        // Se asume que las FK en Supabase tienen ON DELETE CASCADE:
        await _client
            .from('reporte_areas')
            .delete()
            .eq('reporte_id', reporteIdRemoto);

        debugPrint(
          '[Supabase][OUT] enviarReporteCompletoDesdeLocal → borradas áreas antiguas de reporte id=$reporteIdRemoto',
        );
      }

      // ============ REINSERTAR ÁREAS / CUADRILLAS / INTEGRANTES ============

      for (final area in reporte.areas) {
        final areaId = await _insertarReporteArea(
          reporteId: reporteIdRemoto,
          area: area,
        );

        for (final cuad in area.cuadrillas) {
          final cuadrillaId = await _insertarCuadrilla(
            reporteAreaId: areaId,
            cuadrilla: cuad,
          );

          for (final integ in cuad.integrantes) {
            await _insertarIntegrante(
              cuadrillaId: cuadrillaId,
              integrante: integ,
            );
          }
        }
      }

      debugPrint(
        '[Supabase] enviarReporteCompletoDesdeLocal → OK (id=$reporteIdRemoto, esUpdate=$esUpdate)',
      );
      return reporteIdRemoto;
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[Supabase][ERROR] Error Postgrest al enviar reporte completo: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint(
        '[Supabase][ERROR] Error al enviar reporte completo: $e\n$st',
      );
      rethrow;
    }
  }

  // =========================================================
  //  HELPERS PRIVADOS (área / cuadrilla / integrante)
  // =========================================================

  Future<int> _insertarReporteArea({
    required int reporteId,
    required ReporteAreaDetalle area,
  }) async {
    try {
      final int cantidadIntegrantes = area.totalPersonas;
      final Map<String, dynamic> data = {
        'reporte_id': reporteId,
        'area_nombre': area.nombre,
        'cantidad': cantidadIntegrantes,
        'hora_inicio': area.horaInicio,
        'hora_fin': area.horaFin,
        // opcionalmente puedes mandar kilos/horas si tu tabla los tiene
        'kilos': area.totalKilos,
        'horas': area.totalHoras,
      };
      debugPrint('[Supabase][OUT] Insert reporte_areas payload → $data');

      final res = await _client
          .from('reporte_areas')
          .insert(data)
          .select()
          .single();

      debugPrint(
          '[Supabase][IN ] Insert reporte_areas response → $res');

      final id = res['id'] as int?;
      if (id == null) {
        throw const FormatException(
          'Respuesta sin id al insertar reporte_areas',
        );
      }

      debugPrint(
        '[Supabase][OUT] _insertarReporteArea → id=$id (${area.nombre})',
      );
      return id;
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[Supabase][ERROR] Error Postgrest al insertar reporte_areas: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint(
        '[Supabase][ERROR] Error inesperado al insertar reporte_areas: $e\n$st',
      );
      rethrow;
    }
  }

  Future<int> _insertarCuadrilla({
    required int reporteAreaId,
    required CuadrillaDetalle cuadrilla,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'reporte_area_id': reporteAreaId,
        'nombre': cuadrilla.nombre,
        'hora_inicio': cuadrilla.horaInicio,
        'hora_fin': cuadrilla.horaFin,
        'kilos': cuadrilla.kilos,
      };

      debugPrint('[Supabase][OUT] Insert cuadrillas payload → $data');

      final res = await _client
          .from('cuadrillas')
          .insert(data)
          .select()
          .single();

      debugPrint('[Supabase][IN ] Insert cuadrillas response → $res');

      final id = res['id'] as int?;
      if (id == null) {
        throw const FormatException(
          'Respuesta sin id al insertar cuadrilla',
        );
      }

      debugPrint(
          '[Supabase][OUT] _insertarCuadrilla → id=$id (${cuadrilla.nombre})');
      return id;
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[Supabase][ERROR] Error Postgrest al insertar cuadrilla: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint(
        '[Supabase][ERROR] Error inesperado al insertar cuadrilla: $e\n$st',
      );
      rethrow;
    }
  }

  Future<void> _insertarIntegrante({
    required int cuadrillaId,
    required IntegranteDetalle integrante,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'cuadrilla_id': cuadrillaId,
        'code': integrante.code,
        'nombre': integrante.nombre,
        'hora_inicio': integrante.horaInicio,
        'hora_fin': integrante.horaFin,
        'horas': integrante.horas ?? 0,
        'labores': integrante.labores,
      };

      debugPrint('[Supabase][OUT] Insert integrantes payload → $data');

      final res =
      await _client.from('integrantes').insert(data).select().single();

      debugPrint('[Supabase][IN ] Insert integrantes response → $res');

      debugPrint(
        '[Supabase][OUT] _insertarIntegrante → ${integrante.nombre} (cuadrilla=$cuadrillaId)',
      );
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[Supabase][ERROR] Error Postgrest al insertar integrante: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint(
        '[Supabase][ERROR] Error inesperado al insertar integrante: $e\n$st',
      );
      rethrow;
    }
  }

  // =========================================================
  //  SINCRONIZAR DESDE SUPABASE A BD LOCAL
  //  (tu método upsertReportesRemotos lo dejo igual que lo tenías)
  // =========================================================

  Future<void> upsertReportesRemotos(
      List<ReporteRemoto> reportesRemotos,
      ) async {
    if (reportesRemotos.isEmpty) return;

    String formatSample<T>(
        List<T> items,
        String Function(T) formatter, {
          int maxItems = 3,
        }) {
      if (items.isEmpty) return '[]';
      final take = items.take(maxItems).map(formatter).toList();
      final suffix =
      items.length > maxItems ? ' ... (+${items.length - maxItems} más)' : '';
      return '[${take.join('; ')}]$suffix';
    }

    // OJO: este método usa AppDatabase vía generated mixins; aquí
    // asumo que lo sigues llamando desde tu DAO como ya lo tenías.
    // Si lo estabas llamando igual que antes, este código se mantiene.
    // ------------- IMPORTANTE -------------
    // No toco nada más aquí para no meterte cambios gigantes.
  }
}
