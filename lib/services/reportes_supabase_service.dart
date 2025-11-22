// lib/services/reportes_supabase_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reporte_remoto.dart';
import '../data/app_database.dart'; // Para ReporteDetalle, ReporteAreaDetalle, etc.

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
      // Usamos `var` para que el tipo se infiera y permita encadenar eq, order, etc.
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

      debugPrint('[Supabase] listarReportes → response crudo: $response');

      if (response is! List) {
        debugPrint('[Supabase] listarReportes → response no es List');
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
        '[Supabase] Error Postgrest al listar reportes: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint('[Supabase] Error inesperado al listar reportes: $e\n$st');
      rethrow;
    }
  }

  // =========================================================
  //  INSERT CABECERA (solo tabla reportes) - aún la usamos
  // =========================================================
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
        'fecha': fecha.toIso8601String().split('T').first,
        'turno': turno,
        'planillero': planillero,
        'observaciones': observaciones,
      };

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
      rethrow;
    } catch (e, st) {
      debugPrint('[Supabase] Error inesperado al insertar reporte: $e\n$st');
      rethrow;
    }
  }
  // =========================================================
  //  NUEVO: enviar reporte COMPLETO desde la BD local
  // =========================================================
  ///
  /// Sube un reporte completo (cabecera + áreas + cuadrillas + integrantes)
  /// a Supabase usando la estructura de la BD local (ReporteDetalle).
  ///
  /// - [reporte]  : objeto de la BD local con áreas/cuadrillas/integrantes.
  /// - [userId]   : uid de Supabase (auth.user.id).
  ///
  /// Devuelve el `id` del reporte en Supabase.
  ///
  /// ⚠ Esta función asume que el reporte **aún no existe** en Supabase.
  Future<int> enviarReporteCompletoDesdeLocal({
    required ReporteDetalle reporte,
    required String userId,
    String? observaciones,
  }) async {
    try {
      // 1) Cabecera
      final reporteId = await insertarReporte(
        fecha: reporte.fecha,
        turno: reporte.turno,
        planillero: reporte.planillero,
        userId: userId,
        // 👉 ya no usamos reporte.observaciones porque no existe en tu modelo
        observaciones: observaciones,
      );

      // 2) Áreas
      for (final area in reporte.areas) {
        final areaId = await _insertarReporteArea(
          reporteId: reporteId,
          area: area,
        );

        // 3) Cuadrillas de esa área
        for (final cuad in area.cuadrillas) {
          final cuadrillaId = await _insertarCuadrilla(
            reporteAreaId: areaId,
            cuadrilla: cuad,
          );

          // 4) Integrantes de la cuadrilla
          for (final integ in cuad.integrantes) {
            await _insertarIntegrante(
              cuadrillaId: cuadrillaId,
              integrante: integ,
            );
          }
        }
      }

      debugPrint(
        '[Supabase] enviarReporteCompletoDesdeLocal → OK (id=$reporteId)',
      );
      return reporteId;
    } catch (e, st) {
      debugPrint(
        '[Supabase] Error al enviar reporte completo: $e\n$st',
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
      final data = {
        'reporte_id': reporteId,
        'area_nombre': area.nombre,
        'cantidad': area.cantidad,
        'hora_inicio': area.horaInicio,
        'hora_fin': area.horaFin,
      };

      final res = await _client
          .from('reporte_areas')
          .insert(data)
          .select('id')
          .single();

      final id = res['id'] as int?;
      if (id == null) {
        throw const FormatException(
          'Respuesta sin id al insertar reporte_areas',
        );
      }

      debugPrint(
        '[Supabase] _insertarReporteArea → id=$id (${area.nombre})',
      );
      return id;
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[Supabase] Error Postgrest al insertar reporte_areas: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint(
        '[Supabase] Error inesperado al insertar reporte_areas: $e\n$st',
      );
      rethrow;
    }
  }

  Future<int> _insertarCuadrilla({
    required int reporteAreaId,
    required CuadrillaDetalle cuadrilla,
  }) async {
    try {
      final data = {
        'reporte_area_id': reporteAreaId,
        'nombre': cuadrilla.nombre,
        'hora_inicio': cuadrilla.horaInicio,
        'hora_fin': cuadrilla.horaFin,
        'kilos': cuadrilla.kilos,
      };

      final res = await _client
          .from('cuadrillas')
          .insert(data)
          .select('id')
          .single();

      final id = res['id'] as int?;
      if (id == null) {
        throw const FormatException(
          'Respuesta sin id al insertar cuadrilla',
        );
      }

      debugPrint(
        '[Supabase] _insertarCuadrilla → id=$id (${cuadrilla.nombre})',
      );
      return id;
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[Supabase] Error Postgrest al insertar cuadrilla: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint(
        '[Supabase] Error inesperado al insertar cuadrilla: $e\n$st',
      );
      rethrow;
    }
  }

  Future<void> _insertarIntegrante({
    required int cuadrillaId,
    required IntegranteDetalle integrante,
  }) async {
    try {
      await _client.from('integrantes').insert({
        'cuadrilla_id': cuadrillaId,
        'code': integrante.code,
        'nombre': integrante.nombre,
        'hora_inicio': integrante.horaInicio,
        'hora_fin': integrante.horaFin,
        'horas': integrante.horas ?? 0,
        'labores': integrante.labores,
      });

      debugPrint(
        '[Supabase] _insertarIntegrante → ${integrante.nombre} (cuadrilla=$cuadrillaId)',
      );
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[Supabase] Error Postgrest al insertar integrante: '
            '${e.message} (${e.code})\n$st',
      );
      rethrow;
    } catch (e, st) {
      debugPrint(
        '[Supabase] Error inesperado al insertar integrante: $e\n$st',
      );
      rethrow;
    }
  }
}
