// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ReportesTable extends Reportes with TableInfo<$ReportesTable, Reporte> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReportesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _turnoMeta = const VerificationMeta('turno');
  @override
  late final GeneratedColumn<String> turno = GeneratedColumn<String>(
    'turno',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planilleroMeta = const VerificationMeta(
    'planillero',
  );
  @override
  late final GeneratedColumn<String> planillero = GeneratedColumn<String>(
    'planillero',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supabaseIdMeta = const VerificationMeta(
    'supabaseId',
  );
  @override
  late final GeneratedColumn<int> supabaseId = GeneratedColumn<int>(
    'supabase_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fecha,
    turno,
    planillero,
    supabaseId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reportes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reporte> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('turno')) {
      context.handle(
        _turnoMeta,
        turno.isAcceptableOrUnknown(data['turno']!, _turnoMeta),
      );
    } else if (isInserting) {
      context.missing(_turnoMeta);
    }
    if (data.containsKey('planillero')) {
      context.handle(
        _planilleroMeta,
        planillero.isAcceptableOrUnknown(data['planillero']!, _planilleroMeta),
      );
    } else if (isInserting) {
      context.missing(_planilleroMeta);
    }
    if (data.containsKey('supabase_id')) {
      context.handle(
        _supabaseIdMeta,
        supabaseId.isAcceptableOrUnknown(data['supabase_id']!, _supabaseIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reporte map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reporte(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      turno: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turno'],
      )!,
      planillero: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planillero'],
      )!,
      supabaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}supabase_id'],
      ),
    );
  }

  @override
  $ReportesTable createAlias(String alias) {
    return $ReportesTable(attachedDatabase, alias);
  }
}

class Reporte extends DataClass implements Insertable<Reporte> {
  final int id;
  final DateTime fecha;
  final String turno;
  final String planillero;
  final int? supabaseId;
  const Reporte({
    required this.id,
    required this.fecha,
    required this.turno,
    required this.planillero,
    this.supabaseId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['fecha'] = Variable<DateTime>(fecha);
    map['turno'] = Variable<String>(turno);
    map['planillero'] = Variable<String>(planillero);
    if (!nullToAbsent || supabaseId != null) {
      map['supabase_id'] = Variable<int>(supabaseId);
    }
    return map;
  }

  ReportesCompanion toCompanion(bool nullToAbsent) {
    return ReportesCompanion(
      id: Value(id),
      fecha: Value(fecha),
      turno: Value(turno),
      planillero: Value(planillero),
      supabaseId: supabaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(supabaseId),
    );
  }

  factory Reporte.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reporte(
      id: serializer.fromJson<int>(json['id']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      turno: serializer.fromJson<String>(json['turno']),
      planillero: serializer.fromJson<String>(json['planillero']),
      supabaseId: serializer.fromJson<int?>(json['supabaseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fecha': serializer.toJson<DateTime>(fecha),
      'turno': serializer.toJson<String>(turno),
      'planillero': serializer.toJson<String>(planillero),
      'supabaseId': serializer.toJson<int?>(supabaseId),
    };
  }

  Reporte copyWith({
    int? id,
    DateTime? fecha,
    String? turno,
    String? planillero,
    Value<int?> supabaseId = const Value.absent(),
  }) => Reporte(
    id: id ?? this.id,
    fecha: fecha ?? this.fecha,
    turno: turno ?? this.turno,
    planillero: planillero ?? this.planillero,
    supabaseId: supabaseId.present ? supabaseId.value : this.supabaseId,
  );
  Reporte copyWithCompanion(ReportesCompanion data) {
    return Reporte(
      id: data.id.present ? data.id.value : this.id,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      turno: data.turno.present ? data.turno.value : this.turno,
      planillero: data.planillero.present
          ? data.planillero.value
          : this.planillero,
      supabaseId: data.supabaseId.present
          ? data.supabaseId.value
          : this.supabaseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reporte(')
          ..write('id: $id, ')
          ..write('fecha: $fecha, ')
          ..write('turno: $turno, ')
          ..write('planillero: $planillero, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fecha, turno, planillero, supabaseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reporte &&
          other.id == this.id &&
          other.fecha == this.fecha &&
          other.turno == this.turno &&
          other.planillero == this.planillero &&
          other.supabaseId == this.supabaseId);
}

class ReportesCompanion extends UpdateCompanion<Reporte> {
  final Value<int> id;
  final Value<DateTime> fecha;
  final Value<String> turno;
  final Value<String> planillero;
  final Value<int?> supabaseId;
  const ReportesCompanion({
    this.id = const Value.absent(),
    this.fecha = const Value.absent(),
    this.turno = const Value.absent(),
    this.planillero = const Value.absent(),
    this.supabaseId = const Value.absent(),
  });
  ReportesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime fecha,
    required String turno,
    required String planillero,
    this.supabaseId = const Value.absent(),
  }) : fecha = Value(fecha),
       turno = Value(turno),
       planillero = Value(planillero);
  static Insertable<Reporte> custom({
    Expression<int>? id,
    Expression<DateTime>? fecha,
    Expression<String>? turno,
    Expression<String>? planillero,
    Expression<int>? supabaseId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fecha != null) 'fecha': fecha,
      if (turno != null) 'turno': turno,
      if (planillero != null) 'planillero': planillero,
      if (supabaseId != null) 'supabase_id': supabaseId,
    });
  }

  ReportesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? fecha,
    Value<String>? turno,
    Value<String>? planillero,
    Value<int?>? supabaseId,
  }) {
    return ReportesCompanion(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      turno: turno ?? this.turno,
      planillero: planillero ?? this.planillero,
      supabaseId: supabaseId ?? this.supabaseId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (turno.present) {
      map['turno'] = Variable<String>(turno.value);
    }
    if (planillero.present) {
      map['planillero'] = Variable<String>(planillero.value);
    }
    if (supabaseId.present) {
      map['supabase_id'] = Variable<int>(supabaseId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReportesCompanion(')
          ..write('id: $id, ')
          ..write('fecha: $fecha, ')
          ..write('turno: $turno, ')
          ..write('planillero: $planillero, ')
          ..write('supabaseId: $supabaseId')
          ..write(')'))
        .toString();
  }
}

class $ReporteAreasTable extends ReporteAreas
    with TableInfo<$ReporteAreasTable, ReporteArea> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReporteAreasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _reporteIdMeta = const VerificationMeta(
    'reporteId',
  );
  @override
  late final GeneratedColumn<int> reporteId = GeneratedColumn<int>(
    'reporte_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES reportes (id)',
    ),
  );
  static const VerificationMeta _areaNombreMeta = const VerificationMeta(
    'areaNombre',
  );
  @override
  late final GeneratedColumn<String> areaNombre = GeneratedColumn<String>(
    'area_nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cantidadMeta = const VerificationMeta(
    'cantidad',
  );
  @override
  late final GeneratedColumn<int> cantidad = GeneratedColumn<int>(
    'cantidad',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _horaInicioMeta = const VerificationMeta(
    'horaInicio',
  );
  @override
  late final GeneratedColumn<String> horaInicio = GeneratedColumn<String>(
    'hora_inicio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _horaFinMeta = const VerificationMeta(
    'horaFin',
  );
  @override
  late final GeneratedColumn<String> horaFin = GeneratedColumn<String>(
    'hora_fin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reporteId,
    areaNombre,
    cantidad,
    horaInicio,
    horaFin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reporte_areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReporteArea> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reporte_id')) {
      context.handle(
        _reporteIdMeta,
        reporteId.isAcceptableOrUnknown(data['reporte_id']!, _reporteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reporteIdMeta);
    }
    if (data.containsKey('area_nombre')) {
      context.handle(
        _areaNombreMeta,
        areaNombre.isAcceptableOrUnknown(data['area_nombre']!, _areaNombreMeta),
      );
    } else if (isInserting) {
      context.missing(_areaNombreMeta);
    }
    if (data.containsKey('cantidad')) {
      context.handle(
        _cantidadMeta,
        cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta),
      );
    }
    if (data.containsKey('hora_inicio')) {
      context.handle(
        _horaInicioMeta,
        horaInicio.isAcceptableOrUnknown(data['hora_inicio']!, _horaInicioMeta),
      );
    }
    if (data.containsKey('hora_fin')) {
      context.handle(
        _horaFinMeta,
        horaFin.isAcceptableOrUnknown(data['hora_fin']!, _horaFinMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReporteArea map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReporteArea(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reporteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reporte_id'],
      )!,
      areaNombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_nombre'],
      )!,
      cantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cantidad'],
      )!,
      horaInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hora_inicio'],
      ),
      horaFin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hora_fin'],
      ),
    );
  }

  @override
  $ReporteAreasTable createAlias(String alias) {
    return $ReporteAreasTable(attachedDatabase, alias);
  }
}

class ReporteArea extends DataClass implements Insertable<ReporteArea> {
  final int id;
  final int reporteId;
  final String areaNombre;
  final int cantidad;
  final String? horaInicio;
  final String? horaFin;
  const ReporteArea({
    required this.id,
    required this.reporteId,
    required this.areaNombre,
    required this.cantidad,
    this.horaInicio,
    this.horaFin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reporte_id'] = Variable<int>(reporteId);
    map['area_nombre'] = Variable<String>(areaNombre);
    map['cantidad'] = Variable<int>(cantidad);
    if (!nullToAbsent || horaInicio != null) {
      map['hora_inicio'] = Variable<String>(horaInicio);
    }
    if (!nullToAbsent || horaFin != null) {
      map['hora_fin'] = Variable<String>(horaFin);
    }
    return map;
  }

  ReporteAreasCompanion toCompanion(bool nullToAbsent) {
    return ReporteAreasCompanion(
      id: Value(id),
      reporteId: Value(reporteId),
      areaNombre: Value(areaNombre),
      cantidad: Value(cantidad),
      horaInicio: horaInicio == null && nullToAbsent
          ? const Value.absent()
          : Value(horaInicio),
      horaFin: horaFin == null && nullToAbsent
          ? const Value.absent()
          : Value(horaFin),
    );
  }

  factory ReporteArea.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReporteArea(
      id: serializer.fromJson<int>(json['id']),
      reporteId: serializer.fromJson<int>(json['reporteId']),
      areaNombre: serializer.fromJson<String>(json['areaNombre']),
      cantidad: serializer.fromJson<int>(json['cantidad']),
      horaInicio: serializer.fromJson<String?>(json['horaInicio']),
      horaFin: serializer.fromJson<String?>(json['horaFin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reporteId': serializer.toJson<int>(reporteId),
      'areaNombre': serializer.toJson<String>(areaNombre),
      'cantidad': serializer.toJson<int>(cantidad),
      'horaInicio': serializer.toJson<String?>(horaInicio),
      'horaFin': serializer.toJson<String?>(horaFin),
    };
  }

  ReporteArea copyWith({
    int? id,
    int? reporteId,
    String? areaNombre,
    int? cantidad,
    Value<String?> horaInicio = const Value.absent(),
    Value<String?> horaFin = const Value.absent(),
  }) => ReporteArea(
    id: id ?? this.id,
    reporteId: reporteId ?? this.reporteId,
    areaNombre: areaNombre ?? this.areaNombre,
    cantidad: cantidad ?? this.cantidad,
    horaInicio: horaInicio.present ? horaInicio.value : this.horaInicio,
    horaFin: horaFin.present ? horaFin.value : this.horaFin,
  );
  ReporteArea copyWithCompanion(ReporteAreasCompanion data) {
    return ReporteArea(
      id: data.id.present ? data.id.value : this.id,
      reporteId: data.reporteId.present ? data.reporteId.value : this.reporteId,
      areaNombre: data.areaNombre.present
          ? data.areaNombre.value
          : this.areaNombre,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      horaInicio: data.horaInicio.present
          ? data.horaInicio.value
          : this.horaInicio,
      horaFin: data.horaFin.present ? data.horaFin.value : this.horaFin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReporteArea(')
          ..write('id: $id, ')
          ..write('reporteId: $reporteId, ')
          ..write('areaNombre: $areaNombre, ')
          ..write('cantidad: $cantidad, ')
          ..write('horaInicio: $horaInicio, ')
          ..write('horaFin: $horaFin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, reporteId, areaNombre, cantidad, horaInicio, horaFin);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReporteArea &&
          other.id == this.id &&
          other.reporteId == this.reporteId &&
          other.areaNombre == this.areaNombre &&
          other.cantidad == this.cantidad &&
          other.horaInicio == this.horaInicio &&
          other.horaFin == this.horaFin);
}

class ReporteAreasCompanion extends UpdateCompanion<ReporteArea> {
  final Value<int> id;
  final Value<int> reporteId;
  final Value<String> areaNombre;
  final Value<int> cantidad;
  final Value<String?> horaInicio;
  final Value<String?> horaFin;
  const ReporteAreasCompanion({
    this.id = const Value.absent(),
    this.reporteId = const Value.absent(),
    this.areaNombre = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.horaInicio = const Value.absent(),
    this.horaFin = const Value.absent(),
  });
  ReporteAreasCompanion.insert({
    this.id = const Value.absent(),
    required int reporteId,
    required String areaNombre,
    this.cantidad = const Value.absent(),
    this.horaInicio = const Value.absent(),
    this.horaFin = const Value.absent(),
  }) : reporteId = Value(reporteId),
       areaNombre = Value(areaNombre);
  static Insertable<ReporteArea> custom({
    Expression<int>? id,
    Expression<int>? reporteId,
    Expression<String>? areaNombre,
    Expression<int>? cantidad,
    Expression<String>? horaInicio,
    Expression<String>? horaFin,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reporteId != null) 'reporte_id': reporteId,
      if (areaNombre != null) 'area_nombre': areaNombre,
      if (cantidad != null) 'cantidad': cantidad,
      if (horaInicio != null) 'hora_inicio': horaInicio,
      if (horaFin != null) 'hora_fin': horaFin,
    });
  }

  ReporteAreasCompanion copyWith({
    Value<int>? id,
    Value<int>? reporteId,
    Value<String>? areaNombre,
    Value<int>? cantidad,
    Value<String?>? horaInicio,
    Value<String?>? horaFin,
  }) {
    return ReporteAreasCompanion(
      id: id ?? this.id,
      reporteId: reporteId ?? this.reporteId,
      areaNombre: areaNombre ?? this.areaNombre,
      cantidad: cantidad ?? this.cantidad,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reporteId.present) {
      map['reporte_id'] = Variable<int>(reporteId.value);
    }
    if (areaNombre.present) {
      map['area_nombre'] = Variable<String>(areaNombre.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<int>(cantidad.value);
    }
    if (horaInicio.present) {
      map['hora_inicio'] = Variable<String>(horaInicio.value);
    }
    if (horaFin.present) {
      map['hora_fin'] = Variable<String>(horaFin.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReporteAreasCompanion(')
          ..write('id: $id, ')
          ..write('reporteId: $reporteId, ')
          ..write('areaNombre: $areaNombre, ')
          ..write('cantidad: $cantidad, ')
          ..write('horaInicio: $horaInicio, ')
          ..write('horaFin: $horaFin')
          ..write(')'))
        .toString();
  }
}

class $ReporteAreaDesglosesTable extends ReporteAreaDesgloses
    with TableInfo<$ReporteAreaDesglosesTable, ReporteAreaDesglose> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReporteAreaDesglosesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _reporteAreaIdMeta = const VerificationMeta(
    'reporteAreaId',
  );
  @override
  late final GeneratedColumn<int> reporteAreaId = GeneratedColumn<int>(
    'reporte_area_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES reporte_areas (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personasMeta = const VerificationMeta(
    'personas',
  );
  @override
  late final GeneratedColumn<int> personas = GeneratedColumn<int>(
    'personas',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _kilosMeta = const VerificationMeta('kilos');
  @override
  late final GeneratedColumn<double> kilos = GeneratedColumn<double>(
    'kilos',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reporteAreaId,
    categoria,
    personas,
    kilos,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reporte_area_desgloses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReporteAreaDesglose> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reporte_area_id')) {
      context.handle(
        _reporteAreaIdMeta,
        reporteAreaId.isAcceptableOrUnknown(
          data['reporte_area_id']!,
          _reporteAreaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reporteAreaIdMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    } else if (isInserting) {
      context.missing(_categoriaMeta);
    }
    if (data.containsKey('personas')) {
      context.handle(
        _personasMeta,
        personas.isAcceptableOrUnknown(data['personas']!, _personasMeta),
      );
    }
    if (data.containsKey('kilos')) {
      context.handle(
        _kilosMeta,
        kilos.isAcceptableOrUnknown(data['kilos']!, _kilosMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReporteAreaDesglose map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReporteAreaDesglose(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reporteAreaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reporte_area_id'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      )!,
      personas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}personas'],
      )!,
      kilos: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kilos'],
      )!,
    );
  }

  @override
  $ReporteAreaDesglosesTable createAlias(String alias) {
    return $ReporteAreaDesglosesTable(attachedDatabase, alias);
  }
}

class ReporteAreaDesglose extends DataClass
    implements Insertable<ReporteAreaDesglose> {
  final int id;
  final int reporteAreaId;
  final String categoria;
  final int personas;
  final double kilos;
  const ReporteAreaDesglose({
    required this.id,
    required this.reporteAreaId,
    required this.categoria,
    required this.personas,
    required this.kilos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reporte_area_id'] = Variable<int>(reporteAreaId);
    map['categoria'] = Variable<String>(categoria);
    map['personas'] = Variable<int>(personas);
    map['kilos'] = Variable<double>(kilos);
    return map;
  }

  ReporteAreaDesglosesCompanion toCompanion(bool nullToAbsent) {
    return ReporteAreaDesglosesCompanion(
      id: Value(id),
      reporteAreaId: Value(reporteAreaId),
      categoria: Value(categoria),
      personas: Value(personas),
      kilos: Value(kilos),
    );
  }

  factory ReporteAreaDesglose.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReporteAreaDesglose(
      id: serializer.fromJson<int>(json['id']),
      reporteAreaId: serializer.fromJson<int>(json['reporteAreaId']),
      categoria: serializer.fromJson<String>(json['categoria']),
      personas: serializer.fromJson<int>(json['personas']),
      kilos: serializer.fromJson<double>(json['kilos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reporteAreaId': serializer.toJson<int>(reporteAreaId),
      'categoria': serializer.toJson<String>(categoria),
      'personas': serializer.toJson<int>(personas),
      'kilos': serializer.toJson<double>(kilos),
    };
  }

  ReporteAreaDesglose copyWith({
    int? id,
    int? reporteAreaId,
    String? categoria,
    int? personas,
    double? kilos,
  }) => ReporteAreaDesglose(
    id: id ?? this.id,
    reporteAreaId: reporteAreaId ?? this.reporteAreaId,
    categoria: categoria ?? this.categoria,
    personas: personas ?? this.personas,
    kilos: kilos ?? this.kilos,
  );
  ReporteAreaDesglose copyWithCompanion(ReporteAreaDesglosesCompanion data) {
    return ReporteAreaDesglose(
      id: data.id.present ? data.id.value : this.id,
      reporteAreaId: data.reporteAreaId.present
          ? data.reporteAreaId.value
          : this.reporteAreaId,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      personas: data.personas.present ? data.personas.value : this.personas,
      kilos: data.kilos.present ? data.kilos.value : this.kilos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReporteAreaDesglose(')
          ..write('id: $id, ')
          ..write('reporteAreaId: $reporteAreaId, ')
          ..write('categoria: $categoria, ')
          ..write('personas: $personas, ')
          ..write('kilos: $kilos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, reporteAreaId, categoria, personas, kilos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReporteAreaDesglose &&
          other.id == this.id &&
          other.reporteAreaId == this.reporteAreaId &&
          other.categoria == this.categoria &&
          other.personas == this.personas &&
          other.kilos == this.kilos);
}

class ReporteAreaDesglosesCompanion
    extends UpdateCompanion<ReporteAreaDesglose> {
  final Value<int> id;
  final Value<int> reporteAreaId;
  final Value<String> categoria;
  final Value<int> personas;
  final Value<double> kilos;
  const ReporteAreaDesglosesCompanion({
    this.id = const Value.absent(),
    this.reporteAreaId = const Value.absent(),
    this.categoria = const Value.absent(),
    this.personas = const Value.absent(),
    this.kilos = const Value.absent(),
  });
  ReporteAreaDesglosesCompanion.insert({
    this.id = const Value.absent(),
    required int reporteAreaId,
    required String categoria,
    this.personas = const Value.absent(),
    this.kilos = const Value.absent(),
  }) : reporteAreaId = Value(reporteAreaId),
       categoria = Value(categoria);
  static Insertable<ReporteAreaDesglose> custom({
    Expression<int>? id,
    Expression<int>? reporteAreaId,
    Expression<String>? categoria,
    Expression<int>? personas,
    Expression<double>? kilos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reporteAreaId != null) 'reporte_area_id': reporteAreaId,
      if (categoria != null) 'categoria': categoria,
      if (personas != null) 'personas': personas,
      if (kilos != null) 'kilos': kilos,
    });
  }

  ReporteAreaDesglosesCompanion copyWith({
    Value<int>? id,
    Value<int>? reporteAreaId,
    Value<String>? categoria,
    Value<int>? personas,
    Value<double>? kilos,
  }) {
    return ReporteAreaDesglosesCompanion(
      id: id ?? this.id,
      reporteAreaId: reporteAreaId ?? this.reporteAreaId,
      categoria: categoria ?? this.categoria,
      personas: personas ?? this.personas,
      kilos: kilos ?? this.kilos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reporteAreaId.present) {
      map['reporte_area_id'] = Variable<int>(reporteAreaId.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (personas.present) {
      map['personas'] = Variable<int>(personas.value);
    }
    if (kilos.present) {
      map['kilos'] = Variable<double>(kilos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReporteAreaDesglosesCompanion(')
          ..write('id: $id, ')
          ..write('reporteAreaId: $reporteAreaId, ')
          ..write('categoria: $categoria, ')
          ..write('personas: $personas, ')
          ..write('kilos: $kilos')
          ..write(')'))
        .toString();
  }
}

class $CuadrillasTable extends Cuadrillas
    with TableInfo<$CuadrillasTable, Cuadrilla> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CuadrillasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _reporteAreaIdMeta = const VerificationMeta(
    'reporteAreaId',
  );
  @override
  late final GeneratedColumn<int> reporteAreaId = GeneratedColumn<int>(
    'reporte_area_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES reporte_areas (id)',
    ),
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Cuadrilla'),
  );
  static const VerificationMeta _horaInicioMeta = const VerificationMeta(
    'horaInicio',
  );
  @override
  late final GeneratedColumn<String> horaInicio = GeneratedColumn<String>(
    'hora_inicio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _horaFinMeta = const VerificationMeta(
    'horaFin',
  );
  @override
  late final GeneratedColumn<String> horaFin = GeneratedColumn<String>(
    'hora_fin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kilosMeta = const VerificationMeta('kilos');
  @override
  late final GeneratedColumn<double> kilos = GeneratedColumn<double>(
    'kilos',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reporteAreaId,
    nombre,
    horaInicio,
    horaFin,
    kilos,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cuadrillas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cuadrilla> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reporte_area_id')) {
      context.handle(
        _reporteAreaIdMeta,
        reporteAreaId.isAcceptableOrUnknown(
          data['reporte_area_id']!,
          _reporteAreaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reporteAreaIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    }
    if (data.containsKey('hora_inicio')) {
      context.handle(
        _horaInicioMeta,
        horaInicio.isAcceptableOrUnknown(data['hora_inicio']!, _horaInicioMeta),
      );
    }
    if (data.containsKey('hora_fin')) {
      context.handle(
        _horaFinMeta,
        horaFin.isAcceptableOrUnknown(data['hora_fin']!, _horaFinMeta),
      );
    }
    if (data.containsKey('kilos')) {
      context.handle(
        _kilosMeta,
        kilos.isAcceptableOrUnknown(data['kilos']!, _kilosMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cuadrilla map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cuadrilla(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reporteAreaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reporte_area_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      horaInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hora_inicio'],
      ),
      horaFin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hora_fin'],
      ),
      kilos: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kilos'],
      ),
    );
  }

  @override
  $CuadrillasTable createAlias(String alias) {
    return $CuadrillasTable(attachedDatabase, alias);
  }
}

class Cuadrilla extends DataClass implements Insertable<Cuadrilla> {
  final int id;
  final int reporteAreaId;
  final String nombre;
  final String? horaInicio;
  final String? horaFin;
  final double? kilos;
  const Cuadrilla({
    required this.id,
    required this.reporteAreaId,
    required this.nombre,
    this.horaInicio,
    this.horaFin,
    this.kilos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reporte_area_id'] = Variable<int>(reporteAreaId);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || horaInicio != null) {
      map['hora_inicio'] = Variable<String>(horaInicio);
    }
    if (!nullToAbsent || horaFin != null) {
      map['hora_fin'] = Variable<String>(horaFin);
    }
    if (!nullToAbsent || kilos != null) {
      map['kilos'] = Variable<double>(kilos);
    }
    return map;
  }

  CuadrillasCompanion toCompanion(bool nullToAbsent) {
    return CuadrillasCompanion(
      id: Value(id),
      reporteAreaId: Value(reporteAreaId),
      nombre: Value(nombre),
      horaInicio: horaInicio == null && nullToAbsent
          ? const Value.absent()
          : Value(horaInicio),
      horaFin: horaFin == null && nullToAbsent
          ? const Value.absent()
          : Value(horaFin),
      kilos: kilos == null && nullToAbsent
          ? const Value.absent()
          : Value(kilos),
    );
  }

  factory Cuadrilla.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cuadrilla(
      id: serializer.fromJson<int>(json['id']),
      reporteAreaId: serializer.fromJson<int>(json['reporteAreaId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      horaInicio: serializer.fromJson<String?>(json['horaInicio']),
      horaFin: serializer.fromJson<String?>(json['horaFin']),
      kilos: serializer.fromJson<double?>(json['kilos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reporteAreaId': serializer.toJson<int>(reporteAreaId),
      'nombre': serializer.toJson<String>(nombre),
      'horaInicio': serializer.toJson<String?>(horaInicio),
      'horaFin': serializer.toJson<String?>(horaFin),
      'kilos': serializer.toJson<double?>(kilos),
    };
  }

  Cuadrilla copyWith({
    int? id,
    int? reporteAreaId,
    String? nombre,
    Value<String?> horaInicio = const Value.absent(),
    Value<String?> horaFin = const Value.absent(),
    Value<double?> kilos = const Value.absent(),
  }) => Cuadrilla(
    id: id ?? this.id,
    reporteAreaId: reporteAreaId ?? this.reporteAreaId,
    nombre: nombre ?? this.nombre,
    horaInicio: horaInicio.present ? horaInicio.value : this.horaInicio,
    horaFin: horaFin.present ? horaFin.value : this.horaFin,
    kilos: kilos.present ? kilos.value : this.kilos,
  );
  Cuadrilla copyWithCompanion(CuadrillasCompanion data) {
    return Cuadrilla(
      id: data.id.present ? data.id.value : this.id,
      reporteAreaId: data.reporteAreaId.present
          ? data.reporteAreaId.value
          : this.reporteAreaId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      horaInicio: data.horaInicio.present
          ? data.horaInicio.value
          : this.horaInicio,
      horaFin: data.horaFin.present ? data.horaFin.value : this.horaFin,
      kilos: data.kilos.present ? data.kilos.value : this.kilos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cuadrilla(')
          ..write('id: $id, ')
          ..write('reporteAreaId: $reporteAreaId, ')
          ..write('nombre: $nombre, ')
          ..write('horaInicio: $horaInicio, ')
          ..write('horaFin: $horaFin, ')
          ..write('kilos: $kilos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, reporteAreaId, nombre, horaInicio, horaFin, kilos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cuadrilla &&
          other.id == this.id &&
          other.reporteAreaId == this.reporteAreaId &&
          other.nombre == this.nombre &&
          other.horaInicio == this.horaInicio &&
          other.horaFin == this.horaFin &&
          other.kilos == this.kilos);
}

class CuadrillasCompanion extends UpdateCompanion<Cuadrilla> {
  final Value<int> id;
  final Value<int> reporteAreaId;
  final Value<String> nombre;
  final Value<String?> horaInicio;
  final Value<String?> horaFin;
  final Value<double?> kilos;
  const CuadrillasCompanion({
    this.id = const Value.absent(),
    this.reporteAreaId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.horaInicio = const Value.absent(),
    this.horaFin = const Value.absent(),
    this.kilos = const Value.absent(),
  });
  CuadrillasCompanion.insert({
    this.id = const Value.absent(),
    required int reporteAreaId,
    this.nombre = const Value.absent(),
    this.horaInicio = const Value.absent(),
    this.horaFin = const Value.absent(),
    this.kilos = const Value.absent(),
  }) : reporteAreaId = Value(reporteAreaId);
  static Insertable<Cuadrilla> custom({
    Expression<int>? id,
    Expression<int>? reporteAreaId,
    Expression<String>? nombre,
    Expression<String>? horaInicio,
    Expression<String>? horaFin,
    Expression<double>? kilos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reporteAreaId != null) 'reporte_area_id': reporteAreaId,
      if (nombre != null) 'nombre': nombre,
      if (horaInicio != null) 'hora_inicio': horaInicio,
      if (horaFin != null) 'hora_fin': horaFin,
      if (kilos != null) 'kilos': kilos,
    });
  }

  CuadrillasCompanion copyWith({
    Value<int>? id,
    Value<int>? reporteAreaId,
    Value<String>? nombre,
    Value<String?>? horaInicio,
    Value<String?>? horaFin,
    Value<double?>? kilos,
  }) {
    return CuadrillasCompanion(
      id: id ?? this.id,
      reporteAreaId: reporteAreaId ?? this.reporteAreaId,
      nombre: nombre ?? this.nombre,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      kilos: kilos ?? this.kilos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reporteAreaId.present) {
      map['reporte_area_id'] = Variable<int>(reporteAreaId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (horaInicio.present) {
      map['hora_inicio'] = Variable<String>(horaInicio.value);
    }
    if (horaFin.present) {
      map['hora_fin'] = Variable<String>(horaFin.value);
    }
    if (kilos.present) {
      map['kilos'] = Variable<double>(kilos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CuadrillasCompanion(')
          ..write('id: $id, ')
          ..write('reporteAreaId: $reporteAreaId, ')
          ..write('nombre: $nombre, ')
          ..write('horaInicio: $horaInicio, ')
          ..write('horaFin: $horaFin, ')
          ..write('kilos: $kilos')
          ..write(')'))
        .toString();
  }
}

class $CuadrillaDesglosesTable extends CuadrillaDesgloses
    with TableInfo<$CuadrillaDesglosesTable, CuadrillaDesglose> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CuadrillaDesglosesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cuadrillaIdMeta = const VerificationMeta(
    'cuadrillaId',
  );
  @override
  late final GeneratedColumn<int> cuadrillaId = GeneratedColumn<int>(
    'cuadrilla_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuadrillas (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personasMeta = const VerificationMeta(
    'personas',
  );
  @override
  late final GeneratedColumn<int> personas = GeneratedColumn<int>(
    'personas',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _kilosMeta = const VerificationMeta('kilos');
  @override
  late final GeneratedColumn<double> kilos = GeneratedColumn<double>(
    'kilos',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cuadrillaId,
    categoria,
    personas,
    kilos,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cuadrilla_desgloses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CuadrillaDesglose> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cuadrilla_id')) {
      context.handle(
        _cuadrillaIdMeta,
        cuadrillaId.isAcceptableOrUnknown(
          data['cuadrilla_id']!,
          _cuadrillaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cuadrillaIdMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    } else if (isInserting) {
      context.missing(_categoriaMeta);
    }
    if (data.containsKey('personas')) {
      context.handle(
        _personasMeta,
        personas.isAcceptableOrUnknown(data['personas']!, _personasMeta),
      );
    }
    if (data.containsKey('kilos')) {
      context.handle(
        _kilosMeta,
        kilos.isAcceptableOrUnknown(data['kilos']!, _kilosMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CuadrillaDesglose map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CuadrillaDesglose(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cuadrillaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuadrilla_id'],
      )!,
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      )!,
      personas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}personas'],
      )!,
      kilos: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kilos'],
      )!,
    );
  }

  @override
  $CuadrillaDesglosesTable createAlias(String alias) {
    return $CuadrillaDesglosesTable(attachedDatabase, alias);
  }
}

class CuadrillaDesglose extends DataClass
    implements Insertable<CuadrillaDesglose> {
  final int id;
  final int cuadrillaId;
  final String categoria;
  final int personas;
  final double kilos;
  const CuadrillaDesglose({
    required this.id,
    required this.cuadrillaId,
    required this.categoria,
    required this.personas,
    required this.kilos,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cuadrilla_id'] = Variable<int>(cuadrillaId);
    map['categoria'] = Variable<String>(categoria);
    map['personas'] = Variable<int>(personas);
    map['kilos'] = Variable<double>(kilos);
    return map;
  }

  CuadrillaDesglosesCompanion toCompanion(bool nullToAbsent) {
    return CuadrillaDesglosesCompanion(
      id: Value(id),
      cuadrillaId: Value(cuadrillaId),
      categoria: Value(categoria),
      personas: Value(personas),
      kilos: Value(kilos),
    );
  }

  factory CuadrillaDesglose.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CuadrillaDesglose(
      id: serializer.fromJson<int>(json['id']),
      cuadrillaId: serializer.fromJson<int>(json['cuadrillaId']),
      categoria: serializer.fromJson<String>(json['categoria']),
      personas: serializer.fromJson<int>(json['personas']),
      kilos: serializer.fromJson<double>(json['kilos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cuadrillaId': serializer.toJson<int>(cuadrillaId),
      'categoria': serializer.toJson<String>(categoria),
      'personas': serializer.toJson<int>(personas),
      'kilos': serializer.toJson<double>(kilos),
    };
  }

  CuadrillaDesglose copyWith({
    int? id,
    int? cuadrillaId,
    String? categoria,
    int? personas,
    double? kilos,
  }) => CuadrillaDesglose(
    id: id ?? this.id,
    cuadrillaId: cuadrillaId ?? this.cuadrillaId,
    categoria: categoria ?? this.categoria,
    personas: personas ?? this.personas,
    kilos: kilos ?? this.kilos,
  );
  CuadrillaDesglose copyWithCompanion(CuadrillaDesglosesCompanion data) {
    return CuadrillaDesglose(
      id: data.id.present ? data.id.value : this.id,
      cuadrillaId: data.cuadrillaId.present
          ? data.cuadrillaId.value
          : this.cuadrillaId,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      personas: data.personas.present ? data.personas.value : this.personas,
      kilos: data.kilos.present ? data.kilos.value : this.kilos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CuadrillaDesglose(')
          ..write('id: $id, ')
          ..write('cuadrillaId: $cuadrillaId, ')
          ..write('categoria: $categoria, ')
          ..write('personas: $personas, ')
          ..write('kilos: $kilos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cuadrillaId, categoria, personas, kilos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CuadrillaDesglose &&
          other.id == this.id &&
          other.cuadrillaId == this.cuadrillaId &&
          other.categoria == this.categoria &&
          other.personas == this.personas &&
          other.kilos == this.kilos);
}

class CuadrillaDesglosesCompanion extends UpdateCompanion<CuadrillaDesglose> {
  final Value<int> id;
  final Value<int> cuadrillaId;
  final Value<String> categoria;
  final Value<int> personas;
  final Value<double> kilos;
  const CuadrillaDesglosesCompanion({
    this.id = const Value.absent(),
    this.cuadrillaId = const Value.absent(),
    this.categoria = const Value.absent(),
    this.personas = const Value.absent(),
    this.kilos = const Value.absent(),
  });
  CuadrillaDesglosesCompanion.insert({
    this.id = const Value.absent(),
    required int cuadrillaId,
    required String categoria,
    this.personas = const Value.absent(),
    this.kilos = const Value.absent(),
  }) : cuadrillaId = Value(cuadrillaId),
       categoria = Value(categoria);
  static Insertable<CuadrillaDesglose> custom({
    Expression<int>? id,
    Expression<int>? cuadrillaId,
    Expression<String>? categoria,
    Expression<int>? personas,
    Expression<double>? kilos,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cuadrillaId != null) 'cuadrilla_id': cuadrillaId,
      if (categoria != null) 'categoria': categoria,
      if (personas != null) 'personas': personas,
      if (kilos != null) 'kilos': kilos,
    });
  }

  CuadrillaDesglosesCompanion copyWith({
    Value<int>? id,
    Value<int>? cuadrillaId,
    Value<String>? categoria,
    Value<int>? personas,
    Value<double>? kilos,
  }) {
    return CuadrillaDesglosesCompanion(
      id: id ?? this.id,
      cuadrillaId: cuadrillaId ?? this.cuadrillaId,
      categoria: categoria ?? this.categoria,
      personas: personas ?? this.personas,
      kilos: kilos ?? this.kilos,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cuadrillaId.present) {
      map['cuadrilla_id'] = Variable<int>(cuadrillaId.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (personas.present) {
      map['personas'] = Variable<int>(personas.value);
    }
    if (kilos.present) {
      map['kilos'] = Variable<double>(kilos.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CuadrillaDesglosesCompanion(')
          ..write('id: $id, ')
          ..write('cuadrillaId: $cuadrillaId, ')
          ..write('categoria: $categoria, ')
          ..write('personas: $personas, ')
          ..write('kilos: $kilos')
          ..write(')'))
        .toString();
  }
}

class $IntegrantesTable extends Integrantes
    with TableInfo<$IntegrantesTable, Integrante> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntegrantesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cuadrillaIdMeta = const VerificationMeta(
    'cuadrillaId',
  );
  @override
  late final GeneratedColumn<int> cuadrillaId = GeneratedColumn<int>(
    'cuadrilla_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cuadrillas (id)',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _horaInicioMeta = const VerificationMeta(
    'horaInicio',
  );
  @override
  late final GeneratedColumn<String> horaInicio = GeneratedColumn<String>(
    'hora_inicio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _horaFinMeta = const VerificationMeta(
    'horaFin',
  );
  @override
  late final GeneratedColumn<String> horaFin = GeneratedColumn<String>(
    'hora_fin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _horasMeta = const VerificationMeta('horas');
  @override
  late final GeneratedColumn<double> horas = GeneratedColumn<double>(
    'horas',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _laboresMeta = const VerificationMeta(
    'labores',
  );
  @override
  late final GeneratedColumn<String> labores = GeneratedColumn<String>(
    'labores',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cuadrillaId,
    code,
    nombre,
    horaInicio,
    horaFin,
    horas,
    labores,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'integrantes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Integrante> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cuadrilla_id')) {
      context.handle(
        _cuadrillaIdMeta,
        cuadrillaId.isAcceptableOrUnknown(
          data['cuadrilla_id']!,
          _cuadrillaIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cuadrillaIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('hora_inicio')) {
      context.handle(
        _horaInicioMeta,
        horaInicio.isAcceptableOrUnknown(data['hora_inicio']!, _horaInicioMeta),
      );
    }
    if (data.containsKey('hora_fin')) {
      context.handle(
        _horaFinMeta,
        horaFin.isAcceptableOrUnknown(data['hora_fin']!, _horaFinMeta),
      );
    }
    if (data.containsKey('horas')) {
      context.handle(
        _horasMeta,
        horas.isAcceptableOrUnknown(data['horas']!, _horasMeta),
      );
    }
    if (data.containsKey('labores')) {
      context.handle(
        _laboresMeta,
        labores.isAcceptableOrUnknown(data['labores']!, _laboresMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Integrante map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Integrante(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cuadrillaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cuadrilla_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      horaInicio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hora_inicio'],
      ),
      horaFin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hora_fin'],
      ),
      horas: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}horas'],
      ),
      labores: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}labores'],
      ),
    );
  }

  @override
  $IntegrantesTable createAlias(String alias) {
    return $IntegrantesTable(attachedDatabase, alias);
  }
}

class Integrante extends DataClass implements Insertable<Integrante> {
  final int id;
  final int cuadrillaId;
  final String? code;
  final String nombre;
  final String? horaInicio;
  final String? horaFin;
  final double? horas;
  final String? labores;
  const Integrante({
    required this.id,
    required this.cuadrillaId,
    this.code,
    required this.nombre,
    this.horaInicio,
    this.horaFin,
    this.horas,
    this.labores,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cuadrilla_id'] = Variable<int>(cuadrillaId);
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || horaInicio != null) {
      map['hora_inicio'] = Variable<String>(horaInicio);
    }
    if (!nullToAbsent || horaFin != null) {
      map['hora_fin'] = Variable<String>(horaFin);
    }
    if (!nullToAbsent || horas != null) {
      map['horas'] = Variable<double>(horas);
    }
    if (!nullToAbsent || labores != null) {
      map['labores'] = Variable<String>(labores);
    }
    return map;
  }

  IntegrantesCompanion toCompanion(bool nullToAbsent) {
    return IntegrantesCompanion(
      id: Value(id),
      cuadrillaId: Value(cuadrillaId),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      nombre: Value(nombre),
      horaInicio: horaInicio == null && nullToAbsent
          ? const Value.absent()
          : Value(horaInicio),
      horaFin: horaFin == null && nullToAbsent
          ? const Value.absent()
          : Value(horaFin),
      horas: horas == null && nullToAbsent
          ? const Value.absent()
          : Value(horas),
      labores: labores == null && nullToAbsent
          ? const Value.absent()
          : Value(labores),
    );
  }

  factory Integrante.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Integrante(
      id: serializer.fromJson<int>(json['id']),
      cuadrillaId: serializer.fromJson<int>(json['cuadrillaId']),
      code: serializer.fromJson<String?>(json['code']),
      nombre: serializer.fromJson<String>(json['nombre']),
      horaInicio: serializer.fromJson<String?>(json['horaInicio']),
      horaFin: serializer.fromJson<String?>(json['horaFin']),
      horas: serializer.fromJson<double?>(json['horas']),
      labores: serializer.fromJson<String?>(json['labores']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cuadrillaId': serializer.toJson<int>(cuadrillaId),
      'code': serializer.toJson<String?>(code),
      'nombre': serializer.toJson<String>(nombre),
      'horaInicio': serializer.toJson<String?>(horaInicio),
      'horaFin': serializer.toJson<String?>(horaFin),
      'horas': serializer.toJson<double?>(horas),
      'labores': serializer.toJson<String?>(labores),
    };
  }

  Integrante copyWith({
    int? id,
    int? cuadrillaId,
    Value<String?> code = const Value.absent(),
    String? nombre,
    Value<String?> horaInicio = const Value.absent(),
    Value<String?> horaFin = const Value.absent(),
    Value<double?> horas = const Value.absent(),
    Value<String?> labores = const Value.absent(),
  }) => Integrante(
    id: id ?? this.id,
    cuadrillaId: cuadrillaId ?? this.cuadrillaId,
    code: code.present ? code.value : this.code,
    nombre: nombre ?? this.nombre,
    horaInicio: horaInicio.present ? horaInicio.value : this.horaInicio,
    horaFin: horaFin.present ? horaFin.value : this.horaFin,
    horas: horas.present ? horas.value : this.horas,
    labores: labores.present ? labores.value : this.labores,
  );
  Integrante copyWithCompanion(IntegrantesCompanion data) {
    return Integrante(
      id: data.id.present ? data.id.value : this.id,
      cuadrillaId: data.cuadrillaId.present
          ? data.cuadrillaId.value
          : this.cuadrillaId,
      code: data.code.present ? data.code.value : this.code,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      horaInicio: data.horaInicio.present
          ? data.horaInicio.value
          : this.horaInicio,
      horaFin: data.horaFin.present ? data.horaFin.value : this.horaFin,
      horas: data.horas.present ? data.horas.value : this.horas,
      labores: data.labores.present ? data.labores.value : this.labores,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Integrante(')
          ..write('id: $id, ')
          ..write('cuadrillaId: $cuadrillaId, ')
          ..write('code: $code, ')
          ..write('nombre: $nombre, ')
          ..write('horaInicio: $horaInicio, ')
          ..write('horaFin: $horaFin, ')
          ..write('horas: $horas, ')
          ..write('labores: $labores')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cuadrillaId,
    code,
    nombre,
    horaInicio,
    horaFin,
    horas,
    labores,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Integrante &&
          other.id == this.id &&
          other.cuadrillaId == this.cuadrillaId &&
          other.code == this.code &&
          other.nombre == this.nombre &&
          other.horaInicio == this.horaInicio &&
          other.horaFin == this.horaFin &&
          other.horas == this.horas &&
          other.labores == this.labores);
}

class IntegrantesCompanion extends UpdateCompanion<Integrante> {
  final Value<int> id;
  final Value<int> cuadrillaId;
  final Value<String?> code;
  final Value<String> nombre;
  final Value<String?> horaInicio;
  final Value<String?> horaFin;
  final Value<double?> horas;
  final Value<String?> labores;
  const IntegrantesCompanion({
    this.id = const Value.absent(),
    this.cuadrillaId = const Value.absent(),
    this.code = const Value.absent(),
    this.nombre = const Value.absent(),
    this.horaInicio = const Value.absent(),
    this.horaFin = const Value.absent(),
    this.horas = const Value.absent(),
    this.labores = const Value.absent(),
  });
  IntegrantesCompanion.insert({
    this.id = const Value.absent(),
    required int cuadrillaId,
    this.code = const Value.absent(),
    required String nombre,
    this.horaInicio = const Value.absent(),
    this.horaFin = const Value.absent(),
    this.horas = const Value.absent(),
    this.labores = const Value.absent(),
  }) : cuadrillaId = Value(cuadrillaId),
       nombre = Value(nombre);
  static Insertable<Integrante> custom({
    Expression<int>? id,
    Expression<int>? cuadrillaId,
    Expression<String>? code,
    Expression<String>? nombre,
    Expression<String>? horaInicio,
    Expression<String>? horaFin,
    Expression<double>? horas,
    Expression<String>? labores,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cuadrillaId != null) 'cuadrilla_id': cuadrillaId,
      if (code != null) 'code': code,
      if (nombre != null) 'nombre': nombre,
      if (horaInicio != null) 'hora_inicio': horaInicio,
      if (horaFin != null) 'hora_fin': horaFin,
      if (horas != null) 'horas': horas,
      if (labores != null) 'labores': labores,
    });
  }

  IntegrantesCompanion copyWith({
    Value<int>? id,
    Value<int>? cuadrillaId,
    Value<String?>? code,
    Value<String>? nombre,
    Value<String?>? horaInicio,
    Value<String?>? horaFin,
    Value<double?>? horas,
    Value<String?>? labores,
  }) {
    return IntegrantesCompanion(
      id: id ?? this.id,
      cuadrillaId: cuadrillaId ?? this.cuadrillaId,
      code: code ?? this.code,
      nombre: nombre ?? this.nombre,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      horas: horas ?? this.horas,
      labores: labores ?? this.labores,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cuadrillaId.present) {
      map['cuadrilla_id'] = Variable<int>(cuadrillaId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (horaInicio.present) {
      map['hora_inicio'] = Variable<String>(horaInicio.value);
    }
    if (horaFin.present) {
      map['hora_fin'] = Variable<String>(horaFin.value);
    }
    if (horas.present) {
      map['horas'] = Variable<double>(horas.value);
    }
    if (labores.present) {
      map['labores'] = Variable<String>(labores.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntegrantesCompanion(')
          ..write('id: $id, ')
          ..write('cuadrillaId: $cuadrillaId, ')
          ..write('code: $code, ')
          ..write('nombre: $nombre, ')
          ..write('horaInicio: $horaInicio, ')
          ..write('horaFin: $horaFin, ')
          ..write('horas: $horas, ')
          ..write('labores: $labores')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ReportesTable reportes = $ReportesTable(this);
  late final $ReporteAreasTable reporteAreas = $ReporteAreasTable(this);
  late final $ReporteAreaDesglosesTable reporteAreaDesgloses =
      $ReporteAreaDesglosesTable(this);
  late final $CuadrillasTable cuadrillas = $CuadrillasTable(this);
  late final $CuadrillaDesglosesTable cuadrillaDesgloses =
      $CuadrillaDesglosesTable(this);
  late final $IntegrantesTable integrantes = $IntegrantesTable(this);
  late final ReportesDao reportesDao = ReportesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    reportes,
    reporteAreas,
    reporteAreaDesgloses,
    cuadrillas,
    cuadrillaDesgloses,
    integrantes,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'reporte_areas',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reporte_area_desgloses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cuadrillas',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cuadrilla_desgloses', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ReportesTableCreateCompanionBuilder =
    ReportesCompanion Function({
      Value<int> id,
      required DateTime fecha,
      required String turno,
      required String planillero,
      Value<int?> supabaseId,
    });
typedef $$ReportesTableUpdateCompanionBuilder =
    ReportesCompanion Function({
      Value<int> id,
      Value<DateTime> fecha,
      Value<String> turno,
      Value<String> planillero,
      Value<int?> supabaseId,
    });

final class $$ReportesTableReferences
    extends BaseReferences<_$AppDatabase, $ReportesTable, Reporte> {
  $$ReportesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReporteAreasTable, List<ReporteArea>>
  _reporteAreasRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reporteAreas,
    aliasName: $_aliasNameGenerator(db.reportes.id, db.reporteAreas.reporteId),
  );

  $$ReporteAreasTableProcessedTableManager get reporteAreasRefs {
    final manager = $$ReporteAreasTableTableManager(
      $_db,
      $_db.reporteAreas,
    ).filter((f) => f.reporteId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reporteAreasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReportesTableFilterComposer
    extends Composer<_$AppDatabase, $ReportesTable> {
  $$ReportesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turno => $composableBuilder(
    column: $table.turno,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planillero => $composableBuilder(
    column: $table.planillero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> reporteAreasRefs(
    Expression<bool> Function($$ReporteAreasTableFilterComposer f) f,
  ) {
    final $$ReporteAreasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reporteAreas,
      getReferencedColumn: (t) => t.reporteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReporteAreasTableFilterComposer(
            $db: $db,
            $table: $db.reporteAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReportesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReportesTable> {
  $$ReportesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turno => $composableBuilder(
    column: $table.turno,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planillero => $composableBuilder(
    column: $table.planillero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReportesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReportesTable> {
  $$ReportesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get turno =>
      $composableBuilder(column: $table.turno, builder: (column) => column);

  GeneratedColumn<String> get planillero => $composableBuilder(
    column: $table.planillero,
    builder: (column) => column,
  );

  GeneratedColumn<int> get supabaseId => $composableBuilder(
    column: $table.supabaseId,
    builder: (column) => column,
  );

  Expression<T> reporteAreasRefs<T extends Object>(
    Expression<T> Function($$ReporteAreasTableAnnotationComposer a) f,
  ) {
    final $$ReporteAreasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reporteAreas,
      getReferencedColumn: (t) => t.reporteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReporteAreasTableAnnotationComposer(
            $db: $db,
            $table: $db.reporteAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReportesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReportesTable,
          Reporte,
          $$ReportesTableFilterComposer,
          $$ReportesTableOrderingComposer,
          $$ReportesTableAnnotationComposer,
          $$ReportesTableCreateCompanionBuilder,
          $$ReportesTableUpdateCompanionBuilder,
          (Reporte, $$ReportesTableReferences),
          Reporte,
          PrefetchHooks Function({bool reporteAreasRefs})
        > {
  $$ReportesTableTableManager(_$AppDatabase db, $ReportesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReportesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReportesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReportesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> turno = const Value.absent(),
                Value<String> planillero = const Value.absent(),
                Value<int?> supabaseId = const Value.absent(),
              }) => ReportesCompanion(
                id: id,
                fecha: fecha,
                turno: turno,
                planillero: planillero,
                supabaseId: supabaseId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime fecha,
                required String turno,
                required String planillero,
                Value<int?> supabaseId = const Value.absent(),
              }) => ReportesCompanion.insert(
                id: id,
                fecha: fecha,
                turno: turno,
                planillero: planillero,
                supabaseId: supabaseId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReportesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({reporteAreasRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (reporteAreasRefs) db.reporteAreas],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (reporteAreasRefs)
                    await $_getPrefetchedData<
                      Reporte,
                      $ReportesTable,
                      ReporteArea
                    >(
                      currentTable: table,
                      referencedTable: $$ReportesTableReferences
                          ._reporteAreasRefsTable(db),
                      managerFromTypedResult: (p0) => $$ReportesTableReferences(
                        db,
                        table,
                        p0,
                      ).reporteAreasRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.reporteId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ReportesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReportesTable,
      Reporte,
      $$ReportesTableFilterComposer,
      $$ReportesTableOrderingComposer,
      $$ReportesTableAnnotationComposer,
      $$ReportesTableCreateCompanionBuilder,
      $$ReportesTableUpdateCompanionBuilder,
      (Reporte, $$ReportesTableReferences),
      Reporte,
      PrefetchHooks Function({bool reporteAreasRefs})
    >;
typedef $$ReporteAreasTableCreateCompanionBuilder =
    ReporteAreasCompanion Function({
      Value<int> id,
      required int reporteId,
      required String areaNombre,
      Value<int> cantidad,
      Value<String?> horaInicio,
      Value<String?> horaFin,
    });
typedef $$ReporteAreasTableUpdateCompanionBuilder =
    ReporteAreasCompanion Function({
      Value<int> id,
      Value<int> reporteId,
      Value<String> areaNombre,
      Value<int> cantidad,
      Value<String?> horaInicio,
      Value<String?> horaFin,
    });

final class $$ReporteAreasTableReferences
    extends BaseReferences<_$AppDatabase, $ReporteAreasTable, ReporteArea> {
  $$ReporteAreasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReportesTable _reporteIdTable(_$AppDatabase db) =>
      db.reportes.createAlias(
        $_aliasNameGenerator(db.reporteAreas.reporteId, db.reportes.id),
      );

  $$ReportesTableProcessedTableManager get reporteId {
    final $_column = $_itemColumn<int>('reporte_id')!;

    final manager = $$ReportesTableTableManager(
      $_db,
      $_db.reportes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reporteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ReporteAreaDesglosesTable,
    List<ReporteAreaDesglose>
  >
  _reporteAreaDesglosesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.reporteAreaDesgloses,
        aliasName: $_aliasNameGenerator(
          db.reporteAreas.id,
          db.reporteAreaDesgloses.reporteAreaId,
        ),
      );

  $$ReporteAreaDesglosesTableProcessedTableManager
  get reporteAreaDesglosesRefs {
    final manager = $$ReporteAreaDesglosesTableTableManager(
      $_db,
      $_db.reporteAreaDesgloses,
    ).filter((f) => f.reporteAreaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _reporteAreaDesglosesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CuadrillasTable, List<Cuadrilla>>
  _cuadrillasRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cuadrillas,
    aliasName: $_aliasNameGenerator(
      db.reporteAreas.id,
      db.cuadrillas.reporteAreaId,
    ),
  );

  $$CuadrillasTableProcessedTableManager get cuadrillasRefs {
    final manager = $$CuadrillasTableTableManager(
      $_db,
      $_db.cuadrillas,
    ).filter((f) => f.reporteAreaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cuadrillasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReporteAreasTableFilterComposer
    extends Composer<_$AppDatabase, $ReporteAreasTable> {
  $$ReporteAreasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaNombre => $composableBuilder(
    column: $table.areaNombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get horaInicio => $composableBuilder(
    column: $table.horaInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get horaFin => $composableBuilder(
    column: $table.horaFin,
    builder: (column) => ColumnFilters(column),
  );

  $$ReportesTableFilterComposer get reporteId {
    final $$ReportesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reporteId,
      referencedTable: $db.reportes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReportesTableFilterComposer(
            $db: $db,
            $table: $db.reportes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> reporteAreaDesglosesRefs(
    Expression<bool> Function($$ReporteAreaDesglosesTableFilterComposer f) f,
  ) {
    final $$ReporteAreaDesglosesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reporteAreaDesgloses,
      getReferencedColumn: (t) => t.reporteAreaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReporteAreaDesglosesTableFilterComposer(
            $db: $db,
            $table: $db.reporteAreaDesgloses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cuadrillasRefs(
    Expression<bool> Function($$CuadrillasTableFilterComposer f) f,
  ) {
    final $$CuadrillasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cuadrillas,
      getReferencedColumn: (t) => t.reporteAreaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuadrillasTableFilterComposer(
            $db: $db,
            $table: $db.cuadrillas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReporteAreasTableOrderingComposer
    extends Composer<_$AppDatabase, $ReporteAreasTable> {
  $$ReporteAreasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaNombre => $composableBuilder(
    column: $table.areaNombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get horaInicio => $composableBuilder(
    column: $table.horaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get horaFin => $composableBuilder(
    column: $table.horaFin,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReportesTableOrderingComposer get reporteId {
    final $$ReportesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reporteId,
      referencedTable: $db.reportes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReportesTableOrderingComposer(
            $db: $db,
            $table: $db.reportes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReporteAreasTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReporteAreasTable> {
  $$ReporteAreasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get areaNombre => $composableBuilder(
    column: $table.areaNombre,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<String> get horaInicio => $composableBuilder(
    column: $table.horaInicio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get horaFin =>
      $composableBuilder(column: $table.horaFin, builder: (column) => column);

  $$ReportesTableAnnotationComposer get reporteId {
    final $$ReportesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reporteId,
      referencedTable: $db.reportes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReportesTableAnnotationComposer(
            $db: $db,
            $table: $db.reportes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> reporteAreaDesglosesRefs<T extends Object>(
    Expression<T> Function($$ReporteAreaDesglosesTableAnnotationComposer a) f,
  ) {
    final $$ReporteAreaDesglosesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.reporteAreaDesgloses,
          getReferencedColumn: (t) => t.reporteAreaId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ReporteAreaDesglosesTableAnnotationComposer(
                $db: $db,
                $table: $db.reporteAreaDesgloses,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> cuadrillasRefs<T extends Object>(
    Expression<T> Function($$CuadrillasTableAnnotationComposer a) f,
  ) {
    final $$CuadrillasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cuadrillas,
      getReferencedColumn: (t) => t.reporteAreaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuadrillasTableAnnotationComposer(
            $db: $db,
            $table: $db.cuadrillas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReporteAreasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReporteAreasTable,
          ReporteArea,
          $$ReporteAreasTableFilterComposer,
          $$ReporteAreasTableOrderingComposer,
          $$ReporteAreasTableAnnotationComposer,
          $$ReporteAreasTableCreateCompanionBuilder,
          $$ReporteAreasTableUpdateCompanionBuilder,
          (ReporteArea, $$ReporteAreasTableReferences),
          ReporteArea,
          PrefetchHooks Function({
            bool reporteId,
            bool reporteAreaDesglosesRefs,
            bool cuadrillasRefs,
          })
        > {
  $$ReporteAreasTableTableManager(_$AppDatabase db, $ReporteAreasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReporteAreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReporteAreasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReporteAreasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> reporteId = const Value.absent(),
                Value<String> areaNombre = const Value.absent(),
                Value<int> cantidad = const Value.absent(),
                Value<String?> horaInicio = const Value.absent(),
                Value<String?> horaFin = const Value.absent(),
              }) => ReporteAreasCompanion(
                id: id,
                reporteId: reporteId,
                areaNombre: areaNombre,
                cantidad: cantidad,
                horaInicio: horaInicio,
                horaFin: horaFin,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int reporteId,
                required String areaNombre,
                Value<int> cantidad = const Value.absent(),
                Value<String?> horaInicio = const Value.absent(),
                Value<String?> horaFin = const Value.absent(),
              }) => ReporteAreasCompanion.insert(
                id: id,
                reporteId: reporteId,
                areaNombre: areaNombre,
                cantidad: cantidad,
                horaInicio: horaInicio,
                horaFin: horaFin,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReporteAreasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                reporteId = false,
                reporteAreaDesglosesRefs = false,
                cuadrillasRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reporteAreaDesglosesRefs) db.reporteAreaDesgloses,
                    if (cuadrillasRefs) db.cuadrillas,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (reporteId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.reporteId,
                                    referencedTable:
                                        $$ReporteAreasTableReferences
                                            ._reporteIdTable(db),
                                    referencedColumn:
                                        $$ReporteAreasTableReferences
                                            ._reporteIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reporteAreaDesglosesRefs)
                        await $_getPrefetchedData<
                          ReporteArea,
                          $ReporteAreasTable,
                          ReporteAreaDesglose
                        >(
                          currentTable: table,
                          referencedTable: $$ReporteAreasTableReferences
                              ._reporteAreaDesglosesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReporteAreasTableReferences(
                                db,
                                table,
                                p0,
                              ).reporteAreaDesglosesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.reporteAreaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cuadrillasRefs)
                        await $_getPrefetchedData<
                          ReporteArea,
                          $ReporteAreasTable,
                          Cuadrilla
                        >(
                          currentTable: table,
                          referencedTable: $$ReporteAreasTableReferences
                              ._cuadrillasRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReporteAreasTableReferences(
                                db,
                                table,
                                p0,
                              ).cuadrillasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.reporteAreaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ReporteAreasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReporteAreasTable,
      ReporteArea,
      $$ReporteAreasTableFilterComposer,
      $$ReporteAreasTableOrderingComposer,
      $$ReporteAreasTableAnnotationComposer,
      $$ReporteAreasTableCreateCompanionBuilder,
      $$ReporteAreasTableUpdateCompanionBuilder,
      (ReporteArea, $$ReporteAreasTableReferences),
      ReporteArea,
      PrefetchHooks Function({
        bool reporteId,
        bool reporteAreaDesglosesRefs,
        bool cuadrillasRefs,
      })
    >;
typedef $$ReporteAreaDesglosesTableCreateCompanionBuilder =
    ReporteAreaDesglosesCompanion Function({
      Value<int> id,
      required int reporteAreaId,
      required String categoria,
      Value<int> personas,
      Value<double> kilos,
    });
typedef $$ReporteAreaDesglosesTableUpdateCompanionBuilder =
    ReporteAreaDesglosesCompanion Function({
      Value<int> id,
      Value<int> reporteAreaId,
      Value<String> categoria,
      Value<int> personas,
      Value<double> kilos,
    });

final class $$ReporteAreaDesglosesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReporteAreaDesglosesTable,
          ReporteAreaDesglose
        > {
  $$ReporteAreaDesglosesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ReporteAreasTable _reporteAreaIdTable(_$AppDatabase db) =>
      db.reporteAreas.createAlias(
        $_aliasNameGenerator(
          db.reporteAreaDesgloses.reporteAreaId,
          db.reporteAreas.id,
        ),
      );

  $$ReporteAreasTableProcessedTableManager get reporteAreaId {
    final $_column = $_itemColumn<int>('reporte_area_id')!;

    final manager = $$ReporteAreasTableTableManager(
      $_db,
      $_db.reporteAreas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reporteAreaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReporteAreaDesglosesTableFilterComposer
    extends Composer<_$AppDatabase, $ReporteAreaDesglosesTable> {
  $$ReporteAreaDesglosesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get personas => $composableBuilder(
    column: $table.personas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kilos => $composableBuilder(
    column: $table.kilos,
    builder: (column) => ColumnFilters(column),
  );

  $$ReporteAreasTableFilterComposer get reporteAreaId {
    final $$ReporteAreasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reporteAreaId,
      referencedTable: $db.reporteAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReporteAreasTableFilterComposer(
            $db: $db,
            $table: $db.reporteAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReporteAreaDesglosesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReporteAreaDesglosesTable> {
  $$ReporteAreaDesglosesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get personas => $composableBuilder(
    column: $table.personas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kilos => $composableBuilder(
    column: $table.kilos,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReporteAreasTableOrderingComposer get reporteAreaId {
    final $$ReporteAreasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reporteAreaId,
      referencedTable: $db.reporteAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReporteAreasTableOrderingComposer(
            $db: $db,
            $table: $db.reporteAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReporteAreaDesglosesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReporteAreaDesglosesTable> {
  $$ReporteAreaDesglosesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<int> get personas =>
      $composableBuilder(column: $table.personas, builder: (column) => column);

  GeneratedColumn<double> get kilos =>
      $composableBuilder(column: $table.kilos, builder: (column) => column);

  $$ReporteAreasTableAnnotationComposer get reporteAreaId {
    final $$ReporteAreasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reporteAreaId,
      referencedTable: $db.reporteAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReporteAreasTableAnnotationComposer(
            $db: $db,
            $table: $db.reporteAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReporteAreaDesglosesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReporteAreaDesglosesTable,
          ReporteAreaDesglose,
          $$ReporteAreaDesglosesTableFilterComposer,
          $$ReporteAreaDesglosesTableOrderingComposer,
          $$ReporteAreaDesglosesTableAnnotationComposer,
          $$ReporteAreaDesglosesTableCreateCompanionBuilder,
          $$ReporteAreaDesglosesTableUpdateCompanionBuilder,
          (ReporteAreaDesglose, $$ReporteAreaDesglosesTableReferences),
          ReporteAreaDesglose,
          PrefetchHooks Function({bool reporteAreaId})
        > {
  $$ReporteAreaDesglosesTableTableManager(
    _$AppDatabase db,
    $ReporteAreaDesglosesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReporteAreaDesglosesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReporteAreaDesglosesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReporteAreaDesglosesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> reporteAreaId = const Value.absent(),
                Value<String> categoria = const Value.absent(),
                Value<int> personas = const Value.absent(),
                Value<double> kilos = const Value.absent(),
              }) => ReporteAreaDesglosesCompanion(
                id: id,
                reporteAreaId: reporteAreaId,
                categoria: categoria,
                personas: personas,
                kilos: kilos,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int reporteAreaId,
                required String categoria,
                Value<int> personas = const Value.absent(),
                Value<double> kilos = const Value.absent(),
              }) => ReporteAreaDesglosesCompanion.insert(
                id: id,
                reporteAreaId: reporteAreaId,
                categoria: categoria,
                personas: personas,
                kilos: kilos,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReporteAreaDesglosesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({reporteAreaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (reporteAreaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.reporteAreaId,
                                referencedTable:
                                    $$ReporteAreaDesglosesTableReferences
                                        ._reporteAreaIdTable(db),
                                referencedColumn:
                                    $$ReporteAreaDesglosesTableReferences
                                        ._reporteAreaIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReporteAreaDesglosesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReporteAreaDesglosesTable,
      ReporteAreaDesglose,
      $$ReporteAreaDesglosesTableFilterComposer,
      $$ReporteAreaDesglosesTableOrderingComposer,
      $$ReporteAreaDesglosesTableAnnotationComposer,
      $$ReporteAreaDesglosesTableCreateCompanionBuilder,
      $$ReporteAreaDesglosesTableUpdateCompanionBuilder,
      (ReporteAreaDesglose, $$ReporteAreaDesglosesTableReferences),
      ReporteAreaDesglose,
      PrefetchHooks Function({bool reporteAreaId})
    >;
typedef $$CuadrillasTableCreateCompanionBuilder =
    CuadrillasCompanion Function({
      Value<int> id,
      required int reporteAreaId,
      Value<String> nombre,
      Value<String?> horaInicio,
      Value<String?> horaFin,
      Value<double?> kilos,
    });
typedef $$CuadrillasTableUpdateCompanionBuilder =
    CuadrillasCompanion Function({
      Value<int> id,
      Value<int> reporteAreaId,
      Value<String> nombre,
      Value<String?> horaInicio,
      Value<String?> horaFin,
      Value<double?> kilos,
    });

final class $$CuadrillasTableReferences
    extends BaseReferences<_$AppDatabase, $CuadrillasTable, Cuadrilla> {
  $$CuadrillasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReporteAreasTable _reporteAreaIdTable(_$AppDatabase db) =>
      db.reporteAreas.createAlias(
        $_aliasNameGenerator(db.cuadrillas.reporteAreaId, db.reporteAreas.id),
      );

  $$ReporteAreasTableProcessedTableManager get reporteAreaId {
    final $_column = $_itemColumn<int>('reporte_area_id')!;

    final manager = $$ReporteAreasTableTableManager(
      $_db,
      $_db.reporteAreas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reporteAreaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CuadrillaDesglosesTable, List<CuadrillaDesglose>>
  _cuadrillaDesglosesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cuadrillaDesgloses,
        aliasName: $_aliasNameGenerator(
          db.cuadrillas.id,
          db.cuadrillaDesgloses.cuadrillaId,
        ),
      );

  $$CuadrillaDesglosesTableProcessedTableManager get cuadrillaDesglosesRefs {
    final manager = $$CuadrillaDesglosesTableTableManager(
      $_db,
      $_db.cuadrillaDesgloses,
    ).filter((f) => f.cuadrillaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cuadrillaDesglosesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IntegrantesTable, List<Integrante>>
  _integrantesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.integrantes,
    aliasName: $_aliasNameGenerator(
      db.cuadrillas.id,
      db.integrantes.cuadrillaId,
    ),
  );

  $$IntegrantesTableProcessedTableManager get integrantesRefs {
    final manager = $$IntegrantesTableTableManager(
      $_db,
      $_db.integrantes,
    ).filter((f) => f.cuadrillaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_integrantesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CuadrillasTableFilterComposer
    extends Composer<_$AppDatabase, $CuadrillasTable> {
  $$CuadrillasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get horaInicio => $composableBuilder(
    column: $table.horaInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get horaFin => $composableBuilder(
    column: $table.horaFin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kilos => $composableBuilder(
    column: $table.kilos,
    builder: (column) => ColumnFilters(column),
  );

  $$ReporteAreasTableFilterComposer get reporteAreaId {
    final $$ReporteAreasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reporteAreaId,
      referencedTable: $db.reporteAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReporteAreasTableFilterComposer(
            $db: $db,
            $table: $db.reporteAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cuadrillaDesglosesRefs(
    Expression<bool> Function($$CuadrillaDesglosesTableFilterComposer f) f,
  ) {
    final $$CuadrillaDesglosesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cuadrillaDesgloses,
      getReferencedColumn: (t) => t.cuadrillaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuadrillaDesglosesTableFilterComposer(
            $db: $db,
            $table: $db.cuadrillaDesgloses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> integrantesRefs(
    Expression<bool> Function($$IntegrantesTableFilterComposer f) f,
  ) {
    final $$IntegrantesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.integrantes,
      getReferencedColumn: (t) => t.cuadrillaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntegrantesTableFilterComposer(
            $db: $db,
            $table: $db.integrantes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CuadrillasTableOrderingComposer
    extends Composer<_$AppDatabase, $CuadrillasTable> {
  $$CuadrillasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get horaInicio => $composableBuilder(
    column: $table.horaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get horaFin => $composableBuilder(
    column: $table.horaFin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kilos => $composableBuilder(
    column: $table.kilos,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReporteAreasTableOrderingComposer get reporteAreaId {
    final $$ReporteAreasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reporteAreaId,
      referencedTable: $db.reporteAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReporteAreasTableOrderingComposer(
            $db: $db,
            $table: $db.reporteAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CuadrillasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CuadrillasTable> {
  $$CuadrillasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get horaInicio => $composableBuilder(
    column: $table.horaInicio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get horaFin =>
      $composableBuilder(column: $table.horaFin, builder: (column) => column);

  GeneratedColumn<double> get kilos =>
      $composableBuilder(column: $table.kilos, builder: (column) => column);

  $$ReporteAreasTableAnnotationComposer get reporteAreaId {
    final $$ReporteAreasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reporteAreaId,
      referencedTable: $db.reporteAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReporteAreasTableAnnotationComposer(
            $db: $db,
            $table: $db.reporteAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cuadrillaDesglosesRefs<T extends Object>(
    Expression<T> Function($$CuadrillaDesglosesTableAnnotationComposer a) f,
  ) {
    final $$CuadrillaDesglosesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cuadrillaDesgloses,
          getReferencedColumn: (t) => t.cuadrillaId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CuadrillaDesglosesTableAnnotationComposer(
                $db: $db,
                $table: $db.cuadrillaDesgloses,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> integrantesRefs<T extends Object>(
    Expression<T> Function($$IntegrantesTableAnnotationComposer a) f,
  ) {
    final $$IntegrantesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.integrantes,
      getReferencedColumn: (t) => t.cuadrillaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntegrantesTableAnnotationComposer(
            $db: $db,
            $table: $db.integrantes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CuadrillasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CuadrillasTable,
          Cuadrilla,
          $$CuadrillasTableFilterComposer,
          $$CuadrillasTableOrderingComposer,
          $$CuadrillasTableAnnotationComposer,
          $$CuadrillasTableCreateCompanionBuilder,
          $$CuadrillasTableUpdateCompanionBuilder,
          (Cuadrilla, $$CuadrillasTableReferences),
          Cuadrilla,
          PrefetchHooks Function({
            bool reporteAreaId,
            bool cuadrillaDesglosesRefs,
            bool integrantesRefs,
          })
        > {
  $$CuadrillasTableTableManager(_$AppDatabase db, $CuadrillasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CuadrillasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CuadrillasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CuadrillasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> reporteAreaId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> horaInicio = const Value.absent(),
                Value<String?> horaFin = const Value.absent(),
                Value<double?> kilos = const Value.absent(),
              }) => CuadrillasCompanion(
                id: id,
                reporteAreaId: reporteAreaId,
                nombre: nombre,
                horaInicio: horaInicio,
                horaFin: horaFin,
                kilos: kilos,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int reporteAreaId,
                Value<String> nombre = const Value.absent(),
                Value<String?> horaInicio = const Value.absent(),
                Value<String?> horaFin = const Value.absent(),
                Value<double?> kilos = const Value.absent(),
              }) => CuadrillasCompanion.insert(
                id: id,
                reporteAreaId: reporteAreaId,
                nombre: nombre,
                horaInicio: horaInicio,
                horaFin: horaFin,
                kilos: kilos,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CuadrillasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                reporteAreaId = false,
                cuadrillaDesglosesRefs = false,
                integrantesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cuadrillaDesglosesRefs) db.cuadrillaDesgloses,
                    if (integrantesRefs) db.integrantes,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (reporteAreaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.reporteAreaId,
                                    referencedTable: $$CuadrillasTableReferences
                                        ._reporteAreaIdTable(db),
                                    referencedColumn:
                                        $$CuadrillasTableReferences
                                            ._reporteAreaIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cuadrillaDesglosesRefs)
                        await $_getPrefetchedData<
                          Cuadrilla,
                          $CuadrillasTable,
                          CuadrillaDesglose
                        >(
                          currentTable: table,
                          referencedTable: $$CuadrillasTableReferences
                              ._cuadrillaDesglosesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CuadrillasTableReferences(
                                db,
                                table,
                                p0,
                              ).cuadrillaDesglosesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cuadrillaId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (integrantesRefs)
                        await $_getPrefetchedData<
                          Cuadrilla,
                          $CuadrillasTable,
                          Integrante
                        >(
                          currentTable: table,
                          referencedTable: $$CuadrillasTableReferences
                              ._integrantesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CuadrillasTableReferences(
                                db,
                                table,
                                p0,
                              ).integrantesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cuadrillaId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CuadrillasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CuadrillasTable,
      Cuadrilla,
      $$CuadrillasTableFilterComposer,
      $$CuadrillasTableOrderingComposer,
      $$CuadrillasTableAnnotationComposer,
      $$CuadrillasTableCreateCompanionBuilder,
      $$CuadrillasTableUpdateCompanionBuilder,
      (Cuadrilla, $$CuadrillasTableReferences),
      Cuadrilla,
      PrefetchHooks Function({
        bool reporteAreaId,
        bool cuadrillaDesglosesRefs,
        bool integrantesRefs,
      })
    >;
typedef $$CuadrillaDesglosesTableCreateCompanionBuilder =
    CuadrillaDesglosesCompanion Function({
      Value<int> id,
      required int cuadrillaId,
      required String categoria,
      Value<int> personas,
      Value<double> kilos,
    });
typedef $$CuadrillaDesglosesTableUpdateCompanionBuilder =
    CuadrillaDesglosesCompanion Function({
      Value<int> id,
      Value<int> cuadrillaId,
      Value<String> categoria,
      Value<int> personas,
      Value<double> kilos,
    });

final class $$CuadrillaDesglosesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CuadrillaDesglosesTable,
          CuadrillaDesglose
        > {
  $$CuadrillaDesglosesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CuadrillasTable _cuadrillaIdTable(_$AppDatabase db) =>
      db.cuadrillas.createAlias(
        $_aliasNameGenerator(
          db.cuadrillaDesgloses.cuadrillaId,
          db.cuadrillas.id,
        ),
      );

  $$CuadrillasTableProcessedTableManager get cuadrillaId {
    final $_column = $_itemColumn<int>('cuadrilla_id')!;

    final manager = $$CuadrillasTableTableManager(
      $_db,
      $_db.cuadrillas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuadrillaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CuadrillaDesglosesTableFilterComposer
    extends Composer<_$AppDatabase, $CuadrillaDesglosesTable> {
  $$CuadrillaDesglosesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get personas => $composableBuilder(
    column: $table.personas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kilos => $composableBuilder(
    column: $table.kilos,
    builder: (column) => ColumnFilters(column),
  );

  $$CuadrillasTableFilterComposer get cuadrillaId {
    final $$CuadrillasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuadrillaId,
      referencedTable: $db.cuadrillas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuadrillasTableFilterComposer(
            $db: $db,
            $table: $db.cuadrillas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CuadrillaDesglosesTableOrderingComposer
    extends Composer<_$AppDatabase, $CuadrillaDesglosesTable> {
  $$CuadrillaDesglosesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get personas => $composableBuilder(
    column: $table.personas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kilos => $composableBuilder(
    column: $table.kilos,
    builder: (column) => ColumnOrderings(column),
  );

  $$CuadrillasTableOrderingComposer get cuadrillaId {
    final $$CuadrillasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuadrillaId,
      referencedTable: $db.cuadrillas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuadrillasTableOrderingComposer(
            $db: $db,
            $table: $db.cuadrillas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CuadrillaDesglosesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CuadrillaDesglosesTable> {
  $$CuadrillaDesglosesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<int> get personas =>
      $composableBuilder(column: $table.personas, builder: (column) => column);

  GeneratedColumn<double> get kilos =>
      $composableBuilder(column: $table.kilos, builder: (column) => column);

  $$CuadrillasTableAnnotationComposer get cuadrillaId {
    final $$CuadrillasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuadrillaId,
      referencedTable: $db.cuadrillas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuadrillasTableAnnotationComposer(
            $db: $db,
            $table: $db.cuadrillas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CuadrillaDesglosesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CuadrillaDesglosesTable,
          CuadrillaDesglose,
          $$CuadrillaDesglosesTableFilterComposer,
          $$CuadrillaDesglosesTableOrderingComposer,
          $$CuadrillaDesglosesTableAnnotationComposer,
          $$CuadrillaDesglosesTableCreateCompanionBuilder,
          $$CuadrillaDesglosesTableUpdateCompanionBuilder,
          (CuadrillaDesglose, $$CuadrillaDesglosesTableReferences),
          CuadrillaDesglose,
          PrefetchHooks Function({bool cuadrillaId})
        > {
  $$CuadrillaDesglosesTableTableManager(
    _$AppDatabase db,
    $CuadrillaDesglosesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CuadrillaDesglosesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CuadrillaDesglosesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CuadrillaDesglosesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cuadrillaId = const Value.absent(),
                Value<String> categoria = const Value.absent(),
                Value<int> personas = const Value.absent(),
                Value<double> kilos = const Value.absent(),
              }) => CuadrillaDesglosesCompanion(
                id: id,
                cuadrillaId: cuadrillaId,
                categoria: categoria,
                personas: personas,
                kilos: kilos,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cuadrillaId,
                required String categoria,
                Value<int> personas = const Value.absent(),
                Value<double> kilos = const Value.absent(),
              }) => CuadrillaDesglosesCompanion.insert(
                id: id,
                cuadrillaId: cuadrillaId,
                categoria: categoria,
                personas: personas,
                kilos: kilos,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CuadrillaDesglosesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cuadrillaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cuadrillaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cuadrillaId,
                                referencedTable:
                                    $$CuadrillaDesglosesTableReferences
                                        ._cuadrillaIdTable(db),
                                referencedColumn:
                                    $$CuadrillaDesglosesTableReferences
                                        ._cuadrillaIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CuadrillaDesglosesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CuadrillaDesglosesTable,
      CuadrillaDesglose,
      $$CuadrillaDesglosesTableFilterComposer,
      $$CuadrillaDesglosesTableOrderingComposer,
      $$CuadrillaDesglosesTableAnnotationComposer,
      $$CuadrillaDesglosesTableCreateCompanionBuilder,
      $$CuadrillaDesglosesTableUpdateCompanionBuilder,
      (CuadrillaDesglose, $$CuadrillaDesglosesTableReferences),
      CuadrillaDesglose,
      PrefetchHooks Function({bool cuadrillaId})
    >;
typedef $$IntegrantesTableCreateCompanionBuilder =
    IntegrantesCompanion Function({
      Value<int> id,
      required int cuadrillaId,
      Value<String?> code,
      required String nombre,
      Value<String?> horaInicio,
      Value<String?> horaFin,
      Value<double?> horas,
      Value<String?> labores,
    });
typedef $$IntegrantesTableUpdateCompanionBuilder =
    IntegrantesCompanion Function({
      Value<int> id,
      Value<int> cuadrillaId,
      Value<String?> code,
      Value<String> nombre,
      Value<String?> horaInicio,
      Value<String?> horaFin,
      Value<double?> horas,
      Value<String?> labores,
    });

final class $$IntegrantesTableReferences
    extends BaseReferences<_$AppDatabase, $IntegrantesTable, Integrante> {
  $$IntegrantesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CuadrillasTable _cuadrillaIdTable(_$AppDatabase db) =>
      db.cuadrillas.createAlias(
        $_aliasNameGenerator(db.integrantes.cuadrillaId, db.cuadrillas.id),
      );

  $$CuadrillasTableProcessedTableManager get cuadrillaId {
    final $_column = $_itemColumn<int>('cuadrilla_id')!;

    final manager = $$CuadrillasTableTableManager(
      $_db,
      $_db.cuadrillas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cuadrillaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IntegrantesTableFilterComposer
    extends Composer<_$AppDatabase, $IntegrantesTable> {
  $$IntegrantesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get horaInicio => $composableBuilder(
    column: $table.horaInicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get horaFin => $composableBuilder(
    column: $table.horaFin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get horas => $composableBuilder(
    column: $table.horas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labores => $composableBuilder(
    column: $table.labores,
    builder: (column) => ColumnFilters(column),
  );

  $$CuadrillasTableFilterComposer get cuadrillaId {
    final $$CuadrillasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuadrillaId,
      referencedTable: $db.cuadrillas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuadrillasTableFilterComposer(
            $db: $db,
            $table: $db.cuadrillas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntegrantesTableOrderingComposer
    extends Composer<_$AppDatabase, $IntegrantesTable> {
  $$IntegrantesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get horaInicio => $composableBuilder(
    column: $table.horaInicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get horaFin => $composableBuilder(
    column: $table.horaFin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get horas => $composableBuilder(
    column: $table.horas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labores => $composableBuilder(
    column: $table.labores,
    builder: (column) => ColumnOrderings(column),
  );

  $$CuadrillasTableOrderingComposer get cuadrillaId {
    final $$CuadrillasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuadrillaId,
      referencedTable: $db.cuadrillas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuadrillasTableOrderingComposer(
            $db: $db,
            $table: $db.cuadrillas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntegrantesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntegrantesTable> {
  $$IntegrantesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get horaInicio => $composableBuilder(
    column: $table.horaInicio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get horaFin =>
      $composableBuilder(column: $table.horaFin, builder: (column) => column);

  GeneratedColumn<double> get horas =>
      $composableBuilder(column: $table.horas, builder: (column) => column);

  GeneratedColumn<String> get labores =>
      $composableBuilder(column: $table.labores, builder: (column) => column);

  $$CuadrillasTableAnnotationComposer get cuadrillaId {
    final $$CuadrillasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cuadrillaId,
      referencedTable: $db.cuadrillas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CuadrillasTableAnnotationComposer(
            $db: $db,
            $table: $db.cuadrillas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntegrantesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntegrantesTable,
          Integrante,
          $$IntegrantesTableFilterComposer,
          $$IntegrantesTableOrderingComposer,
          $$IntegrantesTableAnnotationComposer,
          $$IntegrantesTableCreateCompanionBuilder,
          $$IntegrantesTableUpdateCompanionBuilder,
          (Integrante, $$IntegrantesTableReferences),
          Integrante,
          PrefetchHooks Function({bool cuadrillaId})
        > {
  $$IntegrantesTableTableManager(_$AppDatabase db, $IntegrantesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntegrantesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntegrantesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntegrantesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cuadrillaId = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> horaInicio = const Value.absent(),
                Value<String?> horaFin = const Value.absent(),
                Value<double?> horas = const Value.absent(),
                Value<String?> labores = const Value.absent(),
              }) => IntegrantesCompanion(
                id: id,
                cuadrillaId: cuadrillaId,
                code: code,
                nombre: nombre,
                horaInicio: horaInicio,
                horaFin: horaFin,
                horas: horas,
                labores: labores,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cuadrillaId,
                Value<String?> code = const Value.absent(),
                required String nombre,
                Value<String?> horaInicio = const Value.absent(),
                Value<String?> horaFin = const Value.absent(),
                Value<double?> horas = const Value.absent(),
                Value<String?> labores = const Value.absent(),
              }) => IntegrantesCompanion.insert(
                id: id,
                cuadrillaId: cuadrillaId,
                code: code,
                nombre: nombre,
                horaInicio: horaInicio,
                horaFin: horaFin,
                horas: horas,
                labores: labores,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IntegrantesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cuadrillaId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cuadrillaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cuadrillaId,
                                referencedTable: $$IntegrantesTableReferences
                                    ._cuadrillaIdTable(db),
                                referencedColumn: $$IntegrantesTableReferences
                                    ._cuadrillaIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IntegrantesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntegrantesTable,
      Integrante,
      $$IntegrantesTableFilterComposer,
      $$IntegrantesTableOrderingComposer,
      $$IntegrantesTableAnnotationComposer,
      $$IntegrantesTableCreateCompanionBuilder,
      $$IntegrantesTableUpdateCompanionBuilder,
      (Integrante, $$IntegrantesTableReferences),
      Integrante,
      PrefetchHooks Function({bool cuadrillaId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ReportesTableTableManager get reportes =>
      $$ReportesTableTableManager(_db, _db.reportes);
  $$ReporteAreasTableTableManager get reporteAreas =>
      $$ReporteAreasTableTableManager(_db, _db.reporteAreas);
  $$ReporteAreaDesglosesTableTableManager get reporteAreaDesgloses =>
      $$ReporteAreaDesglosesTableTableManager(_db, _db.reporteAreaDesgloses);
  $$CuadrillasTableTableManager get cuadrillas =>
      $$CuadrillasTableTableManager(_db, _db.cuadrillas);
  $$CuadrillaDesglosesTableTableManager get cuadrillaDesgloses =>
      $$CuadrillaDesglosesTableTableManager(_db, _db.cuadrillaDesgloses);
  $$IntegrantesTableTableManager get integrantes =>
      $$IntegrantesTableTableManager(_db, _db.integrantes);
}

mixin _$ReportesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReportesTable get reportes => attachedDatabase.reportes;
  $ReporteAreasTable get reporteAreas => attachedDatabase.reporteAreas;
  $ReporteAreaDesglosesTable get reporteAreaDesgloses =>
      attachedDatabase.reporteAreaDesgloses;
  $CuadrillasTable get cuadrillas => attachedDatabase.cuadrillas;
  $CuadrillaDesglosesTable get cuadrillaDesgloses =>
      attachedDatabase.cuadrillaDesgloses;
  $IntegrantesTable get integrantes => attachedDatabase.integrantes;
}
