import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:scanner_trabunda/data/drift/db.dart';
import 'package:scanner_trabunda/features/reports/presentation/pages/cuadrilla/cuadrilla_config_page.dart';

enum ModoTrabajo { individual, cuadrilla }

class AreaDetallePage extends StatefulWidget {
  const AreaDetallePage({
    super.key,
    required this.areaName,
    this.reporteAreaId,
    this.initialTotalPersonas = 0,
  });

  final String areaName;
  final int? reporteAreaId;
  final int initialTotalPersonas;

  @override
  State<AreaDetallePage> createState() => _AreaDetallePageState();
}

class _AreaDetallePageState extends State<AreaDetallePage> {
  // Horas generales (para áreas normales)
  TimeOfDay? _inicio;
  TimeOfDay? _fin;
  bool get usaBD => widget.reporteAreaId != null;

  // Área especial: Saneamiento
  bool get _isSaneamiento =>
      widget.areaName.toLowerCase().contains('saneamiento');

  // Individual (áreas normales)
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _kilosIndividualCtrl = TextEditingController();

  // Saneamiento: lista de trabajadores
  final List<_SaneamientoTrabajadorRow> _saneamientoTrabajadores = [];

  // Cuadrillas (múltiples)
  final List<CuadrillaData> _cuadrillas = [];

  // Modo
  ModoTrabajo _modo = ModoTrabajo.individual;

  // Flag anti-doble pop / transición
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();

    // Si es Saneamiento, solo modo individual
    if (_isSaneamiento) {
      _modo = ModoTrabajo.individual;
      _saneamientoTrabajadores.add(_SaneamientoTrabajadorRow());
    }

    // 👇 Cargar trabajadores desde la BD si ya existe un reporte_area
    if (_isSaneamiento && usaBD && widget.reporteAreaId != null) {
      Future.microtask(_cargarSaneamientoDesdeBD);
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _kilosIndividualCtrl.dispose();

    // Liberar controladores de Saneamiento
    for (final t in _saneamientoTrabajadores) {
      t.dispose();
    }

    super.dispose();
  }

  // ================== CARGA DESDE BD (SANEAMIENTO) ==================

  Future<void> _cargarSaneamientoDesdeBD() async {
    try {
      final lista = await db.reportesDao
          .fetchSaneamientoTrabajadoresPorArea(widget.reporteAreaId!);

      if (!mounted) return;

      setState(() {
        _saneamientoTrabajadores.clear();

        if (lista.isEmpty) {
          // Si no hay nada en BD, dejamos una fila vacía
          _saneamientoTrabajadores.add(_SaneamientoTrabajadorRow());
          return;
        }

        for (final t in lista) {
          // 👇 Trabajador proveniente de BD → bloquear código y nombre
          final row = _SaneamientoTrabajadorRow(lockFromQr: true);

          row.codigoCtrl.text = (t['code'] ?? '') as String;
          row.nombreCtrl.text = (t['name'] ?? '') as String;
          row.laboresCtrl.text = (t['labores'] ?? '') as String;

          row.inicio = _parseTimeOfDay(t['horaInicio'] as String?);
          row.fin = _parseTimeOfDay(t['horaFin'] as String?);

          _saneamientoTrabajadores.add(row);
        }
      });
    } catch (_) {
      // si algo falla no rompemos la pantalla, solo dejamos la fila vacía
    }
  }

  TimeOfDay? _parseTimeOfDay(String? hhmm) {
    if (hhmm == null || hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  // ================== PICKERS DE HORA ==================

  Future<void> _pickHora({required bool inicio}) async {
    final base = inicio ? _inicio : _fin;
    final picked = await showTimePicker(
      context: context,
      initialTime: base ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (inicio) {
          _inicio = picked;
        } else {
          _fin = picked;
        }
      });
    }
  }

  // ----- SANEAMIENTO: hora por trabajador -----
  Future<void> _pickHoraTrabajador(int index, {required bool inicio}) async {
    final row = _saneamientoTrabajadores[index];
    final base = inicio ? row.inicio : row.fin;

    final picked = await showTimePicker(
      context: context,
      initialTime: base ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (inicio) {
          row.inicio = picked;
        } else {
          row.fin = picked;
        }
      });
    }
  }

  void _agregarTrabajadorSaneamiento() {
    setState(() {
      _saneamientoTrabajadores.add(_SaneamientoTrabajadorRow());
    });

    // Después de construir el nuevo ítem, poner el cursor en su campo "código"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final last = _saneamientoTrabajadores.last;
      last.codigoFocus.requestFocus();
    });
  }

  void _eliminarTrabajadorSaneamiento(int index) {
    final row = _saneamientoTrabajadores.removeAt(index);
    row.dispose();
    setState(() {});
  }

  String _fmt(TimeOfDay? t) {
    if (t == null) return '--:--';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ---------- VALIDACIÓN: PERSONA YA REGISTRADA (SANEAMIENTO) ----------

  bool _codigoYaRegistradoSaneamiento(String codigo, int indexActual) {
    final cod = codigo.trim();
    if (cod.isEmpty) return false;

    for (int i = 0; i < _saneamientoTrabajadores.length; i++) {
      if (i == indexActual) continue; // ignorar la fila actual
      if (_saneamientoTrabajadores[i].codigoCtrl.text.trim() == cod) {
        return true;
      }
    }
    return false;
  }

  void _onCodigoSaneamientoIngresado(int index, String codigo) {
    final cod = codigo.trim();
    if (cod.isEmpty) return;

    if (_codigoYaRegistradoSaneamiento(cod, index)) {
      // Mostrar mensaje y limpiar la fila nueva
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PERSONA YA REGISTRADA')),
      );

      setState(() {
        final row = _saneamientoTrabajadores[index];
        row.codigoCtrl.clear();
        row.nombreCtrl.clear();
        row.laboresCtrl.clear();
        row.inicio = null;
        row.fin = null;
        row.lockFromQr = false;
      });
    }
  }

  // ----- INDIVIDUAL: escanear -----
  Future<void> _scanQRIndividual() async {
    final result = await Navigator.pushNamed(
      context,
      '/scanner',
      arguments: const {'pickOnly': true},
    );
    if (!mounted) return;

    if (result is Map) {
      final code = (result['code'] ?? '').toString();
      final data = result['data'];
      String name = (result['name'] ?? '').toString();
      if (name.isEmpty && data is Map) {
        final alt = data['name'] ?? data['nombre'];
        if (alt != null) name = alt.toString();
      }
      setState(() {
        _codigoCtrl.text = code;
        if (name.isNotEmpty) _nombreCtrl.text = name;
      });
    } else if (result is String) {
      setState(() => _codigoCtrl.text = result);
    }
  }

  // ----- SANEAMIENTO: escanear QR por trabajador -----
  Future<void> _scanQRSaneamiento(int index) async {
    final result = await Navigator.pushNamed(
      context,
      '/scanner',
      arguments: const {'pickOnly': true},
    );
    if (!mounted) return;

    final row = _saneamientoTrabajadores[index];

    if (result is Map) {
      final code = (result['code'] ?? '').toString();
      final data = result['data'];
      String name = (result['name'] ?? '').toString();
      if (name.isEmpty && data is Map) {
        final alt = data['name'] ?? data['nombre'];
        if (alt != null) name = alt.toString();
      }
      setState(() {
        row.codigoCtrl.text = code;
        if (name.isNotEmpty) row.nombreCtrl.text = name;
        // 👇 Bloquear código y nombre cuando viene de QR
        row.lockFromQr = true;
      });
      _onCodigoSaneamientoIngresado(index, row.codigoCtrl.text);
    } else if (result is String) {
      setState(() {
        row.codigoCtrl.text = result;
        row.lockFromQr = true; // también bloquear si viene como String
      });
      _onCodigoSaneamientoIngresado(index, row.codigoCtrl.text);
    }
  }

  // ----- CUADRILLA: agregar/editar -----
  Future<void> _crearCuadrilla() async {
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CuadrillaConfigPage(areaName: widget.areaName),
      ),
    );

    if (res != null) {
      setState(() => _cuadrillas.add(CuadrillaData.fromMap(res)));

      // Guarda en BD (no bloquea la UI)
      if (usaBD) {
        Future.microtask(() async {
          final cuadId = await db.reportesDao.upsertCuadrilla(
            id: null,
            reporteAreaId: widget.reporteAreaId!,
            nombre: res['nombre'] ?? '',
            horaInicio: null,
            horaFin: null,
            kilos: (res['kilos'] is num)
                ? (res['kilos'] as num).toDouble()
                : double.tryParse('${res['kilos'] ?? ''}'),
            desglose: (res['desglose'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
          );

          await db.reportesDao.replaceIntegrantes(
            cuadrillaId: cuadId,
            integrantesList:
            List<Map<String, String>>.from(res['integrantes'] ?? []),
          );
        });
      }
    }
  }

  Future<void> _editarCuadrilla(int index) async {
    final c = _cuadrillas[index];
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CuadrillaConfigPage(
          areaName: widget.areaName,
          initialNombre: c.nombre,
          initialIntegrantes: c.integrantes,
          initialKilos: c.kilos,
        ),
      ),
    );
    if (res != null) {
      setState(() => _cuadrillas[index] = CuadrillaData.fromMap(res));
    }
  }

  void _eliminarCuadrilla(int index) {
    setState(() => _cuadrillas.removeAt(index));
  }

  // ===== Cálculos y resultado para volver =====
  int _calcularPersonas() {
    if (_modo == ModoTrabajo.individual) {
      if (_isSaneamiento) {
        // Solo contamos trabajadores que tengan información
        return _saneamientoTrabajadores.where((t) => t.hasData).length;
      }

      // Para áreas normales: cuenta 1 solo si hay algo escrito
      final tieneDatosIndividual = _codigoCtrl.text.trim().isNotEmpty ||
          _nombreCtrl.text.trim().isNotEmpty ||
          _kilosIndividualCtrl.text.trim().isNotEmpty;

      return tieneDatosIndividual ? 1 : 0;
    }

    // Modo cuadrilla
    return _cuadrillas.fold<int>(0, (sum, c) => sum + c.integrantes.length);
  }

  double _calcularKilosTotales() {
    if (_modo == ModoTrabajo.individual) {
      if (_isSaneamiento) {
        // En Saneamiento, usamos kilos_total como total de horas
        return _saneamientoTrabajadores.fold<double>(
          0.0,
              (sum, t) => sum + t.horas,
        );
      }
      return double.tryParse(_kilosIndividualCtrl.text.trim()) ?? 0.0;
    }
    return _cuadrillas.fold<double>(
      0.0,
          (sum, c) => sum + (c.kilos ?? 0.0),
    );
  }

  Map<String, dynamic> _resultadoParaVolver() {
    final personas = _calcularPersonas();
    final kilosTotal = _calcularKilosTotales();
    final horaInicio = _inicio == null
        ? null
        : '${_inicio!.hour.toString().padLeft(2, '0')}:${_inicio!.minute.toString().padLeft(2, '0')}';
    final horaFin = _fin == null
        ? null
        : '${_fin!.hour.toString().padLeft(2, '0')}:${_fin!.minute.toString().padLeft(2, '0')}';

    final saneamientoTrabajadores =
    _isSaneamiento && _modo == ModoTrabajo.individual
        ? _saneamientoTrabajadores
        .where((t) => t.hasData)
        .map(
          (t) => {
        'code': t.codigoCtrl.text.trim(),
        'name': t.nombreCtrl.text.trim(),
        'horaInicio': t.inicio == null
            ? null
            : '${t.inicio!.hour.toString().padLeft(2, '0')}:${t.inicio!.minute.toString().padLeft(2, '0')}',
        'horaFin': t.fin == null
            ? null
            : '${t.fin!.hour.toString().padLeft(2, '0')}:${t.fin!.minute.toString().padLeft(2, '0')}',
        'horas': t.horas,
        'labores': t.laboresCtrl.text.trim(),
      },
    )
        .toList()
        : null;

    return {
      'area': widget.areaName,
      'modo': _modo.name,
      'hora_inicio': _inicio == null
          ? null
          : {'h': _inicio!.hour, 'm': _inicio!.minute},
      'hora_fin': _fin == null ? null : {'h': _fin!.hour, 'm': _fin!.minute},
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'trabajador': _modo == ModoTrabajo.individual && !_isSaneamiento
          ? {
        'code': _codigoCtrl.text.trim(),
        'name': _nombreCtrl.text.trim(),
        'kilos': kilosTotal,
      }
          : null,
      'trabajadoresSaneamiento': saneamientoTrabajadores,
      'cuadrillas': _modo == ModoTrabajo.cuadrilla
          ? _cuadrillas.map((c) => c.toMap()).toList()
          : null,
      'kilos_total': kilosTotal,
      'personas': personas,
      'desglose': const <Map<String, dynamic>>[],
      'resumen': _modo == ModoTrabajo.cuadrilla
          ? {
        'titulo': 'Cuadrillas (${_cuadrillas.length})',
        'subtitulo':
        'Kilos: ${kilosTotal.toStringAsFixed(2)} • Pers.: $personas',
      }
          : _isSaneamiento
          ? {
        'titulo': 'Individual (Saneamiento)',
        'subtitulo':
        'Horas: ${kilosTotal.toStringAsFixed(2)} • Pers.: $personas',
      }
          : {
        'titulo': 'Individual',
        'subtitulo':
        'Kilos: ${kilosTotal.toStringAsFixed(2)} • Pers.: $personas',
      },
    };
  }

  // ===== Validación de códigos de saneamiento (5–8 dígitos numéricos)
  //       + hora de inicio obligatoria (hora fin puede quedar vacía) =====
  bool _validarCodigosSaneamiento() {
    // Solo aplica en área Saneamiento, modo individual
    if (!_isSaneamiento || _modo != ModoTrabajo.individual) {
      return true;
    }

    for (final t in _saneamientoTrabajadores) {
      if (!t.hasData) continue; // filas vacías se ignoran

      final code = t.codigoCtrl.text.trim();

      // Debe existir código si la fila tiene datos
      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cada trabajador debe tener un código.'),
          ),
        );
        return false;
      }

      // Solo números y entre 5 y 8 dígitos
      final soloNumeros = RegExp(r'^\d+$').hasMatch(code);
      if (!soloNumeros || code.length < 5 || code.length > 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cada código de trabajador debe tener entre 5 y 8 dígitos numéricos',
            ),
          ),
        );
        return false;
      }

      // ✅ Hora de inicio obligatoria
      //    La hora de fin se puede llenar luego (no es obligatoria)
      if (t.inicio == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cada trabajador debe tener al menos la hora de inicio. '
                  'La hora de fin se puede completar al final del turno.',
            ),
          ),
        );
        return false;
      }
    }

    return true;
  }

  // ===== Guardar y volver (pop seguro) =====
  Future<void> _guardarYVolver() async {
    if (_cerrando) return; // evita doble ejecución

    // 1) Validar códigos y horas de saneamiento (si aplica)
    if (!_validarCodigosSaneamiento()) return;

    // 2) Validar código individual normal (no saneamiento)
    if (!_isSaneamiento && _modo == ModoTrabajo.individual) {
      final code = _codigoCtrl.text.trim();
      if (code.isNotEmpty) {
        final soloNumeros = RegExp(r'^\d+$').hasMatch(code);
        if (!soloNumeros || code.length < 5 || code.length > 8) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'El código del trabajador debe tener entre 5 y 8 dígitos numéricos',
              ),
            ),
          );
          return;
        }
      }
    }

    _cerrando = true;

    FocusScope.of(context).unfocus();

    final result = _resultadoParaVolver();

    // 👇 AQUÍ EL CAMBIO IMPORTANTE: esperamos los guardados ANTES de hacer pop
    if (usaBD && widget.reporteAreaId != null) {
      final personas = result['personas'] as int;

      // Las horas generales que venían del área
      String? horaInicio = result['horaInicio'] as String?;
      String? horaFin = result['horaFin'] as String?;

      // Lista de trabajadores de saneamiento con sus horas
      final saneamientoList =
          (result['trabajadoresSaneamiento'] as List?)
              ?.cast<Map<String, dynamic>>() ??
              const <Map<String, dynamic>>[];

      // Si en saneamiento no se puso hora general, la deducimos
      if (_isSaneamiento &&
          _modo == ModoTrabajo.individual &&
          saneamientoList.isNotEmpty &&
          ((horaInicio == null || horaInicio.isEmpty) ||
              (horaFin == null || horaFin.isEmpty))) {
        String? firstInicio;
        String? lastFin;

        for (final t in saneamientoList) {
          final hi = (t['horaInicio'] as String?)?.trim();
          final hf = (t['horaFin'] as String?)?.trim();

          if (hi != null && hi.isNotEmpty && firstInicio == null) {
            firstInicio = hi;
          }
          if (hf != null && hf.isNotEmpty) {
            lastFin = hf;
          }
        }

        if (horaInicio == null || horaInicio.isEmpty) {
          horaInicio = firstInicio;
        }
        if (horaFin == null || horaFin.isEmpty) {
          horaFin = lastFin;
        }
      }

      try {
        // Guardar cabecera área
        await db.reportesDao.saveReporteAreaDatos(
          reporteAreaId: widget.reporteAreaId!,
          cantidad: personas,
          horaInicio: horaInicio,
          horaFin: horaFin,
          desglose: const [],
        );

        // Guardar trabajadores de saneamiento como integrantes
        if (_isSaneamiento &&
            _modo == ModoTrabajo.individual &&
            saneamientoList.isNotEmpty) {
          await db.reportesDao.saveSaneamientoTrabajadores(
            reporteAreaId: widget.reporteAreaId!,
            trabajadores: saneamientoList,
          );
        }
      } catch (_) {
        // si hay error, igual seguimos para no bloquear al usuario
      }
    }

    if (!mounted) return;

    void cerrar() {
      if (!mounted) return;
      Navigator.of(context).maybePop(result);
    }

    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      cerrar();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => cerrar());
    }
  }

  @override
  Widget build(BuildContext context) {
    // En Saneamiento nunca será cuadrilla
    final isCuadrilla = !_isSaneamiento && _modo == ModoTrabajo.cuadrilla;

    return WillPopScope(
      onWillPop: () async {
        if (_cerrando) return true;
        if (Navigator.of(context).canPop()) {
          await _guardarYVolver();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.areaName} • Detalle'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _guardarYVolver,
          ),
          actions: [
            IconButton(
              tooltip: 'Guardar',
              onPressed: _guardarYVolver,
              icon: const Icon(Icons.save_rounded),
            ),
          ],
        ),
        floatingActionButton: (!_isSaneamiento && isCuadrilla)
            ? FloatingActionButton.extended(
          onPressed: _crearCuadrilla,
          icon: const Icon(Icons.groups_2_rounded),
          label: const Text('Agregar cuadrilla'),
        )
            : null,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selector Individual / Cuadrilla
            if (!_isSaneamiento)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SegmentedButton<ModoTrabajo>(
                    segments: const [
                      ButtonSegment(
                        value: ModoTrabajo.individual,
                        label: Text('Individual'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment(
                        value: ModoTrabajo.cuadrilla,
                        label: Text('Cuadrilla'),
                        icon: Icon(Icons.groups_2_outlined),
                      ),
                    ],
                    selected: <ModoTrabajo>{_modo},
                    onSelectionChanged: (selection) {
                      setState(() => _modo = selection.first);
                    },
                  ),
                ),
              )
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline),
                      SizedBox(width: 8),
                      Text(
                        'Modo: Individual (Saneamiento)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Horas generales (no se usan en Saneamiento)
            if (!_isSaneamiento)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _HoraTile(
                              label: 'Hora inicio',
                              value: _fmt(_inicio),
                              onTap: () => _pickHora(inicio: true),
                              icon: Icons.access_time,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HoraTile(
                              label: 'Hora fin',
                              value: _fmt(_fin),
                              onTap: () => _pickHora(inicio: false),
                              icon: Icons.timelapse_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // INDIVIDUAL
            if (!isCuadrilla) ...[
              if (_isSaneamiento)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0;
                    i < _saneamientoTrabajadores.length;
                    i++)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _SaneamientoTrabajadorForm(
                            index: i,
                            row: _saneamientoTrabajadores[i],
                            onPickHoraInicio: () =>
                                _pickHoraTrabajador(i, inicio: true),
                            onPickHoraFin: () =>
                                _pickHoraTrabajador(i, inicio: false),
                            onRemove: _saneamientoTrabajadores.length > 1
                                ? () => _eliminarTrabajadorSaneamiento(i)
                                : null,
                            onScanQR: () => _scanQRSaneamiento(i),
                            onCodigoCompleted: (value) =>
                                _onCodigoSaneamientoIngresado(i, value),
                          ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _agregarTrabajadorSaneamiento,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Agregar trabajador'),
                    ),
                  ],
                )
              else
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _codigoCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Código del trabajador',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: 'Escanear QR',
                              onPressed: _scanQRIndividual,
                              icon: const Icon(Icons.qr_code_scanner),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nombreCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre (opcional)',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _kilosIndividualCtrl,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Kilos',
                            hintText: '0.0',
                            prefixIcon: Icon(Icons.scale_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            // CUADRILLAS (lista + total)
            if (isCuadrilla) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F2FA),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                        border: Border(
                          bottom:
                          BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 6, child: Text('Cuadrilla')),
                          Expanded(
                              flex: 3,
                              child: Text('Integrantes',
                                  textAlign: TextAlign.center)),
                          Expanded(
                              flex: 3,
                              child: Text('Kilos',
                                  textAlign: TextAlign.center)),
                          SizedBox(width: 44),
                          SizedBox(width: 44),
                        ],
                      ),
                    ),
                    if (_cuadrillas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'No hay cuadrillas aún. Usa "Agregar cuadrilla".'),
                      )
                    else
                      for (int i = 0; i < _cuadrillas.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Text(
                                    _cuadrillas[i].nombre ?? '—'),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '${_cuadrillas[i].integrantes.length}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  (_cuadrillas[i].kilos ?? 0.0)
                                      .toStringAsFixed(2),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(
                                width: 44,
                                child: IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => _editarCuadrilla(i),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              ),
                              SizedBox(
                                width: 44,
                                child: IconButton(
                                  tooltip: 'Quitar',
                                  onPressed: () =>
                                      _eliminarCuadrilla(i),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 6,
                            child: Text('Kilos totales',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                          const Expanded(flex: 3, child: SizedBox()),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _calcularKilosTotales()
                                  .toStringAsFixed(2),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 88),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _crearCuadrilla,
                icon: const Icon(Icons.groups_2_rounded),
                label: const Text('Agregar cuadrilla'),
              ),
            ],

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _guardarYVolver,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Guardar y volver'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Auxiliares ----

class _HoraTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData icon;

  const _HoraTile({
    required this.label,
    required this.value,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            )
          ],
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, size: 18, color: Colors.black45),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SaneamientoTrabajadorRow {
  _SaneamientoTrabajadorRow({this.lockFromQr = false});

  TimeOfDay? inicio;
  TimeOfDay? fin;

  final TextEditingController codigoCtrl = TextEditingController();
  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController laboresCtrl = TextEditingController();

  // 👇 FocusNode para poder poner el cursor en el nuevo trabajador
  final FocusNode codigoFocus = FocusNode();

  // 👇 Indica si código y nombre vienen de QR / BD y no se deben editar
  bool lockFromQr;

  // Horas trabajadas con 30 minutos descontados (almuerzo)
  double get horas {
    if (inicio == null || fin == null) return 0.0;

    final startMinutes = inicio!.hour * 60 + inicio!.minute;
    final endMinutes = fin!.hour * 60 + fin!.minute;

    // diferencia en minutos
    int diff = endMinutes - startMinutes;

    // Si la diferencia es <= 0, asumimos que cruzó medianoche (ej. 18:00 → 06:00)
    if (diff <= 0) {
      diff += 24 * 60; // sumamos 24 horas
    }

    double rawHours = diff / 60.0;

    // Descontar 30 minutos de almuerzo
    if (rawHours > 0.5) {
      rawHours -= 0.5;
    } else {
      rawHours = 0.0;
    }

    return rawHours;
  }

  // indica si este trabajador tiene algún dato real
  bool get hasData {
    return horas > 0 ||
        codigoCtrl.text.trim().isNotEmpty ||
        nombreCtrl.text.trim().isNotEmpty ||
        laboresCtrl.text.trim().isNotEmpty;
  }

  void dispose() {
    codigoCtrl.dispose();
    nombreCtrl.dispose();
    laboresCtrl.dispose();
    codigoFocus.dispose();
  }
}

class _SaneamientoTrabajadorForm extends StatelessWidget {
  const _SaneamientoTrabajadorForm({
    super.key,
    required this.index,
    required this.row,
    required this.onPickHoraInicio,
    required this.onPickHoraFin,
    this.onRemove,
    required this.onScanQR,
    required this.onCodigoCompleted,
  });

  final int index;
  final _SaneamientoTrabajadorRow row;
  final VoidCallback onPickHoraInicio;
  final VoidCallback onPickHoraFin;
  final VoidCallback? onRemove;
  final VoidCallback onScanQR;
  final ValueChanged<String> onCodigoCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Trabajador ${index + 1}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (onRemove != null)
              IconButton(
                tooltip: 'Eliminar trabajador',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _HoraTile(
                label: 'Hora inicio',
                value: _fmtLocal(row.inicio),
                onTap: onPickHoraInicio,
                icon: Icons.access_time,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HoraTile(
                label: 'Hora fin',
                value: _fmtLocal(row.fin),
                onTap: onPickHoraFin,
                icon: Icons.access_time_filled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: row.codigoCtrl,
          focusNode: row.codigoFocus, // 👈 aquí usamos el FocusNode correcto
          keyboardType: TextInputType.number,
          maxLength: 8,
          readOnly: row.lockFromQr, // 👈 Bloquea edición si viene de QR/BD
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: 'Código del trabajador',
            prefixIcon: const Icon(Icons.badge_outlined),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: 'Escanear QR',
              onPressed: onScanQR,
              icon: const Icon(Icons.qr_code_scanner),
            ),
          ),
          onSubmitted: onCodigoCompleted,
          onEditingComplete: () => onCodigoCompleted(row.codigoCtrl.text),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: row.nombreCtrl,
          readOnly: row.lockFromQr, // 👈 también bloquea el nombre
          decoration: const InputDecoration(
            labelText: 'Nombre del trabajador',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: row.laboresCtrl,
          decoration: const InputDecoration(
            labelText: 'Labores realizadas',
            prefixIcon: Icon(Icons.work_outline),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total horas: ${row.horas.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _fmtLocal(TimeOfDay? t) {
    if (t == null) return '--:--';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class CuadrillaData {
  final String? nombre;
  final List<Map<String, String>> integrantes;
  final double? kilos;
  final String? horaInicio;
  final String? horaFin;
  final List<Map<String, dynamic>> desglose;

  CuadrillaData({
    this.nombre,
    required this.integrantes,
    this.kilos,
    this.horaInicio,
    this.horaFin,
    this.desglose = const [],
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'integrantes': integrantes,
    'kilos': kilos,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'desglose': desglose,
  };

  static CuadrillaData fromMap(Map<String, dynamic> m) => CuadrillaData(
    nombre: (m['nombre'] ?? '') as String?,
    integrantes:
    (m['integrantes'] as List?)?.cast<Map<String, String>>() ??
        <Map<String, String>>[],
    kilos: (m['kilos'] is num)
        ? (m['kilos'] as num).toDouble()
        : double.tryParse('${m['kilos'] ?? 0}') ?? 0.0,
    horaInicio: m['horaInicio'] as String?,
    horaFin: m['horaFin'] as String?,
    desglose: (m['desglose'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ??
        const [],
  );
}
