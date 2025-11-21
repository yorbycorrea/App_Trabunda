class ReporteRemoto {
  final int id;
  final DateTime fecha;
  final String turno;
  final String planillero;
  final String? observaciones;
  final String? userId;
  final List<ReporteAreaRemoto> areas;

  ReporteRemoto({
    required this.id,
    required this.fecha,
    required this.turno,
    required this.planillero,
    required this.areas,
    this.observaciones,
    this.userId,
  });

  factory ReporteRemoto.fromMap(Map<String, dynamic> map) {
    final fechaValue = map['fecha'];
    DateTime parsedFecha;
    if (fechaValue is String) {
      parsedFecha = DateTime.parse(fechaValue);
    } else if (fechaValue is DateTime) {
      parsedFecha = fechaValue;
    } else {
      throw ArgumentError('Fecha inválida en reporte remoto');
    }

    final areasData = map['reporte_areas'];
    final List<ReporteAreaRemoto> areas = areasData is List
        ? areasData
        .whereType<Map<String, dynamic>>()
        .map(ReporteAreaRemoto.fromMap)
        .toList()
        : const [];

    return ReporteRemoto(
      id: map['id'] as int,
      fecha: parsedFecha,
      turno: (map['turno'] ?? '').toString(),
      planillero: (map['planillero'] ?? '').toString(),
      observaciones: map['observaciones'] as String?,
      userId: map['user_id'] as String?,
      areas: areas,
    );
  }
}

class ReporteAreaRemoto {
  final int? id;
  final int? reporteId;
  final String areaNombre;
  final int cantidad;
  final String? horaInicio;
  final String? horaFin;
  final List<CuadrillaRemota> cuadrillas;

  ReporteAreaRemoto({
    required this.areaNombre,
    required this.cantidad,
    required this.cuadrillas,
    this.id,
    this.reporteId,
    this.horaInicio,
    this.horaFin,
  });

  factory ReporteAreaRemoto.fromMap(Map<String, dynamic> map) {
    final cuadrillasData = map['cuadrillas'];
    final cuadrillas = cuadrillasData is List
        ? cuadrillasData
        .whereType<Map<String, dynamic>>()
        .map(CuadrillaRemota.fromMap)
        .toList()
        : const [];

    return ReporteAreaRemoto(
      id: map['id'] as int?,
      reporteId: map['reporte_id'] as int?,
      areaNombre: (map['area_nombre'] ?? '').toString(),
      cantidad: (map['cantidad'] is num) ? (map['cantidad'] as num).toInt() : 0,
      horaInicio: map['hora_inicio'] as String?,
      horaFin: map['hora_fin'] as String?,
      cuadrillas: (map['cuadrillas'] as List<dynamic>? ?? [])
          .map((e) => CuadrillaRemota.fromMap(e as Map<String, dynamic>))
          .toList(),

    );
  }
}

class CuadrillaRemota {
  final int? id;
  final int? reporteAreaId;
  final String? nombre;
  final String? horaInicio;
  final String? horaFin;
  final double? kilos;
  final List<IntegranteRemoto> integrantes;

  CuadrillaRemota({
    required this.integrantes,
    this.id,
    this.reporteAreaId,
    this.nombre,
    this.horaInicio,
    this.horaFin,
    this.kilos,
  });

  factory CuadrillaRemota.fromMap(Map<String, dynamic> map) {
    final integrantesData = map['integrantes'];
    final integrantes = integrantesData is List
        ? integrantesData
        .whereType<Map<String, dynamic>>()
        .map(IntegranteRemoto.fromMap)
        .toList()
        : const [];

    final kilosValue = map['kilos'];

    return CuadrillaRemota(
      id: map['id'] as int?,
      reporteAreaId: map['reporte_area_id'] as int?,
      nombre: map['nombre'] as String?,
      horaInicio: map['hora_inicio'] as String?,
      horaFin: map['hora_fin'] as String?,
      kilos: kilosValue is num ? kilosValue.toDouble() : null,
      integrantes: (map['integrantes'] as List<dynamic>? ?? [])
          .map((e) => IntegranteRemoto.fromMap(e as Map<String, dynamic>))
          .toList(),

    );
  }
}

class IntegranteRemoto {
  final int? id;
  final int? cuadrillaId;
  final String? code;
  final String? nombre;
  final String? horaInicio;
  final String? horaFin;
  final double? horas;
  final String? labores;

  IntegranteRemoto({
    this.id,
    this.cuadrillaId,
    this.code,
    this.nombre,
    this.horaInicio,
    this.horaFin,
    this.horas,
    this.labores,
  });

  factory IntegranteRemoto.fromMap(Map<String, dynamic> map) {
    final horasVal = map['horas'];
    return IntegranteRemoto(
      id: map['id'] as int?,
      cuadrillaId: map['cuadrilla_id'] as int?,
      code: map['code'] as String?,
      nombre: map['nombre'] as String?,
      horaInicio: map['hora_inicio'] as String?,
      horaFin: map['hora_fin'] as String?,
      horas: horasVal is num ? horasVal.toDouble() : null,
      labores: map['labores'] as String?,
    );
  }
}