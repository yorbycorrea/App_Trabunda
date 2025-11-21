import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/reporte_remoto.dart';
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
    ])
class ReportesDao extends DatabaseAccessor<AppDatabase>
    with _$ReportesDaoMixin {
  ReportesDao(AppDatabase db) : super(db);

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
      ..where((t) =>
      t.fecha.equals(fecha) &
      t.turno.equals(turno) &
      t.planillero.equals(planillero)))
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
    final row = await (select(reportes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.supabaseId;
  }


  /// Crea un reporte y sus áreas (solo cabecera y cantidades).
  Future<int> createReporte({
    required DateTime fecha,
    required String turno,
    required String planillero,
    required List<Map<String, dynamic>> areas, // [{area:'Fileteros', cantidad:3}, ...]
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
      ..where((t) =>
      t.reporteId.equals(reporteId) &
      t.areaNombre.equals(areaNombre)))
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
      for (final t in trabajadores) {
        final code = (t['code'] ?? '').toString();
        final name = (t['name'] ?? '').toString();
        final hi = (t['horaInicio'] ?? '') as String?;
        final hf = (t['horaFin'] ?? '') as String?;
        final hs = t['horas'];
        final labores = (t['labores'] ?? '').toString();

        if (code.isEmpty && name.isEmpty) continue;

        await into(integrantes).insert(
          IntegrantesCompanion.insert(
            cuadrillaId: cuadrillaId,
            code: Value(code),
            nombre: name,
            horaInicio: Value(hi),
            horaFin: Value(hf),
            horas: Value(
              hs is num ? hs.toDouble() : null),
            labores: Value(labores.isEmpty ? null : labores),
          ),
        );

      }
    });
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
  a.cantidad AS cantidad,
  IFNULL(SUM(c.kilos), 0) AS kilos,
  IFNULL(SUM(i.horas), 0) AS total_horas
FROM reporte_areas a
INNER JOIN reportes r ON r.id = a.reporte_id
LEFT JOIN cuadrillas c ON c.reporte_area_id = a.id
LEFT JOIN integrantes i ON i.cuadrilla_id = c.id
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
              (it) => IntegranteDetalle(
            id: it.id,
            nombre: it.nombre,
            code: it.code,
            horaInicio: it.horaInicio,
            horaFin: it.horaFin,
            horas: it.horas,
            labores: it.labores,
          ),
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
        totalKilos = areaDesglose.fold<double>(0, (sum, d) => sum + d.kilos);
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

    return ReporteDetalle(
      id: reporteRow.id,
      fecha: reporteRow.fecha,
      turno: reporteRow.turno,
      planillero: reporteRow.planillero,
      areas: areas,
      supabaseId: reporteRow.supabaseId,
    );
  }

  Future<void> upsertReportesRemotos(List<ReporteRemoto> reportesRemotos) async {
    if (reportesRemotos.isEmpty) return;

    await transaction(() async {
      for (final remoto in reportesRemotos) {
        await into(reportes).insert(
          ReportesCompanion(
            id: Value(remoto.id),
            fecha: remoto.fecha,
            turno: remoto.turno,
            planillero: remoto.planillero,
          ),
          mode: InsertMode.insertOrReplace,
        );

        for (final area in remoto.areas) {
          final reporteAreaId = await into(reporteAreas).insert(
            ReporteAreasCompanion(
              id: area.id != null ? Value(area.id!) : const Value.absent(),
              reporteId: Value(area.reporteId ?? remoto.id),
              areaNombre: area.areaNombre,
              cantidad: Value(area.cantidad),
              horaInicio: Value(area.horaInicio),
              horaFin: Value(area.horaFin),
            ),
            mode: InsertMode.insertOrReplace,
          );

          final resolvedAreaId = area.id ?? reporteAreaId;

          for (final cuadrilla in area.cuadrillas) {
            final cuadrillaId = await into(cuadrillas).insert(
              CuadrillasCompanion(
                id: cuadrilla.id != null
                    ? Value(cuadrilla.id!)
                    : const Value.absent(),
                reporteAreaId: Value(cuadrilla.reporteAreaId ?? resolvedAreaId),
                nombre: Value(cuadrilla.nombre ?? 'Cuadrilla'),
                horaInicio: Value(cuadrilla.horaInicio),
                horaFin: Value(cuadrilla.horaFin),
                kilos: Value(cuadrilla.kilos),
              ),
              mode: InsertMode.insertOrReplace,
            );

            final resolvedCuadrillaId = cuadrilla.id ?? cuadrillaId;

            for (final integrante in cuadrilla.integrantes) {
              await into(integrantes).insert(
                IntegrantesCompanion(
                  id: integrante.id != null
                      ? Value(integrante.id!)
                      : const Value.absent(),
                  cuadrillaId: Value(integrante.cuadrillaId ?? resolvedCuadrillaId),
                  code: Value(integrante.code ?? ''),
                  nombre: integrante.nombre ?? '',
                  horaInicio: Value(integrante.horaInicio),
                  horaFin: Value(integrante.horaFin),
                  horas: Value(integrante.horas),
                  labores: Value(integrante.labores),
                ),
                mode: InsertMode.insertOrReplace,
              );
            }
          }
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
  });
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
      areas.fold(0, (sum, area) => sum + area.cantidad);

  double get totalKilos =>
      areas.fold(0, (sum, area) => sum + area.totalKilos);
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
