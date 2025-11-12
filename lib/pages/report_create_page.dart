import 'package:flutter/material.dart';
import 'area_detalle_page.dart';
import '../data/db.dart';

// ===========================================================
//  Crear Reporte
//  - Soporta "borrador": al escribir planillero o abrir Detalles
//    se crea/obtiene automáticamente el reporte y se guarda _reporteId.
// ===========================================================

class ReportCreatePage extends StatefulWidget {
  const ReportCreatePage({
    super.key,
    this.planilleroInicial,
  });

  final String? planilleroInicial;

  @override
  State<ReportCreatePage> createState() => _ReportCreatePageState();
}

// ---- modelo UI de fila de área (solo UI, no BD)
class _AreaRow {
  final String nombre;
  final TextEditingController cantidadCtrl;

  _AreaRow(this.nombre, {int cantidad = 0})
      : cantidadCtrl = TextEditingController(text: cantidad.toString());

  int get cantidad =>
      int.tryParse(cantidadCtrl.text.trim().replaceAll(',', '')) ?? 0;
}

class _ReportCreatePageState extends State<ReportCreatePage> {
  int? _reporteId; // 👈 declarado una sola vez
  DateTime _fecha = DateTime.now();
  String _turno = 'Día'; // Día | Noche
  final TextEditingController _planilleroCtrl = TextEditingController();

  // Áreas visibles en la lista
  final List<_AreaRow> _areas = [
    _AreaRow('Fileteros'),
    _AreaRow('Recepción'),
    _AreaRow('Empaque'),
    _AreaRow('Congelamiento de iqf'),
  ];

  // Catálogo disponible para “Agregar área”
  final List<String> _catalogoAreas = const [
    'Fileteros',
    'Recepción',
    'Empaque',
    'Congelamiento de iqf',
    'Saneamiento',
    'Máquinas orugas',
    'IQF',
  ];

  // ======== DRAFT / BORRADOR ========
  Future<void> _ensureDraft() async {
    // Necesitamos planillero para poder crear un borrador coherente
    final plan = _planilleroCtrl.text.trim();
    if (plan.isEmpty) return;
    if (_reporteId != null) return;

    final id = await db.reportesDao.getOrCreateReporte(
      fecha: _fecha,
      turno: _turno,
      planillero: plan,
    );
    if (!mounted) return;
    setState(() => _reporteId = id);
  }

  @override
  void dispose() {
    _planilleroCtrl.dispose();
    for (final a in _areas) {
      a.cantidadCtrl.dispose();
    }
    super.dispose();
  }

  int get _totalPersonal =>
      _areas.fold<int>(0, (acc, a) => acc + a.cantidad);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDate: _fecha,
    );
    if (picked != null && mounted) {
      setState(() => _fecha = picked);
    }
  }

  Future<void> _showAgregarAreaSheet() async {
    final ya = _areas.map((e) => e.nombre.toLowerCase()).toSet();
    final opciones =
    _catalogoAreas.where((n) => !ya.contains(n.toLowerCase())).toList();

    if (opciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay más áreas para agregar')),
      );
      return;
    }

    final seleccion = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Agregar área'),
              subtitle: Text('Selecciona un área para añadir a la lista'),
            ),
            for (final op in opciones)
              ListTile(
                title: Text(op),
                onTap: () => Navigator.pop(ctx, op),
              ),
          ],
        ),
      ),
    );

    if (seleccion != null && mounted) {
      setState(() => _areas.add(_AreaRow(seleccion)));
    }
  }

  // (opcional) navegación sin BD; lo dejo por si lo usas en otro menú
  Future<void> _irADetalle(_AreaRow areaRow) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AreaDetallePage(
          areaName: areaRow.nombre,
          // sin reporteAreaId
        ),
      ),
    );

    if (result != null && mounted) {
      final personas = (result['personas'] ?? 0) as int;
      setState(() => areaRow.cantidadCtrl.text = '$personas');
    }
  }

  // ======== Guardar / Confirmar ========
  Future<void> _guardar() async {
    final plan = _planilleroCtrl.text.trim();
    if (plan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el planillero')),
      );
      return;
    }

    // Asegura que exista el borrador (crea si aún no hay _reporteId)
    if (_reporteId == null) {
      await _ensureDraft();
    }
    if (_reporteId == null) return; // por seguridad

    // Actualiza cabecera del mismo reporte (no crea otro)
    await db.reportesDao.updateReporteHeader(
      _reporteId!,
      fecha: _fecha,
      turno: _turno,
      planillero: plan,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reporte #$_reporteId guardado')),
    );
  }


  Future<void> _abrirDetallesArea(_AreaRow areaRow) async {
    if (_reporteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero guarda el reporte')),
      );
      return;
    }

    final reporteAreaId =
    await db.reportesDao.getOrCreateReporteAreaId(_reporteId!, areaRow.nombre);

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AreaDetallePage(
          areaName: areaRow.nombre,
          reporteAreaId: reporteAreaId,
        ),
      ),
    );

    if (result != null && mounted) {
      final personas = (result['personas'] ?? 0) as int;
      setState(() => areaRow.cantidadCtrl.text = '$personas');
      await db.reportesDao.updateCantidadArea(reporteAreaId, personas);
    }
  }




  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar información')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== Card de cabecera =====
            Card(
              elevation: 0,
              color: cs.surfaceVariant.withOpacity(.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Fecha
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            onTap: _pickDate,
                            decoration: const InputDecoration(
                              labelText: 'Fecha',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            controller: TextEditingController(
                              text: _fecha
                                  .toLocal()
                                  .toString()
                                  .split(' ')
                                  .first,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Turno
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _turno,
                            items: const [
                              DropdownMenuItem(value: 'Día', child: Text('Día')),
                              DropdownMenuItem(value: 'Noche', child: Text('Noche')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Turno',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => setState(() => _turno = v ?? 'Día'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: _planilleroCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Planillero',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      onChanged: (_) => _ensureDraft(), // 👈 crea/obtiene borrador
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ===== Título "Personal por área" + acciones =====
            Row(
              children: [
                const Text(
                  'Personal por área',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.tune),
                  tooltip: 'Opciones',
                ),
                TextButton.icon(
                  onPressed: _showAgregarAreaSheet,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar área'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ===== Tabla / Lista =====
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  // Cabecera
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(.6),
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text('Área',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        SizedBox(width: 8),
                        SizedBox(
                          width: 95,
                          child: Text(
                            'Cantidad',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        SizedBox(width: 8),
                        SizedBox(width: 32),
                      ],
                    ),
                  ),

                  // Filas
                  for (int i = 0; i < _areas.length; i++)
                    _AreaRowTile(
                      area: _areas[i],
                      onChanged: (_) => setState(() {}),

                      onRemove: () {
                        setState(() {
                          _areas[i].cantidadCtrl.dispose();
                          _areas.removeAt(i);
                        });
                      },
                      onDetalles: () => _abrirDetallesArea(_areas[i]),
                    ),

                  // Total
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: cs.outlineVariant, width: .8)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total personal',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '$_totalPersonal',
                          style:
                          const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 72),
          ],
        ),
      ),

      // ===== Botón guardar =====
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 180,
        height: 48,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _guardar,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ),
    );
  }
}

// ======================= Widgets auxiliares =======================

class _FechaTile extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onTap;
  const _FechaTile({required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final txt = fecha.toLocal().toString().split(' ').first;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text('Fecha', style: TextStyle(fontSize: 12)),
            ),
            Text(txt, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today, size: 18),
          ],
        ),
      ),
    );
  }
}

class _AreaRowTile extends StatelessWidget {
  final _AreaRow area;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;
  final VoidCallback onDetalles;

  const _AreaRowTile({
    required this.area,
    required this.onChanged,
    required this.onRemove,
    required this.onDetalles,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withOpacity(.7)),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(area.nombre)),
          const SizedBox(width: 8),
          SizedBox(
            width: 95,
            child: TextField(
              controller: area.cantidadCtrl,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                  signed: false, decimal: false),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (v) {
              switch (v) {
                case 'detalles':
                // Espera al siguiente frame para que el popup se cierre
                  WidgetsBinding.instance.addPostFrameCallback((_) => onDetalles());
                  break;
                case 'eliminar':
                  WidgetsBinding.instance.addPostFrameCallback((_) => onRemove());
                  break;
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'detalles', child: Text('Detalles')),
              PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }
}

