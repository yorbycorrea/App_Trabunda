import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/db.dart';
import '../services/auth_service.dart';
import '../services/report_pdf_service.dart';

class ReportDetailPage extends StatefulWidget {
  const ReportDetailPage({
    super.key,
    required this.reporteId,
  });

  final int reporteId;

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  late Future<ReporteDetalle?> _future;

  @override
  void initState() {
    super.initState();
    _future = db.reportesDao.fetchReporteDetalle(widget.reporteId);
  }

  Future<void> _reload() async {
    final future = db.reportesDao.fetchReporteDetalle(widget.reporteId);
    setState(() {
      _future = future;
    });
    await future;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informe')),
      body: FutureBuilder<ReporteDetalle?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(onRetry: _reload);
          }

          final detalle = snapshot.data;
          if (detalle == null) {
            return _EmptyState(onRetry: _reload);
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _HeaderCard(
                  fecha: _formatDate(detalle.fecha),
                  turno: detalle.turno,
                  planillero: detalle.planillero,
                  totalPersonas: detalle.totalPersonas,
                  totalKilos: detalle.totalKilos,
                ),
                const SizedBox(height: 16),
                if (detalle.areas.isEmpty)
                  const _NoAreasCard()
                else
                  ...detalle.areas.map(
                        (area) => _AreaSection(
                      area: area,
                      reporte: detalle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.fecha,
    required this.turno,
    required this.planillero,
    required this.totalPersonas,
    required this.totalKilos,
  });

  final String fecha;
  final String turno;
  final String planillero;
  final int totalPersonas;
  final double totalKilos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informe',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 12),
            _HeaderRow(
              icon: Icons.calendar_month_rounded,
              label: 'Fecha',
              value: fecha,
            ),
            const SizedBox(height: 8),
            _HeaderRow(
              icon: Icons.access_time_rounded,
              label: 'Turno',
              value: turno,
            ),
            const SizedBox(height: 8),
            _HeaderRow(
              icon: Icons.badge_outlined,
              label: 'Planillero',
              value: planillero,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatChip(
                  icon: Icons.groups_rounded,
                  label: '$totalPersonas ${_plural(totalPersonas, 'persona', 'personas')}',
                  color: secondary,
                ),
                _StatChip(
                  icon: Icons.scale_rounded,
                  label: '${totalKilos.toStringAsFixed(3)} kg',
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaSection extends StatefulWidget {
  const _AreaSection({
    required this.area,
    required this.reporte,
  });

  final ReporteAreaDetalle area;
  final ReporteDetalle reporte;

  @override
  State<_AreaSection> createState() => _AreaSectionState();
}

class _AreaSectionState extends State<_AreaSection> {
  final ReportPdfService _pdfService = const ReportPdfService();
  bool _isLoading = false;

  bool get _shouldShowDownload {
    final name = widget.area.nombre.toLowerCase();
    return name == 'fileteros' || name == 'recepción' || name == 'recepcion';
  }

  Future<void> _downloadReport(BuildContext context) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final scaffold = ScaffoldMessenger.of(context);

    try {
      final auth = AuthScope.read(context);
      final elaboradoPor =
          auth.currentUser?.name ?? widget.reporte.planillero;

      final result = await _pdfService.generateAreaReport(
        reporte: widget.reporte,
        area: widget.area,
        elaboradoPor: elaboradoPor,
      );

      await _pdfService.share(result);

      scaffold.showSnackBar(
        SnackBar(
          content: Text('Reporte guardado en ${result.file.path}'),
        ),
      );
    } catch (error) {
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('No se pudo generar el PDF. Intenta nuevamente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = widget.area;
    final theme = Theme.of(context);
    final subtitle =
        '${area.cantidad} ${_plural(area.cantidad, 'persona', 'personas')} • '
        '${area.totalKilos.toStringAsFixed(3)} kg';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Text(
          area.nombre,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        children: [
          if ((area.horaInicio != null && area.horaInicio!.isNotEmpty) ||
              (area.horaFin != null && area.horaFin!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatRange(area.horaInicio, area.horaFin),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          if (area.desglose.isNotEmpty) ...[
            _DesgloseCard(desglose: area.desglose),
            const SizedBox(height: 12),
          ],
          if (_shouldShowDownload) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(_isLoading ? 'Generando formato...' : 'Descargar formato'),
                onPressed: _isLoading ? null : () => _downloadReport(context),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (area.cuadrillas.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sin cuadrillas registradas.'),
              ),
            )
          else
            ...area.cuadrillas.map(
                  (c) => _CuadrillaTile(
                cuadrilla: c,
                horario: _formatRange(area.horaInicio, area.horaFin),
              ),
            )
        ],
      ),
    );
  }
}

class _CuadrillaTile extends StatelessWidget {
  const _CuadrillaTile({required this.cuadrilla, required this.horario});

  final CuadrillaDetalle cuadrilla;
  final String horario;



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final integrants = cuadrilla.integrantes;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cuadrilla.nombre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${cuadrilla.totalIntegrantes} ${_plural(cuadrilla.totalIntegrantes, 'persona', 'personas')}',
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16),
              const SizedBox(width: 6),
              Text(horario, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.scale_rounded, size: 16),
              const SizedBox(width: 6),
              Text(
                '${cuadrilla.kilos.toStringAsFixed(3)} kg',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          if (cuadrilla.desglose.isNotEmpty) ...[
            const SizedBox(height: 6),
            _DesgloseList(desglose: cuadrilla.desglose),
          ],
          if (integrants.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Integrantes',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: integrants
                  .map(
                    (it) => Chip(
                  label: Text(it.nombre),
                  avatar: it.code == null || it.code!.isEmpty
                      ? null
                      : const Icon(Icons.qr_code_2, size: 16),
                ),
              )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoAreasCard extends StatelessWidget {
  const _NoAreasCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Este informe no tiene áreas registradas.'),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          const Text('No se pudo cargar el informe.'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.article_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('El informe seleccionado no existe.'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}

String _plural(int value, String singular, String plural) {
  return value == 1 ? singular : plural;
}
String _formatRange(String? start, String? end) {
  if ((start == null || start.isEmpty) && (end == null || end.isEmpty)) {
    return 'Horario no registrado';
  }
  final startText = start == null || start.isEmpty ? '--:--' : start;
  final endText = end == null || end.isEmpty ? '--:--' : end;
  return '$startText - $endText';
}

class _DesgloseCard extends StatelessWidget {
  const _DesgloseCard({required this.desglose});

  final List<CategoriaDesglose> desglose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desglose por categoría',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _DesgloseList(desglose: desglose),
        ],
      ),
    );
  }
}

class _DesgloseList extends StatelessWidget {
  const _DesgloseList({required this.desglose});

  final List<CategoriaDesglose> desglose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: desglose
          .map(
            (d) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  d.categoria,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Text(
                '${d.personas} ${_plural(d.personas, 'persona', 'personas')}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              Text(
                '${d.kilos.toStringAsFixed(3)} kg',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      )
          .toList(),
    );
  }
}
