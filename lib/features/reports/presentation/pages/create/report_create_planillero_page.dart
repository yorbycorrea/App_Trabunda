import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:scanner_trabunda/data/drift/app_database.dart';
import 'package:scanner_trabunda/data/drift/db.dart';
import 'package:scanner_trabunda/features/auth/presentation/controllers/auth_controller.dart';
import 'package:scanner_trabunda/features/reports/data/datasources/reportes_supabase_service.dart';
import 'package:scanner_trabunda/features/reports/presentation/pages/area/area_detalle_page.dart';
import 'package:scanner_trabunda/features/reports/presentation/pages/apoyos_horas_page.dart';

class ReportCreatePlanilleroPage extends StatefulWidget {
  const ReportCreatePlanilleroPage({
    super.key,
    this.planilleroInicial,
  });

  final String? planilleroInicial;

  @override
  State<ReportCreatePlanilleroPage> createState() =>
      _ReportCreatePlanilleroPageState();
}

class _AreaRow {
  final String nombre;
  final TextEditingController cantidadCtrl;

  _AreaRow(this.nombre, {int cantidad = 0})
      : cantidadCtrl = TextEditingController(text: cantidad.toString());

  int get cantidad =>
      int.tryParse(cantidadCtrl.text.trim().replaceAll(',', '')) ?? 0;
}

class _ReportCreatePlanilleroPageState extends State<ReportCreatePlanilleroPage> {
  int? _reporteId;
  bool _enviadoASupabase = false;
  DateTime _fecha = DateTime.now();
  String _turno = 'Día';
  final TextEditingController _planilleroCtrl = TextEditingController();

  late List<_AreaRow> _areas = [
    _AreaRow('Fileteros'),
    _AreaRow('Recepción'),
    _AreaRow('Empaque'),
    _AreaRow('Congelamiento de iqf'),
  ];

  late List<String> _catalogoAreas = const [
    'Fileteros',
    'Recepción',
    'Empaque',
    'Congelamiento de iqf',
    'Saneamiento',
    'Máquinas orugas',
    'IQF',
  ];

  Future<void> _ensureDraft() async {
    final plan = _planilleroCtrl.text.trim();
    if (plan.isEmpty) return;
    if (_reporteId != null) return;

    final id = await db.reportesDao.getOrCreateReporte(
      fecha: _fecha,
      turno: _turno,
      planillero: plan,
    );
    final supabaseId = await db.reportesDao.getReporteSupabaseId(id);
    if (!mounted) return;
    setState(() {
      _reporteId = id;
      _enviadoASupabase = supabaseId != null;
    });
  }

  @override
  void dispose() {
    _planilleroCtrl.dispose();
    for (final a in _areas) {
      a.cantidadCtrl.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final inicial = widget.planilleroInicial;
    if (inicial != null && inicial.isNotEmpty) {
      _planilleroCtrl.text = inicial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _ensureDraft();
        }
      });
    }
  }

  int get _totalPersonal => _areas.fold<int>(0, (acc, a) => acc + a.cantidad);

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

  Future<void> _abrirApoyosPorHoras() async {
    final plan = _planilleroCtrl.text.trim();
    if (plan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero verifica el responsable del reporte.'),
        ),
      );
      return;
    }

    if (_reporteId == null) {
      await _ensureDraft();
    }
    if (_reporteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo crear el borrador del reporte.'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApoyosHorasPage(
          reporteId: _reporteId!,
          fecha: _fecha,
          turno: _turno,
          planillero: plan,
        ),
      ),
    );
  }

  Future<bool> _guardar() async {
    final plan = _planilleroCtrl.text.trim();
    if (plan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el responsable del reporte')),
      );
      return false;
    }

    final bool esNuevoReporte = !_enviadoASupabase;

    if (_reporteId == null) {
      await _ensureDraft();
    }
    if (_reporteId == null) return false;

    await db.reportesDao.updateReporteHeader(
      _reporteId!,
      fecha: _fecha,
      turno: _turno,
      planillero: plan,
    );

    if (esNuevoReporte) {
      final auth = AuthScope.read(context);
      final currentUser = auth.currentUser;

      if (currentUser != null) {
        try {
          final ReporteDetalle? detalle =
              await db.reportesDao.fetchReporteDetalle(_reporteId!);

          if (detalle == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo cargar el detalle del reporte local.'),
              ),
            );
            return false;
          }

          final supabaseId = await ReportesSupabaseService.instance
              .enviarReporteCompletoDesdeLocal(
            reporte: detalle,
            userId: currentUser.id,
            observaciones: null,
          );

          await db.reportesDao.saveReporteSupabaseId(
            _reporteId!,
            supabaseId,
          );

          setState(() => _enviadoASupabase = true);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No se pudo enviar a Supabase: ${e.toString()}',
              ),
            ),
          );
          return false;
        }
      } else {
        debugPrint(
          '[ReportCreatePlanilleroPage] No se pudo enviar a Supabase: currentUser es null',
        );
      }
    }

    return true;
  }

  Future<void> _onGuardarPressed() async {
    if (_totalPersonal == 0) {
      await showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text(
              'Registro inválido',
              textAlign: TextAlign.center,
            ),
            content: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Debes registrar al menos 1 persona en alguna área antes de guardar el reporte.',
                textAlign: TextAlign.center,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    final bool? shouldSave = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text(
            'Confirmar',
            textAlign: TextAlign.center,
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              '¿Estás seguro de guardar este reporte?\n'
              'Esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('NO'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('SÍ'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) return;

    final success = await _guardar();
    if (!success) return;

    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text(
            'Archivo guardado',
            textAlign: TextAlign.center,
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'El reporte se guardó correctamente.',
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
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
      final horaInicio = result['horaInicio'] as String?;
      final horaFin = result['horaFin'] as String?;
      final desglose =
          (result['desglose'] as List?)?.cast<Map<String, dynamic>>();
      setState(() => areaRow.cantidadCtrl.text = '$personas');
      await db.reportesDao.saveReporteAreaDatos(
        reporteAreaId: reporteAreaId,
        cantidad: personas,
        horaInicio: horaInicio,
        horaFin: horaFin,
        desglose: desglose,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = AuthScope.watch(context).currentUser;
    final isAdmin = user?.isAdmin ?? false;
    final bool isPlanillero = user?.isPlanillero ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar información')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                            onChanged: (v) =>
                                setState(() => _turno = v ?? 'Día'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: _planilleroCtrl,
                      readOnly: !isAdmin,
                      enabled: isAdmin || _planilleroCtrl.text.isNotEmpty,
                      decoration: InputDecoration(
                        labelText: user?.role ?? 'Responsable',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ).copyWith(
                        suffixIcon:
                            isAdmin ? null : const Icon(Icons.lock_outline, size: 18),
                        helperText:
                            isAdmin ? null : 'Asignado automáticamente por tu sesión',
                      ),
                      onChanged: isAdmin ? (_) => _ensureDraft() : null,
                    ),
                  ],
                ),
              ),
            ),

            if (isPlanillero) ...[
              const SizedBox(height: 16),
              _ApoyosHorasCard(onTap: _abrirApoyosPorHoras),
            ],

            const SizedBox(height: 16),

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

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.outlineVariant),
              ),
            ),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(.6),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: cs.outlineVariant,
                          width: .8,
                        ),
                      ),
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
                          style: const TextStyle(fontWeight: FontWeight.w700),
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

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 180,
        height: 48,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          onPressed: _onGuardarPressed,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
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
              keyboardType:
                  const TextInputType.numberWithOptions(signed: false, decimal: false),
              readOnly: true,
              showCursor: false,
              enableInteractiveSelection: false,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: onDetalles,
          ),
        ],
      ),
    );
  }
}

class _ApoyosHorasCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ApoyosHorasCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceVariant.withOpacity(.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.access_time_rounded,
                  color: cs.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apoyos por horas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Registrar personal de apoyo pagado por horas trabajadas.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
