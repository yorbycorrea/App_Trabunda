import 'package:flutter/material.dart';

class CuadrillaConfigPage extends StatefulWidget {
  final String areaName;
  final String? initialNombre;
  final List<Map<String, String>>? initialIntegrantes;
  final double? initialKilos; // 👈 importante para editar cuadrillas
  final String? initialHoraInicio;
  final String? initialHoraFin;
  final List<Map<String, dynamic>>? initialDesglose;

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

  @override
  State<CuadrillaConfigPage> createState() => _CuadrillaConfigPageState();
}

class _CuadrillaConfigPageState extends State<CuadrillaConfigPage> {
  static const List<String> _categoriasDefault = [
    'Recepción',
    'Fileteado',
  ];
  final _nombreCtrl = TextEditingController();
  final _kilosCtrl = TextEditingController();
  final List<_Member> _integrantes = [];
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFin;
  final Map<String, TextEditingController> _personasPorCategoria = {};
  final Map<String, TextEditingController> _kilosPorCategoria = {};

  @override
  void initState() {
    super.initState();
    _nombreCtrl.text = widget.initialNombre ?? '';
    // precargar kilos si vienes a editar
    _kilosCtrl.text = (widget.initialKilos == null || widget.initialKilos!.isNaN)
        ? ''
        : widget.initialKilos!.toStringAsFixed(2);

    final init = widget.initialIntegrantes ?? [];
    for (final m in init) {
      _integrantes.add(_Member(code: m['code'] ?? '', name: m['name'] ?? ''));
    }

    _horaInicio = _parseTime(widget.initialHoraInicio);
    _horaFin = _parseTime(widget.initialHoraFin);

    final desgloseInicial = <String, Map<String, dynamic>>{};
    for (final entry in widget.initialDesglose ?? const []) {
      if (entry['categoria'] is! String) continue;
      desgloseInicial[entry['categoria'] as String] = entry;
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
    for (final m in _integrantes) {
      m.codeCtrl.dispose();
      m.nameCtrl.dispose();
    }
    for (final ctrl in _personasPorCategoria.values) {
      ctrl.dispose();
    }
    for (final ctrl in _kilosPorCategoria.values) {
      ctrl.dispose();
    }
    super.dispose();
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

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime({required bool inicio}) async {
    final base = inicio ? _horaInicio : _horaFin;
    final picked = await showTimePicker(
      context: context,
      initialTime: base ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (inicio) {
          _horaInicio = picked;
        } else {
          _horaFin = picked;
        }
      });
    }
  }

  void _addMember({String code = '', String name = ''}) {
    setState(() => _integrantes.add(_Member(code: code, name: name)));
  }

  void _removeMember(int i) {
    setState(() {
      _integrantes[i].codeCtrl.dispose();
      _integrantes[i].nameCtrl.dispose();
      _integrantes.removeAt(i);
    });
  }

  Future<void> _scanQR(int index) async {
    // Abre tu escáner. Debe retornar algo como {'code':'ABC123', 'name':'Juan Perez'} o String.
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
        if (alt != null) name = alt.toString();
      }
      setState(() {
        _integrantes[index].codeCtrl.text = code;
        if (name.isNotEmpty) _integrantes[index].nameCtrl.text = name;
      });
    } else if (result is String) {
      setState(() => _integrantes[index].codeCtrl.text = result);
    }
  }

  void _guardar() {
    final nombre = _nombreCtrl.text.trim();
    final kilos = double.tryParse(_kilosCtrl.text.trim()) ?? 0.0;
    final miembros = _integrantes
        .map((m) => {
      'code': m.codeCtrl.text.trim(),
      'name': m.nameCtrl.text.trim(),
    })
        .toList();
    final desglose = <Map<String, dynamic>>[];
    for (final categoria in _categoriasDefault) {
      final personas =
          int.tryParse(_personasPorCategoria[categoria]!.text.trim()) ?? 0;
      final kilosCat =
          double.tryParse(_kilosPorCategoria[categoria]!.text.trim()) ?? 0.0;
      if (personas == 0 && kilosCat == 0) continue;
      desglose.add({
        'categoria': categoria,
        'personas': personas,
        'kilos': kilosCat,
      });
    }

    Navigator.pop(context, {
      'nombre': nombre,
      'kilos': kilos,               // 👈 vuelve con los kilos de esta cuadrilla
      'integrantes': miembros,
      'horaInicio': _formatTime(_horaInicio),
      'horaFin': _formatTime(_horaFin),
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
        onPressed: () => _addMember(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Agregar integrante'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Horario
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Horario',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickTime(inicio: true),
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text(
                            _horaInicio == null
                                ? 'Hora inicio'
                                : _formatTime(_horaInicio!) ?? '--:--',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickTime(inicio: false),
                          icon: const Icon(Icons.timelapse_rounded),
                          label: Text(
                            _horaFin == null
                                ? 'Hora fin'
                                : _formatTime(_horaFin!) ?? '--:--',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Nombre de cuadrilla
          TextField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre de la cuadrilla',
              prefixIcon: Icon(Icons.groups_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // 👇 Kilos de la cuadrilla (AQUÍ ESTÁ LO QUE FALTABA)
          TextField(
            controller: _kilosCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Kilos de la cuadrilla',
              hintText: '0.00',
              prefixIcon: Icon(Icons.scale_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Desglose por categoría',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  for (final categoria in _categoriasDefault) ...[
                    Text(
                      categoria,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _personasPorCategoria[categoria],
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
                            controller: _kilosPorCategoria[categoria],
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Kilos',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (categoria != _categoriasDefault.last)
                      const Divider(height: 28),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lista de integrantes
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2FA),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex: 4, child: Text('Código')),
                      Expanded(flex: 6, child: Text('Nombre')),
                      SizedBox(width: 44), // QR
                      SizedBox(width: 44), // Quitar
                    ],
                  ),
                ),
                for (int i = 0; i < _integrantes.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: _integrantes[i].codeCtrl,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              hintText: 'Código',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 6,
                          child: TextField(
                            controller: _integrantes[i].nameCtrl,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              hintText: 'Nombre',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 44,
                          child: IconButton(
                            tooltip: 'Escanear QR',
                            onPressed: () => _scanQR(i),
                            icon: const Icon(Icons.qr_code_scanner),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: IconButton(
                            tooltip: 'Quitar',
                            onPressed: () => _removeMember(i),
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_integrantes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aún no hay integrantes.'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _guardar,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Guardar cuadrilla'),
          ),
        ],
      ),
    );
  }
}

class _Member {
  final TextEditingController codeCtrl;
  final TextEditingController nameCtrl;
  _Member({String code = '', String name = ''})
      : codeCtrl = TextEditingController(text: code),
        nameCtrl = TextEditingController(text: name);
}
