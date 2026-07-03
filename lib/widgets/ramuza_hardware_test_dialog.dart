import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/product.dart';
import '../models/product_unit.dart';
import '../models/ramuza_barcode_settings.dart';
import '../providers/inventory_provider.dart';
import '../providers/ramuza_settings_provider.dart';
import '../services/ramuza_barcode_parser.dart';

Future<void> showRamuzaHardwareTestDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const RamuzaHardwareTestDialog(),
  );
}

class RamuzaHardwareTestDialog extends StatefulWidget {
  const RamuzaHardwareTestDialog({super.key});

  @override
  State<RamuzaHardwareTestDialog> createState() =>
      _RamuzaHardwareTestDialogState();
}

class _RamuzaHardwareTestDialogState extends State<RamuzaHardwareTestDialog> {
  final TextEditingController valueController = TextEditingController(
    text: '0,750',
  );
  final TextEditingController scannedController = TextEditingController();

  String? selectedProductId;

  @override
  void dispose() {
    valueController.dispose();
    scannedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final settings = context.watch<RamuzaSettingsProvider>().settings;

    final products = inventory.products.where((product) {
      return !product.isDeleted;
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    if (selectedProductId == null && products.isNotEmpty) {
      selectedProductId = products.first.id;
    }

    var selectedProduct = _findProduct(products, selectedProductId);

    if (selectedProduct == null && products.isNotEmpty) {
      selectedProductId = products.first.id;
      selectedProduct = products.first;
    }

    final simulatedValue = _parseDouble(valueController.text);
    final simulatedCode = selectedProduct == null
        ? ''
        : RamuzaBarcodeParser.buildTestBarcode(
            productCode: selectedProduct.code,
            value: simulatedValue <= 0 ? 0.750 : simulatedValue,
            settings: settings,
          );

    final parsed = RamuzaBarcodeParser.tryParse(
      scannedController.text,
      settings,
    );

    final foundProduct = parsed == null
        ? null
        : _findProductByRamuzaCode(products, parsed.productCode);

    return AlertDialog(
      title: const Text('Teste de leitor USB e etiqueta Ramuza'),
      content: SizedBox(
        width: 940,
        height: 660,
        child: ListView(
          children: [
            _InfoBox(settings: settings),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedProduct?.id,
              decoration: const InputDecoration(
                labelText: 'Produto para simular etiqueta',
              ),
              items: products.map((product) {
                return DropdownMenuItem(
                  value: product.id,
                  child: Text('${product.code} • ${product.name}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedProductId = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: settings.valueMode == RamuzaBarcodeValueMode.weight
                    ? 'Peso/quantidade simulada'
                    : 'Valor total simulado',
                hintText: settings.valueMode == RamuzaBarcodeValueMode.weight
                    ? 'Ex: 0,750'
                    : 'Ex: 25,90',
              ),
            ),
            const SizedBox(height: 14),
            _GeneratedCodeBox(
              code: simulatedCode,
              product: selectedProduct,
              onCopy: simulatedCode.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: simulatedCode),
                      );
                      _showMessage(context, 'Código simulado copiado.');
                    },
              onUse: simulatedCode.isEmpty
                  ? null
                  : () {
                      setState(() {
                        scannedController.text = simulatedCode;
                        scannedController.selection = TextSelection.collapsed(
                          offset: simulatedCode.length,
                        );
                      });
                    },
            ),
            const SizedBox(height: 18),
            TextField(
              controller: scannedController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Campo de teste do leitor USB',
                hintText:
                    'Cole aqui ou leia com o leitor. O leitor USB deve digitar o código e apertar Enter.',
                prefixIcon: Icon(Icons.qr_code_scanner_rounded),
              ),
              onSubmitted: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            _ParsedResultBox(
              settings: settings,
              rawInput: scannedController.text,
              parsed: parsed,
              product: foundProduct,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.settings});

  final RamuzaBarcodeSettings settings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Text(
          'Formato atual: prefixo ${settings.prefix}, '
          '${settings.productCodeDigits} dígitos de PLU, '
          '${settings.valueDigits} dígitos de ${settings.valueMode.label.toLowerCase()}, '
          '${settings.hasChecksum ? 'com' : 'sem'} checksum. '
          'Tamanho esperado: ${settings.expectedLength} dígitos.',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _GeneratedCodeBox extends StatelessWidget {
  const _GeneratedCodeBox({
    required this.code,
    required this.product,
    required this.onCopy,
    required this.onUse,
  });

  final String code;
  final Product? product;
  final VoidCallback? onCopy;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final productText = product == null
        ? 'Nenhum produto selecionado.'
        : '${product!.code} • ${product!.name}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.wine900.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produto: $productText'),
          const SizedBox(height: 8),
          const Text(
            'Etiqueta simulada:',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          SelectableText(
            code.isEmpty ? 'Sem código.' : code,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copiar'),
              ),
              FilledButton.icon(
                onPressed: onUse,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Usar no teste'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParsedResultBox extends StatelessWidget {
  const _ParsedResultBox({
    required this.settings,
    required this.rawInput,
    required this.parsed,
    required this.product,
  });

  final RamuzaBarcodeSettings settings;
  final String rawInput;
  final RamuzaParsedBarcode? parsed;
  final Product? product;

  @override
  Widget build(BuildContext context) {
    final explanation = RamuzaBarcodeParser.explain(rawInput, settings);

    if (rawInput.trim().isEmpty) {
      return const Text(
        'Aguardando código do leitor.',
        style: TextStyle(fontWeight: FontWeight.w800),
      );
    }

    final success = parsed != null && product != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: success
            ? AppColors.success.withOpacity(0.12)
            : AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            explanation,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (parsed == null)
            const Text(
              'Resultado: código ainda não bate com a configuração atual.',
              style: TextStyle(fontWeight: FontWeight.w800),
            )
          else if (product == null)
            Text(
              'Resultado: PLU ${parsed!.productCode} lido, mas não existe produto ativo com esse código.',
              style: const TextStyle(fontWeight: FontWeight.w800),
            )
          else
            Text(
              'Resultado: ${product!.name} encontrado. Quantidade calculada: ${_formatNumber(parsed!.quantityForProduct(product!) ?? 0)} ${product!.unit.label}.',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
        ],
      ),
    );
  }
}

Product? _findProduct(List<Product> products, String? id) {
  if (id == null) return null;

  for (final product in products) {
    if (product.id == id) return product;
  }

  return null;
}

Product? _findProductByRamuzaCode(List<Product> products, String code) {
  final normalized = _normalizeNumericCode(code);

  for (final product in products) {
    final productCode = _normalizeNumericCode(product.code);

    if (productCode == normalized) {
      return product;
    }
  }

  return null;
}

String _normalizeNumericCode(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  final parsed = int.tryParse(digits);

  if (parsed == null) return digits;

  return parsed.toString();
}

double _parseDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}

String _formatNumber(double value) {
  if (value % 1 == 0) return value.toStringAsFixed(0);
  return value.toStringAsFixed(3).replaceAll('.', ',');
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}
