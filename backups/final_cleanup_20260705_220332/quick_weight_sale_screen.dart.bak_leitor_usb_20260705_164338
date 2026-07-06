import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../models/product_unit.dart';
import '../../models/sale.dart';
import '../../models/sale_cart_item.dart';
import '../../models/scale_barcode_data.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_provider.dart';
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
  Product? _selectedProduct;
  Product? _lastBarcodeProduct;
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

  double _manualTotal(Product? product) {
    if (product == null) return 0;
    return _weightKg * product.salePrice;
  }

  String _formatMoney(double value) {
    final cents = (value * 100).round();
    return (cents / 100).toStringAsFixed(2);
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _normalizeProductCode(String value) {
    final digits = _digitsOnly(value);

    if (digits.isEmpty) return '';

    return digits.padLeft(6, '0');
  }

  Product? _findProductByScaleCode(List<Product> products, String code) {
    final normalizedCode = _normalizeProductCode(code);
    final codeWithoutZeros = normalizedCode.replaceFirst(RegExp(r'^0+'), '');

    for (final product in products) {
      final productCode = _normalizeProductCode(product.code);
      final productWithoutZeros = productCode.replaceFirst(RegExp(r'^0+'), '');

      if (productCode == normalizedCode) {
        return product;
      }

      if (productWithoutZeros.isNotEmpty && productWithoutZeros == codeWithoutZeros) {
        return product;
      }
    }

    return null;
  }

  double _quantityFromBarcode(Product product, ScaleBarcodeData barcode) {
    if (_barcodeMode == ScaleBarcodeMode.weightEmbedded) {
      return barcode.weightKgFromBarcode;
    }

    final price = barcode.priceFromBarcode;

    if (product.salePrice <= 0) {
      return 0;
    }

    return price / product.salePrice;
  }

  double _totalFromBarcode(Product product, ScaleBarcodeData barcode) {
    if (_barcodeMode == ScaleBarcodeMode.priceEmbedded) {
      return barcode.priceFromBarcode;
    }

    return barcode.weightKgFromBarcode * product.salePrice;
  }

  void _readBarcode(List<Product> products) {
    final parsed = _parser.parse(
      _barcodeController.text,
      mode: _barcodeMode,
    );

    setState(() {
      _lastBarcode = parsed;
      _lastBarcodeProduct = null;

      if (parsed == null) {
        _message = 'Código inválido. A etiqueta precisa ter 13 números e começar com 2.';
        return;
      }

      final product = _findProductByScaleCode(products, parsed.productCode);

      if (product == null) {
        _message =
            'Etiqueta lida, mas nenhum produto do estoque tem o código/PLU ${parsed.productCode}. Cadastre o produto no sistema com o mesmo código da balança.';
        return;
      }

      _selectedProduct = product;
      _lastBarcodeProduct = product;

      if (_barcodeMode == ScaleBarcodeMode.weightEmbedded) {
        _weightController.text = parsed.weightKgFromBarcode.toStringAsFixed(3);
      } else {
        final quantity = _quantityFromBarcode(product, parsed);
        _weightController.text = quantity.toStringAsFixed(3);
      }

      _message =
          'Etiqueta lida: ${product.name} | código ${parsed.productCode} | ${parsed.modeLabel}.';
    });
  }

  void _finishSale({
    required InventoryProvider inventory,
    required SalesProvider sales,
    required Product? product,
  }) {
    if (product == null) {
      _showError('Cadastre ou selecione um produto antes de finalizar.');
      return;
    }

    final quantity = _lastBarcode != null && _lastBarcodeProduct?.id == product.id
        ? _quantityFromBarcode(product, _lastBarcode!)
        : _weightKg;

    if (quantity <= 0) {
      _showError('Informe um peso/quantidade maior que zero.');
      return;
    }

    final cartItem = SaleCartItem(
      product: product,
      quantity: quantity,
    );

    final validationError = inventory.validateSaleItems([cartItem]);

    if (validationError != null) {
      _showError(validationError);
      return;
    }

    final sale = SaleRecord.fromCart(
      cartItems: [cartItem],
      paymentMethod: sales.paymentMethod,
      createdAt: DateTime.now(),
    );

    final deducted = inventory.deductSaleRecord(sale);

    if (!deducted) {
      _showError('Não foi possível baixar o estoque dessa venda.');
      return;
    }

    sales.completeSale(sale);

    final total = sale.total;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Venda #${sale.shortId} registrada: ${product.name} - R\$ ${_formatMoney(total)}',
        ),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _message =
          'Venda #${sale.shortId} registrada. Baixou ${_formatQty(quantity)} ${product.unit.label} de ${product.name}.';
      _barcodeController.clear();
      _lastBarcode = null;
      _lastBarcodeProduct = null;
      _weightController.text = '0.000';
    });
  }

  void _showError(String message) {
    setState(() {
      _message = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
    final inventory = context.watch<InventoryProvider>();
    final sales = context.watch<SalesProvider>();

    final products = inventory.products;
    final selectedProduct =
        _selectedProduct != null && products.any((p) => p.id == _selectedProduct!.id)
            ? products.firstWhere((p) => p.id == _selectedProduct!.id)
            : products.isNotEmpty
                ? products.first
                : null;

    _selectedProduct = selectedProduct;

    final totalByBarcode = _lastBarcode != null &&
            selectedProduct != null &&
            _lastBarcodeProduct?.id == selectedProduct.id
        ? _totalFromBarcode(selectedProduct, _lastBarcode!)
        : null;

    final totalToShow = totalByBarcode ?? _manualTotal(selectedProduct);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Venda por etiqueta'),
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
                onPressed: () => _finishSale(
                  inventory: inventory,
                  sales: sales,
                  product: selectedProduct,
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text('Finalizar'),
              ),
            ],
          ),
        ),
      ),
      body: products.isEmpty
          ? const _EmptyProductsView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Produto real do estoque',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cadastre no sistema o mesmo código/PLU que foi cadastrado na balança. Assim o leitor USB identifica o produto pela etiqueta.',
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Product>(
                          value: selectedProduct,
                          decoration: const InputDecoration(
                            labelText: 'Produto',
                            border: OutlineInputBorder(),
                          ),
                          items: products.map((product) {
                            return DropdownMenuItem(
                              value: product,
                              child: Text(
                                '${product.code} - ${product.name} | R\$ ${_formatMoney(product.salePrice)}/${product.unit.label} | Estoque ${_formatQty(product.stockQuantity)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _selectedProduct = value;
                              _lastBarcode = null;
                              _lastBarcodeProduct = null;
                              _message = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Peso/quantidade em ${selectedProduct?.unit.label ?? 'kg'}',
                            hintText: 'Ex: 0.750',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            setState(() {
                              _lastBarcode = null;
                              _lastBarcodeProduct = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Total manual: R\$ ${_formatMoney(_manualTotal(selectedProduct))}',
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
                          'Leitor USB de etiqueta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Clique no campo abaixo e passe o leitor na etiqueta. Enquanto o leitor não chega, cole/digite o código para testar.',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ScaleBarcodeMode>(
                          value: _barcodeMode,
                          decoration: const InputDecoration(
                            labelText: 'Formato da etiqueta',
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
                              _lastBarcode = null;
                              _lastBarcodeProduct = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _barcodeController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Código da etiqueta',
                            hintText: 'Passe o leitor USB ou cole/digite o código',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _readBarcode(products),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _readBarcode(products),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Ler etiqueta'),
                        ),
                        if (_lastBarcode != null) ...[
                          const SizedBox(height: 12),
                          Text('Código: ${_lastBarcode!.rawCode}'),
                          Text('PLU/produto na etiqueta: ${_lastBarcode!.productCode}'),
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
                        Text('Produto: ${selectedProduct?.name ?? '-'}'),
                        Text('Código/PLU: ${selectedProduct?.code ?? '-'}'),
                        Text('Preço: R\$ ${_formatMoney(selectedProduct?.salePrice ?? 0)}/${selectedProduct?.unit.label ?? 'kg'}'),
                        Text('Pagamento: ${sales.paymentMethod.label}'),
                        if (_message != null) ...[
                          const SizedBox(height: 8),
                          Text(_message!),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyProductsView extends StatelessWidget {
  const _EmptyProductsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum produto cadastrado no estoque. Cadastre primeiro os produtos com o mesmo código/PLU usado na balança.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
