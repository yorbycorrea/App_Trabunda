import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:scanner_trabunda/data/drift/app_database.dart';
import 'package:scanner_trabunda/data/drift/db.dart';
import 'package:scanner_trabunda/features/auth/presentation/controllers/auth_controller.dart';
import 'package:scanner_trabunda/features/reports/data/datasources/reportes_supabase_service.dart';
import 'package:scanner_trabunda/features/reports/presentation/pages/apoyos_horas_page.dart';
import 'package:scanner_trabunda/features/reports/presentation/pages/report_detail_page.dart';

/// ===================================================================
///  Crear reporte – VISTA PARA PLANILLEROS
///  - Encabezado (fecha, turno, planillero)
///  - 3 opciones: Apoyos por horas / Trabajo por avance / Conteo rápido
///  - Mantiene la lógica de borrador y guardado/envío a Supabase
/// ===================================================================

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

class _ReportCreatePlanilleroPageState
    extends State<ReportCreatePlanilleroPage> {
  int? _reporteId;
  bool _enviadoASupabase = false;

  DateTime _fecha = DateTime.now();
  String _turno = 'Día';

  final TextEditingController _planilleroCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Si viene un nombre inicial lo usamos
    final inicial = widget.planilleroInicial;
    if (inicial != null && inicial.isNotEmpty) {
      _planilleroCtrl.text = inicial;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Sincronizamos siempre el nombre del usuario logueado
    final auth = AuthScope.read(context);
    final user = auth.currentUser;

    if (user != null) {
      // Para planillero, siempre el nombre de su sesión
      if (user.isPlanillero) {
        _planilleroCtrl.text = user.name;
      }
    }
  }

  @override
  void dispose() {
    _planilleroCtrl.dispose();
    super.dispose();
  }

  // ==========================================================
  //  BORRADOR
  // ==========================================================
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

  // ==========================================================
  //  GUARDAR (sin cambiar la lógica original)
  // ==========================================================
  Future<bool> _guardar() async {
    final plan = _planilleroCtrl.text.trim();
    if (plan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el responsable del reporte')),
      );
      return false;
    }

    final bool esNuevoReporte = !_enviadoASupabase;

    // Asegurar borrador
    if (_reporteId == null) {
      await _ensureDraft();
    }
    if (_reporteId == null) return false;

    // 1) Actualizar cabecera en BD local
    await db.reportesDao.updateReporteHeader(
      _reporteId!,
      fecha: _fecha,
      turno: _turno,
      planillero: plan,
    );

    // 2) Si aún no se envió a Supabase => enviar reporte completo
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
                content: Text(
                    'No se pudo cargar el detalle del reporte local.'),
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

  // ==========================================================
  //  FLUJO DEL BOTÓN GUARDAR
  // ==========================================================
  Future<void> _onGuardarPressed() async {
    // Diálogo de confirmación
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('NO'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(true),
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
                Navigator.of(context).pop(); // cierra diálogo
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  //  NAVEGACIÓN A LAS OPCIONES
  // ==========================================================
  Future<void> _goToApoyosHoras() async {
    final plan = _planilleroCtrl.text.trim();
    if (plan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero completa el planillero.')),
      );
      return;
    }

    await _ensureDraft();
    if (_reporteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el borrador.')),
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

  Future<void> _goToTrabajoPorAvance() async {
    final plan = _planilleroCtrl.text.trim();
    if (plan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero completa el planillero.')),
      );
      return;
    }

    await _ensureDraft();
    if (_reporteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear el borrador.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailPage(
          reporteId: _reporteId!,
        ),
      ),
    );
  }

  void _showEnConstruccion(String titulo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$titulo aún está en desarrollo')),
    );
  }

  // ==========================================================
  //  UI
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = AuthScope.watch(context);
    final user = auth.currentUser;
    final bool isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresar información')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== ENCABEZADO =====
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
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2023, 1, 1),
                                lastDate: DateTime(2100, 12, 31),
                                initialDate: _fecha,
                              );
                              if (picked != null && mounted) {
                                setState(() => _fecha = picked);
                              }
                            },
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
                              DropdownMenuItem(
                                value: 'Día',
                                child: Text('Día'),
                              ),
                              DropdownMenuItem(
                                value: 'Noche',
                                child: Text('Noche'),
                              ),
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
                        labelText: 'planillero',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ).copyWith(
                        suffixIcon: isAdmin
                            ? null
                            : const Icon(Icons.lock_outline, size: 18),
                        helperText: isAdmin
                            ? null
                            : 'Asignado automáticamente por tu sesión',
                      ),
                      onChanged: isAdmin ? (_) => _ensureDraft() : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ===== OPCIONES (Apoyos / Trabajo / Conteo) =====
            _OptionCard(
              icon: Icons.access_time_rounded,
              title: 'Apoyos por horas',
              subtitle:
              'Registrar personal de apoyo pagado por horas trabajadas',
              onTap: _goToApoyosHoras,
            ),
            const SizedBox(height: 8),
            _OptionCard(
              icon: Icons.groups_2_rounded,
              title: 'Trabajo por avance',
              subtitle: 'Registrar cuadrillas y áreas de trabajo',
              onTap: _goToTrabajoPorAvance,
            ),
            const SizedBox(height: 8),
            _OptionCard(
              icon: Icons.groups_rounded,
              title: 'Conteo rápido de personal',
              subtitle: 'Registrar personal presente rápidamente',
              onTap: () => _showEnConstruccion('Conteo rápido de personal'),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 180,
        height: 48,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _onGuardarPressed,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ),
    );
  }
}

// ===================================================================
//  Tarjeta reutilizable para las 3 opciones
// ===================================================================

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
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
