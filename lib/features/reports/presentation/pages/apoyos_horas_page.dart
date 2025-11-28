import 'package:flutter/material.dart';
import 'package:scanner_trabunda/core/widgets/qr_scanner.dart';

import 'package:scanner_trabunda/data/drift/app_database.dart';
import 'package:scanner_trabunda/data/drift/db.dart';
// 🔹 Supabase y servicio remoto
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scanner_trabunda/features/reports/data/datasources/reportes_supabase_service.dart';

/// Lista única de áreas de apoyo (la de tu Excel)
const List<String> kAreasApoyo = [
  'APOYO ANILLAS',
  'APOYO REVISADO ANILLAS',
  'APOYO LAVADO',
  'APOYO HIELERO',
  'APOYO ENVASADO TC (PALETEROS)',
  'APOYO RECIBIR PRODUCTO  TC',
  'GLASEADOR',
  'FILTRO MULTICABEZAL',
  'DESCONGELAR PRODUCTO',
  'CARGA DE PLACAS',
  'APOYO PRECAMARA NAVE III',
  'APOYO PRECAMARA NAVE I',
  'OPERADOR DE TRATAMIENTO',
  'APOYO TRATAMIENTO',
  'CTRL- ORUGAS',
  'CTRL- ENVASADO BLOCK',
  'CTRL- PLACAS',
  'CTRL-PESOS',
  'PESADORES - FILETE',
  'PESADORES - NUCAS',
  'PESADORES - ANILLAS',
  'ROTULADOR-ZONA PRIMARIA',
  'LAVANDERIA',
  'ACOPIO',
  'APOYO VIDEOJET',
  'VIDEO JET - ROTULADORES',
  'OPERADOR VIDEO JET',
  'SUPERVISION',
  'PLANILLEROS',
];

class ApoyosHorasPage extends StatefulWidget {
  const ApoyosHorasPage({
    super.key,
    required this.reporteId, // 👈 ya no se usa directamente, pero lo dejamos para no tocar otras pantallas
    required this.fecha,
    required this.turno,
    required this.planillero,
  });

  final int reporteId;
  final DateTime fecha;
  final String turno;
  final String planillero;

  @override
  State<ApoyosHorasPage> createState() => _ApoyosHorasPageState();
}

class _ApoyosHorasPageState extends State<ApoyosHorasPage> {
  /// id REAL del reporte en Drift, garantizado por `obtenerOCrearReportePlanillero`
  late int _reporteIdReal;

  late Future<ApoyosHorasListado> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadApoyos();
  }

  /// Obtiene o crea el reporte por (fecha, turno, planillero) y luego lista apoyos.
  Future<ApoyosHorasListado> _loadApoyos() async {
    // normaliza la fecha a solo día y garantiza un SOLO reporte por día/turno/planillero
    _reporteIdReal = await db.reportesDao.obtenerOCrearReportePlanillero(
      fecha: widget.fecha,
      turno: widget.turno,
      planillero: widget.planillero,
    );

    return db.reportesDao.listarApoyosPorReporte(_reporteIdReal);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadApoyos();
    });
  }

  Future<void> _borrar(int id) async {
    await db.reportesDao.eliminarApoyoHora(id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final fechaStr =
        '${widget.fecha.day.toString().padLeft(2, '0')}/${widget.fecha.month.toString().padLeft(2, '0')}/${widget.fecha.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apoyos por horas'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha: $fechaStr'),
                Text('Turno: ${widget.turno}'),
                Text('Planillero: ${widget.planillero}'),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: FutureBuilder<ApoyosHorasListado>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final data = snapshot.data ?? const ApoyosHorasListado();
                final pendientes = data.pendientes;
                final completos = data.completos;

                // 🔹 Si NO hay apoyos → mostramos formulario inline tipo Saneamiento
                if (pendientes.isEmpty && completos.isEmpty) {
                  return _ApoyosHorasInlineForm(
                    reporteId: _reporteIdReal, // 👈 usamos el id real
                    fecha: widget.fecha,
                    turno: widget.turno,
                    planillero: widget.planillero,
                  );
                }

                Widget _buildSectionTitle(String text) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView(
                  children: [
                    // Banner general de pendientes
                    if (pendientes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tienes ${pendientes.length} apoyo(s) pendiente(s). '
                                      'Completa la hora fin para cerrar el reporte.',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (pendientes.isNotEmpty) ...[
                      _buildSectionTitle('Reportes en espera (24h)'),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: _PendientesResumenCard(
                          pendientes: pendientes,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ApoyosPendientesFormPage(
                                  reporteId: _reporteIdReal,
                                  fecha: widget.fecha,
                                  turno: widget.turno,
                                  planillero: widget.planillero,
                                  pendientes: pendientes,
                                ),
                              ),
                            );
                            _reload();
                          },
                          onDelete: (apoyoId) async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Eliminar apoyo'),
                                content: const Text(
                                  '¿Seguro que deseas eliminar este registro?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ) ??
                                false;
                            if (ok) {
                              await _borrar(apoyoId);
                            }
                          },
                        ),
                      ),
                    ],

                    if (completos.isNotEmpty) ...[
                      _buildSectionTitle('Apoyos registrados'),
                      const Divider(height: 0),
                      ...completos.map(
                            (a) => Column(
                          children: [
                            ListTile(
                              title: Text(
                                '${a.codigoTrabajador} • ${a.areaApoyo}',
                              ),
                              subtitle: Text(
                                'De ${a.horaInicio} a ${a.horaFin ?? '--:--'}  →  ${a.horas.toStringAsFixed(2)} h',
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ApoyoHoraFormPage(
                                      reporteId: _reporteIdReal,
                                      apoyo: a,
                                      fecha: widget.fecha,
                                      turno: widget.turno,
                                      planillero: widget.planillero,
                                    ),
                                  ),
                                );
                                _reload();
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Eliminar apoyo'),
                                      content: const Text(
                                        '¿Seguro que deseas eliminar este registro?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                              context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                              context, true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                      false;
                                  if (ok) {
                                    await _borrar(a.id);
                                  }
                                },
                              ),
                            ),
                            const Divider(height: 0),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      // 👉 Sin botón flotante “+”, todo se maneja con el botón “Agregar trabajador”
    );
  }
}

class _PendientesResumenCard extends StatelessWidget {
  const _PendientesResumenCard({
    required this.pendientes,
    required this.onTap,
    required this.onDelete, // lo dejamos aunque aquí no lo usemos
  });

  final List<ApoyoHoraDetalle> pendientes;
  final VoidCallback onTap;
  final Future<void> Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final totalTrabajadores = pendientes.length;
    final uniqueAreas = pendientes.map((e) => e.areaApoyo).toSet().toList();

    final String resumenAreas = uniqueAreas.isEmpty
        ? 'Sin áreas registradas'
        : (uniqueAreas.length == 1
        ? uniqueAreas.first
        : '${uniqueAreas.length} áreas de apoyo');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        elevation: 0,
        color: cs.surfaceVariant.withOpacity(.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la card
              Row(
                children: [
                  const Icon(Icons.hourglass_bottom, size: 18),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Apoyos pendientes (24h)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Text(
                      '$totalTrabajadores apoyo(s)',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Resumen: número de trabajadores
              Row(
                children: [
                  Icon(Icons.groups_2_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$totalTrabajadores trabajador(es) con hora fin pendiente',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Resumen: áreas
              Row(
                children: [
                  Icon(Icons.work_outline, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      resumenAreas,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Texto explicativo
              Text(
                'Toca la tarjeta para completar las horas fin de todos los apoyos. '
                    'Si no se completan en 24 horas se eliminan automáticamente.',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
///  FORMULARIO INLINE (cuando NO hay apoyos) – estilo Saneamiento
/// ===============================================================

class _ApoyosHorasInlineForm extends StatefulWidget {
  const _ApoyosHorasInlineForm({
    required this.reporteId,
    required this.fecha,
    required this.turno,
    required this.planillero,
  });

  final int reporteId;
  final DateTime fecha;
  final String turno;
  final String planillero;

  @override
  State<_ApoyosHorasInlineForm> createState() =>
      _ApoyosHorasInlineFormState();
}

class _ApoyosHorasInlineFormState extends State<_ApoyosHorasInlineForm> {
  final _formKey = GlobalKey<FormState>();

  final List<_ApoyoFormModel> _trabajadores = [
    _ApoyoFormModel(),
  ];

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  double _calcHoras(TimeOfDay inicio, TimeOfDay fin) {
    final start = Duration(hours: inicio.hour, minutes: inicio.minute);
    final end = Duration(hours: fin.hour, minutes: fin.minute);
    final diff = end - start;
    return diff.inMinutes / 60.0;
  }

  Future<void> _pickHora(
      _ApoyoFormModel model,
      bool esInicio,
      BuildContext context,
      ) async {
    final initial = esInicio
        ? (model.inicio ?? const TimeOfDay(hour: 18, minute: 0))
        : (model.fin ?? const TimeOfDay(hour: 23, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;

    setState(() {
      if (esInicio) {
        model.inicio = picked;
      } else {
        model.fin = picked;
      }
      if (model.inicio != null && model.fin != null) {
        model.horas = _calcHoras(model.inicio!, model.fin!);
      }
    });
  }

  /// Escanea QR para un trabajador usando tu pantalla QrScanner
  /// y bloquea el campo si viene de QR.
  Future<void> _scanQrFor(_ApoyoFormModel model) async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScanner(pickOnly: true),
      ),
    );

    if (!mounted) return;
    if (result == null) return; // usuario canceló

    final code = (result['code'] ?? '').toString().trim();
    final name = (result['name'] ?? '').toString().trim();

    if (code.isEmpty) return;

    setState(() {
      model.codigoCtrl.text = code;
      model.codigoBloqueadoPorQr = true; // 🔒 bloqueamos edición del código

      // Si el scanner devolvió nombre, lo llenamos también
      if (name.isNotEmpty) {
        model.nombreCtrl.text = name;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que hora inicio, área y código sean obligatorios
    for (final m in _trabajadores) {
      if (m.inicio == null || m.area == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completa hora de inicio y área de apoyo para todos.'),
          ),
        );
        return;
      }
    }

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    // Insertar en BD local + Supabase (solo si tiene hora fin)
    for (final m in _trabajadores) {
      final horas = (m.fin != null) ? _calcHoras(m.inicio!, m.fin!) : 0.0;

      final horaInicioStr = _formatTime(m.inicio!);
      final horaFinStr = m.fin != null ? _formatTime(m.fin!) : null;

      final idLocal = await db.reportesDao.insertarApoyoHora(
        reporteId: widget.reporteId,
        codigoTrabajador: m.codigoCtrl.text.trim(),
        nombreTrabajador: m.nombreCtrl.text.trim().isEmpty
            ? null
            : m.nombreCtrl.text.trim(),
        horaInicio: horaInicioStr,
        horaFin: horaFinStr,
        horas: horas,
        areaApoyo: m.area!,
      );

      debugPrint(
        '[INSERT LOCAL] Apoyo guardado en Drift (ID $idLocal): '
            'reporteId=${widget.reporteId}, codigo=${m.codigoCtrl.text.trim()}, '
            'horaInicio=$horaInicioStr, horaFin=$horaFinStr, horas=$horas, area=${m.area}',
      );

      // 🔹 Solo mandamos a Supabase cuando ya tiene hora fin (registro completo)
      if (userId != null && m.fin != null) {
        try {
          await ReportesSupabaseService.instance.insertarApoyoHoraRemoto(
            reporteIdLocal: widget.reporteId,
            fecha: widget.fecha,
            turno: widget.turno,
            planillero: widget.planillero,
            userId: userId,
            codigoTrabajador: m.codigoCtrl.text.trim(),
            nombreTrabajador: m.nombreCtrl.text.trim().isEmpty
                ? null
                : m.nombreCtrl.text.trim(),
            horaInicio: horaInicioStr,
            horaFin: horaFinStr,
            horas: horas,
            area: m.area!,
          );
        } catch (e, st) {
          debugPrint(
            '[ApoyosHoras][REMOTE][ERROR] Error al enviar apoyo inicial a Supabase: '
                '$e\n$st',
          );
        }
      } else {
        debugPrint(
          '[ApoyosHoras][REMOTE] Apoyo pendiente solo local '
              '(userId=$userId, fin=${m.fin}). No se envía a Supabase todavía.',
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop(); // volver al detalle del reporte
    }
  }

  @override
  void dispose() {
    for (final m in _trabajadores) {
      m.codigoCtrl.dispose();
      m.nombreCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (int i = 0; i < _trabajadores.length; i++)
              _TrabajadorCard(
                index: i,
                model: _trabajadores[i],
                colorScheme: cs,
                areasApoyo: kAreasApoyo,
                onPickHoraInicio: () =>
                    _pickHora(_trabajadores[i], true, context),
                onPickHoraFin: () =>
                    _pickHora(_trabajadores[i], false, context),
                onRemove: _trabajadores.length == 1
                    ? null
                    : () {
                  setState(() {
                    _trabajadores.removeAt(i);
                  });
                },
                codigoBloqueado: _trabajadores[i].codigoBloqueadoPorQr,
                onScanQr: () => _scanQrFor(_trabajadores[i]),
              ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _trabajadores.add(_ApoyoFormModel());
                  });
                },
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Agregar trabajador'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar y volver'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modelo del formulario (solo UI, no Drift)
class _ApoyoFormModel {
  final TextEditingController codigoCtrl = TextEditingController();
  final TextEditingController nombreCtrl = TextEditingController();

  TimeOfDay? inicio;
  TimeOfDay? fin;
  double horas = 0.0;
  String? area;

  /// id local en la tabla ApoyosHoras (solo cuando estamos editando pendientes)
  int? idLocal;

  /// true = se escaneó con QR → el código no se puede editar
  bool codigoBloqueadoPorQr = false;
}

/// Card de cada trabajador en el formulario inline
class _TrabajadorCard extends StatelessWidget {
  const _TrabajadorCard({
    required this.index,
    required this.model,
    required this.colorScheme,
    required this.areasApoyo,
    required this.onPickHoraInicio,
    required this.onPickHoraFin,
    required this.onRemove,
    required this.codigoBloqueado,
    required this.onScanQr,
  });

  final int index;
  final _ApoyoFormModel model;
  final ColorScheme colorScheme;
  final List<String> areasApoyo;
  final VoidCallback onPickHoraInicio;
  final VoidCallback onPickHoraFin;
  final VoidCallback? onRemove;

  final bool codigoBloqueado;
  final Future<void> Function() onScanQr;

  @override
  Widget build(BuildContext context) {
    String _horaToText(TimeOfDay? t) {
      if (t == null) return '--:--';
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Trabajador ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // HORAS
            Row(
              children: [
                Expanded(
                  child: _HoraBox(
                    label: 'Hora inicio',
                    value: _horaToText(model.inicio),
                    onTap: onPickHoraInicio,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HoraBox(
                    label: 'Hora fin (opcional)',
                    value: _horaToText(model.fin),
                    onTap: onPickHoraFin,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CÓDIGO TRABAJADOR + QR
            TextFormField(
              controller: model.codigoCtrl,
              keyboardType: TextInputType.number,
              readOnly: codigoBloqueado,
              showCursor: !codigoBloqueado,
              enableInteractiveSelection: !codigoBloqueado,
              decoration: InputDecoration(
                labelText: 'Código del trabajador',
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    await onScanQr();
                  },
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresa el código';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // NOMBRE DEL TRABAJADOR
            TextFormField(
              controller: model.nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del trabajador',
                prefixIcon: Icon(Icons.person_outline, size: 20),
                border: OutlineInputBorder(),
                contentPadding:
                EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),

            const SizedBox(height: 16),

            // ÁREA APOYO
            DropdownButtonFormField<String>(
              value: model.area,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Área de apoyo',
                border: OutlineInputBorder(),
                contentPadding:
                EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              items: areasApoyo
                  .map(
                    (a) => DropdownMenuItem(
                  value: a,
                  child: Text(
                    a,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              )
                  .toList(),
              onChanged: (v) => model.area = v,
              validator: (v) =>
              v == null ? 'Selecciona el área de apoyo' : null,
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total horas: ${model.fin == null ? '--' : model.horas.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoraBox extends StatelessWidget {
  const _HoraBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.access_time, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
///  FORMULARIO INDIVIDUAL (cuando ya hay apoyos y se edita uno)
/// ===============================================================

class ApoyoHoraFormPage extends StatefulWidget {
  const ApoyoHoraFormPage({
    super.key,
    required this.reporteId,
    required this.fecha,
    required this.turno,
    required this.planillero,
    this.apoyo,
    this.soloCapturaHoraFin = false,
  });

  final int reporteId;
  final DateTime fecha;
  final String turno;
  final String planillero;
  final ApoyoHoraDetalle? apoyo;
  final bool soloCapturaHoraFin;

  @override
  State<ApoyoHoraFormPage> createState() => _ApoyoHoraFormPageState();
}

class _ApoyoHoraFormPageState extends State<ApoyoHoraFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();

  TimeOfDay? _inicio;
  TimeOfDay? _fin;
  String? _area;
  double _horasCalculadas = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.apoyo != null) {
      final a = widget.apoyo!;
      _codigoCtrl.text = a.codigoTrabajador;
      _inicio = _parseTime(a.horaInicio);
      if (a.horaFin != null && a.horaFin!.isNotEmpty) {
        _fin = _parseTime(a.horaFin!);
      }
      _area = a.areaApoyo;
      _horasCalculadas = a.horas;
      _nombreCtrl.text = a.nombreTrabajador ?? '';
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  double _calcularHoras(TimeOfDay inicio, TimeOfDay fin) {
    final start = Duration(hours: inicio.hour, minutes: inicio.minute);
    final end = Duration(hours: fin.hour, minutes: fin.minute);
    final diff = end - start;
    return diff.inMinutes / 60.0;
  }

  void _recalcularHoras() {
    if (_inicio != null && _fin != null) {
      setState(() {
        _horasCalculadas = _calcularHoras(_inicio!, _fin!);
      });
    }
  }

  Future<void> _pickHoraInicio() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _inicio ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      setState(() => _inicio = picked);
      _recalcularHoras();
    }
  }

  Future<void> _pickHoraFin() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _fin ?? const TimeOfDay(hour: 23, minute: 0),
    );
    if (picked != null) {
      setState(() => _fin = picked);
      _recalcularHoras();
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final allowGuardarSinHoraFin =
        widget.apoyo == null && !widget.soloCapturaHoraFin;

    if (_inicio == null || _area == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa hora inicio y área de apoyo')),
      );
      return;
    }

    if (_fin == null && !allowGuardarSinHoraFin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Captura la hora fin para continuar')),
      );
      return;
    }

    final horas =
    (_inicio != null && _fin != null) ? _calcularHoras(_inicio!, _fin!) : 0.0;
    final horaInicioStr = _formatTime(_inicio!);
    final horaFinStr = _fin != null ? _formatTime(_fin!) : null;

    // 🔹 Actualizar/insertar en BD local
    if (widget.apoyo == null) {
      await db.reportesDao.insertarApoyoHora(
        reporteId: widget.reporteId,
        codigoTrabajador: _codigoCtrl.text.trim(),
        nombreTrabajador: _nombreCtrl.text.trim().isEmpty
            ? null
            : _nombreCtrl.text.trim(),
        horaInicio: horaInicioStr,
        horaFin: horaFinStr,
        horas: horas,
        areaApoyo: _area!,
      );
    } else {
      await db.reportesDao.actualizarApoyoHora(
        id: widget.apoyo!.id,
        codigoTrabajador: _codigoCtrl.text.trim(),
        nombreTrabajador: _nombreCtrl.text.trim().isEmpty
            ? null
            : _nombreCtrl.text.trim(),
        horaInicio: horaInicioStr,
        horaFin: horaFinStr,
        horas: horas,
        areaApoyo: _area!,
      );
    }

    // 🔹 Enviar/actualizar en Supabase
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    // Solo enviamos a Supabase cuando YA tiene hora fin
    if (userId != null && _fin != null) {
      try {
        await ReportesSupabaseService.instance.insertarApoyoHoraRemoto(
          reporteIdLocal: widget.reporteId,
          fecha: widget.fecha,
          turno: widget.turno,
          planillero: widget.planillero,
          userId: userId,
          codigoTrabajador: _codigoCtrl.text.trim(),
          nombreTrabajador: _nombreCtrl.text.trim().isEmpty
              ? null
              : _nombreCtrl.text.trim(),
          horaInicio: horaInicioStr,
          horaFin: horaFinStr,
          horas: horas,
          area: _area!,
        );
      } catch (e, st) {
        debugPrint(
          '[ApoyosHoras][REMOTE][ERROR] Error al actualizar apoyo en Supabase: '
              '$e\n$st',
        );
      }
    } else {
      debugPrint(
        '[ApoyosHoras][REMOTE] userId=$userId, fin=$_fin → no se envía a Supabase todavía.',
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildHoraBox({
    required String label,
    required TimeOfDay? value,
    required VoidCallback? onTap,
  }) {
    final text = value == null ? '--:--' : value.format(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final editando = widget.apoyo != null;
    final soloCapturaFin = widget.soloCapturaHoraFin;

    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar apoyo' : 'Nuevo apoyo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Card(
                  elevation: 0,
                  color: cs.surfaceVariant.withOpacity(.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trabajador',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildHoraBox(
                              label: 'Hora inicio',
                              value: _inicio,
                              onTap: soloCapturaFin ? null : _pickHoraInicio,
                            ),
                            const SizedBox(width: 12),
                            _buildHoraBox(
                              label: soloCapturaFin
                                  ? 'Hora fin (completar)'
                                  : 'Hora fin',
                              value: _fin,
                              onTap: _pickHoraFin,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _codigoCtrl,
                          keyboardType: TextInputType.number,
                          readOnly: soloCapturaFin,
                          decoration: const InputDecoration(
                            labelText: 'Código del trabajador',
                            prefixIcon:
                            Icon(Icons.badge_outlined, size: 20),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa el código del trabajador';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Nombre del trabajador (solo lectura aquí)
                        TextFormField(
                          controller: _nombreCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del trabajador ',
                            prefixIcon:
                            Icon(Icons.person_outline, size: 20),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _area,
                          isExpanded: true,
                          items: kAreasApoyo
                              .map(
                                (a) => DropdownMenuItem(
                              value: a,
                              child: Text(
                                a,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                              .toList(),
                          onChanged: soloCapturaFin
                              ? null
                              : (v) => setState(() => _area = v),
                          decoration: const InputDecoration(
                            labelText: 'Área de apoyo',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                          v == null ? 'Selecciona el área' : null,
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Total horas: ${_fin == null ? '--' : _horasCalculadas.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _guardar,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      editando ? 'Guardar cambios' : 'Guardar',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
///   NUEVA PANTALLA: completar TODOS los apoyos pendientes a la vez
///   (muestra el mismo formulario múltiple que al inicio)
/// ===============================================================

class ApoyosPendientesFormPage extends StatefulWidget {
  const ApoyosPendientesFormPage({
    super.key,
    required this.reporteId,
    required this.fecha,
    required this.turno,
    required this.planillero,
    required this.pendientes,
  });

  final int reporteId;
  final DateTime fecha;
  final String turno;
  final String planillero;
  final List<ApoyoHoraDetalle> pendientes;

  @override
  State<ApoyosPendientesFormPage> createState() =>
      _ApoyosPendientesFormPageState();
}

class _ApoyosPendientesFormPageState extends State<ApoyosPendientesFormPage> {
  final _formKey = GlobalKey<FormState>();
  late List<_ApoyoFormModel> _trabajadores;

  @override
  void initState() {
    super.initState();
    _trabajadores = widget.pendientes.map((a) {
      final m = _ApoyoFormModel();
      m.idLocal = a.id;
      m.codigoCtrl.text = a.codigoTrabajador;
      m.nombreCtrl.text = a.nombreTrabajador ?? '';
      m.inicio = _parseTime(a.horaInicio);
      // Sigue pendiente → hora fin null
      m.area = a.areaApoyo;
      m.horas = a.horas;
      return m;
    }).toList();
  }

  TimeOfDay? _parseTime(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  double _calcHoras(TimeOfDay inicio, TimeOfDay fin) {
    final start = Duration(hours: inicio.hour, minutes: inicio.minute);
    final end = Duration(hours: fin.hour, minutes: fin.minute);
    final diff = end - start;
    return diff.inMinutes / 60.0;
  }

  Future<void> _pickHora(
      _ApoyoFormModel model,
      bool esInicio,
      BuildContext context,
      ) async {
    final initial = esInicio
        ? (model.inicio ?? const TimeOfDay(hour: 18, minute: 0))
        : (model.fin ?? const TimeOfDay(hour: 23, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;

    setState(() {
      if (esInicio) {
        model.inicio = picked;
      } else {
        model.fin = picked;
      }
      if (model.inicio != null && model.fin != null) {
        model.horas = _calcHoras(model.inicio!, model.fin!);
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;

    // ✅ Permitimos guardar aunque solo algunos tengan hora fin.
    for (int i = 0; i < _trabajadores.length; i++) {
      final m = _trabajadores[i];
      final original = widget.pendientes[i];

      // Si faltan datos mínimos, no tocamos ese registro
      if (m.inicio == null || m.area == null) {
        debugPrint(
          '[ApoyosHoras][LOCAL] Pendiente sin datos mínimos (index=$i) → no se toca.',
        );
        continue;
      }

      final bool tieneFin = m.fin != null;

      final String horaInicioStr = _formatTime(m.inicio!);
      final String? horaFinStr =
      tieneFin ? _formatTime(m.fin!) : null;
      final double horas =
      tieneFin ? _calcHoras(m.inicio!, m.fin!) : 0.0;

      // Tomamos el id de donde esté disponible
      final int idLocal = m.idLocal ?? original.id;

      // 🔹 Siempre actualizamos Drift (aunque siga pendiente)
      await db.reportesDao.actualizarApoyoHora(
        id: idLocal,
        codigoTrabajador: m.codigoCtrl.text.trim(),
        nombreTrabajador: m.nombreCtrl.text.trim().isEmpty
            ? null
            : m.nombreCtrl.text.trim(),
        horaInicio: horaInicioStr,
        horaFin: horaFinStr,
        horas: horas,
        areaApoyo: m.area!,
      );

      // 🔹 Solo mandamos a Supabase si YA tiene hora fin
      if (userId != null && tieneFin) {
        try {
          await ReportesSupabaseService.instance.insertarApoyoHoraRemoto(
            reporteIdLocal: widget.reporteId,
            fecha: widget.fecha,
            turno: widget.turno,
            planillero: widget.planillero,
            userId: userId,
            codigoTrabajador: m.codigoCtrl.text.trim(),
            nombreTrabajador: m.nombreCtrl.text.trim().isEmpty
                ? null
                : m.nombreCtrl.text.trim(),
            horaInicio: horaInicioStr,
            horaFin: horaFinStr,
            horas: horas,
            area: m.area!,
          );
        } catch (e, st) {
          debugPrint(
            '[ApoyosHoras][REMOTE][ERROR] Error al enviar pendientes a Supabase: $e\n$st',
          );
        }
      } else {
        debugPrint(
          '[ApoyosHoras][REMOTE] Pendiente actualizado solo local (idLocal=$idLocal, fin=$tieneFin)',
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    for (final m in _trabajadores) {
      m.codigoCtrl.dispose();
      m.nombreCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar apoyos pendientes'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (int i = 0; i < _trabajadores.length; i++)
                _TrabajadorCard(
                  index: i,
                  model: _trabajadores[i],
                  colorScheme: cs,
                  areasApoyo: kAreasApoyo,
                  onPickHoraInicio: () =>
                      _pickHora(_trabajadores[i], true, context),
                  onPickHoraFin: () =>
                      _pickHora(_trabajadores[i], false, context),
                  onRemove: _trabajadores.length == 1
                      ? null
                      : () {
                    setState(() {
                      _trabajadores.removeAt(i);
                    });
                  },
                  codigoBloqueado: false,
                  onScanQr: () async {},
                ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
