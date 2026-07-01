import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/payment_method.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../models/supplier_purchase.dart';
import '../../providers/customers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/suppliers_provider.dart';

enum _ReportSection {
  overview,
  products,
  categories,
  payments,
  suppliers,
  lowStock,
  credit,
  detailed,
}

enum _ReportPeriod {
  today,
  sevenDays,
  thirtyDays,
  all,
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportSection selectedSection = _ReportSection.overview;
  _ReportPeriod selectedPeriod = _ReportPeriod.today;

  @override
  Widget build(BuildContext context) {
    return Consumer4<SalesProvider, InventoryProvider, CustomersProvider,
        SuppliersProvider>(
      builder: (context, salesProvider, inventory, customers, suppliers, _) {
        final sales = _filterSalesByPeriod(
          salesProvider.sales,
          selectedPeriod,
        );

        final purchases = _filterPurchasesByPeriod(
          suppliers.purchases,
          selectedPeriod,
        );

        final revenue = _salesRevenue(sales);
        final averageTicket = sales.isEmpty ? 0.0 : revenue / sales.length;

        final paymentTotals = _paymentTotals(sales);
        final productTotals = _productTotals(sales);
        final categoryTotals = _categoryTotals(
          sales,
          inventory.products,
        );

        final supplierTotals = _supplierTotals(purchases);
        final totalSupplierPurchases = purchases.fold<double>(
          0,
          (total, purchase) => total + purchase.totalCost,
        );

        final lowStock = inventory.products.where((product) {
          return !product.isDeleted && product.isLowStock;
        }).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderPanel(
                periodLabel: _periodLabel(selectedPeriod),
                salesCount: sales.length,
                revenue: revenue,
                averageTicket: averageTicket,
                openCredit: customers.totalOpenCredit,
                supplierPurchasesTotal: totalSupplierPurchases,
              ),
              const SizedBox(height: 14),
              _PeriodSelector(
                selected: selectedPeriod,
                onChanged: (period) {
                  setState(() => selectedPeriod = period);
                },
              ),
              const SizedBox(height: 14),
              _ReportSelector(
                selected: selectedSection,
                onChanged: (section) {
                  setState(() => selectedSection = section);
                },
              ),
              const SizedBox(height: 14),
              _ReportContent(
                section: selectedSection,
                periodLabel: _periodLabel(selectedPeriod),
                sales: sales,
                revenue: revenue,
                averageTicket: averageTicket,
                paymentTotals: paymentTotals,
                productTotals: productTotals,
                categoryTotals: categoryTotals,
                purchases: purchases,
                supplierTotals: supplierTotals,
                totalSupplierPurchases: totalSupplierPurchases,
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

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({
    required this.periodLabel,
    required this.salesCount,
    required this.revenue,
    required this.averageTicket,
    required this.openCredit,
    required this.supplierPurchasesTotal,
  });

  final String periodLabel;
  final int salesCount;
  final double revenue;
  final double averageTicket;
  final double openCredit;
  final double supplierPurchasesTotal;

  @override
  Widget build(BuildContext context) {
    return _NiceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(icon: Icons.bar_chart_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Central de relatórios',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: _textColor(context),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Período selecionado: $periodLabel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _mutedTextColor(context),
                      ),
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
              _MetricBox(
                icon: Icons.point_of_sale_rounded,
                label: 'Vendas',
                value: salesCount.toString(),
              ),
              _MetricBox(
                icon: Icons.payments_rounded,
                label: 'Faturamento',
                value: _formatMoney(revenue),
              ),
              _MetricBox(
                icon: Icons.receipt_long_rounded,
                label: 'Ticket médio',
                value: _formatMoney(averageTicket),
              ),
              _MetricBox(
                icon: Icons.person_rounded,
                label: 'Fiado aberto',
                value: _formatMoney(openCredit),
              ),
              _MetricBox(
                icon: Icons.local_shipping_rounded,
                label: 'Compras fornecedor',
                value: _formatMoney(supplierPurchasesTotal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final _ReportPeriod selected;
  final ValueChanged<_ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_ReportPeriod.today, 'Hoje', Icons.today_rounded),
      (_ReportPeriod.sevenDays, '7 dias', Icons.date_range_rounded),
      (_ReportPeriod.thirtyDays, '30 dias', Icons.calendar_month_rounded),
      (_ReportPeriod.all, 'Tudo', Icons.all_inclusive_rounded),
    ];

    return _NiceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, color: AppColors.wine700),
          const SizedBox(width: 10),
          Text(
            'Período',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _textColor(context),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: items.map((item) {
                  final active = selected == item.$1;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: active,
                      selectedColor: AppColors.wine900,
                      backgroundColor: _surfaceAltColor(context),
                      side: BorderSide(color: _borderColor(context)),
                      avatar: Icon(
                        item.$3,
                        size: 18,
                        color: active ? AppColors.beige100 : AppColors.wine700,
                      ),
                      label: Text(item.$2),
                      labelStyle: TextStyle(
                        color: active ? AppColors.beige100 : _textColor(context),
                        fontWeight: FontWeight.w900,
                      ),
                      onSelected: (_) => onChanged(item.$1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSelector extends StatelessWidget {
  const _ReportSelector({
    required this.selected,
    required this.onChanged,
  });

  final _ReportSection selected;
  final ValueChanged<_ReportSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ReportOption(
        section: _ReportSection.overview,
        title: 'Visão geral',
        subtitle: 'Resumo',
        icon: Icons.dashboard_rounded,
      ),
      _ReportOption(
        section: _ReportSection.products,
        title: 'Produtos',
        subtitle: 'Por produto',
        icon: Icons.shopping_basket_rounded,
      ),
      _ReportOption(
        section: _ReportSection.categories,
        title: 'Categorias',
        subtitle: 'Por categoria',
        icon: Icons.category_rounded,
      ),
      _ReportOption(
        section: _ReportSection.payments,
        title: 'Pagamentos',
        subtitle: 'Formas',
        icon: Icons.credit_card_rounded,
      ),
      _ReportOption(
        section: _ReportSection.suppliers,
        title: 'Fornecedores',
        subtitle: 'Compras',
        icon: Icons.local_shipping_rounded,
      ),
      _ReportOption(
        section: _ReportSection.lowStock,
        title: 'Estoque baixo',
        subtitle: 'Reposição',
        icon: Icons.warning_rounded,
      ),
      _ReportOption(
        section: _ReportSection.credit,
        title: 'Fiado',
        subtitle: 'Aberto',
        icon: Icons.person_rounded,
      ),
      _ReportOption(
        section: _ReportSection.detailed,
        title: 'Detalhadas',
        subtitle: 'Venda por venda',
        icon: Icons.receipt_long_rounded,
      ),
    ];

    return _NiceCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items.map((item) {
          final active = selected == item.section;

          return _ReportOptionCard(
            option: item,
            active: active,
            onTap: () => onChanged(item.section),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportOptionCard extends StatelessWidget {
  const _ReportOptionCard({
    required this.option,
    required this.active,
    required this.onTap,
  });

  final _ReportOption option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = active ? AppColors.wine900 : _surfaceAltColor(context);
    final textColor = active ? AppColors.beige100 : _textColor(context);
    final subtitleColor = active ? AppColors.beige100 : _mutedTextColor(context);

    return SizedBox(
      width: 170,
      height: 106,
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
                color: active ? AppColors.wine900 : _borderColor(context),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  option.icon,
                  color: active ? AppColors.beige100 : AppColors.wine700,
                ),
                const Spacer(),
                Text(
                  option.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  option.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtitleColor,
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

class _ReportContent extends StatelessWidget {
  const _ReportContent({
    required this.section,
    required this.periodLabel,
    required this.sales,
    required this.revenue,
    required this.averageTicket,
    required this.paymentTotals,
    required this.productTotals,
    required this.categoryTotals,
    required this.purchases,
    required this.supplierTotals,
    required this.totalSupplierPurchases,
    required this.lowStock,
    required this.openCredit,
  });

  final _ReportSection section;
  final String periodLabel;
  final List<dynamic> sales;
  final double revenue;
  final double averageTicket;
  final Map<PaymentMethod, double> paymentTotals;
  final List<_ProductTotal> productTotals;
  final List<_CategoryTotal> categoryTotals;
  final List<SupplierPurchase> purchases;
  final List<_SupplierTotal> supplierTotals;
  final double totalSupplierPurchases;
  final List<Product> lowStock;
  final double openCredit;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case _ReportSection.overview:
        return _OverviewReport(
          periodLabel: periodLabel,
          salesCount: sales.length,
          revenue: revenue,
          averageTicket: averageTicket,
          openCredit: openCredit,
          productTotals: productTotals,
          categoryTotals: categoryTotals,
          paymentTotals: paymentTotals,
          supplierTotals: supplierTotals,
          totalSupplierPurchases: totalSupplierPurchases,
          lowStock: lowStock,
        );
      case _ReportSection.products:
        return _ProductsReport(
          periodLabel: periodLabel,
          productTotals: productTotals,
        );
      case _ReportSection.categories:
        return _CategoriesReport(
          periodLabel: periodLabel,
          categoryTotals: categoryTotals,
        );
      case _ReportSection.payments:
        return _PaymentsReport(
          periodLabel: periodLabel,
          paymentTotals: paymentTotals,
        );
      case _ReportSection.suppliers:
        return _SuppliersReport(
          periodLabel: periodLabel,
          purchases: purchases,
          supplierTotals: supplierTotals,
          totalSupplierPurchases: totalSupplierPurchases,
        );
      case _ReportSection.lowStock:
        return _LowStockReport(products: lowStock);
      case _ReportSection.credit:
        return _CreditReport(openCredit: openCredit);
      case _ReportSection.detailed:
        return _DetailedSalesReport(
          periodLabel: periodLabel,
          sales: sales,
        );
    }
  }
}

class _OverviewReport extends StatelessWidget {
  const _OverviewReport({
    required this.periodLabel,
    required this.salesCount,
    required this.revenue,
    required this.averageTicket,
    required this.openCredit,
    required this.productTotals,
    required this.categoryTotals,
    required this.paymentTotals,
    required this.supplierTotals,
    required this.totalSupplierPurchases,
    required this.lowStock,
  });

  final String periodLabel;
  final int salesCount;
  final double revenue;
  final double averageTicket;
  final double openCredit;
  final List<_ProductTotal> productTotals;
  final List<_CategoryTotal> categoryTotals;
  final Map<PaymentMethod, double> paymentTotals;
  final List<_SupplierTotal> supplierTotals;
  final double totalSupplierPurchases;
  final List<Product> lowStock;

  @override
  Widget build(BuildContext context) {
    return _ReportSectionCard(
      title: 'Visão geral',
      subtitle: 'Resumo do período: $periodLabel',
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricBox(
                icon: Icons.point_of_sale_rounded,
                label: 'Quantidade de vendas',
                value: salesCount.toString(),
              ),
              _MetricBox(
                icon: Icons.payments_rounded,
                label: 'Total vendido',
                value: _formatMoney(revenue),
              ),
              _MetricBox(
                icon: Icons.receipt_long_rounded,
                label: 'Ticket médio',
                value: _formatMoney(averageTicket),
              ),
              _MetricBox(
                icon: Icons.person_rounded,
                label: 'Fiado aberto',
                value: _formatMoney(openCredit),
              ),
              _MetricBox(
                icon: Icons.local_shipping_rounded,
                label: 'Compras fornecedor',
                value: _formatMoney(totalSupplierPurchases),
              ),
              _MetricBox(
                icon: Icons.warning_rounded,
                label: 'Estoque baixo',
                value: lowStock.length.toString(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;

              final tables = [
                _MiniReportTable(
                  title: 'Top produtos',
                  emptyText: 'Nenhum produto vendido.',
                  headers: const ['Produto', 'Total'],
                  rows: productTotals.take(5).map((item) {
                    return [item.name, _formatMoney(item.total)];
                  }).toList(),
                ),
                _MiniReportTable(
                  title: 'Categorias',
                  emptyText: 'Nenhuma categoria vendida.',
                  headers: const ['Categoria', 'Total'],
                  rows: categoryTotals.take(5).map((item) {
                    return [item.category, _formatMoney(item.total)];
                  }).toList(),
                ),
                _MiniReportTable(
                  title: 'Pagamentos',
                  emptyText: 'Sem pagamentos.',
                  headers: const ['Forma', 'Total'],
                  rows: PaymentMethod.values.map((method) {
                    return [
                      method.label,
                      _formatMoney(paymentTotals[method] ?? 0.0),
                    ];
                  }).toList(),
                ),
                _MiniReportTable(
                  title: 'Fornecedores',
                  emptyText: 'Nenhuma compra registrada.',
                  headers: const ['Fornecedor', 'Total'],
                  rows: supplierTotals.take(5).map((item) {
                    return [
                      item.supplierName,
                      _formatMoney(item.total),
                    ];
                  }).toList(),
                ),
              ];

              if (compact) {
                return Column(
                  children: tables
                      .map(
                        (table) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: table,
                        ),
                      )
                      .toList(),
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: tables.map((table) {
                  return SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: table,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductsReport extends StatelessWidget {
  const _ProductsReport({
    required this.periodLabel,
    required this.productTotals,
  });

  final String periodLabel;
  final List<_ProductTotal> productTotals;

  @override
  Widget build(BuildContext context) {
    return _ReportSectionCard(
      title: 'Vendas por produto',
      subtitle: 'Período: $periodLabel',
      child: productTotals.isEmpty
          ? const _EmptyState('Nenhum produto vendido nesse período.')
          : _ProfessionalTable(
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

class _CategoriesReport extends StatelessWidget {
  const _CategoriesReport({
    required this.periodLabel,
    required this.categoryTotals,
  });

  final String periodLabel;
  final List<_CategoryTotal> categoryTotals;

  @override
  Widget build(BuildContext context) {
    return _ReportSectionCard(
      title: 'Vendas por categoria',
      subtitle: 'Período: $periodLabel',
      child: categoryTotals.isEmpty
          ? const _EmptyState('Nenhuma categoria vendida nesse período.')
          : _ProfessionalTable(
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

class _PaymentsReport extends StatelessWidget {
  const _PaymentsReport({
    required this.periodLabel,
    required this.paymentTotals,
  });

  final String periodLabel;
  final Map<PaymentMethod, double> paymentTotals;

  @override
  Widget build(BuildContext context) {
    final total = paymentTotals.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return _ReportSectionCard(
      title: 'Totais por forma de pagamento',
      subtitle: 'Período: $periodLabel',
      child: Column(
        children: [
          _TotalPanel(
            label: 'Total recebido no período',
            value: _formatMoney(total),
          ),
          const SizedBox(height: 14),
          _ProfessionalTable(
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

class _SuppliersReport extends StatelessWidget {
  const _SuppliersReport({
    required this.periodLabel,
    required this.purchases,
    required this.supplierTotals,
    required this.totalSupplierPurchases,
  });

  final String periodLabel;
  final List<SupplierPurchase> purchases;
  final List<_SupplierTotal> supplierTotals;
  final double totalSupplierPurchases;

  @override
  Widget build(BuildContext context) {
    return _ReportSectionCard(
      title: 'Compras de fornecedores',
      subtitle: 'Período: $periodLabel',
      child: Column(
        children: [
          _TotalPanel(
            label: 'Total comprado no período',
            value: _formatMoney(totalSupplierPurchases),
          ),
          const SizedBox(height: 14),
          if (supplierTotals.isEmpty)
            const _EmptyState('Nenhuma compra de fornecedor nesse período.')
          else
            _ProfessionalTable(
              headers: const ['Fornecedor', 'Compras', 'Total'],
              rows: supplierTotals.map((item) {
                return [
                  item.supplierName,
                  item.count.toString(),
                  _formatMoney(item.total),
                ];
              }).toList(),
            ),
          const SizedBox(height: 14),
          if (purchases.isNotEmpty)
            _ProfessionalTable(
              headers: const [
                'Data',
                'Fornecedor',
                'Item',
                'Qtd',
                'Total',
                'Status'
              ],
              rows: purchases.map((purchase) {
                return [
                  _formatDate(purchase.purchaseDate),
                  purchase.supplierName,
                  purchase.itemName,
                  '${_formatNumber(purchase.quantity)} ${purchase.unit.label}',
                  _formatMoney(purchase.totalCost),
                  purchase.paid ? 'Pago' : 'Em aberto',
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
    return _ReportSectionCard(
      title: 'Estoque baixo',
      subtitle: 'Mostra o estoque atual, não depende do período.',
      child: products.isEmpty
          ? const _EmptyState('Nenhum produto em estoque baixo.')
          : _ProfessionalTable(
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
    return _ReportSectionCard(
      title: 'Relatório de fiado',
      subtitle: 'Resumo atual do valor em aberto.',
      child: Column(
        children: [
          _TotalPanel(
            label: 'Total em aberto no fiado',
            value: _formatMoney(openCredit),
          ),
          const SizedBox(height: 12),
          const _EmptyState(
            'Para ver cliente por cliente, abra a aba Fiado.',
          ),
        ],
      ),
    );
  }
}

class _DetailedSalesReport extends StatelessWidget {
  const _DetailedSalesReport({
    required this.periodLabel,
    required this.sales,
  });

  final String periodLabel;
  final List<dynamic> sales;

  @override
  Widget build(BuildContext context) {
    return _ReportSectionCard(
      title: 'Vendas detalhadas',
      subtitle: 'Período: $periodLabel',
      child: sales.isEmpty
          ? const _EmptyState('Nenhuma venda nesse período.')
          : _ProfessionalTable(
              headers: const [
                'Venda',
                'Data',
                'Hora',
                'Pagamento',
                'Itens',
                'Total'
              ],
              rows: sales.map((sale) {
                final date = sale.createdAt as DateTime;

                return [
                  '#${sale.shortId}',
                  _formatDate(date),
                  _formatTime(date),
                  (sale.paymentMethod as PaymentMethod).label,
                  sale.totalItems.toString(),
                  _formatMoney(sale.total as double),
                ];
              }).toList(),
            ),
    );
  }
}

class _NiceCard extends StatelessWidget {
  const _NiceCard({
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: _surfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: _borderColor(context)),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _ReportSectionCard extends StatelessWidget {
  const _ReportSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _NiceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(icon: Icons.analytics_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: _textColor(context),
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _mutedTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        color: AppColors.beige100,
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 116,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceAltColor(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _borderColor(context)),
        ),
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
                    color: _textColor(context),
                  ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _mutedTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalPanel extends StatelessWidget {
  const _TotalPanel({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.beige100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: AppColors.wine900,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.beige100,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalTable extends StatelessWidget {
  const _ProfessionalTable({
    required this.headers,
    required this.rows,
  });

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final minWidth = headers.length * 170.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : minWidth;

        final tableWidth =
            availableWidth > minWidth ? availableWidth : minWidth;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: _surfaceAltColor(context),
                  border: Border.all(color: _borderColor(context)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TableLine(
                      cells: headers,
                      isHeader: true,
                      striped: false,
                      tableWidth: tableWidth,
                    ),
                    ...rows.asMap().entries.map((entry) {
                      return _TableLine(
                        cells: entry.value,
                        isHeader: false,
                        striped: entry.key.isOdd,
                        tableWidth: tableWidth,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniReportTable extends StatelessWidget {
  const _MiniReportTable({
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
    return Container(
      decoration: BoxDecoration(
        color: _surfaceAltColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor(context)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: _textColor(context),
            ),
          ),
          const SizedBox(height: 10),
          rows.isEmpty
              ? Text(
                  emptyText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _mutedTextColor(context),
                  ),
                )
              : _ProfessionalTable(
                  headers: headers,
                  rows: rows,
                ),
        ],
      ),
    );
  }
}

class _TableLine extends StatelessWidget {
  const _TableLine({
    required this.cells,
    required this.isHeader,
    required this.striped,
    required this.tableWidth,
  });

  final List<String> cells;
  final bool isHeader;
  final bool striped;
  final double tableWidth;

  @override
  Widget build(BuildContext context) {
    final background = isHeader
        ? AppColors.wine900
        : striped
            ? _surfaceColor(context)
            : _surfaceAltColor(context);

    final foreground = isHeader ? AppColors.beige100 : _textColor(context);
    final firstWidth = cells.length <= 2 ? tableWidth * 0.55 : tableWidth * 0.34;
    final otherWidth = cells.length <= 1
        ? tableWidth
        : (tableWidth - firstWidth) / (cells.length - 1);

    return Container(
      width: tableWidth,
      decoration: BoxDecoration(
        color: background,
        border: isHeader
            ? null
            : Border(
                top: BorderSide(color: _borderColor(context)),
              ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      child: Row(
        children: List.generate(cells.length, (index) {
          final cell = cells[index];
          final width = index == 0 ? firstWidth : otherWidth;

          return SizedBox(
            width: width - 12,
            child: Padding(
              padding: EdgeInsets.only(
                right: index == cells.length - 1 ? 0 : 12,
              ),
              child: Text(
                cell,
                maxLines: isHeader ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: isHeader ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceAltColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.wine700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportOption {
  const _ReportOption({
    required this.section,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final _ReportSection section;
  final String title;
  final String subtitle;
  final IconData icon;
}

List<dynamic> _filterSalesByPeriod(List<dynamic> sales, _ReportPeriod period) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  final filtered = sales.where((sale) {
    final createdAt = sale.createdAt as DateTime;

    switch (period) {
      case _ReportPeriod.today:
        return _sameDay(createdAt, now);

      case _ReportPeriod.sevenDays:
        return !createdAt.isBefore(
          todayStart.subtract(const Duration(days: 6)),
        );

      case _ReportPeriod.thirtyDays:
        return !createdAt.isBefore(
          todayStart.subtract(const Duration(days: 29)),
        );

      case _ReportPeriod.all:
        return true;
    }
  }).toList();

  filtered.sort((a, b) {
    final aDate = a.createdAt as DateTime;
    final bDate = b.createdAt as DateTime;

    return bDate.compareTo(aDate);
  });

  return filtered;
}

List<SupplierPurchase> _filterPurchasesByPeriod(
  List<SupplierPurchase> purchases,
  _ReportPeriod period,
) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  final filtered = purchases.where((purchase) {
    final date = purchase.purchaseDate;

    switch (period) {
      case _ReportPeriod.today:
        return _sameDay(date, now);

      case _ReportPeriod.sevenDays:
        return !date.isBefore(todayStart.subtract(const Duration(days: 6)));

      case _ReportPeriod.thirtyDays:
        return !date.isBefore(todayStart.subtract(const Duration(days: 29)));

      case _ReportPeriod.all:
        return true;
    }
  }).toList();

  filtered.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

  return filtered;
}

double _salesRevenue(List<dynamic> sales) {
  return sales.fold<double>(
    0,
    (sum, sale) => sum + (sale.total as double),
  );
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
  final productCategoryById = <String, String>{};

  for (final product in products) {
    productCategoryById[product.id] = product.category.label;
  }

  final map = <String, _CategoryTotal>{};

  for (final sale in sales) {
    for (final item in sale.items) {
      final productId = item.productId as String;
      final category = productCategoryById[productId] ?? 'Sem categoria';
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

List<_SupplierTotal> _supplierTotals(List<SupplierPurchase> purchases) {
  final map = <String, _SupplierTotal>{};

  for (final purchase in purchases) {
    final key = purchase.supplierName.trim().isEmpty
        ? 'Sem fornecedor'
        : purchase.supplierName.trim();

    final existing = map[key];

    if (existing == null) {
      map[key] = _SupplierTotal(
        supplierName: key,
        count: 1,
        total: purchase.totalCost,
      );
    } else {
      map[key] = existing.copyWith(
        count: existing.count + 1,
        total: existing.total + purchase.totalCost,
      );
    }
  }

  final result = map.values.toList();
  result.sort((a, b) => b.total.compareTo(a.total));

  return result;
}

String _periodLabel(_ReportPeriod period) {
  switch (period) {
    case _ReportPeriod.today:
      return 'Hoje';
    case _ReportPeriod.sevenDays:
      return 'Últimos 7 dias';
    case _ReportPeriod.thirtyDays:
      return 'Últimos 30 dias';
    case _ReportPeriod.all:
      return 'Todo o histórico';
  }
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

Color _surfaceColor(BuildContext context) {
  return Theme.of(context).cardColor;
}

Color _surfaceAltColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.darkSurfaceAlt
      : AppColors.beige100;
}

Color _textColor(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface;
}

Color _mutedTextColor(BuildContext context) {
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

Color _borderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.wine700.withOpacity(0.35)
      : AppColors.beige300;
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');

  return 'R\$ $fixed';
}

String _formatNumber(double value) {
  if (value % 1 == 0) return value.toStringAsFixed(0);

  return value.toStringAsFixed(3).replaceAll('.', ',');
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();

  return '$day/$month/$year';
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

class _SupplierTotal {
  const _SupplierTotal({
    required this.supplierName,
    required this.count,
    required this.total,
  });

  final String supplierName;
  final int count;
  final double total;

  _SupplierTotal copyWith({
    int? count,
    double? total,
  }) {
    return _SupplierTotal(
      supplierName: supplierName,
      count: count ?? this.count,
      total: total ?? this.total,
    );
  }
}
