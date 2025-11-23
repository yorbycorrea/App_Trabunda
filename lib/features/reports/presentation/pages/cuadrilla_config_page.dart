import 'package:flutter/material.dart';

class CuadrillaConfigPage extends StatefulWidget {
  const CuadrillaConfigPage({
    super.key,
    required this.areaName,
    this.initialNombre,
    this.initialIntegrantes,
    this.initialKilos,

  });

  final String areaName;
  final String? initialNombre;
  final List<Map<String, String>>? initialIntegrantes;
  final double? initialKilos;


  @override
  State<CuadrillaConfigPage> createState() => _CuadrillaConfigPageState();
}

class _CuadrillaConfigPageState extends State<CuadrillaConfigPage> {


  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _kilosCtrl = TextEditingController();
  final List<_Member> _integrantes = [];


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



  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _kilosCtrl.dispose();
    for (final member in _integrantes) {
      member.dispose();
    }

    super.dispose();
  }

  String _formatInitialKilos(double? value) {
    if (value == null || value.isNaN) return '';
    return value.toStringAsFixed(2);
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



    Navigator.pop(context, {
      'nombre': nombre,
      'kilos': kilos,
      'integrantes': integrantes,
      'horaInicio': null,
      'horaFin': null,
      'desglose': const <Map<String, dynamic>>[],
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
