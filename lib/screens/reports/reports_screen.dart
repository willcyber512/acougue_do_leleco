import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/payment_method.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../providers/customers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_provider.dart';

enum _ReportSection {
  overview,
  productSales,
  categorySales,
  payments,
  lowStock,
  credit,
  detailedSales,
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportSection selected = _ReportSection.overview;

  @override
  Widget build(BuildContext context) {
    return Consumer3<SalesProvider, InventoryProvider, CustomersProvider>(
      builder: (context, sales, inventory, customers, _) {
        final todaySales = sales.todaySales;
        final revenue = sales.todayRevenue;
        final averageTicket =
            todaySales.isEmpty ? 0.0 : revenue / todaySales.length;

        final paymentTotals = _paymentTotals(todaySales);
        final productTotals = _productTotals(todaySales);
        final categoryTotals = _categoryTotals(
          todaySales,
          inventory.products,
        );

        final lowStock = inventory.products.where((product) {
          return !product.isDeleted && product.isLowStock;
        }).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReportsHero(
                salesCount: todaySales.length,
                revenue: revenue,
                averageTicket: averageTicket,
                openCredit: customers.totalOpenCredit,
              ),
              const SizedBox(height: 14),
              _ReportMenu(
                selected: selected,
                onSelected: (value) {
                  setState(() => selected = value);
                },
              ),
              const SizedBox(height: 14),
              _SelectedReportContent(
                selected: selected,
                todaySales: todaySales,
                revenue: revenue,
                averageTicket: averageTicket,
                paymentTotals: paymentTotals,
                productTotals: productTotals,
                categoryTotals: categoryTotals,
                lowStock: lowStock,
                openCredit: customers.totalOpenCredit,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportsHero extends StatelessWidget {
  const _ReportsHero({
    required this.salesCount,
    required this.revenue,
    required this.averageTicket,
    required this.openCredit,
  });

  final int salesCount;
  final double revenue;
  final double averageTicket;
  final double openCredit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.wine900,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.beige100,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Central de relatórios',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Escolha abaixo o tipo de relatório que deseja visualizar.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SmallMetric(
                      width: compact ? 160 : 190,
                      icon: Icons.point_of_sale_rounded,
                      label: 'Vendas hoje',
                      value: salesCount.toString(),
                    ),
                    _SmallMetric(
                      width: compact ? 160 : 190,
                      icon: Icons.payments_rounded,
                      label: 'Faturamento',
                      value: _formatMoney(revenue),
                    ),
                    _SmallMetric(
                      width: compact ? 160 : 190,
                      icon: Icons.receipt_long_rounded,
                      label: 'Ticket médio',
                      value: _formatMoney(averageTicket),
                    ),
                    _SmallMetric(
                      width: compact ? 160 : 190,
                      icon: Icons.person_rounded,
                      label: 'Fiado aberto',
                      value: _formatMoney(openCredit),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReportMenu extends StatelessWidget {
  const _ReportMenu({
    required this.selected,
    required this.onSelected,
  });

  final _ReportSection selected;
  final ValueChanged<_ReportSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ReportMenuItem(
        section: _ReportSection.overview,
        icon: Icons.dashboard_rounded,
        title: 'Visão geral',
        subtitle: 'Resumo do dia',
      ),
      _ReportMenuItem(
        section: _ReportSection.productSales,
        icon: Icons.shopping_basket_rounded,
        title: 'Produtos',
        subtitle: 'Vendas por produto',
      ),
      _ReportMenuItem(
        section: _ReportSection.categorySales,
        icon: Icons.category_rounded,
        title: 'Categorias',
        subtitle: 'Bovina, frango...',
      ),
      _ReportMenuItem(
        section: _ReportSection.payments,
        icon: Icons.credit_card_rounded,
        title: 'Pagamentos',
        subtitle: 'Dinheiro, Pix...',
      ),
      _ReportMenuItem(
        section: _ReportSection.lowStock,
        icon: Icons.warning_rounded,
        title: 'Estoque baixo',
        subtitle: 'Reposição',
      ),
      _ReportMenuItem(
        section: _ReportSection.credit,
        icon: Icons.person_rounded,
        title: 'Fiado',
        subtitle: 'Saldo aberto',
      ),
      _ReportMenuItem(
        section: _ReportSection.detailedSales,
        icon: Icons.receipt_long_rounded,
        title: 'Detalhadas',
        subtitle: 'Venda por venda',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return _ReportMenuCard(
              item: item,
              selected: selected == item.section,
              onTap: () => onSelected(item.section),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ReportMenuCard extends StatelessWidget {
  const _ReportMenuCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _ReportMenuItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.wine900 : null;
    final foreground = selected ? AppColors.beige100 : AppColors.wine700;

    return SizedBox(
      width: 180,
      height: 104,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? AppColors.wine900 : AppColors.beige300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: foreground),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.beige100 : null,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedReportContent extends StatelessWidget {
  const _SelectedReportContent({
    required this.selected,
    required this.todaySales,
    required this.revenue,
    required this.averageTicket,
    required this.paymentTotals,
    required this.productTotals,
    required this.categoryTotals,
    required this.lowStock,
    required this.openCredit,
  });

  final _ReportSection selected;
  final List<dynamic> todaySales;
  final double revenue;
  final double averageTicket;
  final Map<PaymentMethod, double> paymentTotals;
  final List<_ProductTotal> productTotals;
  final List<_CategoryTotal> categoryTotals;
  final List<Product> lowStock;
  final double openCredit;

  @override
  Widget build(BuildContext context) {
    switch (selected) {
      case _ReportSection.overview:
        return _OverviewReport(
          salesCount: todaySales.length,
          revenue: revenue,
          averageTicket: averageTicket,
          openCredit: openCredit,
          productTotals: productTotals,
          categoryTotals: categoryTotals,
          paymentTotals: paymentTotals,
          lowStock: lowStock,
        );
      case _ReportSection.productSales:
        return _ProductSalesReport(productTotals: productTotals);
      case _ReportSection.categorySales:
        return _CategorySalesReport(categoryTotals: categoryTotals);
      case _ReportSection.payments:
        return _PaymentReport(paymentTotals: paymentTotals);
      case _ReportSection.lowStock:
        return _LowStockReport(products: lowStock);
      case _ReportSection.credit:
        return _CreditReport(openCredit: openCredit);
      case _ReportSection.detailedSales:
        return _DetailedSalesReport(sales: todaySales);
    }
  }
}

class _OverviewReport extends StatelessWidget {
  const _OverviewReport({
    required this.salesCount,
    required this.revenue,
    required this.averageTicket,
    required this.openCredit,
    required this.productTotals,
    required this.categoryTotals,
    required this.paymentTotals,
    required this.lowStock,
  });

  final int salesCount;
  final double revenue;
  final double averageTicket;
  final double openCredit;
  final List<_ProductTotal> productTotals;
  final List<_CategoryTotal> categoryTotals;
  final Map<PaymentMethod, double> paymentTotals;
  final List<Product> lowStock;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Visão geral do dia',
      subtitle: 'Resumo rápido para conferência',
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SmallMetric(
                icon: Icons.point_of_sale_rounded,
                label: 'Quantidade de vendas',
                value: salesCount.toString(),
              ),
              _SmallMetric(
                icon: Icons.payments_rounded,
                label: 'Total vendido',
                value: _formatMoney(revenue),
              ),
              _SmallMetric(
                icon: Icons.receipt_long_rounded,
                label: 'Ticket médio',
                value: _formatMoney(averageTicket),
              ),
              _SmallMetric(
                icon: Icons.person_rounded,
                label: 'Fiado aberto',
                value: _formatMoney(openCredit),
              ),
              _SmallMetric(
                icon: Icons.warning_rounded,
                label: 'Estoque baixo',
                value: lowStock.length.toString(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MiniTablesGrid(
            children: [
              _MiniTableCard(
                title: 'Top produtos',
                emptyText: 'Nenhum produto vendido hoje.',
                headers: const ['Produto', 'Total'],
                rows: productTotals.take(5).map((item) {
                  return [item.name, _formatMoney(item.total)];
                }).toList(),
              ),
              _MiniTableCard(
                title: 'Categorias',
                emptyText: 'Nenhuma categoria vendida hoje.',
                headers: const ['Categoria', 'Total'],
                rows: categoryTotals.take(5).map((item) {
                  return [item.category, _formatMoney(item.total)];
                }).toList(),
              ),
              _MiniTableCard(
                title: 'Pagamentos',
                emptyText: 'Sem pagamentos hoje.',
                headers: const ['Forma', 'Total'],
                rows: PaymentMethod.values.map((method) {
                  return [
                    method.label,
                    _formatMoney(paymentTotals[method] ?? 0.0),
                  ];
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductSalesReport extends StatelessWidget {
  const _ProductSalesReport({required this.productTotals});

  final List<_ProductTotal> productTotals;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Vendas por produto',
      subtitle: 'Mostra quais produtos venderam mais no dia',
      child: productTotals.isEmpty
          ? const _EmptyReportText('Nenhum produto vendido hoje.')
          : _ReportTable(
              headers: const ['Produto', 'Qtd vendida', 'Total vendido'],
              rows: productTotals.map((item) {
                return [
                  item.name,
                  _formatNumber(item.quantity),
                  _formatMoney(item.total),
                ];
              }).toList(),
            ),
    );
  }
}

class _CategorySalesReport extends StatelessWidget {
  const _CategorySalesReport({required this.categoryTotals});

  final List<_CategoryTotal> categoryTotals;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Vendas por categoria',
      subtitle: 'Resumo separado por tipo de produto',
      child: categoryTotals.isEmpty
          ? const _EmptyReportText('Nenhuma categoria vendida hoje.')
          : _ReportTable(
              headers: const ['Categoria', 'Qtd vendida', 'Total vendido'],
              rows: categoryTotals.map((item) {
                return [
                  item.category,
                  _formatNumber(item.quantity),
                  _formatMoney(item.total),
                ];
              }).toList(),
            ),
    );
  }
}

class _PaymentReport extends StatelessWidget {
  const _PaymentReport({required this.paymentTotals});

  final Map<PaymentMethod, double> paymentTotals;

  @override
  Widget build(BuildContext context) {
    final total = paymentTotals.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return _SectionCard(
      title: 'Totais por forma de pagamento',
      subtitle: 'Ajuda na conferência do caixa',
      child: Column(
        children: [
          _BigTotalCard(
            label: 'Total recebido no dia',
            value: _formatMoney(total),
          ),
          const SizedBox(height: 14),
          _ReportTable(
            headers: const ['Forma', 'Total'],
            rows: PaymentMethod.values.map((method) {
              return [
                method.label,
                _formatMoney(paymentTotals[method] ?? 0.0),
              ];
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LowStockReport extends StatelessWidget {
  const _LowStockReport({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Estoque baixo',
      subtitle: 'Produtos que precisam de atenção',
      child: products.isEmpty
          ? const _EmptyReportText('Nenhum produto em estoque baixo.')
          : _ReportTable(
              headers: const ['Código', 'Produto', 'Estoque', 'Mínimo'],
              rows: products.map((product) {
                return [
                  product.code,
                  product.name,
                  '${_formatNumber(product.stockQuantity)} ${product.unit.label}',
                  '${_formatNumber(product.minStock)} ${product.unit.label}',
                ];
              }).toList(),
            ),
    );
  }
}

class _CreditReport extends StatelessWidget {
  const _CreditReport({required this.openCredit});

  final double openCredit;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Relatório de fiado',
      subtitle: 'Resumo do valor em aberto',
      child: Column(
        children: [
          _BigTotalCard(
            label: 'Total em aberto no fiado',
            value: _formatMoney(openCredit),
          ),
          const SizedBox(height: 12),
          const _EmptyReportText(
            'Para ver cliente por cliente, abra a aba Fiado. Aqui fica o resumo para conferência rápida.',
          ),
        ],
      ),
    );
  }
}

class _DetailedSalesReport extends StatelessWidget {
  const _DetailedSalesReport({required this.sales});

  final List<dynamic> sales;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Vendas detalhadas',
      subtitle: 'Lista venda por venda do dia',
      child: sales.isEmpty
          ? const _EmptyReportText('Nenhuma venda hoje.')
          : _ReportTable(
              headers: const ['Venda', 'Hora', 'Pagamento', 'Itens', 'Total'],
              rows: sales.map((sale) {
                return [
                  '#${sale.shortId}',
                  _formatTime(sale.createdAt as DateTime),
                  (sale.paymentMethod as PaymentMethod).label,
                  sale.totalItems.toString(),
                  _formatMoney(sale.total as double),
                ];
              }).toList(),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_rounded, color: AppColors.wine700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.width = 190,
  });

  final IconData icon;
  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 112,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.wine700),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigTotalCard extends StatelessWidget {
  const _BigTotalCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
          Text(
            label,
            style: const TextStyle(
              color: AppColors.beige100,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.beige100,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTablesGrid extends StatelessWidget {
  const _MiniTablesGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 950;

        if (compact) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: child,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children
              .map(
                (child) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: child,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MiniTableCard extends StatelessWidget {
  const _MiniTableCard({
    required this.title,
    required this.emptyText,
    required this.headers,
    required this.rows,
  });

  final String title;
  final String emptyText;
  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            rows.isEmpty
                ? Text(emptyText)
                : _ReportTable(
                    headers: headers,
                    rows: rows,
                    compact: true,
                  ),
          ],
        ),
      ),
    );
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({
    required this.headers,
    required this.rows,
    this.compact = false,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: compact ? 38 : 46,
        dataRowMaxHeight: compact ? 46 : 56,
        headingTextStyle: const TextStyle(fontWeight: FontWeight.w900),
        columns: headers.map((header) {
          return DataColumn(label: Text(header));
        }).toList(),
        rows: rows.map((row) {
          return DataRow(
            cells: row.map((cell) {
              return DataCell(
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? 130 : 260,
                  ),
                  child: Text(
                    cell,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyReportText extends StatelessWidget {
  const _EmptyReportText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceAlt
            : AppColors.beige100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ReportMenuItem {
  const _ReportMenuItem({
    required this.section,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final _ReportSection section;
  final IconData icon;
  final String title;
  final String subtitle;
}

Map<PaymentMethod, double> _paymentTotals(List<dynamic> sales) {
  final totals = <PaymentMethod, double>{};

  for (final sale in sales) {
    final method = sale.paymentMethod as PaymentMethod;
    totals[method] = (totals[method] ?? 0.0) + (sale.total as double);
  }

  return totals;
}

List<_ProductTotal> _productTotals(List<dynamic> sales) {
  final map = <String, _ProductTotal>{};

  for (final sale in sales) {
    for (final item in sale.items) {
      final productId = item.productId as String;
      final existing = map[productId];

      if (existing == null) {
        map[productId] = _ProductTotal(
          name: item.productName as String,
          quantity: item.quantity as double,
          total: item.subtotal as double,
        );
      } else {
        map[productId] = existing.copyWith(
          quantity: existing.quantity + (item.quantity as double),
          total: existing.total + (item.subtotal as double),
        );
      }
    }
  }

  final result = map.values.toList();
  result.sort((a, b) => b.total.compareTo(a.total));
  return result;
}

List<_CategoryTotal> _categoryTotals(
  List<dynamic> sales,
  List<Product> products,
) {
  final categories = <String, String>{};

  for (final product in products) {
    categories[product.id] = product.category.label;
  }

  final map = <String, _CategoryTotal>{};

  for (final sale in sales) {
    for (final item in sale.items) {
      final productId = item.productId as String;
      final category = categories[productId] ?? 'Sem categoria';
      final existing = map[category];

      if (existing == null) {
        map[category] = _CategoryTotal(
          category: category,
          quantity: item.quantity as double,
          total: item.subtotal as double,
        );
      } else {
        map[category] = existing.copyWith(
          quantity: existing.quantity + (item.quantity as double),
          total: existing.total + (item.subtotal as double),
        );
      }
    }
  }

  final result = map.values.toList();
  result.sort((a, b) => b.total.compareTo(a.total));
  return result;
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}

String _formatNumber(double value) {
  if (value % 1 == 0) return value.toStringAsFixed(0);
  return value.toStringAsFixed(3).replaceAll('.', ',');
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

class _ProductTotal {
  const _ProductTotal({
    required this.name,
    required this.quantity,
    required this.total,
  });

  final String name;
  final double quantity;
  final double total;

  _ProductTotal copyWith({
    double? quantity,
    double? total,
  }) {
    return _ProductTotal(
      name: name,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }
}

class _CategoryTotal {
  const _CategoryTotal({
    required this.category,
    required this.quantity,
    required this.total,
  });

  final String category;
  final double quantity;
  final double total;

  _CategoryTotal copyWith({
    double? quantity,
    double? total,
  }) {
    return _CategoryTotal(
      category: category,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }
}
