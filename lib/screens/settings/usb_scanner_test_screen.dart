import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/scale_barcode_data.dart';
import '../../services/scales/scale_barcode_parser.dart';

class UsbScannerTestScreen extends StatefulWidget {
  const UsbScannerTestScreen({super.key});

  @override
  State<UsbScannerTestScreen> createState() => _UsbScannerTestScreenState();
}

class _UsbScannerTestScreenState extends State<UsbScannerTestScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _parser = const ScaleBarcodeParser();

  Timer? _debounce;
  String _lastRaw = '';
  ScaleBarcodeData? _lastParsed;
  String _status = 'Clique no campo e passe o leitor USB na etiqueta.';

  @override
  void initState() {
    super.initState();
    _focusField();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _focusField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    final digits = _digitsOnly(value);

    setState(() {
      _status = 'Recebendo código... ${digits.length} número(s)';
    });

    if (digits.length >= 13) {
      _debounce = Timer(const Duration(milliseconds: 180), _readCode);
    }
  }

  void _readCode() {
    final raw = _digitsOnly(_controller.text);
    final code = raw.length > 13 ? raw.substring(0, 13) : raw;

    final parsed = _parser.parse(
      code,
      mode: ScaleBarcodeMode.priceEmbedded,
    );

    setState(() {
      _lastRaw = code;
      _lastParsed = parsed;

      if (code.isEmpty) {
        _status = 'Nenhum código recebido ainda.';
      } else if (code.length != 13) {
        _status = 'Código recebido, mas ele tem ${code.length} número(s). O esperado geralmente é 13.';
      } else if (parsed == null) {
        _status = 'Código recebido, mas não parece uma etiqueta de balança começando com 2.';
      } else {
        _status = 'Leitor funcionando. Código recebido e interpretado.';
      }

      _controller.clear();
    });

    _focusField();
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _lastRaw = '';
      _lastParsed = null;
      _status = 'Teste limpo. Passe o leitor novamente.';
    });

    _focusField();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste do leitor USB'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: colorScheme.onPrimary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teste rápido do leitor USB',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Use esta tela quando o leitor chegar para confirmar se ele está mandando o código para o sistema.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Campo que recebe o leitor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Conecte o leitor USB, clique no campo abaixo e passe a etiqueta. O leitor deve digitar os números aqui como se fosse um teclado.',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Passe o leitor aqui',
                      hintText: 'O código vai aparecer automaticamente',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.usb_rounded),
                    ),
                    onChanged: _onChanged,
                    onSubmitted: (_) => _readCode(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _readCode,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Ler agora'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _clear,
                        icon: const Icon(Icons.cleaning_services_rounded),
                        label: const Text('Limpar teste'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Resultado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ResultLine(label: 'Status', value: _status),
                  _ResultLine(
                    label: 'Último código',
                    value: _lastRaw.isEmpty ? '-' : _lastRaw,
                  ),
                  _ResultLine(
                    label: 'Tamanho',
                    value: _lastRaw.isEmpty ? '-' : '${_lastRaw.length} dígitos',
                  ),
                  _ResultLine(
                    label: 'PLU/produto',
                    value: _lastParsed?.productCode ?? '-',
                  ),
                  _ResultLine(
                    label: 'Valor/peso embutido',
                    value: _lastParsed?.valueCode ?? '-',
                  ),
                  _ResultLine(
                    label: 'Dígito verificador',
                    value: _lastParsed == null
                        ? '-'
                        : _lastParsed!.isCheckDigitValid
                            ? 'correto'
                            : 'diferente',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Se nada aparecer no campo, o leitor pode não estar em modo USB Keyboard. Se aparecer o código mas não adicionar sozinho, configure o leitor para enviar Enter no final da leitura.',
                    ),
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

class _ResultLine extends StatelessWidget {
  const _ResultLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
