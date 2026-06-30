import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/product_unit.dart';
import '../providers/inventory_provider.dart';
import 'product_detail_dialog.dart';

Future<void> showInventoryCategoriesDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return const InventoryCategoriesDialog();
    },
  );
}

class InventoryCategoriesDialog extends StatefulWidget {
  const InventoryCategoriesDialog({super.key});

  @override
  State<InventoryCategoriesDialog> createState() =>
      _InventoryCategoriesDialogState();
}

class _InventoryCategoriesDialogState extends State<InventoryCategoriesDialog> {
  ProductCategory? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, _) {
        final products = inventory.products.where((product) {
          return !product.isDeleted;
        }).toList();

        final visibleProducts = selectedCategory == null
            ? products
            : products.where((product) {
                return product.category == selectedCategory;
              }).toList();

        visibleProducts.sort((a, b) {
          if (a.isLowStock != b.isLowStock) {
            return a.isLowStock ? -1 : 1;
          }

          return a.name.compareTo(b.name);
        });

        return AlertDialog(
          title: const Text('Estoque por categorias'),
          content: SizedBox(
            width: 980,
            height: 640,
            child: Row(
              children: [
                SizedBox(
                  width: 320,
                  child: _CategoryColumn(
                    products: products,
                    selectedCategory: selectedCategory,
                    onSelect: (category) {
                      setState(() => selectedCategory = category);
                    },
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _ProductsByCategoryPanel(
                    selectedCategory: selectedCategory,
                    products: visibleProducts,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryColumn extends StatelessWidget {
  const _CategoryColumn({
    required this.products,
    required this.selectedCategory,
    required this.onSelect,
  });

  final List<Product> products;
  final ProductCategory? selectedCategory;
  final ValueChanged<ProductCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    final totalStats = _CategoryStats.fromProducts(products);

    return Column(
      children: [
        _CategoryCard(
          title: 'Todas',
          subtitle: 'Visão geral do estoque',
          icon: Icons.inventory_2_rounded,
          selected: selectedCategory == null,
          stats: totalStats,
          onTap: () => onSelect(null),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: ProductCategory.values.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = ProductCategory.values[index];

              final categoryProducts = products.where((product) {
                return product.category == category;
              }).toList();

              return _CategoryCard(
                title: category.label,
                subtitle: '${categoryProducts.length} produto(s)',
                icon: _categoryIcon(category),
                selected: selectedCategory == category,
                stats: _CategoryStats.fromProducts(categoryProducts),
                onTap: () => onSelect(category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.stats,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final _CategoryStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? AppColors.wine900 : null;
    final textColor = selected ? AppColors.beige100 : null;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.beige100.withOpacity(0.18)
                      : AppColors.wine900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: AppColors.beige100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: selected
                            ? AppColors.beige100.withOpacity(0.75)
                            : null,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniStat(
                          text: '${stats.totalProducts} itens',
                          selected: selected,
                        ),
                        _MiniStat(
                          text: '${stats.lowStockProducts} baixo',
                          selected: selected,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.text,
    required this.selected,
  });

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.beige100.withOpacity(0.16)
            : AppColors.wine900.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? AppColors.beige100 : AppColors.wine900,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProductsByCategoryPanel extends StatelessWidget {
  const _ProductsByCategoryPanel({
    required this.selectedCategory,
    required this.products,
  });

  final ProductCategory? selectedCategory;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final stats = _CategoryStats.fromProducts(products);
    final title = selectedCategory == null ? 'Todas' : selectedCategory!.label;

    return Column(
      children: [
        _CategorySummaryHeader(
          title: title,
          stats: stats,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: products.isEmpty
              ? const Center(
                  child: Text('Nenhum produto encontrado nesta categoria.'),
                )
              : GridView.builder(
                  itemCount: products.length,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 330,
                    mainAxisExtent: 185,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    return _CategoryProductCard(product: products[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class _CategorySummaryHeader extends StatelessWidget {
  const _CategorySummaryHeader({
    required this.title,
    required this.stats,
  });

  final String title;
  final _CategoryStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.wine900,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.category_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.totalProducts} produto(s) • ${stats.lowStockProducts} com estoque baixo',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _HeaderStat(
              label: 'Valor em estoque',
              value: _formatMoney(stats.stockSaleValue),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.wine900.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _CategoryProductCard extends StatelessWidget {
  const _CategoryProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final stockColor = product.isLowStock ? AppColors.warning : AppColors.success;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _ProductThumb(product: product),
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
                  const SizedBox(height: 4),
                  Text(
                    'Código ${product.code}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _StockBadge(
                    text: _formatQuantity(product.stockQuantity, product.unit),
                    color: stockColor,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatMoney(product.salePrice),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.wine700,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          showProductDetailDialog(context, product);
                        },
                        child: const Text('Ficha'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imagePath = product.imagePath?.trim() ?? '';

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.wine900.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath.isEmpty
          ? const Icon(
              Icons.set_meal_rounded,
              color: AppColors.wine700,
              size: 34,
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
            size: 34,
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
          size: 34,
        );
      },
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CategoryStats {
  const _CategoryStats({
    required this.totalProducts,
    required this.lowStockProducts,
    required this.stockSaleValue,
  });

  final int totalProducts;
  final int lowStockProducts;
  final double stockSaleValue;

  factory _CategoryStats.fromProducts(List<Product> products) {
    return _CategoryStats(
      totalProducts: products.length,
      lowStockProducts: products.where((product) => product.isLowStock).length,
      stockSaleValue: products.fold(
        0,
        (total, product) => total + (product.stockQuantity * product.salePrice),
      ),
    );
  }
}

IconData _categoryIcon(ProductCategory category) {
  switch (category.name) {
    case 'bovina':
    case 'beef':
      return Icons.set_meal_rounded;

    case 'suina':
    case 'suína':
    case 'pork':
      return Icons.lunch_dining_rounded;

    case 'frango':
    case 'ave':
    case 'aves':
    case 'chicken':
      return Icons.egg_alt_rounded;

    case 'linguica':
    case 'linguiça':
    case 'linguicas':
    case 'linguiças':
    case 'embutidos':
    case 'sausage':
      return Icons.local_dining_rounded;

    default:
      return Icons.category_rounded;
  }
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
