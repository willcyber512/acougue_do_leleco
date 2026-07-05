import 'package:flutter/material.dart';

import '../../models/scale_barcode_data.dart';
import '../../services/scales/scale_barcode_parser.dart';

class QuickWeightSaleScreen extends StatefulWidget {
  const QuickWeightSaleScreen({super.key});

  @override
  State<QuickWeightSaleScreen> createState() => _QuickWeightSaleScreenState();
}

class _QuickWeightSaleScreenState extends State<QuickWeightSaleScreen> {
  final _barcodeController = TextEditingController();
  final _weightController = TextEditingController(text: '0.000');

  final _parser = const ScaleBarcodeParser();

  ScaleBarcodeMode _barcodeMode = ScaleBarcodeMode.priceEmbedded;
  _DemoProduct _selectedProduct = _demoProducts.first;
  ScaleBarcodeData? _lastBarcode;
  String? _message;

  @override
  void dispose() {
    _barcodeController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double get _weightKg {
    final text = _weightController.text.trim().replaceAll(',', '.');
    return double.tryParse(text) ?? 0;
  }

  double get _manualTotal {
    return _weightKg * _selectedProduct.pricePerKg;
  }

  String _formatMoney(double value) {
    final cents = (value * 100).round();
    return (cents / 100).toStringAsFixed(2);
  }

  void _readBarcode() {
    final parsed = _parser.parse(
      _barcodeController.text,
      mode: _barcodeMode,
    );

    setState(() {
      _lastBarcode = parsed;

      if (parsed == null) {
        _message = 'Código inválido. Passe o leitor USB ou digite um EAN-13 começando com 2.';
        return;
      }

      final product = _demoProducts.where((item) {
        return item.scaleCode == parsed.productCode;
      }).firstOrNull;

      if (product != null) {
        _selectedProduct = product;
      }

      if (_barcodeMode == ScaleBarcodeMode.weightEmbedded) {
        _weightController.text = parsed.weightKgFromBarcode.toStringAsFixed(3);
      }

      _message = 'Etiqueta lida: produto ${parsed.productCode}, valor ${parsed.valueCode}.';
    });
  }

  void _finishSale() {
    final total = _lastBarcode != null && _barcodeMode == ScaleBarcodeMode.priceEmbedded
        ? _lastBarcode!.priceFromBarcode
        : _manualTotal;

    final text = 'Venda registrada: ${_selectedProduct.name} - Total R\$ ${_formatMoney(total)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _message = text;
      _barcodeController.clear();
      _lastBarcode = null;
    });
  }

  String _modeLabel(ScaleBarcodeMode mode) {
    switch (mode) {
      case ScaleBarcodeMode.priceEmbedded:
        return 'Código contém preço';
      case ScaleBarcodeMode.weightEmbedded:
        return 'Código contém peso';
      case ScaleBarcodeMode.unknown:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalByBarcode = _lastBarcode != null && _barcodeMode == ScaleBarcodeMode.priceEmbedded
        ? _lastBarcode!.priceFromBarcode
        : null;

    final totalToShow = totalByBarcode ?? _manualTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venda rápida por peso'),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, -2),
                color: Color(0x22000000),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Total: R\$ ${_formatMoney(totalToShow)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _finishSale,
                icon: const Icon(Icons.check_circle),
                label: const Text('Finalizar'),
              ),
            ],
          ),
        ),
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
                    'Modo emergência da balança',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use quando a balança pesa, mas o teclado/PLU não funciona. O funcionário digita o peso visto no visor ou passa o leitor USB na etiqueta.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<_DemoProduct>(
                    value: _selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Produto',
                      border: OutlineInputBorder(),
                    ),
                    items: _demoProducts.map((product) {
                      return DropdownMenuItem(
                        value: product,
                        child: Text('${product.name} - R\$ ${product.pricePerKg.toStringAsFixed(2)}/kg'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedProduct = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Peso visto na balança em kg',
                      hintText: 'Ex: 0.750',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total manual: R\$ ${_formatMoney(_manualTotal)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                    'Leitor USB / etiqueta da balança',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ScaleBarcodeMode>(
                    value: _barcodeMode,
                    decoration: const InputDecoration(
                      labelText: 'Formato do código da etiqueta',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      ScaleBarcodeMode.priceEmbedded,
                      ScaleBarcodeMode.weightEmbedded,
                    ].map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(_modeLabel(mode)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _barcodeMode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _barcodeController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Código lido pelo leitor USB',
                      hintText: 'Passe o leitor ou digite o código',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _readBarcode(),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _readBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Ler código'),
                  ),
                  if (_lastBarcode != null) ...[
                    const SizedBox(height: 12),
                    Text('Código: ${_lastBarcode!.rawCode}'),
                    Text('Produto na etiqueta: ${_lastBarcode!.productCode}'),
                    Text('Valor na etiqueta: ${_lastBarcode!.valueCode}'),
                    Text('Dígito verificador correto: ${_lastBarcode!.isCheckDigitValid ? 'sim' : 'não'}'),
                  ],
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
                  Text(
                    'Total da venda: R\$ ${_formatMoney(totalToShow)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Produto: ${_selectedProduct.name}'),
                  Text('Preço/kg: R\$ ${_selectedProduct.pricePerKg.toStringAsFixed(2)}'),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(_message!),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _finishSale,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Finalizar venda teste'),
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

class _DemoProduct {
  final String id;
  final String name;
  final String scaleCode;
  final double pricePerKg;

  const _DemoProduct({
    required this.id,
    required this.name,
    required this.scaleCode,
    required this.pricePerKg,
  });
}

const _demoProducts = [
  _DemoProduct(
    id: '1',
    name: 'Carne moída',
    scaleCode: '001234',
    pricePerKg: 35.90,
  ),
  _DemoProduct(
    id: '2',
    name: 'Frango',
    scaleCode: '000002',
    pricePerKg: 18.90,
  ),
  _DemoProduct(
    id: '3',
    name: 'Coxão mole',
    scaleCode: '000003',
    pricePerKg: 42.90,
  ),
];
