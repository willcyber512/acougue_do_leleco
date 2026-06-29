import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/leleco_metric_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, _) {
        if (inventory.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = inventory.filteredProducts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 250,
                  child: LelecoMetricCard(
                    icon: Icons.inventory_2_rounded,
                    title: 'Produtos cadastrados',
                    value: inventory.totalProducts.toString(),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: LelecoMetricCard(
                    icon: Icons.warning_rounded,
                    title: 'Estoque baixo',
                    value: inventory.lowStockCount.toString(),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: LelecoMetricCard(
                    icon: Icons.star_rounded,
                    title: 'Favoritos',
                    value: inventory.favoriteCount.toString(),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: LelecoMetricCard(
                    icon: Icons.delete_rounded,
                    title: 'Na lixeira',
                    value: inventory.deletedProductsCount.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InventoryToolbar(inventory: inventory),
            if (inventory.lowStockCount > 0) ...[
              const SizedBox(height: 16),
              _LowStockWarning(count: inventory.lowStockCount),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: products.isEmpty
                  ? const _EmptyInventory()
                  : ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _ProductListCard(product: products[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _InventoryToolbar extends StatelessWidget {
  const _InventoryToolbar({required this.inventory});

  final InventoryProvider inventory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: inventory.setSearchTerm,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, código ou categoria...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 230,
          child: DropdownButtonFormField<String>(
            value: inventory.selectedCategory?.name ?? 'all',
            decoration: InputDecoration(
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Todas categorias'),
              ),
              ...ProductCategory.values.map(
                (category) => DropdownMenuItem(
                  value: category.name,
                  child: Text(category.label),
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null || value == 'all') {
                inventory.setCategory(null);
                return;
              }

              final category = ProductCategory.values.firstWhere(
                (item) => item.name == value,
              );

              inventory.setCategory(category);
            },
          ),
        ),
        const SizedBox(width: 14),
        OutlinedButton.icon(
          onPressed: () => _openTrashDialog(context),
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text('Lixeira (${inventory.deletedProductsCount})'),
        ),
        const SizedBox(width: 14),
        FilledButton.icon(
          onPressed: () => _openProductDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Novo produto'),
        ),
      ],
    );
  }
}

class _LowStockWarning extends StatelessWidget {
  const _LowStockWarning({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count produto(s) precisam de atenção no estoque.',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductListCard extends StatelessWidget {
  const _ProductListCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final inventory = context.read<InventoryProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.wine900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                product.favorite
                    ? Icons.star_rounded
                    : Icons.inventory_2_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Código ${product.code} • ${product.category.label}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preço',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(_formatMoney(product.salePrice)),
                ],
              ),
            ),
            SizedBox(
              width: 145,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estoque',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(_formatQuantity(product.stockQuantity, product.unit)),
                ],
              ),
            ),
            _StockChip(product: product),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Favoritar',
              onPressed: () => inventory.toggleFavorite(product.id),
              icon: Icon(
                product.favorite ? Icons.star_rounded : Icons.star_border_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Repor estoque',
              onPressed: () => _openReplenishDialog(context, product),
              icon: const Icon(Icons.add_box_rounded),
            ),
            IconButton(
              tooltip: 'Editar produto',
              onPressed: () => _openProductDialog(context, product: product),
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              tooltip: 'Mover para lixeira',
              onPressed: () => _moveProductToTrash(context, product),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final isLow = product.isLowStock;

    return Container(
      width: 116,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.warning.withOpacity(0.16)
            : AppColors.success.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isLow ? 'Baixo' : 'Ok',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isLow ? AppColors.warning : AppColors.success,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Nenhum produto encontrado.',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

Future<void> _openProductDialog(
  BuildContext context, {
  Product? product,
}) async {
  final inventory = context.read<InventoryProvider>();

  final codeController = TextEditingController(text: product?.code ?? '');
  final nameController = TextEditingController(text: product?.name ?? '');
  final salePriceController = TextEditingController(
    text: product == null ? '' : product.salePrice.toStringAsFixed(2),
  );
  final costPriceController = TextEditingController(
    text: product == null ? '' : product.costPrice.toStringAsFixed(2),
  );
  final stockController = TextEditingController(
    text: product == null ? '' : product.stockQuantity.toString(),
  );
  final minStockController = TextEditingController(
    text: product == null ? '' : product.minStock.toString(),
  );

  var category = product?.category ?? ProductCategory.bovina;
  var unit = product?.unit ?? ProductUnit.kg;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(product == null ? 'Novo produto' : 'Editar produto'),
            content: SizedBox(
              width: 640,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeController,
                            decoration: const InputDecoration(
                              labelText: 'Código interno',
                              hintText: 'Ex: 1001',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do produto',
                              hintText: 'Ex: Picanha',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                              setDialogState(() => category = value);
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
                              setDialogState(() => unit = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: salePriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Preço de venda',
                              hintText: 'Ex: 39,90',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: costPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Preço de custo',
                              hintText: 'Ex: 29,00',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Estoque atual',
                              hintText: 'Ex: 10',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: minStockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Estoque mínimo',
                              hintText: 'Ex: 5',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final code = codeController.text.trim();
                  final name = nameController.text.trim();

                  if (code.isEmpty || name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha código e nome do produto.'),
                      ),
                    );
                    return;
                  }

                  final now = DateTime.now();

                  final newProduct = Product(
                    id: product?.id ?? now.microsecondsSinceEpoch.toString(),
                    code: code,
                    name: name,
                    category: category,
                    unit: unit,
                    salePrice: _parseDouble(salePriceController.text),
                    costPrice: _parseDouble(costPriceController.text),
                    stockQuantity: _parseDouble(stockController.text),
                    minStock: _parseDouble(minStockController.text),
                    favorite: product?.favorite ?? false,
                    imagePath: product?.imagePath,
                    createdAt: product?.createdAt ?? now,
                    updatedAt: now,
                    deletedAt: product?.deletedAt,
                  );

                  if (product == null) {
                    inventory.addProduct(newProduct);
                  } else {
                    inventory.updateProduct(newProduct);
                  }

                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _openReplenishDialog(
  BuildContext context,
  Product product,
) async {
  final inventory = context.read<InventoryProvider>();
  final quantityController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Repor ${product.name}'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantidade para adicionar (${product.unit.label})',
              hintText: 'Ex: 10',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final quantity = _parseDouble(quantityController.text);
              inventory.replenishProduct(product.id, quantity);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Repor'),
          ),
        ],
      );
    },
  );
}

void _moveProductToTrash(BuildContext context, Product product) {
  final inventory = context.read<InventoryProvider>();

  inventory.moveProductToTrash(product.id);

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('${product.name} foi movido para a lixeira.'),
        action: SnackBarAction(
          label: 'DESFAZER',
          onPressed: () => inventory.restoreProduct(product.id),
        ),
      ),
    );
}

Future<void> _openTrashDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Consumer<InventoryProvider>(
        builder: (context, inventory, _) {
          final deletedProducts = inventory.deletedProducts;

          return AlertDialog(
            title: const Text('Lixeira de produtos'),
            content: SizedBox(
              width: 720,
              height: 430,
              child: deletedProducts.isEmpty
                  ? const Center(
                      child: Text('A lixeira está vazia.'),
                    )
                  : ListView.separated(
                      itemCount: deletedProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = deletedProducts[index];

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.wine900,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.beige100,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Código ${product.code} • Excluído em ${_formatDateTime(product.deletedAt)}',
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Restaurar',
                                  onPressed: () {
                                    inventory.restoreProduct(product.id);
                                  },
                                  icon: const Icon(Icons.restore_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Excluir definitivamente',
                                  onPressed: () async {
                                    final confirmed = await _confirmAction(
                                      context,
                                      title: 'Excluir definitivamente?',
                                      message:
                                          'O produto "${product.name}" será removido para sempre.',
                                    );

                                    if (!confirmed) return;

                                    inventory.deleteProductForever(product.id);
                                  },
                                  icon: const Icon(Icons.delete_forever_rounded),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: deletedProducts.isEmpty
                    ? null
                    : () async {
                        final confirmed = await _confirmAction(
                          context,
                          title: 'Esvaziar lixeira?',
                          message:
                              'Todos os produtos da lixeira serão removidos definitivamente.',
                        );

                        if (!confirmed) return;

                        inventory.emptyTrash();
                      },
                child: const Text('Esvaziar lixeira'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<bool> _confirmAction(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      );
    },
  );

  return result ?? false;
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

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';

  final day = _two(value.day);
  final month = _two(value.month);
  final year = value.year;
  final hour = _two(value.hour);
  final minute = _two(value.minute);

  return '$day/$month/$year $hour:$minute';
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}

double _parseDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}
