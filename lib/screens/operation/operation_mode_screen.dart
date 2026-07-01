import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/payment_method.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../models/ramuza_barcode_event.dart';
import '../../models/sale_cart_item.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/ramuza_barcode_log_provider.dart';
import '../../providers/ramuza_settings_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/ramuza_barcode_parser.dart';
import '../../widgets/leleco_logo.dart';
import '../../widgets/quick_product_from_barcode_dialog.dart';
import '../../widgets/sale_receipt_dialog.dart';

class OperationModeScreen extends StatefulWidget {
  const OperationModeScreen({super.key});

  @override
  State<OperationModeScreen> createState() => _OperationModeScreenState();
}

class _OperationModeScreenState extends State<OperationModeScreen> {
  final TextEditingController scannerController = TextEditingController();
  final FocusNode scannerFocus = FocusNode();

  String searchTerm = '';

  KeyEventResult _handleShortcut(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.f2) {
      _clearScanner();
      _showMessage(context, 'Campo de leitura limpo.', success: true);
      return KeyEventResult.handled;
    }

    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

    if (key == LogicalKeyboardKey.f4 ||
        (isCtrlPressed && key == LogicalKeyboardKey.enter)) {
      _finishFromShortcut();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.f6 ||
        (isCtrlPressed && key == LogicalKeyboardKey.digit6) ||
        (isCtrlPressed && key == LogicalKeyboardKey.numpad6)) {
      _cyclePaymentMethod();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd ||
        key == LogicalKeyboardKey.equal) {
      _increaseLastCartItem();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _decreaseLastCartItem();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _finishFromShortcut() async {
    final sales = context.read<SalesProvider>();

    if (!sales.hasItems) {
      _showMessage(context, 'Carrinho vazio.', error: true);
      _refocusScanner();
      return;
    }

    await _finishOperationSale(context);
    _refocusScanner();
  }

  void _cyclePaymentMethod() {
    final sales = context.read<SalesProvider>();

    final methods = PaymentMethod.values.where((method) {
      return method != PaymentMethod.fiado;
    }).toList();

    final current = methods.contains(sales.paymentMethod)
        ? sales.paymentMethod
        : PaymentMethod.dinheiro;

    final currentIndex = methods.indexOf(current);
    final next = methods[(currentIndex + 1) % methods.length];

    sales.setPaymentMethod(next);

    _showMessage(
      context,
      'Pagamento: ${next.label}',
      success: true,
    );

    _refocusScanner();
  }

  void _increaseLastCartItem() {
    final sales = context.read<SalesProvider>();

    if (sales.items.isEmpty) {
      _showMessage(context, 'Carrinho vazio.', error: true);
      _refocusScanner();
      return;
    }

    final item = sales.items.last;

    sales.increaseQuantity(item.product.id);

    _showMessage(
      context,
      '+ ${item.product.name}',
      success: true,
    );

    _refocusScanner();
  }

  void _decreaseLastCartItem() {
    final sales = context.read<SalesProvider>();

    if (sales.items.isEmpty) {
      _showMessage(context, 'Carrinho vazio.', error: true);
      _refocusScanner();
      return;
    }

    final item = sales.items.last;

    sales.decreaseQuantity(item.product.id);

    _showMessage(
      context,
      '- ${item.product.name}',
      success: true,
    );

    _refocusScanner();
  }

  @override
  void initState() {
    super.initState();

    HardwareKeyboard.instance.addHandler(_handleGlobalShortcut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scannerFocus.requestFocus();
    });
  }

  bool _handleGlobalShortcut(KeyEvent event) {
    if (!mounted) return false;

    final result = _handleShortcut(event);

    return result == KeyEventResult.handled;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalShortcut);

    scannerController.dispose();
    scannerFocus.dispose();
    super.dispose();
  }

  void _refocusScanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      scannerFocus.requestFocus();
    });
  }

  void _clearScanner() {
    scannerController.clear();

    setState(() {
      searchTerm = '';
    });

    _refocusScanner();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _handleShortcut(event),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.beige100,
        body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _refocusScanner,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1050;

                return Column(
                  children: [
                    _OperationHeader(
                      controller: scannerController,
                      focusNode: scannerFocus,
                      searchTerm: searchTerm,
                      compact: compact,
                      onChanged: (value) {
                        setState(() => searchTerm = value);
                      },
                      onSubmitted: _handleSubmitted,
                      onExit: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: compact
                          ? Column(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _ProductsBoard(
                                    searchTerm: searchTerm,
                                    onProductTap: _addProduct,
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Expanded(
                                  flex: 5,
                                  child: _CartBoard(
                                    onFinished: _refocusScanner,
                                    compact: true,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: _ProductsBoard(
                                    searchTerm: searchTerm,
                                    onProductTap: _addProduct,
                                    compact: false,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 4,
                                  child: _CartBoard(
                                    onFinished: _refocusScanner,
                                    compact: false,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _handleSubmitted(String value) async {
    final text = value.trim();

    if (text.isEmpty) {
      _clearScanner();
      return;
    }

    final inventory = context.read<InventoryProvider>();
    final sales = context.read<SalesProvider>();
    final ramuzaSettings = context.read<RamuzaSettingsProvider>().settings;

    final parsed = RamuzaBarcodeParser.tryParse(text, ramuzaSettings);

    if (parsed != null) {
      var product = _findByRamuzaCode(inventory.products, parsed.productCode);

      if (product == null) {
        _showMessage(
          context,
          'PLU ${parsed.productCode} não cadastrado. Abrindo cadastro rápido.',
        );

        product = await showQuickProductFromBarcodeDialog(
          context: context,
          productCode: parsed.productCode,
          rawBarcode: parsed.digits,
          suggestedQuantity: parsed.quantity,
        );

        if (!mounted) return;

        if (product == null) {
          _logRamuzaBarcodeRead(
            context: context,
            parsed: parsed,
            product: null,
            status: RamuzaBarcodeStatus.canceledQuickRegister,
            message: 'Cadastro rápido cancelado.',
          );

          _clearScanner();
          return;
        }
      }

      if (product.isDeleted) {
        _logRamuzaBarcodeRead(
          context: context,
          parsed: parsed,
          product: product,
          status: RamuzaBarcodeStatus.productDeleted,
          message: 'Produto está na lixeira.',
        );

        _showMessage(context, '${product.name} está na lixeira.', error: true);
        _clearScanner();
        return;
      }

      final quantity = parsed.quantityForProduct(product);

      if (quantity == null || quantity <= 0) {
        _logRamuzaBarcodeRead(
          context: context,
          parsed: parsed,
          product: product,
          status: RamuzaBarcodeStatus.invalidQuantity,
          message: 'Quantidade inválida na etiqueta.',
        );

        _showMessage(context, 'Quantidade inválida na etiqueta.', error: true);
        _clearScanner();
        return;
      }

      final validation = _validateQuantity(product, quantity);

      if (validation != null) {
        _logRamuzaBarcodeRead(
          context: context,
          parsed: parsed,
          product: product,
          status: RamuzaBarcodeStatus.invalidQuantity,
          message: validation,
          quantity: quantity,
        );

        _showMessage(context, validation, error: true);
        _clearScanner();
        return;
      }

      sales.addProduct(product, quantity: quantity);

      _logRamuzaBarcodeRead(
        context: context,
        parsed: parsed,
        product: product,
        status: RamuzaBarcodeStatus.success,
        message: 'Etiqueta adicionada ao carrinho.',
        quantity: quantity,
      );

      _showMessage(
        context,
        'Etiqueta OK: ${product.name} • ${_formatNumber(quantity)} ${product.unit.label}.',
        success: true,
      );

      _clearScanner();
      return;
    }

    final product = _findByCodeOrName(inventory.products, text);

    if (product == null) {
      _showMessage(context, 'Produto não encontrado.', error: true);
      _clearScanner();
      return;
    }

    _addProduct(product);
    _clearScanner();
  }

  void _addProduct(Product product) {
    final validation = _validateQuantity(product, 1);

    if (validation != null) {
      _showMessage(context, validation, error: true);
      _refocusScanner();
      return;
    }

    context.read<SalesProvider>().addProduct(product);

    _showMessage(
      context,
      '${product.name} adicionado.',
    );

    _refocusScanner();
  }
}

class _OperationHeader extends StatelessWidget {
  const _OperationHeader({
    required this.controller,
    required this.focusNode,
    required this.searchTerm,
    required this.compact,
    required this.onChanged,
    required this.onSubmitted,
    required this.onExit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchTerm;
  final bool compact;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: compact ? 94 : 98,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const LelecoLogo(size: 50),
            const SizedBox(width: 12),
            if (!compact) ...[
              Text(
                'Modo Balcão',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(width: 18),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                decoration: InputDecoration(
                  hintText: compact
                      ? 'Leia ou digite...'
                      : 'Leia etiqueta/código • F4 ou Ctrl+Enter finaliza • F6 ou Ctrl+6 pagamento',
                  prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                  suffixIcon: const Icon(Icons.keyboard_return_rounded),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: onExit,
              tooltip: 'Sair do modo balcão',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsBoard extends StatelessWidget {
  const _ProductsBoard({
    required this.searchTerm,
    required this.onProductTap,
    required this.compact,
  });

  final String searchTerm;
  final ValueChanged<Product> onProductTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Consumer2<InventoryProvider, RamuzaSettingsProvider>(
      builder: (context, inventory, ramuzaProvider, _) {
        final parsed = RamuzaBarcodeParser.tryParse(
          searchTerm,
          ramuzaProvider.settings,
        );

        final products = parsed == null
            ? _filterProducts(inventory.products, searchTerm)
            : _filterProductsForRamuzaCode(
                inventory.products,
                parsed.productCode,
              );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BoardTitle(
                  icon: Icons.inventory_2_rounded,
                  title: parsed == null
                      ? 'Produtos rápidos'
                      : 'Etiqueta detectada: PLU ${parsed.productCode}',
                  subtitle: parsed == null
                      ? '${products.length} produto(s) disponível(is)'
                      : 'Aperte Enter para adicionar a etiqueta ao carrinho',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Text(
                            parsed == null
                                ? 'Nenhum produto encontrado.'
                                : 'PLU ${parsed.productCode} não disponível no estoque.',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                      : GridView.builder(
                          itemCount: products.length,
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: compact ? 210 : 235,
                            mainAxisExtent: compact ? 150 : 165,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            return _FastProductCard(
                              product: products[index],
                              onTap: () => onProductTap(products[index]),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FastProductCard extends StatelessWidget {
  const _FastProductCard({
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final low = product.isLowStock;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.wine900,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      product.favorite
                          ? Icons.star_rounded
                          : Icons.shopping_basket_rounded,
                      color: AppColors.beige100,
                      size: 21,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      product.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatNumber(product.stockQuantity)} ${product.unit.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: low ? AppColors.warning : null,
                ),
              ),
              const Spacer(),
              Text(
                _formatMoney(product.salePrice),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.wine700,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBoard extends StatelessWidget {
  const _CartBoard({
    required this.onFinished,
    required this.compact,
  });

  final VoidCallback onFinished;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, sales, _) {
        final methods = PaymentMethod.values.where((method) {
          return method != PaymentMethod.fiado;
        }).toList();

        final selectedMethod = methods.contains(sales.paymentMethod)
            ? sales.paymentMethod
            : PaymentMethod.dinheiro;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _BoardTitle(
                  icon: Icons.shopping_cart_rounded,
                  title: 'Carrinho',
                  subtitle: '${sales.items.length} item(ns)',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: sales.items.isEmpty
                      ? const Center(
                          child: Text(
                            'Leia uma etiqueta ou toque em um produto.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        )
                      : ListView.separated(
                          itemCount: sales.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _FastCartItem(item: sales.items[index]);
                          },
                        ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Pagamento',
                  ),
                  items: methods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    sales.setPaymentMethod(value);
                  },
                ),
                const SizedBox(height: 12),
                _TotalPanel(total: sales.total),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: sales.hasItems ? sales.clearCart : null,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Limpar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: sales.hasItems
                            ? () async {
                                await _finishOperationSale(context);
                                onFinished();
                              }
                            : null,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Finalizar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FastCartItem extends StatelessWidget {
  const _FastCartItem({required this.item});

  final SaleCartItem item;

  @override
  Widget build(BuildContext context) {
    final sales = context.read<SalesProvider>();
    final product = item.product;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceAlt
            : AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openCartQuantityDialog(context, item),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatNumber(item.quantity)} ${product.unit.label} x ${_formatMoney(product.salePrice)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => sales.decreaseQuantity(product.id),
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text(
            _formatNumber(item.quantity),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          IconButton(
            onPressed: () => sales.increaseQuantity(product.id),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            onPressed: () => sales.removeItem(product.id),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _BoardTitle extends StatelessWidget {
  const _BoardTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TotalPanel extends StatelessWidget {
  const _TotalPanel({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total',
            style: TextStyle(
              color: AppColors.beige100,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatMoney(total),
            style: const TextStyle(
              color: AppColors.beige100,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _finishOperationSale(BuildContext context) async {
  final inventory = context.read<InventoryProvider>();
  final sales = context.read<SalesProvider>();

  if (sales.paymentMethod == PaymentMethod.fiado) {
    sales.setPaymentMethod(PaymentMethod.dinheiro);
  }

  final validationError = inventory.validateSaleItems(sales.items);

  if (validationError != null) {
    _showMessage(context, validationError, error: true);
    return;
  }

  final sale = sales.createSaleRecord();

  if (sale == null) {
    _showMessage(context, 'Adicione produtos ao carrinho.', error: true);
    return;
  }

  final stockOk = inventory.deductSaleRecord(sale);

  if (!stockOk) {
    _showMessage(context, 'Não foi possível baixar o estoque.', error: true);
    return;
  }

  sales.completeSale(sale);

  _showMessage(context, 'Venda #${sale.shortId} finalizada.', success: true);

  await showSaleReceiptDialog(context, sale);
}

Future<void> _openCartQuantityDialog(
  BuildContext context,
  SaleCartItem item,
) async {
  final controller = TextEditingController(
    text: _formatNumber(item.quantity),
  );

  final quantity = await showDialog<double>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Quantidade - ${item.product.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Quantidade (${item.product.unit.label})',
            hintText: 'Ex: 1,250',
          ),
          onSubmitted: (_) {
            Navigator.of(dialogContext).pop(
              _parseNumber(controller.text),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(
                _parseNumber(controller.text),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );

  controller.dispose();

  if (quantity == null || quantity <= 0) return;

  final error = _validateQuantity(item.product, quantity);

  if (error != null) {
    _showMessage(context, error);
    return;
  }

  context.read<SalesProvider>().updateQuantity(item.product.id, quantity);
}

Future<void> _openQuantityDialog(
  BuildContext context,
  Product product,
) async {
  final controller = TextEditingController(
    text: product.unit == ProductUnit.kg ? '1,000' : '1',
  );

  final quantity = await showDialog<double>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Adicionar ${product.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Quantidade (${product.unit.label})',
            hintText: product.unit == ProductUnit.kg ? 'Ex: 1,250' : 'Ex: 2',
          ),
          onSubmitted: (_) {
            Navigator.of(dialogContext).pop(
              _parseNumber(controller.text),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(
                _parseNumber(controller.text),
              );
            },
            child: const Text('Adicionar'),
          ),
        ],
      );
    },
  );

  controller.dispose();

  if (quantity == null || quantity <= 0) return;

  final error = _validateQuantity(product, quantity);

  if (error != null) {
    _showMessage(context, error);
    return;
  }

  context.read<SalesProvider>().addProduct(product, quantity: quantity);

  _showMessage(
    context,
    '${product.name} adicionado com ${_formatNumber(quantity)} ${product.unit.label}.',
  );
}

List<Product> _filterProducts(List<Product> products, String searchTerm) {
  final term = searchTerm.trim().toLowerCase();

  final available = products.where((product) {
    return !product.isDeleted && product.stockQuantity > 0;
  }).toList();

  available.sort((a, b) {
    if (a.favorite != b.favorite) {
      return a.favorite ? -1 : 1;
    }

    if (a.isLowStock != b.isLowStock) {
      return a.isLowStock ? -1 : 1;
    }

    return a.name.compareTo(b.name);
  });

  if (term.isEmpty) return available;

  return available.where((product) {
    return product.name.toLowerCase().contains(term) ||
        product.code.toLowerCase().contains(term) ||
        product.category.label.toLowerCase().contains(term);
  }).toList();
}

List<Product> _filterProductsForRamuzaCode(
  List<Product> products,
  String code,
) {
  final normalizedCode = _normalizeNumericCode(code);

  return products.where((product) {
    if (product.isDeleted || product.stockQuantity <= 0) return false;

    return _normalizeNumericCode(product.code) == normalizedCode;
  }).toList();
}

Product? _findByRamuzaCode(List<Product> products, String code) {
  final normalizedCode = _normalizeNumericCode(code);

  for (final product in products) {
    if (_normalizeNumericCode(product.code) == normalizedCode) {
      return product;
    }
  }

  return null;
}

Product? _findByCodeOrName(List<Product> products, String value) {
  final term = value.trim().toLowerCase();

  if (term.isEmpty) return null;

  try {
    return products.firstWhere((product) {
      return !product.isDeleted &&
          product.stockQuantity > 0 &&
          (product.code.toLowerCase() == term ||
              product.name.toLowerCase() == term);
    });
  } catch (_) {
    return null;
  }
}

String? _validateQuantity(Product product, double quantity) {
  if (quantity <= 0) {
    return 'Quantidade inválida.';
  }

  if (product.stockQuantity <= 0) {
    return '${product.name} está com estoque zerado.';
  }

  if (quantity > product.stockQuantity) {
    return 'Estoque insuficiente para ${product.name}. Disponível: ${_formatNumber(product.stockQuantity)} ${product.unit.label}.';
  }

  return null;
}

void _logRamuzaBarcodeRead({
  required BuildContext context,
  required RamuzaParsedBarcode parsed,
  required Product? product,
  required RamuzaBarcodeStatus status,
  required String message,
  double? quantity,
}) {
  final now = DateTime.now();

  context.read<RamuzaBarcodeLogProvider>().addEvent(
        RamuzaBarcodeEvent(
          id: now.microsecondsSinceEpoch.toString(),
          rawBarcode: parsed.raw,
          digits: parsed.digits,
          productCode: parsed.productCode,
          productName: product?.name,
          quantity: quantity,
          totalPrice: parsed.totalPrice,
          status: status,
          message: message,
          screen: 'Modo Balcão',
          createdAt: now,
        ),
      );
}

String _normalizeNumericCode(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  final parsed = int.tryParse(digits);

  if (parsed == null) return digits;

  return parsed.toString();
}

double _parseNumber(String value) {
  final text = value.trim().replaceAll(',', '.');

  return double.tryParse(text) ?? 0;
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}

String _formatNumber(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(3).replaceAll('.', ',');
}

void _showMessage(
  BuildContext context,
  String message, {
  bool success = false,
  bool error = false,
}) {
  if (error) {
    SystemSound.play(SystemSoundType.alert);
  } else if (success) {
    SystemSound.play(SystemSoundType.click);
  }

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? AppColors.danger
            : success
                ? AppColors.success
                : null,
      ),
    );
}
