import 'package:flutter/material.dart';
import 'area_detalle_page.dart';

/// Lista maestra de áreas en el orden solicitado (¡no modificar el orden!)
const List<String> kAreasOrdenadas = [
  'Recepción',
  'Fileteros',
  'Apoyo Fileteros',
  'Lavado Filete',
  'Pesadores Lavado',
  'Clasificado de filete',
  'Apoyos de lavado',
  'Lavado Nuca',
  'Pesador de Nucas',
  'Rotuladores',
  'Maquinas Peladoras',
  'Maquinas laminadoras',
  'Maquinas Orugas',
  'Cortador de anillas',
  'Clasificadora de anillas',
  'Apoyos de anillas',
  'Pesador de anillas',
  'Cocinero',
  'Hielero',
  'Operador de tratamiento',
  'Apoyo de tratamiento',
  'Envasado',
  'Control de Envasado',
  'Empaque block',
  'Controladores de placas',
  'Control de pesos empaque',
  'Corte de rodaja en maquina',
  'Pesador de rodajas manual',
  'Corte de rodaja en maquina',
  'Pesador de rodajas de maquina',
  'Corte de puntas',
  'Filtro de maquina rabera',
  'Congelamiento de rodajas',
  'Congelamiento de iqf',
  'Paletero de iqf',
  'Recibidores iqf',
  'Empaque iqf',
  'Filtros multicabezal',
  'Operador de Videojet',
  'Rotulador Videojet',
  'Apoyo Videojet',
  'Embarque',
  'Etiquetado',
  'Detector de metales',
  'Almacenamiento',
  'Saneamiento',
  'Lavanderia',
  'Jefe de turno',
  'Supervisores',
];

class AsistenciaPage extends StatefulWidget {
  const AsistenciaPage({super.key});

  @override
  State<AsistenciaPage> createState() => _AsistenciaPageState();
}

class _AsistenciaPageState extends State<AsistenciaPage> {
  final _formKey = GlobalKey<FormState>();

  DateTime _fecha = DateTime.now();
  String _turno = 'Día';
  final _planilleroCtrl = TextEditingController();

  // Áreas base que aparecen al abrir (puedes cambiarlas)
  final List<_AreaRow> _areas = [
    _AreaRow(nombre: 'Fileteros'),
    _AreaRow(nombre: 'Recepción'),
    _AreaRow(nombre: 'Empaque'),
    _AreaRow(nombre: 'Congelamiento de iqf'),
  ];

  @override
  void dispose() {
    _planilleroCtrl.dispose();
    for (final a in _areas) {
      a.ctrl.dispose();
    }
    super.dispose();
  }

  // Formateo de fecha YYYY-MM-DD
  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _fecha = picked);
    }
  }

  // Cálculo de total
  int get _totalPersonal {
    int total = 0;
    for (final a in _areas) {
      final v = int.tryParse(a.ctrl.text.trim());
      if (v != null) total += v;
    }
    return total;
  }

  // Filtra la lista maestra para mostrar solo las no agregadas aún
  List<String> get _areasDisponibles {
    final yaAgregadas = _areas.map((e) => e.nombre).toSet();
    return kAreasOrdenadas.where((n) => !yaAgregadas.contains(n)).toList();
  }

  // Selector con la lista completa de áreas (orden exacto)
  void _addAreaDialog() {
    final disponibles = _areasDisponibles;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black26, borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Selecciona un área',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (disponibles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Ya agregaste todas las áreas.'),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: disponibles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final name = disponibles[i];
                        return ListTile(
                          leading: const Icon(Icons.add_circle_outline, color: Color(0xFF0F5DAA)),
                          title: Text(name),
                          onTap: () {
                            setState(() => _areas.add(_AreaRow(nombre: name)));
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'fecha': _fmt(_fecha),
      'turno': _turno,
      'planillero': _planilleroCtrl.text.trim(),
      'areas': [
        for (final a in _areas) {'area': a.nombre, 'cantidad': int.tryParse(a.ctrl.text.trim()) ?? 0}
      ],
      'total': _totalPersonal,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Asistencia guardada (total: ${payload['total']})')),
    );

    // TODO: Aquí llamaremos a tu API real (HTTP POST) con `payload`.
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF0F5DAA);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        actions: [
          IconButton(
            tooltip: 'Escanear (opcional)',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.pushNamed(context, '/scanner'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.save),
        onPressed: _guardar,
        label: const Text('Guardar'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cabecera
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickFecha,
                              borderRadius: BorderRadius.circular(10),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Fecha',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_fmt(_fecha)),
                                    const Icon(Icons.calendar_today, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _turno,
                              decoration: InputDecoration(
                                labelText: 'Turno',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Día', child: Text('Día')),
                                DropdownMenuItem(value: 'Noche', child: Text('Noche')),
                              ],
                              onChanged: (v) => setState(() => _turno = v ?? 'Día'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _planilleroCtrl,
                        decoration: InputDecoration(
                          labelText: 'Planillero',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.badge),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el planillero' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Encabezado de sección + botón para agregar desde la lista
              Row(
                children: [
                  const Text('Personal por área', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addAreaDialog,
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Agregar área'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Tabla
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    // Encabezado tabla
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F2FA),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: const [
                          Expanded(flex: 6, child: Text('Área', style: TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(flex: 3, child: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.w600))),
                          SizedBox(width: 40), // eliminar
                          SizedBox(width: 8),
                          SizedBox(width: 40), // espacio para botón Detalle
                        ],
                      ),

                    ),

                    // Filas
                    for (int i = 0; i < _areas.length; i++)
                      _AreaRowWidget(
                        row: _areas[i],
                        onChanged: () => setState(() {}), // refresca el total al editar
                        onDelete: () {
                          setState(() {
                            _areas[i].ctrl.dispose();
                            _areas.removeAt(i);
                          });
                        },
                      ),

                    // Total
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 6,
                            child: Text('Total personal', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _totalPersonal.toString(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: brand,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80), // margen para el FAB
            ],
          ),
        ),
      ),
    );
  }
}

/// Modelo simple de fila de área
class _AreaRow {
  final String nombre;
  final TextEditingController ctrl;
  _AreaRow({required this.nombre}) : ctrl = TextEditingController(text: '0');
}

/// Widget de fila editable
class _AreaRowWidget extends StatelessWidget {
  final _AreaRow row;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  const _AreaRowWidget({
    required this.row,
    required this.onDelete,
    required this.onChanged,
    super.key,
  });

  Future<void> _openDetalle(BuildContext context) async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => AreaDetallePage(areaName: row.nombre)),
    );
    if (result != null) {
      row.ctrl.text = result.toString();
      onChanged(); // refresca total
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Text(row.nombre, style: const TextStyle(fontSize: 15)),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: row.ctrl,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '0';
                final n = int.tryParse(v.trim());
                if (n == null || n < 0) return 'N°';
                return null;
              },
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Detalle (QR y lista)',
            icon: const Icon(Icons.list_alt_rounded, color: Color(0xFF0F5DAA)),
            onPressed: () => _openDetalle(context),
          ),
          IconButton(
            tooltip: 'Quitar área',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

