import 'package:flutter/material.dart';

class CuadrillaConfigPage extends StatefulWidget {
  const CuadrillaConfigPage({
    super.key,
    required this.areaName,
    this.initialNombre,
    this.initialIntegrantes,
    this.initialKilos,
    this.initialHoraInicio,
    this.initialHoraFin,
    this.initialDesglose,
  });

  final String areaName;
  final String? initialNombre;
  final List<Map<String, String>>? initialIntegrantes;
  final double? initialKilos;
  final String? initialHoraInicio;
  final String? initialHoraFin;
  final List<Map<String, dynamic>>? initialDesglose;

  @override
  State<CuadrillaConfigPage> createState() => _CuadrillaConfigPageState();
}

class _CuadrillaConfigPageState extends State<CuadrillaConfigPage> {
  static const List<String> _categoriasDefault = [
    'Recepción',
    'Fileteado',
  ];

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _kilosCtrl = TextEditingController();
  final List<_Member> _integrantes = [];
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  final Map<String, TextEditingController> _personasPorCategoria = {};
  final Map<String, TextEditingController> _kilosPorCategoria = {};

  @override
  void initState() {
    super.initState();

    // Nombre y kilos iniciales
    _nombreCtrl.text = widget.initialNombre ?? '';
    _kilosCtrl.text = _formatInitialKilos(widget.initialKilos);

    // Integrantes iniciales
    for (final integrante in widget.initialIntegrantes ?? const []) {
      _integrantes.add(
        _Member(
          code: integrante['code'] ?? '',
          name: integrante['name'] ?? '',
        ),
      );
    }
    if (_integrantes.isEmpty) {
      _integrantes.add(_Member());
    }

    // Horas iniciales
    _horaInicio = _parseTime(widget.initialHoraInicio);
    _horaFin = _parseTime(widget.initialHoraFin);

    // Desglose inicial por categoría
    final Map<String, Map<String, dynamic>> desgloseInicial = {};
    for (final entry in widget.initialDesglose ?? const []) {
      final categoria = entry['categoria'];
      if (categoria is String) {
        desgloseInicial[categoria] = entry;
      }
    }

    for (final categoria in _categoriasDefault) {
      final personasCtrl = TextEditingController();
      final kilosCtrl = TextEditingController();
      final initial = desgloseInicial[categoria];

      if (initial != null) {
        final personas = initial['personas'];
        final kilos = initial['kilos'];
        if (personas != null) personasCtrl.text = '$personas';
        if (kilos != null) kilosCtrl.text = '$kilos';
      }

      _personasPorCategoria[categoria] = personasCtrl;
      _kilosPorCategoria[categoria] = kilosCtrl;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _kilosCtrl.dispose();
    for (final member in _integrantes) {
      member.dispose();
    }
    for (final controller in _personasPorCategoria.values) {
      controller.dispose();
    }
    for (final controller in _kilosPorCategoria.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatInitialKilos(double? value) {
    if (value == null || value.isNaN) return '';
    return value.toStringAsFixed(2);
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickTime({required bool inicio}) async {
    final initial = inicio ? _horaInicio : _horaFin;

    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (inicio) {
        _horaInicio = picked;
      } else {
        _horaFin = picked;
      }
    });
  }

  void _addMember({String code = '', String name = ''}) {
    setState(() {
      _integrantes.add(_Member(code: code, name: name));
    });
  }

  void _removeMember(int index) {
    if (_integrantes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe haber al menos un integrante.')),
      );
      return;
    }
    setState(() {
      final member = _integrantes.removeAt(index);
      member.dispose();
    });
  }

  Future<void> _scanQR(int index) async {
    final result = await Navigator.pushNamed(
      context,
      '/scanner',
      arguments: const {'pickOnly': true},
    );

    if (!mounted) return;

    if (result is Map) {
      final code = (result['code'] ?? '').toString();
      final data = result['data'];
      String name = (result['name'] ?? '').toString();

      if (name.isEmpty && data is Map) {
        final alt = data['name'] ?? data['nombre'];
        if (alt != null) {
          name = alt.toString();
        }
      }

      setState(() {
        _integrantes[index].codeCtrl.text = code;
        if (name.isNotEmpty) {
          _integrantes[index].nameCtrl.text = name;
        }
      });
    } else if (result is String) {
      setState(() {
        _integrantes[index].codeCtrl.text = result;
      });
    }
  }

  void _guardar() {
    final nombre = _nombreCtrl.text.trim();
    final kilos = double.tryParse(_kilosCtrl.text.trim()) ?? 0;

    final integrantes = _integrantes
        .map(
          (member) => {
        'code': member.codeCtrl.text.trim(),
        'name': member.nameCtrl.text.trim(),
      },
    )
        .toList();

    final desglose = <Map<String, dynamic>>[];
    for (final categoria in _categoriasDefault) {
      final personasCtrl = _personasPorCategoria[categoria];
      final kilosCtrl = _kilosPorCategoria[categoria];
      if (personasCtrl == null || kilosCtrl == null) continue;

      final personas = int.tryParse(personasCtrl.text.trim()) ?? 0;
      final kilosCat = double.tryParse(kilosCtrl.text.trim()) ?? 0;
      if (personas == 0 && kilosCat == 0) continue;

      desglose.add({
        'categoria': categoria,
        'personas': personas,
        'kilos': kilosCat,
      });
    }

    Navigator.pop(context, {
      'nombre': nombre,
      'kilos': kilos,
      'integrantes': integrantes,
      'horaInicio':
      _horaInicio == null ? null : _formatTime(_horaInicio),
      'horaFin': _horaFin == null ? null : _formatTime(_horaFin),
      'desglose': desglose,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.areaName} • Cuadrilla'),
        actions: [
          IconButton(
            onPressed: _guardar,
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Guardar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMember,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Agregar integrante'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Horario
          _HorarioCard(
            horaInicio: _formatTime(_horaInicio),
            horaFin: _formatTime(_horaFin),
            onPickInicio: () => _pickTime(inicio: true),
            onPickFin: () => _pickTime(inicio: false),
          ),
          const SizedBox(height: 12),

          // Nombre cuadrilla
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre de la cuadrilla',
              prefixIcon: Icon(Icons.groups_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Kilos de la cuadrilla
          TextField(
            controller: _kilosCtrl,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Kilos de la cuadrilla',
              hintText: '0.00',
              prefixIcon: Icon(Icons.scale_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Desglose por categoría
          _DesgloseCard(
            categorias: _categoriasDefault,
            personasPorCategoria: _personasPorCategoria,
            kilosPorCategoria: _kilosPorCategoria,
          ),
          const SizedBox(height: 16),

          // Integrantes
          Text(
            'Integrantes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_integrantes.isEmpty)
            const Text('Agrega al menos un integrante a la cuadrilla.')
          else
            ...List.generate(
              _integrantes.length,
                  (index) => Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                child: _IntegranteCard(
                  index: index,
                  member: _integrantes[index],
                  onScan: () => _scanQR(index),
                  onRemove: () => _removeMember(index),
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _HorarioCard extends StatelessWidget {
  const _HorarioCard({
    required this.horaInicio,
    required this.horaFin,
    required this.onPickInicio,
    required this.onPickFin,
  });

  final String horaInicio;
  final String horaFin;
  final VoidCallback onPickInicio;
  final VoidCallback onPickFin;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Horario',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickInicio,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(
                      horaInicio == '--:--' ? 'Hora inicio' : horaInicio,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickFin,
                    icon: const Icon(Icons.timelapse_rounded),
                    label: Text(
                      horaFin == '--:--' ? 'Hora fin' : horaFin,
                    ),
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

class _DesgloseCard extends StatelessWidget {
  const _DesgloseCard({
    required this.categorias,
    required this.personasPorCategoria,
    required this.kilosPorCategoria,
  });

  final List<String> categorias;
  final Map<String, TextEditingController> personasPorCategoria;
  final Map<String, TextEditingController> kilosPorCategoria;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Desglose por categoría',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            for (final categoria in categorias) ...[
              Text(
                categoria,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: personasPorCategoria[categoria],
                      keyboardType:
                      const TextInputType.numberWithOptions(),
                      decoration: const InputDecoration(
                        labelText: 'Personas',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: kilosPorCategoria[categoria],
                      keyboardType:
                      const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Kilos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              if (categoria != categorias.last)
                const Divider(height: 28),
            ],
          ],
        ),
      ),
    );
  }
}

class _IntegranteCard extends StatelessWidget {
  const _IntegranteCard({
    required this.index,
    required this.member,
    required this.onScan,
    required this.onRemove,
  });

  final int index;
  final _Member member;
  final VoidCallback onScan;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Integrante ${index + 1}'),
                const Spacer(),
                IconButton(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  tooltip: 'Escanear QR',
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_forever_rounded),
                  tooltip: 'Quitar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: member.codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Código',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: member.nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Member {
  _Member({
    String code = '',
    String name = '',
  })  : codeCtrl = TextEditingController(text: code),
        nameCtrl = TextEditingController(text: name);

  final TextEditingController codeCtrl;
  final TextEditingController nameCtrl;

  void dispose() {
    codeCtrl.dispose();
    nameCtrl.dispose();
  }
}
