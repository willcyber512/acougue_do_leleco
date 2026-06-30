import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/customer.dart';
import '../../models/payment_method.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../models/sale_cart_item.dart';
import '../../providers/customers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/leleco_logo.dart';
import '../../widgets/sale_receipt_dialog.dart';

class OperationModeScreen extends StatefulWidget {
  const OperationModeScreen({super.key});

  @override
  State<OperationModeScreen> createState() => _OperationModeScreenState();
}

class _OperationModeScreenState extends State<OperationModeScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchTerm = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<InventoryProvider, SalesProvider>(
      builder: (context, inventory, sales, _) {
        final products = _filterProducts(inventory.products, searchTerm);

        return Scaffold(
          body: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _OperationHeader(
                    searchController: searchController,
                    onSearchChanged: (value) {
                      setState(() => searchTerm = value);
                    },
                    onExit: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: _ProductsFastPanel(products: products),
                        ),
                        const SizedBox(width: 18),
                        const Expanded(
                          flex: 4,
                          child: _FastCartPanel(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OperationHeader extends StatelessWidget {
  const _OperationHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.onExit,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const LelecoLogo(size: 58),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modo Balcão',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Text(
                'Tela rápida para venda no atendimento',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 460,
          child: TextField(
            controller: searchController,
            autofocus: true,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar produto ou código...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onExit,
          icon: const Icon(Icons.close_rounded),
          label: const Text('Sair'),
        ),
      ],
    );
  }
}

class _ProductsFastPanel extends StatelessWidget {
  const _ProductsFastPanel({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Card(
        child: Center(
          child: Text('Nenhum produto encontrado.'),
        ),
      );
    }

    return GridView.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 210,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        return _FastProductCard(product: products[index]);
      },
    );
  }
}

class _FastProductCard extends StatelessWidget {
  const _FastProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final sales = context.read<SalesProvider>();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          sales.addProduct(product);
          _showMessage(
            context,
            '${product.name} adicionado com 1 ${product.unit.label}.',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ProductImage(product: product),
                  const Spacer(),
                  if (product.favorite)
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.warning,
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
                'Cód. ${product.code}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                _formatQuantity(product.stockQuantity, product.unit),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color:
                      product.isLowStock ? AppColors.warning : AppColors.success,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatMoney(product.salePrice),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.wine700,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => _openFastQuantityDialog(context, product),
                    child: const Text('Qtd'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => sales.addProduct(product),
                    child: const Text('+1'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imagePath = product.imagePath?.trim() ?? '';

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.wine900.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath.isEmpty
          ? const Icon(
              Icons.set_meal_rounded,
              color: AppColors.wine700,
            )
          : _ImagePreview(imagePath: imagePath),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.set_meal_rounded,
            color: AppColors.wine700,
          );
        },
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return const Icon(
          Icons.set_meal_rounded,
          color: AppColors.wine700,
        );
      },
    );
  }
}

class _FastCartPanel extends StatelessWidget {
  const _FastCartPanel();

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
                      'Carrinho rápido',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${sales.items.length}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: sales.items.isEmpty
                      ? const Center(
                          child: Text('Toque em um produto para adicionar.'),
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
                const SizedBox(height: 14),
                _PaymentSelector(
                  selected: sales.paymentMethod,
                  onChanged: sales.setPaymentMethod,
                ),
                const SizedBox(height: 14),
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
                            ? () => _finishFastSale(context)
                            : null,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Finalizar venda'),
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
                  const SizedBox(height: 3),
                  Text(
                    '${_formatNumber(item.quantity)} ${product.unit.label} x ${_formatMoney(product.salePrice)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
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
          SizedBox(
            width: 78,
            child: Text(
              _formatMoney(item.subtotal),
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
        labelText: 'Pagamento',
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
            'Total',
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

Future<void> _openFastQuantityDialog(
  BuildContext context,
  Product product,
) async {
  final sales = context.read<SalesProvider>();

  final controller = TextEditingController(
    text: product.unit == ProductUnit.kg ? '1,000' : '1',
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Adicionar ${product.name}'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantidade (${product.unit.label})',
              hintText: product.unit == ProductUnit.kg ? 'Ex: 1,250' : 'Ex: 2',
              suffixText: product.unit.label,
            ),
            onSubmitted: (_) {
              _confirmAddQuantity(
                context: context,
                dialogContext: dialogContext,
                product: product,
                sales: sales,
                text: controller.text,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              _confirmAddQuantity(
                context: context,
                dialogContext: dialogContext,
                product: product,
                sales: sales,
                text: controller.text,
              );
            },
            child: const Text('Adicionar'),
          ),
        ],
      );
    },
  );
}

Future<void> _openCartQuantityDialog(
  BuildContext context,
  SaleCartItem item,
) async {
  final sales = context.read<SalesProvider>();
  final product = item.product;

  final controller = TextEditingController(
    text: product.unit == ProductUnit.kg
        ? item.quantity.toStringAsFixed(3).replaceAll('.', ',')
        : item.quantity.toStringAsFixed(0),
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Alterar quantidade'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantidade (${product.unit.label})',
              suffixText: product.unit.label,
            ),
            onSubmitted: (_) {
              _confirmUpdateQuantity(
                context: context,
                dialogContext: dialogContext,
                product: product,
                sales: sales,
                text: controller.text,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              _confirmUpdateQuantity(
                context: context,
                dialogContext: dialogContext,
                product: product,
                sales: sales,
                text: controller.text,
              );
            },
            child: const Text('Salvar'),
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
    '${product.name}: ${_formatNumber(quantity)} ${product.unit.label}.',
  );
}

void _confirmUpdateQuantity({
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
}

Future<void> _finishFastSale(BuildContext context) async {
  final sales = context.read<SalesProvider>();
  final inventory = context.read<InventoryProvider>();
  final customersProvider = context.read<CustomersProvider>();

  Customer? selectedCustomer;

  if (sales.paymentMethod == PaymentMethod.fiado) {
    selectedCustomer = await _selectCustomerForFiado(context);

    if (selectedCustomer == null) return;
  }

  final validationError = inventory.validateSaleItems(sales.items);

  if (validationError != null) {
    _showMessage(context, validationError);
    return;
  }

  final sale = sales.createSaleRecord(
    customerId: selectedCustomer?.id,
    customerName: selectedCustomer?.name,
  );

  if (sale == null) {
    _showMessage(context, 'Adicione produtos ao carrinho.');
    return;
  }

  final stockOk = inventory.deductSaleRecord(sale);

  if (!stockOk) {
    _showMessage(context, 'Não foi possível baixar o estoque.');
    return;
  }

  sales.completeSale(sale);

  if (sale.paymentMethod == PaymentMethod.fiado && selectedCustomer != null) {
    customersProvider.registerPurchase(sale, selectedCustomer);
  }

  _showMessage(context, 'Venda #${sale.shortId} finalizada.');

  if (!context.mounted) return;

  await showSaleReceiptDialog(context, sale);
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
                        'Nenhum cliente cadastrado. Cadastre na tela Fiado primeiro.',
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

  availableProducts.sort((a, b) {
    if (a.favorite != b.favorite) {
      return a.favorite ? -1 : 1;
    }

    if (a.isLowStock != b.isLowStock) {
      return a.isLowStock ? -1 : 1;
    }

    return a.name.compareTo(b.name);
  });

  if (term.isEmpty) return availableProducts;

  return availableProducts.where((product) {
    return product.name.toLowerCase().contains(term) ||
        product.code.toLowerCase().contains(term) ||
        product.category.label.toLowerCase().contains(term);
  }).toList();
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
