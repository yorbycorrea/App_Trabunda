import 'package:flutter/material.dart';
import 'cuadrilla_config_page.dart';
import '../data/db.dart';
import '../data/app_database.dart';

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
  // Horas
  TimeOfDay? _inicio;
  TimeOfDay? _fin;
  bool get usaBD => widget.reporteAreaId != null;

  // Individual
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _kilosIndividualCtrl = TextEditingController();

  // Cuadrillas (múltiples)
  final List<CuadrillaData> _cuadrillas = [];

  // Modo
  ModoTrabajo _modo = ModoTrabajo.individual;

  // Flag anti-doble pop / transición
  bool _cerrando = false;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _kilosIndividualCtrl.dispose();
    super.dispose();
  }

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

  String _fmt(TimeOfDay? t) {
    if (t == null) return '--:--';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ----- INDIVIDUAL: escanear -----
  Future<void> _scanQRIndividual() async {
    final result = await Navigator.pushNamed(context, '/scanner');
    if (!mounted) return;

    if (result is Map) {
      final code = (result['code'] ?? '').toString();
      final name = (result['name'] ?? '').toString();
      setState(() {
        _codigoCtrl.text = code;
        if (name.isNotEmpty) _nombreCtrl.text = name;
      });
    } else if (result is String) {
      setState(() => _codigoCtrl.text = result);
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
            kilos: (res['kilos'] ?? 0.0) as double?,
          );

          // 👇 usa el nombre de parámetro "integrantes" para tu DAO
          await db.reportesDao.replaceIntegrantes(
            cuadrillaId: cuadId,
            integrantesList: List<Map<String, String>>.from(res['integrantes'] ?? []),
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
    if (_modo == ModoTrabajo.individual) return 1;
    return _cuadrillas.fold<int>(0, (sum, c) => sum + c.integrantes.length);
  }

  double _calcularKilosTotales() {
    if (_modo == ModoTrabajo.individual) {
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

    return {
      'area': widget.areaName,
      'modo': _modo.name,
      'hora_inicio': _inicio == null ? null : {'h': _inicio!.hour, 'm': _inicio!.minute},
      'hora_fin': _fin == null ? null : {'h': _fin!.hour, 'm': _fin!.minute},
      'trabajador': _modo == ModoTrabajo.individual
          ? {
        'code': _codigoCtrl.text.trim(),
        'name': _nombreCtrl.text.trim(),
        'kilos': kilosTotal,
      }
          : null,
      'cuadrillas': _modo == ModoTrabajo.cuadrilla
          ? _cuadrillas.map((c) => c.toMap()).toList()
          : null,
      'kilos_total': kilosTotal,
      'personas': personas,
      'resumen': _modo == ModoTrabajo.cuadrilla
          ? {
        'titulo': 'Cuadrillas (${_cuadrillas.length})',
        'subtitulo': 'Kilos: ${kilosTotal.toStringAsFixed(2)} • Pers.: $personas',
      }
          : {
        'titulo': 'Individual',
        'subtitulo': 'Kilos: ${kilosTotal.toStringAsFixed(2)} • Pers.: $personas',
      },
    };
  }

  // ===== Guardar y volver (pop seguro) =====
  Future<void> _guardarYVolver() async {
    FocusScope.of(context).unfocus();

    final result = _resultadoParaVolver();

    if (usaBD && widget.reporteAreaId != null) {
      final personas = result['personas'] as int;
      Future.microtask(() async {
        try {
          await db.reportesDao.updateCantidadArea(widget.reporteAreaId!, personas);
        } catch (_) {}
      });
    }

    if (!mounted) return;

    // Desencadenar el pop en el siguiente frame evita _debugLocked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // usa maybePop para cubrir navegadores anidados
      Navigator.of(context).maybePop(result);
    });
  }



  @override
  Widget build(BuildContext context) {
    final isCuadrilla = _modo == ModoTrabajo.cuadrilla;

    return WillPopScope(
      // Captura back nativo (gesto/flecha Android) y usa nuestro cierre seguro
      onWillPop: () async {
      if (Navigator.of(context).canPop()) {
        await _guardarYVolver();
        return false; // ya hicimos pop manual
      }
      return true;},
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.areaName} • Detalle'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _guardarYVolver, // flecha también guarda y vuelve
          ),
          actions: [
            IconButton(
              tooltip: 'Guardar',
              onPressed: _guardarYVolver,
              icon: const Icon(Icons.save_rounded),
            ),
          ],
        ),
        floatingActionButton: isCuadrilla
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
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            ),

            const SizedBox(height: 12),

            // Horas
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _codigoCtrl,
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
                        const TextInputType.numberWithOptions(decimal: true),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F2FA),
                        borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: const [
                          Expanded(flex: 6, child: Text('Cuadrilla')),
                          Expanded(
                              flex: 3,
                              child:
                              Text('Integrantes', textAlign: TextAlign.center)),
                          Expanded(
                              flex: 3,
                              child: Text('Kilos', textAlign: TextAlign.center)),
                          SizedBox(width: 44), // editar
                          SizedBox(width: 44), // borrar
                        ],
                      ),
                    ),
                    if (_cuadrillas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child:
                        Text('No hay cuadrillas aún. Usa "Agregar cuadrilla".'),
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
                                  child: Text(_cuadrillas[i].nombre ?? '—')),
                              Expanded(
                                flex: 3,
                                child: Text(
                                    '${_cuadrillas[i].integrantes.length}',
                                    textAlign: TextAlign.center),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  (_cuadrillas[i].kilos ?? 0.0).toStringAsFixed(2),
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
                                  onPressed: () => _eliminarCuadrilla(i),
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
                      padding:
                      const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 6,
                            child: Text('Kilos totales',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          const Expanded(flex: 3, child: SizedBox()),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _calcularKilosTotales().toStringAsFixed(2),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
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
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
          ],
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
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

class CuadrillaData {
  final String? nombre;
  final List<Map<String, String>> integrantes;
  final double? kilos;

  CuadrillaData({this.nombre, required this.integrantes, this.kilos});

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'integrantes': integrantes,
    'kilos': kilos,
  };

  static CuadrillaData fromMap(Map<String, dynamic> m) => CuadrillaData(
    nombre: (m['nombre'] ?? '') as String?,
    integrantes: (m['integrantes'] as List?)
        ?.cast<Map<String, String>>() ??
        <Map<String, String>>[],
    kilos: (m['kilos'] is num)
        ? (m['kilos'] as num).toDouble()
        : double.tryParse('${m['kilos'] ?? 0}') ?? 0.0,
  );
}
