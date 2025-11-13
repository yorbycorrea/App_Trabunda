import 'package:flutter/material.dart';
import 'dart:collection';
import '../data/db.dart';
import '../services/auth_service.dart';
import 'report_detail_page.dart';

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

const Color _kPrimaryColor = Color(0xFF0E4B3B);
const Color _kBackgroundColor = Color(0xFFF4F6F5);
const Color _kSurfaceColor = Colors.white;

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
  bool _syncedPlanillero = false;
  bool _autoFetchedForPlanillero = false;

  @override
  void dispose() {
    _planilleroCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedPlanillero) return;
    final auth = AuthScope.read(context);
    final user = auth.currentUser;
    if (user != null && user.isPlanillero) {
      _planilleroCtrl.text = user.name;
      if (!_autoFetchedForPlanillero) {
        _autoFetchedForPlanillero = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _fetchReports();
          }
        });
      }
    }
    _syncedPlanillero = true;
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
      final auth = AuthScope.read(context);
      final user = auth.currentUser;
      if (user != null && user.isPlanillero) {
        _planilleroCtrl.text = user.name;
      } else {
        _planilleroCtrl.clear();
      }
      _items.clear();
    });
  }

  Future<void> _fetchReports() async {
    final auth = AuthScope.read(context);
    final user = auth.currentUser;
    final bool isPlanillero = user?.isPlanillero ?? false;
    final String planilleroFilter =
    isPlanillero ? user!.name : _planilleroCtrl.text.trim();

    setState(() => _loading = true);

    try {
      DateTime? inicio;
      DateTime? fin;
      if (_rango != null) {
        inicio = DateTime(
            _rango!.start.year, _rango!.start.month, _rango!.start.day);
        fin = DateTime(
          _rango!.end.year,
          _rango!.end.month,
          _rango!.end.day,
          23,
          59,
          59,
          999,
        );
      }

      final resultados = await db.reportesDao.fetchReportesFiltrados(
        fechaInicio: inicio,
        fechaFin: fin,
        areas: _areas.isEmpty ? null : _areas.toList(),
        turno: _turno == 'Todos' ? null : _turno,
        planilleroQuery: planilleroFilter.isEmpty ? null : planilleroFilter,
      );

      if (!mounted) return;

      final filtered = isPlanillero
          ? resultados
          .where(
            (r) => r.planillero.toLowerCase() ==
            planilleroFilter.toLowerCase(),
      )
          .toList()
          : resultados;

      final Map<int, _AggregatedReport> aggregated = {};
      for (final row in filtered) {
        final group = aggregated.putIfAbsent(
          row.reporteId,
              () => _AggregatedReport(
            reporteId: row.reporteId,
            fecha: row.fecha,
            turno: row.turno,
            planillero: row.planillero,
          ),
        );
        group.totalPersonal += row.cantidad;
        group.totalKilos += row.kilos;
        group.areaNames.add(row.areaNombre);
      }

      setState(() {
        _items
          ..clear()
          ..addAll(
            aggregated.values.map(
                  (g) => ReportSummary(
                reporteId: g.reporteId,
                fecha: g.fecha,
                turno: g.turno,
                totalPersonal: g.totalPersonal,
                kilos: g.totalKilos,
                planillero: g.planillero,
                areaNames: List<String>.unmodifiable(g.areaNames),
              ),
            ),
          );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar los reportes')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    } // 👈 cierra finally
  } // 👈 cierra _fetchReports

  @override
  Widget build(BuildContext context) {
    const primaryColor = _kPrimaryColor;
    const backgroundColor = _kBackgroundColor;
    const surfaceColor = _kSurfaceColor;
    final auth = AuthScope.watch(context);
    final user = auth.currentUser;
    final bool isPlanillero = user?.isPlanillero ?? false;
    final bool isAdmin = user?.isAdmin ?? false;

    final totalAreas = _items.fold<int>(0, (acc, e) => acc + e.totalAreas);
    final totalPersonal =
    _items.fold<int>(0, (acc, e) => acc + e.totalPersonal);
    final totalKilos = _items.fold<double>(0, (acc, e) => acc + e.kilos);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Ver reportes'),
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            // Filtros
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE1E5E3)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _FilterTile(
                          label: 'Rango de fechas',
                          value: _rango == null
                              ? 'Selecciona'
                              : '${_fmtDate(_rango!.start)}  —  ${_fmtDate(_rango!.end)}',
                          icon: Icons.calendar_month_rounded,
                          background: primaryColor,
                          foreground: Colors.white,
                          onTap: _pickRango,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: _TurnoPill(
                          value: _turno,
                          color: primaryColor,
                          onChanged: (v) => setState(() => _turno = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FilterTile(
                    label: 'Planillero',
                    value: _planilleroCtrl.text.trim().isEmpty
                        ? 'Buscar planillero'
                        : _planilleroCtrl.text.trim(),
                    icon: Icons.badge_outlined,
                    background:
                    _planilleroCtrl.text.trim().isEmpty ? null : primaryColor,
                    foreground:
                    _planilleroCtrl.text.trim().isEmpty ? null : Colors.white,
                    onTap: isAdmin
                        ? () async {
                      await showDialog<void>(
                        context: context,
                        builder: (ctx) {
                          return _PlanilleroDialog(
                            controller: _planilleroCtrl,
                            primaryColor: primaryColor,
                          );
                        },
                      );
                      if (mounted) setState(() {});
                    }
                        : null,
                    enabled: isAdmin,
                  ),
                  if (isPlanillero)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Se mostrarán únicamente los reportes asociados a tu sesión.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5E6A66),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _FilterTile(
                    label: 'Áreas',
                    value: _areas.isEmpty
                        ? 'Todas las áreas'
                        : _areas.length == 1
                        ? _areas.first
                        : '${_areas.length} seleccionadas',
                    icon: Icons.segment_rounded,
                    background: _areas.isEmpty ? null : primaryColor,
                    foreground: _areas.isEmpty ? null : Colors.white,
                    onTap: _openAreasSheet,
                  ),
                  if (_areas.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _areas
                          .map(
                            (a) => Chip(
                          label: Text(a),
                          deleteIconColor: primaryColor,
                          onDeleted: () => setState(() => _areas.remove(a)),
                        ),
                      )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _limpiar,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
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

            if (_items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE1E5E3)),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total áreas: $totalAreas',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Personal total: $totalPersonal'),
                    const SizedBox(height: 4),
                    Text('Kilos totales: ${totalKilos.toStringAsFixed(3)}'),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 16),

            // Resultados
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_items.isEmpty)
              _EmptyState(onTapBuscar: _fetchReports)
            else
              ..._items.map(
                    (r) => _ReportCard(
                  data: r,
                  primaryColor: primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailPage(
                          reporteId: r.reporteId,
                        ),
                      ),
                    ); // ← cierre correcto con );
                  },
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// ======= MODELOS Y WIDGETS =======

class ReportSummary {
  final int reporteId;
  final DateTime fecha;
  final String turno;
  final int totalPersonal;
  final double kilos;
  final String planillero;
  final List<String> areaNames;

  ReportSummary({
    required this.reporteId,
    required this.fecha,
    required this.turno,
    required this.totalPersonal,
    required this.kilos,
    required this.planillero,
    required this.areaNames,
  });
  String get formattedId => 'RPT-${reporteId.toString().padLeft(4, '0')}';

  int get totalAreas => areaNames.length;
}
class _AggregatedReport {
  _AggregatedReport({
    required this.reporteId,
    required this.fecha,
    required this.turno,
    required this.planillero,
  });

  final int reporteId;
  final DateTime fecha;
  final String turno;
  final String planillero;
  int totalPersonal = 0;
  double totalKilos = 0;
  final LinkedHashSet<String> areaNames = LinkedHashSet();
}
class _ReportCard extends StatelessWidget {
  final ReportSummary data;
  final Color primaryColor;
  final VoidCallback onTap;
  const _ReportCard({
    required this.data,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final areaCountText = data.totalAreas == 0
        ? 'Sin áreas registradas'
        : data.totalAreas == 1
        ? '1 área registrada'
        : '${data.totalAreas} áreas registradas';

    final displayedAreas = data.areaNames.take(3).toList();
    final remainingAreas = data.totalAreas - displayedAreas.length;
    final String? areaSummaryText;
    if (displayedAreas.isEmpty) {
      areaSummaryText = null;
    } else {
      final buffer = StringBuffer(displayedAreas.join(', '));
      if (remainingAreas > 0) {
        buffer.write(' +$remainingAreas más');
      }
      areaSummaryText = buffer.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1E5E3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fmt(data.fecha),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      data.turno,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.person_outline,
                text: data.planillero.isEmpty
                    ? 'Sin planillero'
                    : data.planillero,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.apartment_rounded,
                text: areaCountText,
              ),
              if (areaSummaryText != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    areaSummaryText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.groups_rounded,
                text: '${data.totalPersonal} personas',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.scale_rounded,
                text: '${data.kilos.toStringAsFixed(3)} kg',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onTap,
                  child: const Text('Ver detalle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _FilterTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? foreground;
  final bool enabled;
  const _FilterTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.background,
    this.foreground,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool clickable = enabled && onTap != null;
    final bool highlighted = background != null;
    final Color effectiveBackground = background ?? Colors.white;
    final Color effectiveForeground =
        foreground ?? (highlighted ? Colors.white : const Color(0xFF0E1F18));
    final bool isHint = value.trim().isEmpty ||
        value.toLowerCase().contains('selecciona') ||
        value.toLowerCase().contains('buscar');
    final Color labelColor = highlighted
        ? (foreground ?? Colors.white).withOpacity(0.8)
        : (clickable ? const Color(0xFF7A807D) : const Color(0xFF9BA29F));
    final Color valueColor = highlighted
        ? (foreground ?? Colors.white)
        : isHint
        ? const Color(0xFF9BA29F)
        : (clickable ? effectiveForeground : const Color(0xFF5F6662));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: clickable ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: effectiveBackground,
            borderRadius: BorderRadius.circular(18),
            border: highlighted
                ? null
                : Border.all(
              color: clickable
                  ? const Color(0xFFE1E5E3)
                  : const Color(0xFFD5DAD7),
            ),
            boxShadow: highlighted
                ? [
              BoxShadow(
                color: background!.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ]
                : clickable
                ? const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: highlighted
                        ? (foreground ?? Colors.white)
                        : (clickable
                        ? const Color(0xFF0E4B3B)
                        : const Color(0xFF7D8A85)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: valueColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurnoPill extends StatelessWidget {
  final String value;
  final Color color;
  final ValueChanged<String> onChanged;
  const _TurnoPill({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      padding: EdgeInsets.zero,
      itemBuilder: (ctx) => const [
        PopupMenuItem(value: 'Todos', child: Text('Todos')),
        PopupMenuItem(value: 'Día', child: Text('Día')),
        PopupMenuItem(value: 'Noche', child: Text('Noche')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.schedule_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            // El texto real se pinta en el padre
          ],
        ),
      ),
    );
  }
}

class _PlanilleroDialog extends StatefulWidget {
  final TextEditingController controller;
  final Color primaryColor;
  const _PlanilleroDialog({
    required this.controller,
    required this.primaryColor,
  });

  @override
  State<_PlanilleroDialog> createState() => _PlanilleroDialogState();
}

class _PlanilleroDialogState extends State<_PlanilleroDialog> {
  late final TextEditingController _tmpController;

  @override
  void initState() {
    super.initState();
    _tmpController = TextEditingController(text: widget.controller.text);
  }

  @override
  void dispose() {
    _tmpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Buscar planillero'),
      content: TextField(
        controller: _tmpController,
        decoration: const InputDecoration(
          hintText: 'Nombre del planillero',
          prefixIcon: Icon(Icons.search_rounded),
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.primaryColor),
          onPressed: _submit,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  void _submit() {
    widget.controller.text = _tmpController.text;
    Navigator.pop(context);
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
          left: 16,
          right: 16,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Selecciona áreas',
                  style: TextStyle(fontWeight: FontWeight.w700)),
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
            const Icon(Icons.find_in_page_outlined,
                size: 64, color: Colors.black38),
            const SizedBox(height: 12),
            const Text('Sin resultados',
                style: TextStyle(fontWeight: FontWeight.w700)),
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
