import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:scanner_trabunda/data/drift/db.dart';
import 'package:scanner_trabunda/data/drift/app_database.dart';
import 'package:scanner_trabunda/features/auth/presentation/controllers/auth_controller.dart';

import 'package:scanner_trabunda/features/reports/data/datasources/reportes_supabase_service.dart';

// NUEVOS MÓDULOS
import 'package:scanner_trabunda/features/reports/presentation/pages/apoyos_horas_page.dart';
import 'package:scanner_trabunda/features/reports/presentation/pages/area/area_detalle_page.dart';

class ReportCreatePage extends StatefulWidget {
  const ReportCreatePage({
    super.key,
    this.planilleroInicial,
  });

  final String? planilleroInicial;

  @override
  State<ReportCreatePage> createState() => _ReportCreatePageState();
}

class _ReportCreatePageState extends State<ReportCreatePage> {
  int? _reporteId;
  bool _enviadoASupabase = false;

  DateTime _fecha = DateTime.now();
  String _turno = 'Día';
  final TextEditingController _planilleroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.planilleroInicial != null &&
        widget.planilleroInicial!.trim().isNotEmpty) {
      _planilleroCtrl.text = widget.planilleroInicial!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureDraft();
      });
    }
  }

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(2100),
      initialDate: _fecha,
    );
    if (picked != null && mounted) {
      setState(() => _fecha = picked);
      _ensureDraft();
    }
  }

  Future<void> _goToApoyosHoras() async {
    if (_planilleroCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero ingresa el planillero')),
      );
      return;
    }

    await _ensureDraft();
    if (_reporteId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApoyosHorasPage(
          reporteId: _reporteId!,
          fecha: _fecha,
          turno: _turno,
          planillero: _planilleroCtrl.text.trim(),
        ),
      ),
    );
  }

  Future<void> _goToTrabajoPorAvance() async {
    if (_planilleroCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero ingresa el planillero')),
      );
      return;
    }

    await _ensureDraft();
    if (_reporteId == null) return;

    // La pantalla área_detalle_page es tu módulo actual
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AreaDetallePage(
          areaName: "Trabajo por avance",
          reporteAreaId: _reporteId!, // reutilizamos el ID del reporte
        ),
      ),
    );
  }

  Future<void> _goToConteoRapido() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esta función está en desarrollo')),
    );
  }

  Future<void> _guardarFinal() async {
    if (_planilleroCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el planillero')),
      );
      return;
    }

    await _ensureDraft();
    if (_reporteId == null) return;

    // actualizar la cabecera
    await db.reportesDao.updateReporteHeader(
      _reporteId!,
      fecha: _fecha,
      turno: _turno,
      planillero: _planilleroCtrl.text.trim(),
    );

    if (!_enviadoASupabase) {
      final auth = AuthScope.read(context);
      final user = auth.currentUser;

      if (user != null) {
        final ReporteDetalle? detalle =
        await db.reportesDao.fetchReporteDetalle(_reporteId!);
        if (detalle == null) return;

        final supabaseId =
        await ReportesSupabaseService.instance.enviarReporteCompletoDesdeLocal(
          reporte: detalle,
          userId: user.id,
          observaciones: null,
        );

        await db.reportesDao.saveReporteSupabaseId(_reporteId!, supabaseId);

        if (mounted) {
          setState(() => _enviadoASupabase = true);
        }
      }
    }

    if (!mounted) return;
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Guardado"),
        content: const Text("El reporte fue guardado correctamente."),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = AuthScope.watch(context).currentUser;

    final bool isAdmin = user?.isAdmin ?? false;
    final bool isPlanillero = user?.isPlanillero ?? false;
    // final bool isSupervisorSaneamiento = user?.isSupervisorSaneamiento ?? false;
    // (si lo necesitas para otras decisiones, ya lo tienes arriba comentado)

    return Scaffold(
      appBar: AppBar(title: const Text("Ingresar información")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --------------------------------------------------------
          // CABECERA DEL REPORTE
          // --------------------------------------------------------
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: cs.surfaceVariant.withOpacity(.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _fecha.toString().split(" ").first,
                          ),
                          onTap: _pickDate,
                          decoration: const InputDecoration(
                            labelText: "Fecha",
                            suffixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField(
                          value: _turno,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Turno",
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "Día",
                              child: Text("Día"),
                            ),
                            DropdownMenuItem(
                              value: "Noche",
                              child: Text("Noche"),
                            ),
                          ],
                          onChanged: (v) {
                            _turno = v ?? "Día";
                            _ensureDraft();
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _planilleroCtrl,
                    readOnly: !isAdmin,
                    decoration: InputDecoration(
                      labelText: user?.role ?? "Planillero",
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon:
                      isAdmin ? null : const Icon(Icons.lock_outline),
                    ),
                    onChanged: (_) => _ensureDraft(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // --------------------------------------------------------
          // MÓDULOS (3 CARDS) — SOLO PARA ROL PLANILLERO
          // --------------------------------------------------------
          if (isPlanillero) ...[
            // Apoyos por horas
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text("Apoyos por horas"),
                subtitle: const Text("Registrar pagos por horas trabajadas"),
                onTap: _goToApoyosHoras,
              ),
            ),
            const SizedBox(height: 10),

            // Trabajo por avance
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.groups_2_outlined),
                title: const Text("Trabajo por avance"),
                subtitle:
                const Text("Registrar cuadrillas y áreas de trabajo"),
                onTap: _goToTrabajoPorAvance,
              ),
            ),
            const SizedBox(height: 10),

            // Conteo rápido
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text("Conteo rápido de personal"),
                subtitle: const Text(
                    "Registrar personal presente rápidamente"),
                onTap: _goToConteoRapido,
              ),
            ),
            const SizedBox(height: 80),
          ] else
          // Para saneamiento u otros roles solo dejamos un espacio
            const SizedBox(height: 80),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 180,
        height: 48,
        child: FloatingActionButton.extended(
          label: const Text("Guardar"),
          icon: const Icon(Icons.save_outlined),
          onPressed: _guardarFinal,
        ),
      ),
    );
  }
}
