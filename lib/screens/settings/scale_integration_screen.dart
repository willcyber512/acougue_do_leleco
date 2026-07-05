import 'package:flutter/material.dart';

import '../../models/scale_plu.dart';
import '../../services/scales/scale_service.dart';
import '../../services/scales/scale_service_factory.dart';

class ScaleIntegrationScreen extends StatefulWidget {
  const ScaleIntegrationScreen({super.key});

  @override
  State<ScaleIntegrationScreen> createState() => _ScaleIntegrationScreenState();
}

class _ScaleIntegrationScreenState extends State<ScaleIntegrationScreen> {
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.0.150',
  );

  final TextEditingController _portController = TextEditingController(
    text: '33581',
  );

  ScaleConnectionMode _mode = ScaleConnectionMode.simulator;
  bool _loading = false;
  final List<String> _logs = [];

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    final time = TimeOfDay.now().format(context);

    setState(() {
      _logs.insert(0, '[$time] $message');
    });
  }

  ScaleService _createService() {
    final port = int.tryParse(_portController.text.trim()) ?? 33581;

    return ScaleServiceFactory.create(
      mode: _mode,
      ip: _ipController.text.trim(),
      port: port,
    );
  }

  Future<void> _runAction(Future<ScaleResult> Function() action) async {
    setState(() {
      _loading = true;
    });

    try {
      final result = await action();

      _addLog(result.message);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      _addLog('Erro inesperado: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _testConnection() async {
    final service = _createService();

    await _runAction(() => service.testConnection());
  }

  Future<void> _sendTestPlu() async {
    final service = _createService();

    final plu = ScalePlu(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: 'produto-teste',
      pluCode: '000001',
      barcode: '2000001000000',
      name: 'Carne moida teste',
      pricePerKg: 35.90,
      isWeightProduct: true,
    );

    await _runAction(() => service.sendPlu(plu));
  }

  Future<void> _sendAllTestPlus() async {
    final service = _createService();

    final plus = [
      const ScalePlu(
        id: '1',
        productId: 'p1',
        pluCode: '000001',
        barcode: '2000001000000',
        name: 'Carne moida',
        pricePerKg: 35.90,
        isWeightProduct: true,
      ),
      const ScalePlu(
        id: '2',
        productId: 'p2',
        pluCode: '000002',
        barcode: '2000002000000',
        name: 'Frango',
        pricePerKg: 18.90,
        isWeightProduct: true,
      ),
      const ScalePlu(
        id: '3',
        productId: 'p3',
        pluCode: '000003',
        barcode: '2000003000000',
        name: 'Coxao mole',
        pricePerKg: 42.90,
        isWeightProduct: true,
      ),
    ];

    await _runAction(() => service.sendAllPlus(plus));
  }

  String _modeLabel(ScaleConnectionMode mode) {
    switch (mode) {
      case ScaleConnectionMode.simulator:
        return 'Simulador';
      case ScaleConnectionMode.ramuzaTcp:
        return 'Ramuza TCP/Rede';
    }
  }

  @override
  Widget build(BuildContext context) {
    final usingTcp = _mode == ScaleConnectionMode.ramuzaTcp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Integração Ramuza Atena II'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Configuração da balança',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ScaleConnectionMode>(
                    value: _mode,
                    decoration: const InputDecoration(
                      labelText: 'Modo de conexão',
                      border: OutlineInputBorder(),
                    ),
                    items: ScaleConnectionMode.values.map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(_modeLabel(mode)),
                      );
                    }).toList(),
                    onChanged: _loading
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              _mode = value;
                            });

                            _addLog('Modo alterado para: ${_modeLabel(value)}');
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ipController,
                    enabled: usingTcp && !_loading,
                    decoration: const InputDecoration(
                      labelText: 'IP da balança',
                      hintText: '192.168.0.150',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portController,
                    enabled: usingTcp && !_loading,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Porta',
                      hintText: '33581',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _testConnection,
                    icon: const Icon(Icons.wifi),
                    label: const Text('Testar conexão'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _sendTestPlu,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar PLU teste'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _sendAllTestPlus,
                    icon: const Icon(Icons.playlist_add_check),
                    label: const Text('Enviar lista teste'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Log da integração',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_logs.isEmpty)
                    const Text('Nenhum teste executado ainda.'),
                  for (final log in _logs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(log),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
