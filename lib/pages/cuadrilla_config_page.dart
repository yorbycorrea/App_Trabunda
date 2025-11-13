import 'package:flutter/material.dart';

class CuadrillaConfigPage extends StatefulWidget {
  final String areaName;
  final String? initialNombre;
  final List<Map<String, String>>? initialIntegrantes;
  final double? initialKilos; // 👈 importante para editar cuadrillas

  const CuadrillaConfigPage({
    super.key,
    required this.areaName,
    this.initialNombre,
    this.initialIntegrantes,
    this.initialKilos,
  });

  @override
  State<CuadrillaConfigPage> createState() => _CuadrillaConfigPageState();
}

class _CuadrillaConfigPageState extends State<CuadrillaConfigPage> {
  final _nombreCtrl = TextEditingController();
  final _kilosCtrl = TextEditingController();
  final List<_Member> _integrantes = [];

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
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _kilosCtrl.dispose();
    for (final m in _integrantes) {
      m.codeCtrl.dispose();
      m.nameCtrl.dispose();
    }
    super.dispose();
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

    Navigator.pop(context, {
      'nombre': nombre,
      'kilos': kilos,               // 👈 vuelve con los kilos de esta cuadrilla
      'integrantes': miembros,
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
