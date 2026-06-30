import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/customer.dart';
import '../../models/inventory_loss.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../models/sale.dart';
import '../../providers/customers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/leleco_metric_card.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<InventoryProvider, SalesProvider, CustomersProvider>(
      builder: (context, inventory, sales, customers, _) {
        final lowStockProducts = inventory.products
            .where((product) => product.isLowStock)
            .toList()
          ..sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));

        final debtCustomers = customers.customers.where((customer) {
          return customers.balanceForCustomer(customer.id) > 0.009;
        }).toList()
          ..sort(
            (a, b) => customers
                .balanceForCustomer(b.id)
                .compareTo(customers.balanceForCustomer(a.id)),
          );

        final canceledSales = sales.sales
            .where((sale) => sale.isCanceled)
            .toList()
          ..sort((a, b) {
            final aDate = a.canceledAt ?? a.createdAt;
            final bDate = b.canceledAt ?? b.createdAt;
            return bDate.compareTo(aDate);
          });

        final losses = inventory.losses.take(20).toList();

        final totalAlerts = lowStockProducts.length +
            debtCustomers.length +
            canceledSales.length +
            losses.length;

        return ListView(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.notifications_rounded,
                    title: 'Alertas totais',
                    value: totalAlerts.toString(),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.warning_rounded,
                    title: 'Estoque baixo',
                    value: lowStockProducts.length.toString(),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.money_off_rounded,
                    title: 'Fiado em aberto',
                    value: _formatMoney(customers.totalOpenCredit),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.cancel_rounded,
                    title: 'Vendas canceladas',
                    value: canceledSales.length.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _AlertHeader(totalAlerts: totalAlerts),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LowStockSection(products: lowStockProducts),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DebtSection(
                    customers: debtCustomers,
                    provider: customers,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CanceledSalesSection(sales: canceledSales),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _LossesSection(losses: losses),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AlertHeader extends StatelessWidget {
  const _AlertHeader({required this.totalAlerts});

  final int totalAlerts;

  @override
  Widget build(BuildContext context) {
    final hasAlerts = totalAlerts > 0;

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: hasAlerts ? AppColors.warning : AppColors.success,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                hasAlerts
                    ? Icons.notifications_active_rounded
                    : Icons.check_circle_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                hasAlerts
                    ? 'Existem pontos que precisam de atenção no sistema.'
                    : 'Tudo certo. Nenhum alerta importante no momento.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LowStockSection extends StatelessWidget {
  const _LowStockSection({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return _AlertSection(
      title: 'Estoque baixo',
      icon: Icons.warning_rounded,
      emptyText: 'Nenhum produto com estoque baixo.',
      children: products.take(10).map((product) {
        return _AlertTile(
          icon: Icons.inventory_2_rounded,
          color: AppColors.warning,
          title: product.name,
          subtitle:
              '${product.category.label} • mínimo ${_formatQuantity(product.minStock, product.unit)}',
          trailing: _formatQuantity(product.stockQuantity, product.unit),
        );
      }).toList(),
    );
  }
}

class _DebtSection extends StatelessWidget {
  const _DebtSection({
    required this.customers,
    required this.provider,
  });

  final List<Customer> customers;
  final CustomersProvider provider;

  @override
  Widget build(BuildContext context) {
    return _AlertSection(
      title: 'Fiado em aberto',
      icon: Icons.money_off_rounded,
      emptyText: 'Nenhum cliente devendo.',
      children: customers.take(10).map((customer) {
        final balance = provider.balanceForCustomer(customer.id);

        return _AlertTile(
          icon: Icons.person_rounded,
          color: AppColors.warning,
          title: customer.name,
          subtitle: customer.phone == null || customer.phone!.isEmpty
              ? 'Sem telefone cadastrado'
              : customer.phone!,
          trailing: _formatMoney(balance),
        );
      }).toList(),
    );
  }
}

class _CanceledSalesSection extends StatelessWidget {
  const _CanceledSalesSection({required this.sales});

  final List<SaleRecord> sales;

  @override
  Widget build(BuildContext context) {
    return _AlertSection(
      title: 'Vendas canceladas',
      icon: Icons.cancel_rounded,
      emptyText: 'Nenhuma venda cancelada.',
      children: sales.take(10).map((sale) {
        return _AlertTile(
          icon: Icons.receipt_long_rounded,
          color: AppColors.danger,
          title: 'Venda #${sale.shortId}',
          subtitle:
              '${_formatDateTime(sale.canceledAt ?? sale.createdAt)} • ${sale.cancelReason ?? 'Cancelamento manual'}',
          trailing: _formatMoney(sale.total),
        );
      }).toList(),
    );
  }
}

class _LossesSection extends StatelessWidget {
  const _LossesSection({required this.losses});

  final List<InventoryLoss> losses;

  @override
  Widget build(BuildContext context) {
    return _AlertSection(
      title: 'Perdas registradas',
      icon: Icons.remove_circle_rounded,
      emptyText: 'Nenhuma perda registrada.',
      children: losses.map((loss) {
        return _AlertTile(
          icon: Icons.remove_circle_outline_rounded,
          color: AppColors.warning,
          title: loss.productName,
          subtitle:
              '${loss.type.label} • ${_formatNumber(loss.quantity)} ${loss.unitLabel} • ${loss.reason}',
          trailing: _formatMoney(loss.estimatedValue),
        );
      }).toList(),
    );
  }
}

class _AlertSection extends StatelessWidget {
  const _AlertSection({
    required this.title,
    required this.icon,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final IconData icon;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 380,
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
                _CountBadge(count: children.length),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: children.isEmpty
                  ? Center(child: Text(emptyText))
                  : ListView.separated(
                      itemCount: children.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => children[index],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailing;

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
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final hasItems = count > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: hasItems
            ? AppColors.warning.withOpacity(0.16)
            : AppColors.success.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          color: hasItems ? AppColors.warning : AppColors.success,
          fontWeight: FontWeight.w900,
        ),
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
  final hour = _two(value.hour);
  final minute = _two(value.minute);

  return '$day/$month $hour:$minute';
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}
