import 'dart:async';

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
import '../../services/cash_sale_sync.dart';

class QuickWeightSaleScreen extends StatefulWidget {
  const QuickWeightSaleScreen({super.key});

  @override
  State<QuickWeightSaleScreen> createState() => _QuickWeightSaleScreenState();
}

class _QuickWeightSaleScreenState extends State<QuickWeightSaleScreen> {
  final _barcodeController = TextEditingController();
  final _weightController = TextEditingController(text: '0.000');
  final _barcodeFocusNode = FocusNode();
  final _parser = const ScaleBarcodeParser();

  static const ScaleBarcodeMode _barcodeMode = ScaleBarcodeMode.priceEmbedded;
  Product? _selectedProduct;
  String? _message;
  bool _autoAddBarcode = true;
  Timer? _barcodeDebounce;

  final List<_LabelSaleItem> _pendingItems = [];

  @override
  void initState() {
    super.initState();
    _focusBarcodeField();
  }

  @override
  void dispose() {
    _barcodeDebounce?.cancel();
    _barcodeController.dispose();
    _weightController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _focusBarcodeField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _barcodeFocusNode.requestFocus();
    });
  }

  double get _weightKg {
    final text = _weightController.text.trim().replaceAll(',', '.');
    return double.tryParse(text) ?? 0;
  }

  double get _pendingTotal {
    return _pendingItems.fold(0.0, (total, item) => total + item.total);
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

    return value
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _normalizeProductCode(String value) {
    final digits = _digitsOnly(value);

    if (digits.isEmpty) return '';

    if (digits.length > 6) {
      return digits.substring(digits.length - 6);
    }

    return digits.padLeft(6, '0');
  }

  void _onBarcodeChanged(List<Product> products, String value) {
    if (!_autoAddBarcode) return;

    final digits = _digitsOnly(value);

    _barcodeDebounce?.cancel();

    if (digits.length < 13) return;

    if (digits.length > 13) {
      _barcodeController.text = digits.substring(0, 13);
      _barcodeController.selection = TextSelection.fromPosition(
        TextPosition(offset: _barcodeController.text.length),
      );
    }

    _barcodeDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _addBarcodeToSale(products, silentWhenEmpty: true);
    });
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

      if (productWithoutZeros.isNotEmpty &&
          productWithoutZeros == codeWithoutZeros) {
        return product;
      }
    }

    return null;
  }

  _DecodedLabel _decodeLabel(Product product, ScaleBarcodeData barcode) {
    final valueAsPrice = barcode.priceFromBarcode;
    final valueAsWeight = barcode.weightKgFromBarcode;

    final quantityIfPrice = product.salePrice <= 0
        ? 0.0
        : valueAsPrice / product.salePrice;
    final totalIfWeight = valueAsWeight * product.salePrice;

    final stockLimit = product.stockQuantity <= 0
        ? 999999.0
        : product.stockQuantity * 1.05;

    final priceLooksPossible =
        valueAsPrice > 0 &&
        quantityIfPrice > 0 &&
        quantityIfPrice <= stockLimit;

    final weightLooksPossible =
        valueAsWeight > 0 && valueAsWeight <= stockLimit && valueAsWeight <= 30;

    if (weightLooksPossible && !priceLooksPossible) {
      return _DecodedLabel(
        modeLabel: 'peso detectado',
        quantity: valueAsWeight,
        total: totalIfWeight,
      );
    }

    if (priceLooksPossible && !weightLooksPossible) {
      return _DecodedLabel(
        modeLabel: 'preço detectado',
        quantity: quantityIfPrice,
        total: valueAsPrice,
      );
    }

    if (valueAsWeight > 30 && priceLooksPossible) {
      return _DecodedLabel(
        modeLabel: 'preço detectado',
        quantity: quantityIfPrice,
        total: valueAsPrice,
      );
    }

    if (valueAsPrice < 1 && weightLooksPossible) {
      return _DecodedLabel(
        modeLabel: 'peso detectado',
        quantity: valueAsWeight,
        total: totalIfWeight,
      );
    }

    return _DecodedLabel(
      modeLabel: 'preço detectado',
      quantity: quantityIfPrice,
      total: valueAsPrice,
    );
  }

  void _generateTestBarcode(Product? product) {
    if (product == null) {
      _showError('Cadastre ou selecione um produto primeiro.');
      return;
    }

    final productCode = _normalizeProductCode(product.code);

    if (productCode.isEmpty) {
      _showError('Esse produto está sem código/PLU.');
      return;
    }

    final value = _barcodeMode == ScaleBarcodeMode.priceEmbedded
        ? (_manualTotal(product) * 100).round()
        : (_weightKg * 1000).round();

    if (value <= 0) {
      _showError(
        'Digite um peso/quantidade maior que zero para gerar a etiqueta teste.',
      );
      return;
    }

    final code = _parser.buildInternalScaleCode(
      productCode: productCode,
      valueInCentsOrGrams: value,
    );

    setState(() {
      _barcodeController.text = code;
      _message =
          'Etiqueta teste gerada para ${product.name}. Agora clique em "Adicionar etiqueta".';
    });

    _focusBarcodeField();
  }

  void _addBarcodeToSale(
    List<Product> products, {
    bool silentWhenEmpty = false,
  }) {
    _barcodeDebounce?.cancel();

    final rawCode = _barcodeController.text.trim();

    if (rawCode.isEmpty) {
      if (!silentWhenEmpty) {
        _showError('Passe uma etiqueta ou digite o código antes de adicionar.');
      }
      return;
    }

    final parsed = _parser.parse(rawCode, mode: _barcodeMode);

    if (parsed == null) {
      _showError(
        'Código inválido. A etiqueta precisa ter 13 números e começar com 2.',
      );
      return;
    }

    final product = _findProductByScaleCode(products, parsed.productCode);

    if (product == null) {
      _showError(
        'Etiqueta lida, mas nenhum produto do estoque tem o código/PLU ${parsed.productCode}. Cadastre o produto no sistema com o mesmo código da balança.',
      );
      return;
    }

    final decoded = _decodeLabel(product, parsed);
    final quantity = decoded.quantity;
    final total = decoded.total;

    if (quantity <= 0 || total <= 0) {
      _showError('A etiqueta foi lida, mas o peso/valor ficou zerado.');
      return;
    }

    setState(() {
      _selectedProduct = product;
      _weightController.text = quantity.toStringAsFixed(3);
      _pendingItems.add(
        _LabelSaleItem(
          product: product,
          quantity: quantity,
          total: total,
          rawBarcode: parsed.rawCode,
          productCodeFromBarcode: parsed.productCode,
        ),
      );
      _barcodeController.clear();
      _message =
          'Etiqueta adicionada: ${product.name} | ${decoded.modeLabel} | ${_formatQty(quantity)} ${product.unit.label} | R\$ ${_formatMoney(total)}.';
    });

    _focusBarcodeField();
  }

  void _addManualItem(Product? product) {
    if (product == null) {
      _showError('Selecione um produto.');
      return;
    }

    final quantity = _weightKg;
    final total = _manualTotal(product);

    if (quantity <= 0 || total <= 0) {
      _showError('Digite um peso/quantidade maior que zero.');
      return;
    }

    setState(() {
      _pendingItems.add(
        _LabelSaleItem(
          product: product,
          quantity: quantity,
          total: total,
          rawBarcode: null,
          productCodeFromBarcode: _normalizeProductCode(product.code),
        ),
      );
      _weightController.text = '0.000';
      _message =
          'Item manual adicionado: ${product.name} | ${_formatQty(quantity)} ${product.unit.label} | R\$ ${_formatMoney(total)}.';
    });

    _focusBarcodeField();
  }

  List<SaleCartItem> _buildGroupedCartItems() {
    final grouped = <String, _GroupedItem>{};

    for (final item in _pendingItems) {
      final current = grouped[item.product.id];

      if (current == null) {
        grouped[item.product.id] = _GroupedItem(
          product: item.product,
          quantity: item.quantity,
        );
      } else {
        grouped[item.product.id] = _GroupedItem(
          product: current.product,
          quantity: current.quantity + item.quantity,
        );
      }
    }

    return grouped.values.map((item) {
      return SaleCartItem(product: item.product, quantity: item.quantity);
    }).toList();
  }

  void _finishSale({
    required InventoryProvider inventory,
    required SalesProvider sales,
  }) {
    if (_pendingItems.isEmpty) {
      _showError('Adicione pelo menos uma etiqueta/item antes de finalizar.');
      return;
    }

    final cartItems = _buildGroupedCartItems();
    final validationError = inventory.validateSaleItems(cartItems);

    if (validationError != null) {
      _showError(validationError);
      return;
    }

    final sale = SaleRecord.fromCart(
      cartItems: cartItems,
      paymentMethod: sales.paymentMethod,
      createdAt: DateTime.now(),
    );

    final deducted = inventory.deductSaleRecord(sale);

    if (!deducted) {
      _showError('Não foi possível baixar o estoque dessa venda.');
      return;
    }

    sales.registerExternalSale(sale);

    syncSaleCashMovement(context, sale);

    final itemCount = _pendingItems.length;
    final total = sale.total;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Venda #${sale.shortId} registrada: $itemCount item(ns) - R\$ ${_formatMoney(total)}',
        ),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _pendingItems.clear();
      _barcodeController.clear();
      _weightController.text = '0.000';
      _message = 'Venda #${sale.shortId} registrada com sucesso.';
    });

    _focusBarcodeField();
  }

  void _removePendingItem(int index) {
    if (index < 0 || index >= _pendingItems.length) return;

    final removed = _pendingItems[index];

    setState(() {
      _pendingItems.removeAt(index);
      _message = 'Item removido: ${removed.product.name}.';
    });

    _focusBarcodeField();
  }

  void _clearPendingItems() {
    setState(() {
      _pendingItems.clear();
      _message = 'Venda atual limpa.';
    });

    _focusBarcodeField();
  }

  void _showError(String message) {
    setState(() {
      _message = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );

    _focusBarcodeField();
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final sales = context.watch<SalesProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final products = inventory.products;
    final selectedProduct =
        _selectedProduct != null &&
            products.any((p) => p.id == _selectedProduct!.id)
        ? products.firstWhere((p) => p.id == _selectedProduct!.id)
        : products.isNotEmpty
        ? products.first
        : null;

    _selectedProduct = selectedProduct;

    return Scaffold(
      appBar: AppBar(title: const Text('Venda por etiqueta')),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
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
                child: _BottomTotal(
                  itemCount: _pendingItems.length,
                  total: _pendingTotal,
                  formatMoney: _formatMoney,
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () =>
                    _finishSale(inventory: inventory, sales: sales),
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
                _HeaderPanel(
                  itemCount: _pendingItems.length,
                  total: _pendingTotal,
                  paymentLabel: sales.paymentMethod.label,
                  formatMoney: _formatMoney,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;

                    if (!wide) {
                      return Column(
                        children: [
                          _buildReaderCard(products),
                          const SizedBox(height: 16),
                          _buildManualCard(selectedProduct, products),
                          const SizedBox(height: 16),
                          _buildCurrentSaleCard(sales, inventory),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _buildReaderCard(products),
                              const SizedBox(height: 16),
                              _buildManualCard(selectedProduct, products),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: _buildCurrentSaleCard(sales, inventory),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildReaderCard(List<Product> products) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Leitor USB',
              subtitle:
                  'Passe a etiqueta da balança. Cada leitura entra na venda atual.',
            ),
            const SizedBox(height: 16),
            _ScannerInfoBox(),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _autoAddBarcode,
              title: const Text('Adicionar automaticamente'),
              subtitle: const Text(
                'Quando o leitor enviar 13 números ou Enter, a etiqueta entra na venda.',
              ),
              onChanged: (value) {
                setState(() {
                  _autoAddBarcode = value;
                });

                _focusBarcodeField();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _barcodeController,
              focusNode: _barcodeFocusNode,
              autofocus: true,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                labelText: 'Código da etiqueta',
                hintText: 'Passe o leitor USB aqui',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.barcode_reader),
                suffixIcon: IconButton(
                  tooltip: 'Limpar código',
                  onPressed: () {
                    _barcodeController.clear();
                    _focusBarcodeField();
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
              onChanged: (value) => _onBarcodeChanged(products, value),
              onSubmitted: (_) =>
                  _addBarcodeToSale(products, silentWhenEmpty: true),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _addBarcodeToSale(products),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Adicionar agora'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _generateTestBarcode(_selectedProduct),
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('Gerar teste'),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              _MessageBox(message: _message!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualCard(Product? selectedProduct, List<Product> products) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(
              icon: Icons.scale_rounded,
              title: 'Entrada manual',
              subtitle: 'Use quando precisar digitar o peso visto na balança.',
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
                });

                _focusBarcodeField();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText:
                    'Peso/quantidade em ${selectedProduct?.unit.label ?? 'kg'}',
                hintText: 'Ex: 0.750',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _ManualTotalLine(
              total: _manualTotal(selectedProduct),
              formatMoney: _formatMoney,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _addManualItem(selectedProduct),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar manualmente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSaleCard(
    SalesProvider sales,
    InventoryProvider inventory,
  ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: _SectionTitle(
                    icon: Icons.receipt_long_rounded,
                    title: 'Venda atual',
                    subtitle: 'Confira os itens antes de finalizar.',
                  ),
                ),
                if (_pendingItems.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearPendingItems,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Limpar'),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (_pendingItems.isEmpty)
              const _EmptySaleBox()
            else
              for (var i = 0; i < _pendingItems.length; i++)
                _PendingItemTile(
                  item: _pendingItems[i],
                  index: i,
                  formatMoney: _formatMoney,
                  formatQty: _formatQty,
                  onRemove: () => _removePendingItem(i),
                ),
            const Divider(height: 28),
            _TotalBigLine(total: _pendingTotal, formatMoney: _formatMoney),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              value: sales.paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Forma de pagamento',
                border: OutlineInputBorder(),
              ),
              items: PaymentMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                sales.setPaymentMethod(value);
                _focusBarcodeField();
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _finishSale(inventory: inventory, sales: sales),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Finalizar venda'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerInfoBox extends StatelessWidget {
  const _ScannerInfoBox();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.usb_rounded),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Modo leitor USB: a balança imprime a etiqueta, o leitor envia o código e o sistema coloca o produto na venda. Confira peso e valor antes de finalizar.',
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({
    required this.itemCount,
    required this.total,
    required this.paymentLabel,
    required this.formatMoney,
  });

  final int itemCount;
  final double total;
  final String paymentLabel;
  final String Function(double value) formatMoney;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primary,
            child: Icon(
              Icons.point_of_sale_rounded,
              color: colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Venda por etiqueta',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Text('Tela preparada para leitor USB.'),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HeaderMetric(label: 'Itens', value: '$itemCount'),
          const SizedBox(width: 8),
          _HeaderMetric(label: 'Pagamento', value: paymentLabel),
          const SizedBox(width: 8),
          _HeaderMetric(label: 'Total', value: 'R\$ ${formatMoney(total)}'),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(icon, color: colorScheme.onSecondaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _ManualTotalLine extends StatelessWidget {
  const _ManualTotalLine({required this.total, required this.formatMoney});

  final double total;
  final String Function(double value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Total manual: R\$ ${formatMoney(total)}',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    );
  }
}

class _TotalBigLine extends StatelessWidget {
  const _TotalBigLine({required this.total, required this.formatMoney});

  final double total;
  final String Function(double value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Total da venda: R\$ ${formatMoney(total)}',
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
    );
  }
}

class _BottomTotal extends StatelessWidget {
  const _BottomTotal({
    required this.itemCount,
    required this.total,
    required this.formatMoney,
  });

  final int itemCount;
  final double total;
  final String Function(double value) formatMoney;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$itemCount item(ns) • R\$ ${formatMoney(total)}',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    );
  }
}

class _PendingItemTile extends StatelessWidget {
  const _PendingItemTile({
    required this.item,
    required this.index,
    required this.formatMoney,
    required this.formatQty,
    required this.onRemove,
  });

  final _LabelSaleItem item;
  final int index;
  final String Function(double value) formatMoney;
  final String Function(double value) formatQty;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final subtitle = item.rawBarcode == null
        ? 'Manual'
        : 'Etiqueta ${item.rawBarcode}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(
          item.product.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '$subtitle • ${formatQty(item.quantity)} ${item.product.unit.label}',
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Text(
              'R\$ ${formatMoney(item.total)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            IconButton(
              tooltip: 'Remover',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySaleBox extends StatelessWidget {
  const _EmptySaleBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.4),
        ),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 38),
          SizedBox(height: 8),
          Text(
            'Nenhum item na venda atual.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text('Passe uma etiqueta ou adicione um item manual.'),
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

class _DecodedLabel {
  const _DecodedLabel({
    required this.modeLabel,
    required this.quantity,
    required this.total,
  });

  final String modeLabel;
  final double quantity;
  final double total;
}

class _LabelSaleItem {
  const _LabelSaleItem({
    required this.product,
    required this.quantity,
    required this.total,
    required this.rawBarcode,
    required this.productCodeFromBarcode,
  });

  final Product product;
  final double quantity;
  final double total;
  final String? rawBarcode;
  final String productCodeFromBarcode;
}

class _GroupedItem {
  const _GroupedItem({required this.product, required this.quantity});

  final Product product;
  final double quantity;
}
