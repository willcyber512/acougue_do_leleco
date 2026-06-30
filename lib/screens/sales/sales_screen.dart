import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../models/sale_cart_item.dart';
import '../../providers/customers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/ramuza_settings_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/ramuza_barcode_parser.dart';
import '../../widgets/sale_receipt_dialog.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          flex: 7,
          child: _ProductsPanel(),
        ),
        SizedBox(width: 18),
        Expanded(
          flex: 4,
          child: _CartPanel(),
        ),
      ],
    );
  }
}

class _ProductsPanel extends StatelessWidget {
  const _ProductsPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer2<InventoryProvider, SalesProvider>(
      builder: (context, inventory, sales, _) {
        final ramuzaSettings = context.watch<RamuzaSettingsProvider>().settings;

        final parsedBarcode = RamuzaBarcodeParser.tryParse(
          sales.searchTerm,
          ramuzaSettings,
        );

        final products = parsedBarcode == null
            ? _filterProducts(
                inventory.products,
                sales.searchTerm,
              )
            : _filterProductsForRamuzaCode(
                inventory.products,
                parsedBarcode.productCode,
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BarcodeSearchField(
              value: sales.searchTerm,
              onChanged: sales.setSearchTerm,
              onSubmitted: (value) {
                _handleSalesInput(context, value);
              },
            ),
            const SizedBox(height: 12),
            Text(
              parsedBarcode == null
                  ? 'Enter adiciona 1 unidade/kg. Para peso exato, use o botão "Qtd".'
                  : 'Etiqueta Ramuza detectada: PLU ${parsedBarcode.productCode}. Aperte Enter para adicionar.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: products.isEmpty
                  ? _EmptyProducts(
                      message: parsedBarcode == null
                          ? 'Nenhum produto encontrado.'
                          : 'Etiqueta detectada, mas o PLU ${parsedBarcode.productCode} não está disponível no estoque.',
                    )
                  : GridView.builder(
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 270,
                        mainAxisExtent: 190,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        return _ProductSaleCard(product: products[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _BarcodeSearchField extends StatelessWidget {
  const _BarcodeSearchField({
    required this.value,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: TextField(
          autofocus: true,
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: 'Digite ou leia o código do produto...',
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
    );
  }
}

class _ProductSaleCard extends StatelessWidget {
  const _ProductSaleCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final sales = context.read<SalesProvider>();
    final isLow = product.isLowStock;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.wine900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    product.favorite
                        ? Icons.star_rounded
                        : Icons.shopping_bag_rounded,
                    color: AppColors.beige100,
                  ),
                ),
                const Spacer(),
                Text(
                  product.code,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatQuantity(product.stockQuantity, product.unit)} em estoque',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLow ? AppColors.warning : null,
                fontWeight: isLow ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatMoney(product.salePrice),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.wine700,
                        ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _openQuantityDialog(context, product),
                  child: const Text('Qtd'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    sales.addProduct(product);
                  },
                  child: const Text('+1'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, sales, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_rounded),
                    const SizedBox(width: 10),
                    Text(
                      'Carrinho',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${sales.items.length} item(ns)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: sales.items.isEmpty
                      ? const _EmptyCart()
                      : ListView.separated(
                          itemCount: sales.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _CartItemTile(item: sales.items[index]);
                          },
                        ),
                ),
                const SizedBox(height: 16),
                _PaymentSelector(
                  selected: sales.paymentMethod,
                  onChanged: sales.setPaymentMethod,
                ),
                const SizedBox(height: 16),
                _TotalBox(total: sales.total),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: sales.hasItems ? sales.clearCart : null,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Limpar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: sales.hasItems
                            ? () async {
                                final inventory =
                                    context.read<InventoryProvider>();
                                final customersProvider =
                                    context.read<CustomersProvider>();

                                Customer? selectedCustomer;

                                if (sales.paymentMethod == PaymentMethod.fiado) {
                                  selectedCustomer =
                                      await _selectCustomerForFiado(context);

                                  if (selectedCustomer == null) {
                                    return;
                                  }
                                }

                                final validationError =
                                    inventory.validateSaleItems(sales.items);

                                if (validationError != null) {
                                  _showMessage(context, validationError);
                                  return;
                                }

                                final sale = sales.createSaleRecord(
                                  customerId: selectedCustomer?.id,
                                  customerName: selectedCustomer?.name,
                                );

                                if (sale == null) {
                                  _showMessage(
                                    context,
                                    'Adicione produtos ao carrinho.',
                                  );
                                  return;
                                }

                                final stockOk = inventory.deductSaleRecord(sale);

                                if (!stockOk) {
                                  _showMessage(
                                    context,
                                    'Não foi possível baixar o estoque.',
                                  );
                                  return;
                                }

                                sales.completeSale(sale);

                                if (sale.paymentMethod == PaymentMethod.fiado &&
                                    selectedCustomer != null) {
                                  customersProvider.registerPurchase(
                                    sale,
                                    selectedCustomer,
                                  );
                                }

                                _showMessage(
                                  context,
                                  'Venda #${sale.shortId} finalizada.',
                                );

                                if (!context.mounted) return;

                                await showSaleReceiptDialog(context, sale);
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

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final SaleCartItem item;

  @override
  Widget build(BuildContext context) {
    final sales = context.read<SalesProvider>();
    final product = item.product;
    final quantity = item.quantity;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceAlt
            : AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.wine900,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.shopping_basket_rounded,
              color: AppColors.beige100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _openCartQuantityDialog(context, item),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatMoney(product.salePrice)} x ${_formatNumber(quantity)} ${product.unit.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Diminuir',
            onPressed: () => sales.decreaseQuantity(product.id),
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          InkWell(
            onTap: () => _openCartQuantityDialog(context, item),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatNumber(quantity),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Aumentar',
            onPressed: () => sales.increaseQuantity(product.id),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          SizedBox(
            width: 78,
            child: Text(
              _formatMoney(item.subtotal),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            tooltip: 'Remover',
            onPressed: () => sales.removeItem(product.id),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  const _PaymentSelector({
    required this.selected,
    required this.onChanged,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PaymentMethod>(
      value: selected,
      decoration: InputDecoration(
        labelText: 'Forma de pagamento',
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
      items: PaymentMethod.values.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Text(method.label),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
    );
  }
}

class _TotalBox extends StatelessWidget {
  const _TotalBox({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total da venda',
            style: TextStyle(
              color: AppColors.beige100,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatMoney(total),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.beige100,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Adicione produtos para iniciar a venda.'),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message),
    );
  }
}


void _handleSalesInput(BuildContext context, String value) {
  final inventory = context.read<InventoryProvider>();
  final sales = context.read<SalesProvider>();
  final ramuzaSettings = context.read<RamuzaSettingsProvider>().settings;

  final parsed = RamuzaBarcodeParser.tryParse(value, ramuzaSettings);

  if (parsed != null) {
    final product = _findByRamuzaCode(inventory.products, parsed.productCode);

    if (product == null) {
      _showMessage(
        context,
        'Etiqueta lida. PLU ${parsed.productCode} não está cadastrado no estoque.',
      );
      sales.setSearchTerm('');
      return;
    }

    if (product.isDeleted) {
      _showMessage(
        context,
        'Etiqueta lida. Produto ${product.name} está na lixeira.',
      );
      sales.setSearchTerm('');
      return;
    }

    final quantity = parsed.quantityForProduct(product);

    if (quantity == null || quantity <= 0) {
      _showMessage(
        context,
        'Etiqueta lida, mas não deu para calcular quantidade/valor.',
      );
      sales.setSearchTerm('');
      return;
    }

    if (product.stockQuantity <= 0) {
      _showMessage(
        context,
        'Etiqueta lida: ${product.name}, mas o estoque está zerado.',
      );
      sales.setSearchTerm('');
      return;
    }

    final error = _validateQuantity(product, quantity);

    if (error != null) {
      _showMessage(
        context,
        'Etiqueta lida: ${product.name}. $error',
      );
      sales.setSearchTerm('');
      return;
    }

    sales.addProduct(product, quantity: quantity);
    sales.setSearchTerm('');

    _showMessage(
      context,
      'Etiqueta OK: ${product.name} • ${_formatNumber(quantity)} ${product.unit.label}.',
    );

    return;
  }

  final product = _findByCodeOrName(inventory.products, value);

  if (product == null) {
    _showMessage(context, 'Produto não encontrado.');
    return;
  }

  sales.addProduct(product);
  sales.setSearchTerm('');

  _showMessage(
    context,
    '${product.name} adicionado com 1 ${product.unit.label}.',
  );
}

Product? _findByRamuzaCode(List<Product> products, String code) {
  final normalizedCode = _normalizeNumericCode(code);

  for (final product in products) {
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

Future<void> _openQuantityDialog(
  BuildContext context,
  Product product,
) async {
  final sales = context.read<SalesProvider>();
  final quantityController = TextEditingController(
    text: product.unit == ProductUnit.kg ? '1,000' : '1',
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Adicionar ${product.name}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Estoque disponível: ${_formatQuantity(product.stockQuantity, product.unit)}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantidade (${product.unit.label})',
                  hintText:
                      product.unit == ProductUnit.kg ? 'Ex: 1,250' : 'Ex: 2',
                  suffixText: product.unit.label,
                ),
                onSubmitted: (_) {
                  _confirmAddQuantity(
                    context: context,
                    dialogContext: dialogContext,
                    product: product,
                    sales: sales,
                    text: quantityController.text,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              _confirmAddQuantity(
                context: context,
                dialogContext: dialogContext,
                product: product,
                sales: sales,
                text: quantityController.text,
              );
            },
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Adicionar'),
          ),
        ],
      );
    },
  );
}

void _confirmAddQuantity({
  required BuildContext context,
  required BuildContext dialogContext,
  required Product product,
  required SalesProvider sales,
  required String text,
}) {
  final quantity = _parseDouble(text);

  final error = _validateQuantity(product, quantity);

  if (error != null) {
    _showMessage(context, error);
    return;
  }

  sales.addProduct(product, quantity: quantity);

  Navigator.of(dialogContext).pop();

  _showMessage(
    context,
    '${product.name} adicionado: ${_formatNumber(quantity)} ${product.unit.label}.',
  );
}

Future<void> _openCartQuantityDialog(
  BuildContext context,
  SaleCartItem item,
) async {
  final sales = context.read<SalesProvider>();
  final product = item.product;

  final quantityController = TextEditingController(
    text: product.unit == ProductUnit.kg
        ? item.quantity.toStringAsFixed(3).replaceAll('.', ',')
        : item.quantity.toStringAsFixed(0),
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Alterar quantidade'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Estoque disponível: ${_formatQuantity(product.stockQuantity, product.unit)}',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nova quantidade (${product.unit.label})',
                  hintText:
                      product.unit == ProductUnit.kg ? 'Ex: 0,750' : 'Ex: 3',
                  suffixText: product.unit.label,
                ),
                onSubmitted: (_) {
                  _confirmUpdateCartQuantity(
                    context: context,
                    dialogContext: dialogContext,
                    product: product,
                    sales: sales,
                    text: quantityController.text,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              _confirmUpdateCartQuantity(
                context: context,
                dialogContext: dialogContext,
                product: product,
                sales: sales,
                text: quantityController.text,
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

void _confirmUpdateCartQuantity({
  required BuildContext context,
  required BuildContext dialogContext,
  required Product product,
  required SalesProvider sales,
  required String text,
}) {
  final quantity = _parseDouble(text);

  final error = _validateQuantity(product, quantity);

  if (error != null) {
    _showMessage(context, error);
    return;
  }

  sales.updateQuantity(product.id, quantity);

  Navigator.of(dialogContext).pop();

  _showMessage(
    context,
    'Quantidade de ${product.name}: ${_formatNumber(quantity)} ${product.unit.label}.',
  );
}

String? _validateQuantity(Product product, double quantity) {
  if (quantity <= 0) {
    return 'Informe uma quantidade maior que zero.';
  }

  if (quantity > product.stockQuantity) {
    return 'Quantidade maior que o estoque disponível.';
  }

  if (product.unit != ProductUnit.kg && quantity % 1 != 0) {
    return 'Para unidade ou pacote, use número inteiro.';
  }

  return null;
}

Future<Customer?> _selectCustomerForFiado(BuildContext context) async {
  return showDialog<Customer>(
    context: context,
    builder: (dialogContext) {
      return Consumer<CustomersProvider>(
        builder: (context, provider, _) {
          final customers = provider.customers;

          return AlertDialog(
            title: const Text('Selecionar cliente para fiado'),
            content: SizedBox(
              width: 640,
              height: 430,
              child: customers.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum cliente cadastrado. Cadastre um cliente na tela Fiado primeiro.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        final balance = provider.balanceForCustomer(customer.id);

                        return Card(
                          child: ListTile(
                            onTap: () {
                              Navigator.of(dialogContext).pop(customer);
                            },
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.wine900,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.beige100,
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              customer.phone == null || customer.phone!.isEmpty
                                  ? 'Sem telefone'
                                  : customer.phone!,
                            ),
                            trailing: Text(
                              _formatMoney(balance),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      );
    },
  );
}

List<Product> _filterProducts(List<Product> products, String searchTerm) {
  final term = searchTerm.trim().toLowerCase();

  final availableProducts = products.where((product) {
    return !product.isDeleted && product.stockQuantity > 0;
  }).toList();

  if (term.isEmpty) {
    return availableProducts;
  }

  return availableProducts.where((product) {
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

Product? _findByCodeOrName(List<Product> products, String value) {
  final term = value.trim().toLowerCase();

  if (term.isEmpty) return null;

  try {
    return products.firstWhere(
      (product) {
        return !product.isDeleted &&
            product.stockQuantity > 0 &&
            (product.code.toLowerCase() == term ||
                product.name.toLowerCase() == term);
      },
    );
  } catch (_) {
    return null;
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(message)),
    );
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}

String _formatQuantity(double value, ProductUnit unit) {
  if (unit == ProductUnit.kg) {
    return '${value.toStringAsFixed(3).replaceAll('.', ',')} ${unit.label}';
  }

  return '${value.toStringAsFixed(0)} ${unit.label}';
}

String _formatNumber(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(3).replaceAll('.', ',');
}

double _parseDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}
