import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:scanner_trabunda/features/reports/domain/entities/reporte_remoto.dart';

part 'app_database.g.dart';

/// =======================
/// TABLAS
/// =======================

class Reportes extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get turno => text()(); // 'Día' | 'Mañana' | ...
  TextColumn get planillero => text()();
  IntColumn get supabaseId => integer().nullable()();
}

class ReporteAreas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reporteId => integer().references(Reportes, #id)();
  TextColumn get areaNombre => text()(); // 'Fileteros', etc.
  IntColumn get cantidad => integer().withDefault(const Constant(0))();
  TextColumn get horaInicio => text().nullable()();
  TextColumn get horaFin => text().nullable()();
}

class ReporteAreaDesgloses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reporteAreaId =>
      integer().references(ReporteAreas, #id, onDelete: KeyAction.cascade)();
  TextColumn get categoria => text()();
  IntColumn get personas => integer().withDefault(const Constant(0))();
  RealColumn get kilos => real().withDefault(const Constant(0.0))();
}

class Cuadrillas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reporteAreaId => integer().references(ReporteAreas, #id)();
  TextColumn get nombre => text().withDefault(const Constant('Cuadrilla'))();
  TextColumn get horaInicio => text().nullable()(); // 'HH:mm'
  TextColumn get horaFin => text().nullable()(); // 'HH:mm'
  RealColumn get kilos => real().nullable()();
}

class CuadrillaDesgloses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cuadrillaId =>
      integer().references(Cuadrillas, #id, onDelete: KeyAction.cascade)();
  TextColumn get categoria => text()();
  IntColumn get personas => integer().withDefault(const Constant(0))();
  RealColumn get kilos => real().withDefault(const Constant(0.0))();
}

class Integrantes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cuadrillaId => integer().references(Cuadrillas, #id)();
  TextColumn get code => text().nullable()(); // QR opcional
  TextColumn get nombre => text()();
  TextColumn get horaInicio => text().nullable()();
  TextColumn get horaFin => text().nullable()();
  RealColumn get horas => real().nullable()(); // ej: 7.5 horas
  TextColumn get labores => text().nullable()();
}

/// =======================
/// CONEXIÓN
/// =======================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'trabunda.db'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(
  tables: [
    Reportes,
    ReporteAreas,
    ReporteAreaDesgloses,
    Cuadrillas,
    CuadrillaDesgloses,
    Integrantes
  ],
  daos: [ReportesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(reporteAreas, reporteAreas.horaInicio);
        await m.addColumn(reporteAreas, reporteAreas.horaFin);
        await m.createTable(reporteAreaDesgloses);
        await m.createTable(cuadrillaDesgloses);
      }

      if (from < 3) {
        await m.addColumn(integrantes, integrantes.horaInicio);
        await m.addColumn(integrantes, integrantes.horaFin);
        await m.addColumn(integrantes, integrantes.horas);
      }
      if (from < 4) {
        await m.addColumn(integrantes, integrantes.labores);
      }
      if (from < 5) {
        await m.addColumn(reportes, reportes.supabaseId);
      }
    },
  );

  /// =====================================================
  /// 🔹 Borrar todos los datos locales (para logout, debug)
  /// =====================================================
  Future<void> clearAllData() async {
    await transaction(() async {
      await batch((b) {
        // Primero hijos, luego padres
        b.deleteWhere(integrantes, (_) => const Constant(true));
        b.deleteWhere(cuadrillaDesgloses, (_) => const Constant(true));
        b.deleteWhere(cuadrillas, (_) => const Constant(true));
        b.deleteWhere(reporteAreaDesgloses, (_) => const Constant(true));
        b.deleteWhere(reporteAreas, (_) => const Constant(true));
        b.deleteWhere(reportes, (_) => const Constant(true));
      });
    });
  }
}

/// =======================
/// DAO
/// =======================

@DriftAccessor(
  tables: [
    Reportes,
    ReporteAreas,
    ReporteAreaDesgloses,
    Cuadrillas,
    CuadrillaDesgloses,
    Integrantes
  ],
)
class ReportesDao extends DatabaseAccessor<AppDatabase>
    with _$ReportesDaoMixin {
  ReportesDao(AppDatabase db) : super(db);

  /// Devuelve los trabajadores de Saneamiento (integrantes) para un área dada.
  /// Se usa en AreaDetallePage para rellenar la lista cuando abres un reporte
  /// que ya tenía gente registrada.
  Future<List<Map<String, dynamic>>>
  fetchSaneamientoTrabajadoresPorArea(int reporteAreaId) async {
    // Tomamos la primera cuadrilla que pertenezca a ese reporte_area
    final cuadList = await (select(cuadrillas)
      ..where((c) => c.reporteAreaId.equals(reporteAreaId)))
        .get();

    if (cuadList.isEmpty) return [];

    final cuadrillaId = cuadList.first.id;

    final integrantesRows = await (select(integrantes)
      ..where((i) => i.cuadrillaId.equals(cuadrillaId)))
        .get();

    return integrantesRows
        .map(
          (i) => {
        'code': i.code ?? '',
        'name': i.nombre,
        'horaInicio': i.horaInicio,
        'horaFin': i.horaFin,
        'horas': i.horas,
        'labores': i.labores ?? '',
      },
    )
        .toList();
  }

  Future<bool> hasReportes() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS total FROM reportes',
      readsFrom: {reportes},
    ).getSingle();

    final total = row.data['total'];
    if (total is int) return total > 0;
    if (total is BigInt) return total > BigInt.zero;
    return false;
  }

  /// Obtiene o crea un reporte (borrador) por fecha+turno+planillero.
  Future<int> getOrCreateReporte({
    required DateTime fecha,
    required String turno,
    required String planillero,
  }) async {
    final row = await (select(reportes)
      ..where(
            (t) =>
        t.fecha.equals(fecha) &
        t.turno.equals(turno) &
        t.planillero.equals(planillero),
      ))
        .getSingleOrNull();

    if (row != null) return row.id;

    return into(reportes).insert(
      ReportesCompanion.insert(
        fecha: fecha,
        turno: turno,
        planillero: planillero,
      ),
    );
  }

  /// Si cambiaste cabecera, actualiza el registro (opcional).
  Future<void> updateReporteHeader(
      int id, {
        DateTime? fecha,
        String? turno,
        String? planillero,
      }) async {
    await (update(reportes)..where((t) => t.id.equals(id))).write(
      ReportesCompanion(
        fecha: fecha != null ? Value(fecha) : const Value.absent(),
        turno: turno != null ? Value(turno) : const Value.absent(),
        planillero:
        planillero != null ? Value(planillero) : const Value.absent(),
      ),
    );
  }

  Future<void> saveReporteSupabaseId(int id, int supabaseId) async {
    await (update(reportes)..where((t) => t.id.equals(id))).write(
      ReportesCompanion(
        supabaseId: Value(supabaseId),
      ),
    );
  }

  Future<int?> getReporteSupabaseId(int id) async {
    final row =
    await (select(reportes)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.supabaseId;
  }

  /// Crea un reporte y sus áreas (solo cabecera y cantidades).
  Future<int> createReporte({
    required DateTime fecha,
    required String turno,
    required String planillero,
    required List<Map<String, dynamic>>
    areas, // [{area:'Fileteros', cantidad:3}, ...]
  }) async {
    return transaction(() async {
      final repId = await into(reportes).insert(
        ReportesCompanion.insert(
          fecha: fecha,
          turno: turno,
          planillero: planillero,
        ),
      );

      for (final a in areas) {
        final nombre = (a['area'] ?? '').toString();
        final cant =
        (a['cantidad'] is num) ? (a['cantidad'] as num).toInt() : 0;
        await into(reporteAreas).insert(
          ReporteAreasCompanion.insert(
            reporteId: repId,
            areaNombre: nombre,
            cantidad: Value(cant),
          ),
        );
      }

      return repId;
    });
  }

  /// Devuelve o crea (si no existe) el ID de ReporteArea por nombre.
  Future<int> getOrCreateReporteAreaId(int reporteId, String areaNombre) async {
    final q = await (select(reporteAreas)
      ..where(
            (t) =>
        t.reporteId.equals(reporteId) &
        t.areaNombre.equals(areaNombre),
      ))
        .getSingleOrNull();
    if (q != null) return q.id;

    return into(reporteAreas).insert(
      ReporteAreasCompanion.insert(
        reporteId: reporteId,
        areaNombre: areaNombre,
      ),
    );
  }

  /// Actualiza cantidad manualmente (si la editas en la pantalla 1).
  Future<void> saveReporteAreaDatos({
    required int reporteAreaId,
    int? cantidad,
    String? horaInicio,
    String? horaFin,
    List<Map<String, dynamic>>? desglose,
  }) async {
    await transaction(() async {
      final companion = ReporteAreasCompanion(
        cantidad:
        cantidad != null ? Value(cantidad) : const Value.absent(),
        horaInicio: Value(horaInicio),
        horaFin: Value(horaFin),
      );
      await (update(reporteAreas)..where((t) => t.id.equals(reporteAreaId)))
          .write(companion);

      if (desglose != null) {
        await (delete(reporteAreaDesgloses)
          ..where((t) => t.reporteAreaId.equals(reporteAreaId)))
            .go();

        for (final entry in desglose) {
          final categoria = (entry['categoria'] ?? '').toString();
          final personas = entry['personas'];
          final kilos = entry['kilos'];
          await into(reporteAreaDesgloses).insert(
            ReporteAreaDesglosesCompanion.insert(
              reporteAreaId: reporteAreaId,
              categoria: categoria,
              personas: Value(
                personas is num ? personas.toInt() : 0,
              ),
              kilos: Value(
                kilos is num ? kilos.toDouble() : 0.0,
              ),
            ),
          );
        }
      }
    });
  }

  /// Crea/actualiza cuadrilla para un área de reporte.
  Future<int> upsertCuadrilla({
    required int? id, // null = crear
    required int reporteAreaId,
    required String nombre,
    String? horaInicio,
    String? horaFin,
    double? kilos,
    List<Map<String, dynamic>>? desglose,
  }) async {
    return transaction(() async {
      late int targetId;
      if (id == null) {
        targetId = await into(cuadrillas).insert(
          CuadrillasCompanion.insert(
            reporteAreaId: reporteAreaId,
            nombre: Value(nombre),
            horaInicio: Value(horaInicio),
            horaFin: Value(horaFin),
            kilos: Value(kilos),
          ),
        );
      } else {
        await (update(cuadrillas)..where((t) => t.id.equals(id))).write(
          CuadrillasCompanion(
            nombre: Value(nombre),
            horaInicio: Value(horaInicio),
            horaFin: Value(horaFin),
            kilos: Value(kilos),
          ),
        );
        targetId = id;
      }

      if (desglose != null) {
        await (delete(cuadrillaDesgloses)
          ..where((t) => t.cuadrillaId.equals(targetId)))
            .go();

        for (final entry in desglose) {
          final categoria = (entry['categoria'] ?? '').toString();
          final personas = entry['personas'];
          final kilosEntry = entry['kilos'];
          await into(cuadrillaDesgloses).insert(
            CuadrillaDesglosesCompanion.insert(
              cuadrillaId: targetId,
              categoria: categoria,
              personas: Value(
                personas is num ? personas.toInt() : 0,
              ),
              kilos: Value(
                kilosEntry is num ? kilosEntry.toDouble() : 0.0,
              ),
            ),
          );
        }
      }

      return targetId;
    });
  }

  /// Guarda los trabajadores de SANEAMIENTO como integrantes de una cuadrilla.
  Future<void> saveSaneamientoTrabajadores({
    required int reporteAreaId,
    required List<Map<String, dynamic>> trabajadores,
    String? horaInicioGeneral,
    String? horaFinGeneral,
  }) async {
    await transaction(() async {
      // Buscamos (o creamos) UNA única cuadrilla para este área
      final existing = await (select(cuadrillas)
        ..where((c) => c.reporteAreaId.equals(reporteAreaId)))
          .get();

      int cuadrillaId;

      if (existing.isEmpty) {
        // No hay cuadrillas aún: creamos una genérica "Saneamiento"
        cuadrillaId = await into(cuadrillas).insert(
          CuadrillasCompanion.insert(
            reporteAreaId: reporteAreaId,
            nombre: const Value('Saneamiento'),
            horaInicio: const Value(null),
            horaFin: const Value(null),
            kilos: const Value(0.0),
          ),
        );
      } else {
        // Reutilizamos la primera cuadrilla existente
        cuadrillaId = existing.first.id;
      }

      // Limpiamos los integrantes anteriores de esa cuadrilla
      await (delete(integrantes)
        ..where((t) => t.cuadrillaId.equals(cuadrillaId)))
          .go();

      // Insertamos los trabajadores nuevos
      final hiGeneral = horaInicioGeneral?.trim();
      final hfGeneral = horaFinGeneral?.trim();
      for (final t in trabajadores) {
        final code = (t['code'] ?? '').toString();
        final name = (t['name'] ?? '').toString();
        final hiRaw = t['horaInicio'];
        final hfRaw = t['horaFin'];
        final hi = (hiRaw is String ? hiRaw : hiRaw?.toString())?.trim();
        final hf = (hfRaw is String ? hfRaw : hfRaw?.toString())?.trim();
        final horaInicio =
            (hi != null && hi.isNotEmpty)
                ? hi
                : (hiGeneral?.isNotEmpty == true ? hiGeneral : null);
        final horaFin =
            (hf != null && hf.isNotEmpty)
                ? hf
                : (hfGeneral?.isNotEmpty == true ? hfGeneral : null);
        final hs = t['horas'];
        double? horasFinal = hs is num ? hs.toDouble() : null;

        if ((horasFinal == null || horasFinal == 0) &&
            horaInicio != null &&
            horaFin != null &&
            horaInicio.isNotEmpty &&
            horaFin.isNotEmpty) {
          final partsIni = horaInicio.split(':');
          final partsFin = horaFin.split(':');

          if (partsIni.length == 2 && partsFin.length == 2) {
            final hiH = int.tryParse(partsIni[0]);
            final hiM = int.tryParse(partsIni[1]);
            final hfH = int.tryParse(partsFin[0]);
            final hfM = int.tryParse(partsFin[1]);

            if (hiH != null && hiM != null && hfH != null && hfM != null) {
              int startMinutes = hiH * 60 + hiM;
              int endMinutes = hfH * 60 + hfM;
              int diff = endMinutes - startMinutes;

              if (diff <= 0) {
                diff += 24 * 60; // cruza medianoche
              }

              double rawHours = diff / 60.0;

              if (rawHours > 0.5) {
                rawHours -= 0.5; // Descuento de 30 minutos de almuerzo
              } else {
                rawHours = 0.0;
              }

              horasFinal = rawHours;
            }
          }
        }
        final labores = (t['labores'] ?? '').toString();

        if (code.isEmpty && name.isEmpty) continue;

        await into(integrantes).insert(
          IntegrantesCompanion.insert(
            cuadrillaId: cuadrillaId,
            code: Value(code),
            nombre: name,
            horaInicio: Value(horaInicio),
            horaFin: Value(horaFin),
            horas: Value(horasFinal),
            labores: Value(labores.isEmpty ? null : labores),
          ),
        );
      }
    });

    // --- Actualizamos la CANTIDAD de personas en reporte_areas ---
    final personasValidas = trabajadores.where((t) {
      final code = (t['code'] ?? '').toString();
      final name = (t['name'] ?? '').toString();
      // contamos solo si tiene algo
      return code.isNotEmpty || name.isNotEmpty;
    }).length;

    await (update(reporteAreas)..where((t) => t.id.equals(reporteAreaId)))
        .write(
      ReporteAreasCompanion(
        cantidad: Value(personasValidas),
      ),
    );
  }

  Future<void> replaceIntegrantes({
    required int cuadrillaId,
    required List<Map<String, String>> integrantesList,
  }) async {
    await transaction(() async {
      // Borra los anteriores de la cuadrilla
      await (delete(integrantes)
        ..where((t) => t.cuadrillaId.equals(cuadrillaId)))
          .go();

      // Inserta los nuevos
      for (final it in integrantesList) {
        await into(integrantes).insert(
          IntegrantesCompanion.insert(
            cuadrillaId: cuadrillaId,
            code: Value(it['code'] ?? ''),
            nombre: it['name'] ?? '',
          ),
        );
      }
    });
  }

  /// Suma de integrantes en todas las cuadrillas de un área.
  Future<int> sumIntegrantesPorArea(int reporteAreaId) async {
    final res = await (select(integrantes)
      ..where(
            (t) => t.cuadrillaId.isInQuery(
          (select(cuadrillas)
            ..where((c) => c.reporteAreaId.equals(reporteAreaId))),
        ),
      ))
        .get();

    return res.length;
  }

  Future<List<ReporteAreaResumen>> fetchReportesFiltrados({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    List<String>? areas,
    String? turno,
    String? planilleroQuery,
  }) async {
    final sql = StringBuffer('''
SELECT
  r.id AS reporte_id,
  a.id AS reporte_area_id,
  r.fecha AS fecha,
  r.turno AS turno,
  r.planillero AS planillero,
  a.area_nombre AS area_nombre,
  CASE
    WHEN a.cantidad > 0 THEN a.cantidad
    ELSE IFNULL(i_sum.integrantes_count, 0)
  END AS cantidad,
  IFNULL(c_sum.kilos, 0) AS kilos,
  IFNULL(i_sum.total_horas, 0) AS total_horas,
  IFNULL(i_sum.pendientes_salida, 0) AS pendientes_salida
FROM reporte_areas a
INNER JOIN reportes r ON r.id = a.reporte_id
LEFT JOIN (
  SELECT reporte_area_id, SUM(kilos) AS kilos
  FROM cuadrillas
  GROUP BY reporte_area_id
) c_sum ON c_sum.reporte_area_id = a.id
  LEFT JOIN (
    SELECT
      c.reporte_area_id,
      COUNT(i.id) AS integrantes_count,
      SUM(
        CASE
          WHEN i.horas IS NOT NULL AND i.horas > 0 THEN i.horas
          WHEN i.hora_inicio IS NOT NULL AND i.hora_inicio != ''
               AND i.hora_fin IS NOT NULL AND i.hora_fin != '' THEN
            CASE
              WHEN (
                (
                  (CAST(substr(i.hora_fin, 1, 2) AS INTEGER) * 60 +
                      CAST(substr(i.hora_fin, 4, 2) AS INTEGER)) -
                      (CAST(substr(i.hora_inicio, 1, 2) AS INTEGER) * 60 +
                          CAST(substr(i.hora_inicio, 4, 2) AS INTEGER))
                ) + CASE
                  WHEN (
                    (CAST(substr(i.hora_fin, 1, 2) AS INTEGER) * 60 +
                        CAST(substr(i.hora_fin, 4, 2) AS INTEGER)) -
                        (CAST(substr(i.hora_inicio, 1, 2) AS INTEGER) * 60 +
                            CAST(substr(i.hora_inicio, 4, 2) AS INTEGER))
                  ) <= 0 THEN 1440 ELSE 0 END
              ) / 60.0 > 0.5 THEN (
                (
                  (CAST(substr(i.hora_fin, 1, 2) AS INTEGER) * 60 +
                      CAST(substr(i.hora_fin, 4, 2) AS INTEGER)) -
                      (CAST(substr(i.hora_inicio, 1, 2) AS INTEGER) * 60 +
                          CAST(substr(i.hora_inicio, 4, 2) AS INTEGER))
                ) + CASE
                  WHEN (
                    (CAST(substr(i.hora_fin, 1, 2) AS INTEGER) * 60 +
                        CAST(substr(i.hora_fin, 4, 2) AS INTEGER)) -
                        (CAST(substr(i.hora_inicio, 1, 2) AS INTEGER) * 60 +
                            CAST(substr(i.hora_inicio, 4, 2) AS INTEGER))
                  ) <= 0 THEN 1440 ELSE 0 END
              ) / 60.0 - 0.5 ELSE 0
            END
          ELSE 0
        END
      ) AS total_horas,
      SUM(
        CASE
          WHEN i.hora_inicio IS NOT NULL
             AND (i.hora_fin IS NULL OR i.hora_fin = '')
        THEN 1 
        ELSE 0 
      END
    ) AS pendientes_salida
  FROM integrantes i
  INNER JOIN cuadrillas c ON c.id = i.cuadrilla_id
  GROUP BY c.reporte_area_id
) i_sum ON i_sum.reporte_area_id = a.id
''');

    final where = <String>[];
    final vars = <Variable>[];

    if (fechaInicio != null) {
      where.add('r.fecha >= ?');
      vars.add(Variable.withDateTime(fechaInicio));
    }
    if (fechaFin != null) {
      where.add('r.fecha <= ?');
      vars.add(Variable.withDateTime(fechaFin));
    }
    if (areas != null && areas.isNotEmpty) {
      final placeholders = List.generate(areas.length, (_) => '?').join(', ');
      where.add('a.area_nombre IN ($placeholders)');
      for (final area in areas) {
        vars.add(Variable.withString(area));
      }
    }
    if (turno != null && turno.isNotEmpty) {
      where.add('r.turno = ?');
      vars.add(Variable.withString(turno));
    }
    if (planilleroQuery != null && planilleroQuery.isNotEmpty) {
      where.add('LOWER(r.planillero) LIKE ?');
      vars.add(Variable.withString('%${planilleroQuery.toLowerCase()}%'));
    }

    if (where.isNotEmpty) {
      sql.write('WHERE ${where.join(' AND ')}\n');
    }

    sql
      ..write('GROUP BY a.id\n')
      ..write(
          'ORDER BY r.fecha DESC, r.id DESC, a.area_nombre COLLATE NOCASE ASC');

    final rows = await customSelect(
      sql.toString(),
      variables: vars,
      readsFrom: {reportes, reporteAreas, cuadrillas, integrantes},
    ).get();

    return rows
        .map(
          (row) => ReporteAreaResumen(
        reporteId: row.read<int>('reporte_id'),
        reporteAreaId: row.read<int>('reporte_area_id'),
        fecha: row.read<DateTime>('fecha'),
        turno: row.read<String>('turno'),
        planillero: row.read<String>('planillero'),
        areaNombre: row.read<String>('area_nombre'),
        cantidad: row.read<int>('cantidad'),
        kilos: row.read<double?>('kilos') ?? 0,
        totalHoras: row.read<double?>('total_horas') ?? 0,
        pendientesSalida: row.read<int>('pendientes_salida'),
      ),
    )
        .toList();
  }

  Future<ReporteDetalle?> fetchReporteDetalle(int reporteId) async {
    final reporteRow =
    await (select(reportes)..where((t) => t.id.equals(reporteId)))
        .getSingleOrNull();
    if (reporteRow == null) return null;

    final areasQuery = await (select(reporteAreas)
      ..where((t) => t.reporteId.equals(reporteId)))
        .get();

    final areas = <ReporteAreaDetalle>[];

    for (final area in areasQuery) {
      final cuadrillasQuery = await (select(cuadrillas)
        ..where((t) => t.reporteAreaId.equals(area.id)))
          .get();

      final cuadrillasDetalle = <CuadrillaDetalle>[];

      for (final cuad in cuadrillasQuery) {
        final integrantesQuery = await (select(integrantes)
          ..where((t) => t.cuadrillaId.equals(cuad.id)))
            .get();

        final integrantesDetalle = integrantesQuery
            .map(
              (it) {
            // 🔹 Recalcular horas si vienen null/0 pero hay horaInicio y horaFin
            double? horasFinal = it.horas;
            final hi = it.horaInicio;
            final hf = it.horaFin;

            if ((horasFinal == null || horasFinal == 0) &&
                hi != null &&
                hf != null &&
                hi.isNotEmpty &&
                hf.isNotEmpty) {
              final partsIni = hi.split(':');
              final partsFin = hf.split(':');
              if (partsIni.length == 2 && partsFin.length == 2) {
                final hiH = int.tryParse(partsIni[0]);
                final hiM = int.tryParse(partsIni[1]);
                final hfH = int.tryParse(partsFin[0]);
                final hfM = int.tryParse(partsFin[1]);
                if (hiH != null &&
                    hiM != null &&
                    hfH != null &&
                    hfM != null) {
                  int startMinutes = hiH * 60 + hiM;
                  int endMinutes = hfH * 60 + hfM;
                  int diff = endMinutes - startMinutes;
                  if (diff <= 0) {
                    diff += 24 * 60; // cruza medianoche
                  }
                  double rawHours = diff / 60.0;
                  // Descuento de 30 minutos de almuerzo
                  if (rawHours > 0.5) {
                    rawHours -= 0.5;
                  } else {
                    rawHours = 0.0;
                  }
                  horasFinal = rawHours;
                }
              }
            }

            return IntegranteDetalle(
              id: it.id,
              nombre: it.nombre,
              code: it.code,
              horaInicio: it.horaInicio,
              horaFin: it.horaFin,
              horas: horasFinal,
              labores: it.labores,
            );
          },
        )
            .toList();

        final desgloseCuadrillaRows = await (select(cuadrillaDesgloses)
          ..where((t) => t.cuadrillaId.equals(cuad.id)))
            .get();

        final desgloseCuadrilla = desgloseCuadrillaRows
            .map(
              (d) => CategoriaDesglose(
            categoria: d.categoria,
            personas: d.personas,
            kilos: d.kilos,
          ),
        )
            .toList();

        cuadrillasDetalle.add(
          CuadrillaDetalle(
            id: cuad.id,
            nombre: cuad.nombre,
            horaInicio: cuad.horaInicio,
            horaFin: cuad.horaFin,
            kilos: cuad.kilos ?? 0,
            integrantes: integrantesDetalle,
            desglose: desgloseCuadrilla,
          ),
        );
      }

      final areaDesgloseRows = await (select(reporteAreaDesgloses)
        ..where((t) => t.reporteAreaId.equals(area.id)))
          .get();

      final areaDesglose = areaDesgloseRows
          .map(
            (d) => CategoriaDesglose(
          categoria: d.categoria,
          personas: d.personas,
          kilos: d.kilos,
        ),
      )
          .toList();

      var totalKilos = cuadrillasDetalle.fold<double>(
        0,
            (sum, c) => sum + c.kilos,
      );
      if (totalKilos == 0 && areaDesglose.isNotEmpty) {
        totalKilos =
            areaDesglose.fold<double>(0, (sum, d) => sum + d.kilos);
      }

      areas.add(
        ReporteAreaDetalle(
          id: area.id,
          nombre: area.areaNombre,
          cantidad: area.cantidad,
          totalKilos: totalKilos,
          cuadrillas: cuadrillasDetalle,
          horaInicio: area.horaInicio,
          horaFin: area.horaFin,
          desglose: areaDesglose,
        ),
      );
    }
    // 🔹 Eliminar áreas "fantasma": sin personas y sin horas
    final nonEmptyAreas = areas.where((a) {
      return a.totalPersonas > 0 || a.totalHoras > 0;
    }).toList();

    return ReporteDetalle(
      id: reporteRow.id,
      fecha: reporteRow.fecha,
      turno: reporteRow.turno,
      planillero: reporteRow.planillero,
      areas: nonEmptyAreas,
      supabaseId: reporteRow.supabaseId,
    );
  }

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

    await transaction(() async {
      for (final remoto in reportesRemotos) {
        debugPrint(
          '[upsertReportesRemotos] Reporte ${remoto.id} con '
              '${remoto.areas.length} áreas remotas recibidas.',
        );

        // 1) Insertar/actualizar cabecera del reporte
        await into(reportes).insert(
          ReportesCompanion(
            id: Value(remoto.id),
            fecha: Value(remoto.fecha),
            turno: Value(remoto.turno),
            planillero: Value(remoto.planillero),
          ),
          mode: InsertMode.insertOrReplace,
        );

        // 2) Si NO vienen áreas desde Supabase: no tocamos las áreas locales
        if (remoto.areas.isEmpty) {
          debugPrint(
            '[upsertReportesRemotos] Reporte ${remoto.id} sin áreas remotas. '
                'Se mantienen las áreas locales existentes.',
          );
          continue;
        }

        // 3) Si SÍ vienen áreas, las sincronizamos
        for (final area in remoto.areas) {
          var integrantesArea = 0;

          debugPrint(
            '[upsertReportesRemotos][Reporte ${remoto.id}] Área '
                '${area.areaNombre}: ${area.desglose.length} desgloses '
                '(${formatSample(area.desglose, (d) => '${d.categoria}:${d.personas}p/${d.kilos}kg')}) | '
                '${area.cuadrillas.length} cuadrillas '
                '(${formatSample(area.cuadrillas, (c) => '${c.nombre ?? 'Cuadrilla'}: ${c.integrantes.length} integrantes, '
                'kilos=${c.kilos ?? 0}')} ).',
          );

          // 🔹 Buscar áreas locales existentes por (reporteId + nombre)
          final existingAreas = await (select(reporteAreas)
            ..where(
                  (t) =>
              t.reporteId.equals(remoto.id) &
              t.areaNombre.equals(area.areaNombre),
            ))
              .get();

          int resolvedAreaId;

          if (existingAreas.isNotEmpty) {
            // Nos quedamos con la primera como "oficial"
            final existingArea = existingAreas.first;
            resolvedAreaId = existingArea.id;

            // Si hay más de una, consideramos las demás como duplicadas y las limpiamos
            if (existingAreas.length > 1) {
              final duplicateIds =
              existingAreas.skip(1).map((a) => a.id).toList();

              // Borrar cuadrillas + integrantes + desgloses de esas áreas duplicadas
              if (duplicateIds.isNotEmpty) {
                final oldCuadrillas = await (select(cuadrillas)
                  ..where(
                        (c) => c.reporteAreaId.isIn(duplicateIds),
                  ))
                    .get();

                for (final c in oldCuadrillas) {
                  await (delete(integrantes)
                    ..where((i) => i.cuadrillaId.equals(c.id)))
                      .go();
                  await (delete(cuadrillaDesgloses)
                    ..where((d) => d.cuadrillaId.equals(c.id)))
                      .go();
                }

                await (delete(cuadrillas)
                  ..where((c) => c.reporteAreaId.isIn(duplicateIds)))
                    .go();

                await (delete(reporteAreaDesgloses)
                  ..where((d) => d.reporteAreaId.isIn(duplicateIds)))
                    .go();

                await (delete(reporteAreas)
                  ..where((a) => a.id.isIn(duplicateIds)))
                    .go();

                debugPrint(
                  '[upsertReportesRemotos][Reporte ${remoto.id}] '
                      'Eliminadas ${duplicateIds.length} áreas duplicadas '
                      'para "${area.areaNombre}".',
                );
              }
            }

            // Actualizamos cabecera del área que conservamos
            await (update(reporteAreas)
              ..where((t) => t.id.equals(resolvedAreaId)))
                .write(
              ReporteAreasCompanion(
                cantidad: Value(area.cantidad ?? existingArea.cantidad),
                horaInicio: Value(area.horaInicio ?? existingArea.horaInicio),
                horaFin: Value(area.horaFin ?? existingArea.horaFin),
              ),
            );

            // Limpiamos desgloses y cuadrillas de esa área para volver a llenar
            await (delete(reporteAreaDesgloses)
              ..where((d) => d.reporteAreaId.equals(resolvedAreaId)))
                .go();

            final oldCuadrillas = await (select(cuadrillas)
              ..where((c) => c.reporteAreaId.equals(resolvedAreaId)))
                .get();

            for (final c in oldCuadrillas) {
              await (delete(integrantes)
                ..where((i) => i.cuadrillaId.equals(c.id)))
                  .go();
              await (delete(cuadrillaDesgloses)
                ..where((d) => d.cuadrillaId.equals(c.id)))
                  .go();
            }
            await (delete(cuadrillas)
              ..where((c) => c.reporteAreaId.equals(resolvedAreaId)))
                .go();
          } else {
            // No existía: insertamos una área nueva local sin usar el id remoto
            final newAreaId = await into(reporteAreas).insert(
              ReporteAreasCompanion.insert(
                reporteId: remoto.id,
                areaNombre: area.areaNombre,
                cantidad: Value(area.cantidad ?? 0),
                horaInicio: Value(area.horaInicio),
                horaFin: Value(area.horaFin),
              ),
            );
            resolvedAreaId = newAreaId;
          }

          // ----- Desgloses del área (desde cero) -----
          for (final desglose in area.desglose) {
            await into(reporteAreaDesgloses).insert(
              ReporteAreaDesglosesCompanion.insert(
                reporteAreaId: resolvedAreaId,
                categoria: desglose.categoria,
                personas: Value(desglose.personas),
                kilos: Value(desglose.kilos),
              ),
            );
          }

          if (area.desglose.isNotEmpty) {
            debugPrint(
              '[upsertReportesRemotos][Reporte ${remoto.id}] Área '
                  '${area.areaNombre}: insertados ${area.desglose.length} '
                  'desgloses.',
            );
          }

          // ----- Cuadrillas del área -----
          for (final cuadrilla in area.cuadrillas) {
            final cuadrillaId = await into(cuadrillas).insert(
              CuadrillasCompanion.insert(
                reporteAreaId: resolvedAreaId,
                nombre: Value(cuadrilla.nombre ?? 'Cuadrilla'),
                horaInicio: Value(cuadrilla.horaInicio),
                horaFin: Value(cuadrilla.horaFin),
                kilos: Value(cuadrilla.kilos),
              ),
            );

            // Desgloses de cuadrilla
            for (final desglose in cuadrilla.desglose) {
              await into(cuadrillaDesgloses).insert(
                CuadrillaDesglosesCompanion.insert(
                  cuadrillaId: cuadrillaId,
                  categoria: desglose.categoria,
                  personas: Value(desglose.personas),
                  kilos: Value(desglose.kilos),
                ),
              );
            }

            // Integrantes
            integrantesArea += cuadrilla.integrantes.length;

            for (final integrante in cuadrilla.integrantes) {
              await into(integrantes).insert(
                IntegrantesCompanion.insert(
                  cuadrillaId: cuadrillaId,
                  code: Value(integrante.code ?? ''),
                  nombre: integrante.nombre ?? '',
                  horaInicio: Value(integrante.horaInicio),
                  horaFin: Value(integrante.horaFin),
                  horas: Value(integrante.horas),
                  labores: Value(integrante.labores),
                ),
              );
            }
          }

          // Si la cantidad del área es 0 o null, usamos el número de integrantes
          if ((area.cantidad ?? 0) == 0) {
            await (update(reporteAreas)
              ..where((t) => t.id.equals(resolvedAreaId)))
                .write(
              ReporteAreasCompanion(
                cantidad: Value(integrantesArea),
              ),
            );
          }

          final cantidadRecibida = area.cantidad ?? 0;
          final cantidadGuardada =
          cantidadRecibida == 0 ? integrantesArea : cantidadRecibida;
          debugPrint(
            '[upsertReportesRemotos][Reporte ${remoto.id}] Área '
                '${area.areaNombre}: cantidad recibida=$cantidadRecibida, '
                'guardada=$cantidadGuardada (integrantes recalculados='
                '$integrantesArea).',
          );
        }

        // Resumen local
        final detalleLocal = await fetchReporteDetalle(remoto.id);
        if (detalleLocal != null) {
          final totalAreas = detalleLocal.areas.length;
          final totalPersonas = detalleLocal.totalPersonas;
          final totalKilos = detalleLocal.totalKilos;
          final totalHoras = detalleLocal.totalHoras;

          debugPrint(
            '[upsertReportesRemotos][Reporte ${remoto.id}] Resumen local → '
                'áreas=$totalAreas, personas=$totalPersonas, '
                'kilos=${totalKilos.toStringAsFixed(2)}, '
                'horas=${totalHoras.toStringAsFixed(2)}. '
                'Supabase envió áreas=${remoto.areas.length}.',
          );
        } else {
          debugPrint(
            '[upsertReportesRemotos][Reporte ${remoto.id}] No se pudo obtener '
                'detalle local para el resumen.',
          );
        }
      }
    });
  }
}

/// =======================
/// MODELOS DE LECTURA
/// =======================

class ReporteAreaResumen {
  final int reporteId;
  final int reporteAreaId;
  final DateTime fecha;
  final String turno;
  final String planillero;
  final String areaNombre;
  final int cantidad;
  final double kilos;
  final double totalHoras;
  final int pendientesSalida;

  const ReporteAreaResumen({
    required this.reporteId,
    required this.reporteAreaId,
    required this.fecha,
    required this.turno,
    required this.planillero,
    required this.areaNombre,
    required this.cantidad,
    required this.kilos,
    required this.totalHoras,
    required this.pendientesSalida,
  });

  /// Hay al menos un trabajador con hora_inicio y SIN hora_fin
  bool get tienePendientesSalida => pendientesSalida > 0;
}

class ReporteDetalle {
  final int id;
  final DateTime fecha;
  final String turno;
  final String planillero;
  final List<ReporteAreaDetalle> areas;
  final int? supabaseId;

  const ReporteDetalle({
    required this.id,
    required this.fecha,
    required this.turno,
    required this.planillero,
    required this.areas,
    this.supabaseId,
  });

  int get totalPersonas =>
      areas.fold(0, (sum, area) => sum + area.totalPersonas);

  double get totalKilos =>
      areas.fold(0, (sum, area) => sum + area.totalKilos);

  double get totalHoras =>
      areas.fold(0, (sum, area) => sum + area.totalHoras);
}

class ReporteAreaDetalle {
  final int id;
  final String nombre;
  final int cantidad;
  final double totalKilos;
  final List<CuadrillaDetalle> cuadrillas;
  final String? horaInicio;
  final String? horaFin;
  final List<CategoriaDesglose> desglose;

  const ReporteAreaDetalle({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.totalKilos,
    required this.cuadrillas,
    this.horaInicio,
    this.horaFin,
    this.desglose = const [],
  });

  int get totalIntegrantes =>
      cuadrillas.fold(0, (sum, c) => sum + c.totalIntegrantes);

  int get totalPersonas => cantidad != 0 ? cantidad : totalIntegrantes;

  double get totalHoras =>
      cuadrillas.fold(0, (sum, c) => sum + c.totalHoras);
}

class CuadrillaDetalle {
  final int id;
  final String nombre;
  final String? horaInicio;
  final String? horaFin;
  final double kilos;
  final List<IntegranteDetalle> integrantes;
  final List<CategoriaDesglose> desglose;

  const CuadrillaDetalle({
    required this.id,
    required this.nombre,
    this.horaInicio,
    this.horaFin,
    required this.kilos,
    required this.integrantes,
    this.desglose = const [],
  });

  int get totalIntegrantes => integrantes.length;

  double get totalHoras =>
      integrantes.fold(0, (sum, it) => sum + (it.horas ?? 0));
}

class IntegranteDetalle {
  final int id;
  final String nombre;
  final String? code;
  final String? horaInicio;
  final String? horaFin;
  final double? horas;
  final String? labores;

  const IntegranteDetalle({
    required this.id,
    required this.code,
    required this.nombre,
    this.horaInicio,
    this.horaFin,
    this.horas,
    this.labores,
  });
}

class CategoriaDesglose {
  final String categoria;
  final int personas;
  final double kilos;

  const CategoriaDesglose({
    required this.categoria,
    this.personas = 0,
    this.kilos = 0,
  });
}
