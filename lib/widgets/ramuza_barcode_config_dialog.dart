import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/product.dart';
import '../models/product_unit.dart';
import '../models/ramuza_barcode_settings.dart';
import '../providers/inventory_provider.dart';
import '../providers/ramuza_settings_provider.dart';
import '../services/ramuza_barcode_parser.dart';

Future<void> showbalançaBarcodeConfigDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return const balançaBarcodeConfigDialog();
    },
  );
}

class balançaBarcodeConfigDialog extends StatefulWidget {
  const balançaBarcodeConfigDialog({super.key});

  @override
  State<balançaBarcodeConfigDialog> createState() =>
      _balançaBarcodeConfigDialogState();
}

class _balançaBarcodeConfigDialogState extends State<balançaBarcodeConfigDialog> {
  late final TextEditingController prefixController;
  late final TextEditingController productDigitsController;
  late final TextEditingController valueDigitsController;
  late final TextEditingController weightDecimalsController;
  late final TextEditingController priceDecimalsController;
  late final TextEditingController testCodeController;

  bool enabled = true;
  bool hasChecksum = true;
  RamuzaBarcodeValueMode valueMode = RamuzaBarcodeValueMode.weight;

  @override
  void initState() {
    super.initState();

    final settings = context.read<RamuzaSettingsProvider>().settings;

    enabled = settings.enabled;
    hasChecksum = settings.hasChecksum;
    valueMode = settings.valueMode;

    prefixController = TextEditingController(text: settings.prefix);
    productDigitsController = TextEditingController(
      text: settings.productCodeDigits.toString(),
    );
    valueDigitsController = TextEditingController(
      text: settings.valueDigits.toString(),
    );
    weightDecimalsController = TextEditingController(
      text: settings.weightDecimals.toString(),
    );
    priceDecimalsController = TextEditingController(
      text: settings.priceDecimals.toString(),
    );

    testCodeController = TextEditingController();
  }

  @override
  void dispose() {
    prefixController.dispose();
    productDigitsController.dispose();
    valueDigitsController.dispose();
    weightDecimalsController.dispose();
    priceDecimalsController.dispose();
    testCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _buildSettingsFromFields();

    return Consumer2<RamuzaSettingsProvider, InventoryProvider>(
      builder: (context, provider, inventory, _) {
        final explanation = RamuzaBarcodeParser.explain(
          testCodeController.text,
          settings,
        );

        final parsed = RamuzaBarcodeParser.tryParse(
          testCodeController.text,
          settings,
        );

        final product = parsed == null
            ? null
            : _findProductByRamuzaCode(inventory.products, parsed.productCode);

        return AlertDialog(
          title: const Text('Teste de etiqueta'),
          content: SizedBox(
            width: 900,
            height: 650,
            child: ListView(
              children: [
                _InfoHeader(settings: settings),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SwitchListTile(
                        value: enabled,
                        onChanged: (value) {
                          setState(() => enabled = value);
                        },
                        title: const Text('Ativar leitura balança'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: SwitchListTile(
                        value: hasChecksum,
                        onChanged: (value) {
                          setState(() => hasChecksum = value);
                        },
                        title: const Text('Último dígito é checksum'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: prefixController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Prefixo/flag',
                          hintText: 'Ex: 20',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: productDigitsController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Dígitos do PLU/código',
                          hintText: 'Ex: 4',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: valueDigitsController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Dígitos do valor/peso',
                          hintText: 'Ex: 6',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<RamuzaBarcodeValueMode>(
                        value: valueMode,
                        decoration: const InputDecoration(
                          labelText: 'O código contém',
                        ),
                        items: RamuzaBarcodeValueMode.values.map((mode) {
                          return DropdownMenuItem(
                            value: mode,
                            child: Text(mode.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => valueMode = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: weightDecimalsController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Casas decimais do peso',
                          hintText: 'Ex: 3',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceDecimalsController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Casas decimais do dinheiro',
                          hintText: 'Ex: 2',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _TestPanel(
                  controller: testCodeController,
                  explanation: explanation,
                  product: product,
                  parsed: parsed,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                provider.resetDefaults();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Padrão'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                provider.updateSettings(settings);

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Configuração da etiqueta balança salva.'),
                    ),
                  );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  RamuzaBarcodeSettings _buildSettingsFromFields() {
    final prefix = prefixController.text.replaceAll(RegExp(r'[^0-9]'), '');

    return RamuzaBarcodeSettings(
      enabled: enabled,
      prefix: prefix,
      productCodeDigits: _safeInt(productDigitsController.text, fallback: 4),
      valueDigits: _safeInt(valueDigitsController.text, fallback: 6),
      valueMode: valueMode,
      weightDecimals: _safeInt(weightDecimalsController.text, fallback: 3),
      priceDecimals: _safeInt(priceDecimalsController.text, fallback: 2),
      hasChecksum: hasChecksum,
    );
  }
}

class _InfoHeader extends StatelessWidget {
  const _InfoHeader({required this.settings});

  final RamuzaBarcodeSettings settings;

  @override
  Widget build(BuildContext context) {
    final example = _exampleCode(settings);

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.wine900,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Configure o formato do código impresso pela balança. '
                'O tamanho esperado agora é ${settings.expectedLength} dígitos. '
                'Exemplo para teste: $example',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _exampleCode(RamuzaBarcodeSettings settings) {
    final productCode = '1234'.padLeft(settings.productCodeDigits, '0');

    final payload = settings.valueMode == RamuzaBarcodeValueMode.weight
        ? '1250'.padLeft(settings.valueDigits, '0')
        : '1250'.padLeft(settings.valueDigits, '0');

    final checksum = settings.hasChecksum ? '0' : '';

    return '${settings.prefix}$productCode$payload$checksum';
  }
}

class _TestPanel extends StatelessWidget {
  const _TestPanel({
    required this.controller,
    required this.explanation,
    required this.product,
    required this.parsed,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String explanation;
  final Product? product;
  final RamuzaParsedBarcode? parsed;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final foundProduct = product;

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teste de leitura',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código lido pela etiqueta',
                hintText: 'Ex: 2012340012500',
                prefixIcon: Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              explanation,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (foundProduct == null)
              Text(
                parsed == null
                    ? 'Produto encontrado: nenhum.'
                    : 'Produto encontrado: nenhum. PLU lido: ${parsed!.productCode}. Cadastre um produto com esse código interno.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              )
            else
              _ProductFound(product: foundProduct, parsed: parsed),
          ],
        ),
      ),
    );
  }
}

class _ProductFound extends StatelessWidget {
  const _ProductFound({
    required this.product,
    required this.parsed,
  });

  final Product product;
  final RamuzaParsedBarcode? parsed;

  @override
  Widget build(BuildContext context) {
    final quantity = parsed?.quantityForProduct(product);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Produto encontrado: ${product.name}${quantity == null ? '' : ' • Quantidade: ${_formatNumber(quantity)} ${product.unit.label}'}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

Product? _findProductByRamuzaCode(List<Product> products, String code) {
  final normalizedCode = _normalizeNumericCode(code);

  for (final product in products) {
    if (product.isDeleted) continue;

    final productCode = _normalizeNumericCode(product.code);

    if (productCode == normalizedCode) {
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

int _safeInt(String value, {required int fallback}) {
  final parsed = int.tryParse(value.trim());

  if (parsed == null || parsed < 0) {
    return fallback;
  }

  return parsed;
}

String _formatNumber(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(3).replaceAll('.', ',');
}
