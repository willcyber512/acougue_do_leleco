import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_provider.dart';

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
        final products = _filterProducts(
          inventory.products,
          sales.searchTerm,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BarcodeSearchField(
              value: sales.searchTerm,
              onChanged: sales.setSearchTerm,
              onSubmitted: (value) {
                final product = _findByCodeOrName(inventory.products, value);

                if (product == null) {
                  _showMessage(context, 'Produto não encontrado.');
                  return;
                }

                sales.addProduct(product);
              },
            ),
            const SizedBox(height: 18),
            Expanded(
              child: products.isEmpty
                  ? const _EmptyProducts()
                  : GridView.builder(
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 260,
                        mainAxisExtent: 155,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => sales.addProduct(product),
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
              const Spacer(),
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
              const SizedBox(height: 8),
              Text(
                _formatMoney(product.salePrice),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.wine700,
                    ),
              ),
            ],
          ),
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
                            ? () {
                                final ok = sales.finishSale();

                                if (!ok) {
                                  _showMessage(
                                    context,
                                    'Adicione produtos ao carrinho.',
                                  );
                                  return;
                                }

                                _showMessage(
                                  context,
                                  'Venda finalizada no modo teste.',
                                );
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

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final sales = context.read<SalesProvider>();
    final product = item.product as Product;
    final quantity = item.quantity as double;

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
                  '${_formatMoney(product.salePrice)} x ${_formatNumber(quantity)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => sales.decreaseQuantity(product.id),
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text(
            _formatNumber(quantity),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          IconButton(
            onPressed: () => sales.increaseQuantity(product.id),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          SizedBox(
            width: 78,
            child: Text(
              _formatMoney(item.subtotal as double),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
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
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Nenhum produto encontrado.'),
    );
  }
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
