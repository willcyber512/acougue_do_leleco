import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/product_category.dart';
import '../models/product_unit.dart';
import '../providers/inventory_provider.dart';

Future<Product?> showQuickProductFromBarcodeDialog({
  required BuildContext context,
  required String productCode,
  required String rawBarcode,
  required double? suggestedQuantity,
}) async {
  return showDialog<Product>(
    context: context,
    builder: (dialogContext) {
      return _QuickProductFromBarcodeDialog(
        productCode: productCode,
        rawBarcode: rawBarcode,
        suggestedQuantity: suggestedQuantity,
      );
    },
  );
}

class _QuickProductFromBarcodeDialog extends StatefulWidget {
  const _QuickProductFromBarcodeDialog({
    required this.productCode,
    required this.rawBarcode,
    required this.suggestedQuantity,
  });

  final String productCode;
  final String rawBarcode;
  final double? suggestedQuantity;

  @override
  State<_QuickProductFromBarcodeDialog> createState() =>
      _QuickProductFromBarcodeDialogState();
}

class _QuickProductFromBarcodeDialogState
    extends State<_QuickProductFromBarcodeDialog> {
  late final TextEditingController codeController;
  late final TextEditingController nameController;
  late final TextEditingController salePriceController;
  late final TextEditingController costPriceController;
  late final TextEditingController stockController;
  late final TextEditingController minStockController;

  ProductCategory category = ProductCategory.values.first;
  ProductUnit unit = ProductUnit.kg;

  @override
  void initState() {
    super.initState();

    final suggestedStock = widget.suggestedQuantity == null
        ? '1,000'
        : widget.suggestedQuantity!.toStringAsFixed(3).replaceAll('.', ',');

    codeController = TextEditingController(text: widget.productCode);
    nameController = TextEditingController();
    salePriceController = TextEditingController();
    costPriceController = TextEditingController(text: '0,00');
    stockController = TextEditingController(text: suggestedStock);
    minStockController = TextEditingController(text: '1,000');
  }

  @override
  void dispose() {
    codeController.dispose();
    nameController.dispose();
    salePriceController.dispose();
    costPriceController.dispose();
    stockController.dispose();
    minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cadastrar produto da etiqueta'),
      content: SizedBox(
        width: 640,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Etiqueta lida: ${widget.rawBarcode}\nPLU/Código detectado: ${widget.productCode}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Código interno / PLU',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nome do produto',
                hintText: 'Ex: Picanha etiqueta',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ProductCategory>(
                    value: category,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                    ),
                    items: ProductCategory.values.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => category = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<ProductUnit>(
                    value: unit,
                    decoration: const InputDecoration(
                      labelText: 'Unidade',
                    ),
                    items: ProductUnit.values.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => unit = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: salePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Preço de venda',
                      prefixText: 'R\$ ',
                      hintText: 'Ex: 49,90',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: costPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custo',
                      prefixText: 'R\$ ',
                      hintText: 'Opcional',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Estoque inicial (${unit.label})',
                      hintText: unit == ProductUnit.kg ? 'Ex: 10,000' : 'Ex: 10',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: minStockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Estoque mínimo (${unit.label})',
                      hintText: unit == ProductUnit.kg ? 'Ex: 1,000' : 'Ex: 1',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Dica: o estoque inicial precisa ser maior ou igual ao peso/quantidade da etiqueta para conseguir finalizar a venda.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saveProduct,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Cadastrar e usar'),
        ),
      ],
    );
  }

  void _saveProduct() {
    final inventory = context.read<InventoryProvider>();

    final code = codeController.text.trim();
    final name = nameController.text.trim();
    final salePrice = _parseMoney(salePriceController.text);
    final costPrice = _parseMoney(costPriceController.text);
    final stock = _parseNumber(stockController.text);
    final minStock = _parseNumber(minStockController.text);

    if (code.isEmpty) {
      _showMessage('Código inválido.');
      return;
    }

    if (name.isEmpty) {
      _showMessage('Informe o nome do produto.');
      return;
    }

    if (salePrice <= 0) {
      _showMessage('Informe o preço de venda.');
      return;
    }

    if (stock <= 0) {
      _showMessage('Informe o estoque inicial.');
      return;
    }

    final now = DateTime.now();

    final product = Product(
      id: now.microsecondsSinceEpoch.toString(),
      code: code,
      name: name,
      category: category,
      unit: unit,
      salePrice: salePrice,
      costPrice: costPrice,
      stockQuantity: stock,
      minStock: minStock,
      favorite: false,
      imagePath: null,
      createdAt: now,
      updatedAt: now,
    );

    inventory.addProduct(product);

    Navigator.of(context).pop(product);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }
}

double _parseMoney(String value) {
  var text = value.trim().replaceAll('R\$', '').replaceAll(' ', '');

  if (text.contains(',')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  }

  return double.tryParse(text) ?? 0;
}

double _parseNumber(String value) {
  final text = value.trim().replaceAll(',', '.');

  return double.tryParse(text) ?? 0;
}
