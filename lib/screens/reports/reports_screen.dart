import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/payment_method.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../models/sale.dart';
import '../../providers/customers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/leleco_metric_card.dart';

enum _ReportPeriod {
  today,
  all,
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportPeriod period = _ReportPeriod.today;

  @override
  Widget build(BuildContext context) {
    return Consumer3<InventoryProvider, SalesProvider, CustomersProvider>(
      builder: (context, inventory, sales, customers, _) {
        final visibleSales =
            period == _ReportPeriod.today ? sales.todaySales : sales.sales;

        final validSales =
            visibleSales.where((sale) => !sale.isCanceled).toList();
        final canceledCount =
            visibleSales.where((sale) => sale.isCanceled).length;

        final revenue = validSales.fold(
          0.0,
          (total, sale) => total + sale.total,
        );

        final averageTicket =
            validSales.isEmpty ? 0.0 : revenue / validSales.length;

        final topProducts = _topProducts(validSales);
        final lowStockProducts =
            inventory.products.where((product) => product.isLowStock).toList()
              ..sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));

        return ListView(
          children: [
            _ReportsToolbar(
              period: period,
              onChanged: (value) => setState(() => period = value),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.payments_rounded,
                    title: period == _ReportPeriod.today
                        ? 'Faturamento hoje'
                        : 'Faturamento total',
                    value: _formatMoney(revenue),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Vendas válidas',
                    value: validSales.length.toString(),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Ticket médio',
                    value: _formatMoney(averageTicket),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.cancel_rounded,
                    title: 'Canceladas',
                    value: canceledCount.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 255,
              child: Row(
                children: [
                  Expanded(
                    child: _ReportPanel(
                      title: 'Formas de pagamento',
                      icon: Icons.credit_card_rounded,
                      child: Column(
                        children: [
                          _InfoLine(
                            label: 'Dinheiro',
                            value: _formatMoney(
                              _sumByMethod(
                                validSales,
                                PaymentMethod.dinheiro,
                              ),
                            ),
                          ),
                          _InfoLine(
                            label: 'Pix',
                            value: _formatMoney(
                              _sumByMethod(validSales, PaymentMethod.pix),
                            ),
                          ),
                          _InfoLine(
                            label: 'Débito',
                            value: _formatMoney(
                              _sumByMethod(validSales, PaymentMethod.debito),
                            ),
                          ),
                          _InfoLine(
                            label: 'Crédito',
                            value: _formatMoney(
                              _sumByMethod(validSales, PaymentMethod.credito),
                            ),
                          ),
                          _InfoLine(
                            label: 'Fiado',
                            value: _formatMoney(
                              _sumByMethod(validSales, PaymentMethod.fiado),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ReportPanel(
                      title: 'Resumo geral',
                      icon: Icons.dashboard_customize_rounded,
                      child: Column(
                        children: [
                          _InfoLine(
                            label: 'Fiado aberto',
                            value: _formatMoney(customers.totalOpenCredit),
                          ),
                          _InfoLine(
                            label: 'Clientes devendo',
                            value: customers.customersWithDebt.toString(),
                          ),
                          _InfoLine(
                            label: 'Produtos no estoque',
                            value: inventory.totalProducts.toString(),
                          ),
                          _InfoLine(
                            label: 'Valor em estoque',
                            value: _formatMoney(inventory.stockValue),
                          ),
                          _InfoLine(
                            label: 'Perdas registradas',
                            value: _formatMoney(inventory.lossesEstimatedValue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 430,
              child: Row(
                children: [
                  Expanded(
                    child: _TopProductsPanel(products: topProducts),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LowStockPanel(products: lowStockProducts),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RecentSalesPanel(sales: validSales),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReportsToolbar extends StatelessWidget {
  const _ReportsToolbar({
    required this.period,
    required this.onChanged,
  });

  final _ReportPeriod period;
  final ValueChanged<_ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SegmentedButton<_ReportPeriod>(
          segments: const [
            ButtonSegment(
              value: _ReportPeriod.today,
              icon: Icon(Icons.today_rounded),
              label: Text('Hoje'),
            ),
            ButtonSegment(
              value: _ReportPeriod.all,
              icon: Icon(Icons.list_alt_rounded),
              label: Text('Tudo'),
            ),
          ],
          selected: {period},
          onSelectionChanged: (values) => onChanged(values.first),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.wine900.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Relatórios rápidos para acompanhar o açougue',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ReportPanel extends StatelessWidget {
  const _ReportPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
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
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _TopProductsPanel extends StatelessWidget {
  const _TopProductsPanel({required this.products});

  final List<_ProductSalesSummary> products;

  @override
  Widget build(BuildContext context) {
    return _ListPanel(
      title: 'Mais vendidos',
      icon: Icons.local_fire_department_rounded,
      emptyText: 'Nenhuma venda no período.',
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        return _SmallListItem(
          icon: Icons.shopping_basket_rounded,
          title: product.name,
          subtitle:
              'Código ${product.code} • ${_formatNumber(product.quantity)} vendido(s)',
          trailing: _formatMoney(product.total),
        );
      },
    );
  }
}

class _LowStockPanel extends StatelessWidget {
  const _LowStockPanel({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return _ListPanel(
      title: 'Estoque baixo',
      icon: Icons.warning_rounded,
      emptyText: 'Nenhum produto com estoque baixo.',
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        return _SmallListItem(
          icon: Icons.inventory_2_rounded,
          title: product.name,
          subtitle:
              '${product.category.label} • mínimo ${_formatQuantity(product.minStock, product.unit)}',
          trailing: _formatQuantity(product.stockQuantity, product.unit),
        );
      },
    );
  }
}

class _RecentSalesPanel extends StatelessWidget {
  const _RecentSalesPanel({required this.sales});

  final List<SaleRecord> sales;

  @override
  Widget build(BuildContext context) {
    final recent = sales.take(10).toList();

    return _ListPanel(
      title: 'Últimas vendas',
      icon: Icons.receipt_long_rounded,
      emptyText: 'Nenhuma venda no período.',
      itemCount: recent.length,
      itemBuilder: (context, index) {
        final sale = recent[index];

        return _SmallListItem(
          icon: Icons.point_of_sale_rounded,
          title: 'Venda #${sale.shortId}',
          subtitle:
              '${_formatDateTime(sale.createdAt)} • ${sale.paymentMethod.label}',
          trailing: _formatMoney(sale.total),
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
  });

  final String title;
  final IconData icon;
  final String emptyText;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
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

class _SmallListItem extends StatelessWidget {
  const _SmallListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
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
              color: AppColors.wine900,
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

class _ProductSalesSummary {
  const _ProductSalesSummary({
    required this.code,
    required this.name,
    required this.quantity,
    required this.total,
  });

  final String code;
  final String name;
  final double quantity;
  final double total;
}

List<_ProductSalesSummary> _topProducts(List<SaleRecord> sales) {
  final Map<String, _ProductSalesSummary> map = {};

  for (final sale in sales) {
    for (final item in sale.items) {
      final current = map[item.productId];

      if (current == null) {
        map[item.productId] = _ProductSalesSummary(
          code: item.productCode,
          name: item.productName,
          quantity: item.quantity,
          total: item.subtotal,
        );
      } else {
        map[item.productId] = _ProductSalesSummary(
          code: current.code,
          name: current.name,
          quantity: current.quantity + item.quantity,
          total: current.total + item.subtotal,
        );
      }
    }
  }

  final result = map.values.toList();
  result.sort((a, b) => b.total.compareTo(a.total));

  return result.take(10).toList();
}

double _sumByMethod(List<SaleRecord> sales, PaymentMethod method) {
  return sales
      .where((sale) => sale.paymentMethod == method)
      .fold(0.0, (total, sale) => total + sale.total);
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
