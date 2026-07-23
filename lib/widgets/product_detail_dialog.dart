import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/inventory_event.dart';
import '../models/inventory_loss.dart';
import '../models/payment_method.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/product_unit.dart';
import '../models/sale.dart';
import '../providers/inventory_provider.dart';
import '../providers/sales_provider.dart';

Future<void> showProductDetailDialog(
  BuildContext context,
  Product product,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return ProductDetailDialog(product: product);
    },
  );
}

class ProductDetailDialog extends StatelessWidget {
  const ProductDetailDialog({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Consumer2<InventoryProvider, SalesProvider>(
      builder: (context, inventory, sales, _) {
        final events = inventory.eventsForProduct(product.id);
        final losses = inventory.lossesForProduct(product.id);
        final relatedSales = sales.sales.where((sale) {
          return sale.items.any((item) => item.productId == product.id);
        }).toList();

        return AlertDialog(
          title: Text('Ficha do produto'),
          content: SizedBox(
            width: 920,
            height: 620,
            child: ListView(
              children: [
                _ProductHeader(product: product),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _InfoPanel(
                        title: 'Dados principais',
                        icon: Icons.info_rounded,
                        children: [
                          _InfoLine(label: 'Código', value: product.code),
                          _InfoLine(label: 'Nome', value: product.name),
                          _InfoLine(
                            label: 'Categoria',
                            value: product.category.label,
                          ),
                          _InfoLine(
                            label: 'Unidade',
                            value: product.unit.label,
                          ),
                          _InfoLine(
                            label: 'Favorito',
                            value: product.favorite ? 'Sim' : 'Não',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _InfoPanel(
                        title: 'Preço e estoque',
                        icon: Icons.inventory_2_rounded,
                        children: [
                          _InfoLine(
                            label: 'Venda ao cliente',
                            value: _formatMoney(product.salePrice),
                          ),
                          _InfoLine(
                            label: 'Custo do açougue',
                            value: _formatMoney(product.costPrice),
                          ),
                          _InfoLine(
                            label: 'Estoque',
                            value: _formatQuantity(
                              product.stockQuantity,
                              product.unit,
                            ),
                          ),
                          _InfoLine(
                            label: 'Mínimo para aviso',
                            value: _formatQuantity(
                              product.minStock,
                              product.unit,
                            ),
                          ),
                          _InfoLine(
                            label: 'Situação',
                            value: product.isLowStock ? 'Estoque baixo' : 'Ok',
                            valueColor: product.isLowStock
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _HistoryPanel(events: events)),
                    const SizedBox(width: 14),
                    Expanded(child: _LossPanel(losses: losses)),
                  ],
                ),
                const SizedBox(height: 14),
                _SalesPanel(sales: relatedSales, productId: product.id),
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

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _ProductImage(product: product),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Código ${product.code} • ${product.category.label}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Badge(
                        text: _formatMoney(product.salePrice),
                        color: AppColors.wine700,
                      ),
                      _Badge(
                        text: _formatQuantity(
                          product.stockQuantity,
                          product.unit,
                        ),
                        color: product.isLowStock
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      if (product.favorite)
                        const _Badge(
                          text: 'Favorito',
                          color: AppColors.warning,
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

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imagePath = product.imagePath?.trim() ?? '';

    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.wine900.withOpacity(0.12),
        borderRadius: BorderRadius.circular(26),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath.isEmpty
          ? const _ImagePlaceholder()
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
        errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.set_meal_rounded, size: 58, color: AppColors.wine700),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 230,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.wine700),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(width: 92, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.events});

  final List<InventoryEvent> events;

  @override
  Widget build(BuildContext context) {
    return _ListPanel(
      title: 'Histórico',
      icon: Icons.history_rounded,
      emptyText: 'Nenhum histórico encontrado.',
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        return _SmallTile(
          icon: Icons.history_rounded,
          color: AppColors.wine900,
          title: event.type.label,
          subtitle: '${event.description}\n${_formatDateTime(event.createdAt)}',
          trailing: event.quantity == null
              ? null
              : _formatNumber(event.quantity!),
        );
      },
    );
  }
}

class _LossPanel extends StatelessWidget {
  const _LossPanel({required this.losses});

  final List<InventoryLoss> losses;

  @override
  Widget build(BuildContext context) {
    return _ListPanel(
      title: 'Perdas',
      icon: Icons.remove_circle_outline_rounded,
      emptyText: 'Nenhuma perda registrada.',
      itemCount: losses.length,
      itemBuilder: (context, index) {
        final loss = losses[index];

        return _SmallTile(
          icon: Icons.remove_circle_outline_rounded,
          color: AppColors.warning,
          title: loss.type.label,
          subtitle:
              '${_formatNumber(loss.quantity)} ${loss.unitLabel} • ${loss.reason}\n${_formatDateTime(loss.createdAt)}',
          trailing: _formatMoney(loss.estimatedValue),
        );
      },
    );
  }
}

class _SalesPanel extends StatelessWidget {
  const _SalesPanel({required this.sales, required this.productId});

  final List<SaleRecord> sales;
  final String productId;

  @override
  Widget build(BuildContext context) {
    return _ListPanel(
      title: 'Vendas relacionadas',
      icon: Icons.receipt_long_rounded,
      emptyText: 'Nenhuma venda encontrada para este produto.',
      height: 300,
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];

        final relatedItems = sale.items.where((item) {
          return item.productId == productId;
        }).toList();

        final quantity = relatedItems.fold(
          0.0,
          (total, item) => total + item.quantity,
        );

        final total = relatedItems.fold(
          0.0,
          (sum, item) => sum + item.subtotal,
        );

        return _SmallTile(
          icon: sale.isCanceled
              ? Icons.cancel_rounded
              : Icons.point_of_sale_rounded,
          color: sale.isCanceled ? AppColors.danger : AppColors.wine900,
          title: 'Venda #${sale.shortId}',
          subtitle:
              '${_formatDateTime(sale.createdAt)} • ${sale.paymentMethod.label}${sale.customerName == null ? '' : ' • ${sale.customerName}'}',
          trailing: '${_formatNumber(quantity)} • ${_formatMoney(total)}',
        );
      },
    );
  }
}

class _ListPanel extends StatelessWidget {
  const _ListPanel({
    required this.title,
    required this.icon,
    required this.emptyText,
    required this.itemCount,
    required this.itemBuilder,
    this.height = 330,
  });

  final String title;
  final IconData icon;
  final String emptyText;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: height,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.wine700),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  itemCount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: itemCount == 0
                  ? Center(child: Text(emptyText))
                  : ListView.separated(
                      itemCount: itemCount,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: itemBuilder,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallTile extends StatelessWidget {
  const _SmallTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.beige100, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Text(
              trailing!,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
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

String _formatNumber(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(3).replaceAll('.', ',');
}

String _formatDateTime(DateTime value) {
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
