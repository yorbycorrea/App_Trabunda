import 'package:flutter/material.dart';

/// 🔹 Lista referencia de áreas (puedes unificarla con la que ya usas)
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

class ReportsListPage extends StatefulWidget {
  const ReportsListPage({super.key});

  @override
  State<ReportsListPage> createState() => _ReportsListPageState();
}

class _ReportsListPageState extends State<ReportsListPage> {
  // Filtros
  DateTimeRange? _rango;
  final Set<String> _areas = {};
  String _turno = 'Todos'; // Todos | Día | Noche
  final _planilleroCtrl = TextEditingController();

  // Resultados
  final List<ReportSummary> _items = [];
  bool _loading = false;

  @override
  void dispose() {
    _planilleroCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickRango() async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 2, 1, 1),
      lastDate: DateTime(today.year + 1, 12, 31),
      initialDateRange: _rango ?? DateTimeRange(start: today, end: today),
    );
    if (picked != null) setState(() => _rango = picked);
  }

  void _openAreasSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AreasPickerSheet(
        seleccionadas: _areas,
        onConfirm: (set) {
          setState(() {
            _areas
              ..clear()
              ..addAll(set);
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _limpiar() {
    setState(() {
      _rango = null;
      _areas.clear();
      _turno = 'Todos';
      _planilleroCtrl.clear();
      _items.clear();
    });
  }

  Future<void> _fetchReports() async {
    setState(() => _loading = true);

    // TODO: Reemplaza por tu llamada real a backend
    await Future.delayed(const Duration(milliseconds: 600));
    final demo = <ReportSummary>[
      ReportSummary(
        fecha: DateTime.now(),
        area: 'Fileteros',
        turno: 'Día',
        totalPersonal: 8,
        kilos: 1234.5,
        planillero: 'María',
        id: 'RPT-0001',
      ),
      ReportSummary(
        fecha: DateTime.now().subtract(const Duration(days: 1)),
        area: 'Congelamiento de iqf',
        turno: 'Noche',
        totalPersonal: 6,
        kilos: 980.0,
        planillero: 'Pedro',
        id: 'RPT-0002',
      ),
    ];

    // Filtrado local de demo según filtros
    Iterable<ReportSummary> data = demo;
    if (_rango != null) {
      data = data.where((r) =>
      !r.fecha.isBefore(_onlyDate(_rango!.start)) &&
          !r.fecha.isAfter(_onlyDate(_rango!.end)));
    }
    if (_areas.isNotEmpty) {
      data = data.where((r) => _areas.contains(r.area));
    }
    if (_turno != 'Todos') {
      data = data.where((r) => r.turno == _turno);
    }
    if (_planilleroCtrl.text.trim().isNotEmpty) {
      final q = _planilleroCtrl.text.trim().toLowerCase();
      data = data.where((r) => r.planillero.toLowerCase().contains(q));
    }

    setState(() {
      _items
        ..clear()
        ..addAll(data);
      _loading = false;
    });
  }

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ver reportes')),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filtros
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Rango + Turno
                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: _FilterTile(
                            label: 'Rango de fechas',
                            value: _rango == null
                                ? 'Selecciona'
                                : '${_fmtDate(_rango!.start)}  —  ${_fmtDate(_rango!.end)}',
                            icon: Icons.date_range, // 👈 reemplazo de event_range
                            onTap: _pickRango,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Turno',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.schedule_rounded),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _turno,
                                items: const [
                                  DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                                  DropdownMenuItem(value: 'Día', child: Text('Día')),
                                  DropdownMenuItem(value: 'Noche', child: Text('Noche')),
                                ],
                                onChanged: (v) => setState(() => _turno = v ?? 'Todos'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Áreas + Planillero
                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: _FilterTile(
                            label: 'Áreas',
                            value: _areas.isEmpty
                                ? 'Todas'
                                : _areas.length == 1
                                ? _areas.first
                                : '${_areas.length} seleccionadas',
                            icon: Icons.segment_rounded,
                            onTap: _openAreasSheet,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: _planilleroCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Planillero',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Chips de áreas seleccionadas
                    if (_areas.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _areas
                              .map((a) => Chip(
                            label: Text(a),
                            onDeleted: () => setState(() => _areas.remove(a)),
                          ))
                              .toList(),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _limpiar,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _fetchReports,
                            icon: const Icon(Icons.search_rounded),
                            label: const Text('Buscar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Resultados
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              _EmptyState(onTapBuscar: _fetchReports) // 👈 ahora existe
            else
              ..._items.map((r) => _ReportCard(
                data: r,
                onTap: () {
                  // TODO: Navegar a detalle completo del reporte
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ver detalle: ${r.id}')),
                  );
                },
              )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// ======= MODELOS Y WIDGETS =======

class ReportSummary {
  final String id;
  final DateTime fecha;
  final String area;
  final String turno;
  final int totalPersonal;
  final double kilos;
  final String planillero;

  ReportSummary({
    required this.id,
    required this.fecha,
    required this.area,
    required this.turno,
    required this.totalPersonal,
    required this.kilos,
    required this.planillero,
  });
}

class _ReportCard extends StatelessWidget {
  final ReportSummary data;
  final VoidCallback onTap;
  const _ReportCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.area,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data.turno,
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(fmt(data.fecha)),
                  const Spacer(),
                  const Icon(Icons.badge_outlined, size: 16, color: Colors.black54),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      data.planillero,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _pill(icon: Icons.group_outlined, label: 'Personal', value: '${data.totalPersonal}'),
                  const SizedBox(width: 8),
                  _pill(icon: Icons.scale_outlined, label: 'Kilos', value: data.kilos.toStringAsFixed(2)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Ver detalle'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  const _FilterTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
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
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

/// BottomSheet para multi-selección de áreas con búsqueda rápida
class _AreasPickerSheet extends StatefulWidget {
  final Set<String> seleccionadas;
  final ValueChanged<Set<String>> onConfirm;
  const _AreasPickerSheet({
    required this.seleccionadas,
    required this.onConfirm,
  });

  @override
  State<_AreasPickerSheet> createState() => _AreasPickerSheetState();
}

class _AreasPickerSheetState extends State<_AreasPickerSheet> {
  late Set<String> _tmp;
  final _qCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tmp = {...widget.seleccionadas};
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = kAreasOrdenadas
        .where((a) => a.toLowerCase().contains(_qCtrl.text.trim().toLowerCase()))
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          left: 16, right: 16, top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black26, borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Selecciona áreas', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar área…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final a = filtered[i];
                  final checked = _tmp.contains(a);
                  return ListTile(
                    title: Text(a),
                    trailing: Checkbox(
                      value: checked,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _tmp.add(a);
                          } else {
                            _tmp.remove(a);
                          }
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        if (checked) {
                          _tmp.remove(a);
                        } else {
                          _tmp.add(a);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => widget.onConfirm(_tmp),
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vacío cuando no hay resultados
class _EmptyState extends StatelessWidget {
  final VoidCallback onTapBuscar;
  const _EmptyState({required this.onTapBuscar});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          children: [
            const Icon(Icons.find_in_page_outlined, size: 64, color: Colors.black38),
            const SizedBox(height: 12),
            const Text('Sin resultados', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Ajusta los filtros y vuelve a intentarlo.',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onTapBuscar,
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
          ],
        ),
      ),
    );
  }
}
