import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/payment_method.dart';
import '../../models/cash_movement.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../models/supplier_purchase.dart';
import '../../providers/customers_provider.dart';
import '../../providers/cash_movement_provider.dart';
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
  cash,
  credit,
  detailed,
}

enum _ReportPeriod { today, sevenDays, thirtyDays, all }

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
    return Consumer5<
      SalesProvider,
      InventoryProvider,
      CustomersProvider,
      SuppliersProvider,
      CashMovementProvider
    >(
      builder:
          (
            context,
            salesProvider,
            inventory,
            customers,
            suppliers,
            cashMovementsProvider,
            _,
          ) {
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
            final categoryTotals = _categoryTotals(sales, inventory.products);
            final supplierTotals = _supplierTotals(purchases);

            final totalSupplierPurchases = purchases.fold<double>(
              0,
              (total, purchase) => total + purchase.totalCost,
            );

            final cashMovements = _filterCashMovementsByPeriod(
              cashMovementsProvider.movements,
              selectedPeriod,
            );
            final manualCashInputs = _cashMovementTotal(
              cashMovements,
              CashMovementType.input,
            );
            final manualCashOutputs = _cashMovementTotal(
              cashMovements,
              CashMovementType.output,
            );
            final manualCashBalance = manualCashInputs - manualCashOutputs;
            final cashOutputCategoryTotals = _cashOutputTotalsByCategory(
              cashMovements,
            );

            final lowStock = inventory.products.where((product) {
              return !product.isDeleted && product.isLowStock;
            }).toList();

            return Container(
              color: _pageBackground(context),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReportsHeader(
                      selectedPeriod: selectedPeriod,
                      periodLabel: _periodLabel(selectedPeriod),
                      onPeriodChanged: (period) {
                        setState(() => selectedPeriod = period);
                      },
                    ),
                    const SizedBox(height: 14),
                    _ReportsPdfActionPanel(
                      onPressed: () => _showReportsPdfOptionsDialog(
                        context: context,
                        periodLabel: _periodLabel(selectedPeriod),
                        sales: sales,
                        revenue: revenue,
                        averageTicket: averageTicket,
                        openCredit: customers.totalOpenCredit,
                        supplierPurchases: totalSupplierPurchases,
                        lowStockCount: lowStock.length,
                        paymentTotals: paymentTotals,
                        productTotals: productTotals,
                        categoryTotals: categoryTotals,
                        purchases: purchases,
                        lowStock: lowStock,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _KpiGrid(
                      salesCount: sales.length,
                      revenue: revenue,
                      averageTicket: averageTicket,
                      openCredit: customers.totalOpenCredit,
                      supplierPurchases: totalSupplierPurchases,
                      lowStockCount: lowStock.length,
                    ),
                    const SizedBox(height: 14),
                    _CashFlowSummaryPanel(
                      inputs: manualCashInputs,
                      outputs: manualCashOutputs,
                      balance: manualCashBalance,
                    ),
                    const SizedBox(height: 14),
                    _ReportMenu(
                      selected: selectedSection,
                      onChanged: (section) {
                        setState(() => selectedSection = section);
                      },
                    ),
                    const SizedBox(height: 14),
                    _ReportBody(
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
                      cashMovements: cashMovements,
                      manualCashInputs: manualCashInputs,
                      manualCashOutputs: manualCashOutputs,
                      manualCashBalance: manualCashBalance,
                      cashOutputCategoryTotals: cashOutputCategoryTotals,
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({
    required this.selectedPeriod,
    required this.periodLabel,
    required this.onPeriodChanged,
  });

  final _ReportPeriod selectedPeriod;
  final String periodLabel;
  final ValueChanged<_ReportPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_ReportPeriod.today, 'Hoje', Icons.today_rounded),
      (_ReportPeriod.sevenDays, '7 dias', Icons.date_range_rounded),
      (_ReportPeriod.thirtyDays, '30 dias', Icons.calendar_month_rounded),
      (_ReportPeriod.all, 'Tudo', Icons.all_inclusive_rounded),
    ];

    return _LelecoPanel(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: compact ? 0 : 1,
                    child: Row(
                      children: [
                        _IconBadge(icon: Icons.bar_chart_rounded),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Central de relatórios',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: _titleColor(context),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Painel geral do açougue • $periodLabel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _mutedColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (compact) const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items.map((item) {
                      final active = selectedPeriod == item.$1;

                      return ChoiceChip(
                        selected: active,
                        selectedColor: AppColors.wine900,
                        backgroundColor: _chipBackground(context),
                        side: BorderSide(
                          color: active
                              ? AppColors.wine900
                              : _borderColor(context),
                        ),
                        avatar: Icon(
                          item.$3,
                          size: 18,
                          color: active
                              ? AppColors.beige100
                              : AppColors.wine700,
                        ),
                        label: Text(item.$2),
                        labelStyle: TextStyle(
                          color: active
                              ? AppColors.beige100
                              : _titleColor(context),
                          fontWeight: FontWeight.w900,
                        ),
                        onSelected: (_) => onPeriodChanged(item.$1),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.salesCount,
    required this.revenue,
    required this.averageTicket,
    required this.openCredit,
    required this.supplierPurchases,
    required this.lowStockCount,
  });

  final int salesCount;
  final double revenue;
  final double averageTicket;
  final double openCredit;
  final double supplierPurchases;
  final int lowStockCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(
        title: 'Vendas',
        value: salesCount.toString(),
        detail: 'Quantidade no período',
        icon: Icons.point_of_sale_rounded,
        tag: 'operação',
        values: const [2, 5, 4, 8, 6, 9, 11, 10],
      ),
      _KpiCard(
        title: 'Faturamento',
        value: _formatMoney(revenue),
        detail: 'Total vendido',
        icon: Icons.payments_rounded,
        tag: 'receita',
        values: const [5, 6, 6, 8, 7, 9, 10, 12],
      ),
      _KpiCard(
        title: 'Ticket médio',
        value: _formatMoney(averageTicket),
        detail: 'Média por venda',
        icon: Icons.receipt_long_rounded,
        tag: 'média',
        values: const [4, 4, 5, 6, 6, 7, 6, 8],
      ),
      _KpiCard(
        title: 'Fornecedores',
        value: _formatMoney(supplierPurchases),
        detail: 'Compras no período',
        icon: Icons.local_shipping_rounded,
        tag: 'compras',
        values: const [7, 5, 6, 9, 7, 8, 10, 9],
      ),
      _KpiCard(
        title: 'Fiado aberto',
        value: _formatMoney(openCredit),
        detail: 'Saldo atual',
        icon: Icons.person_rounded,
        tag: 'aberto',
        values: const [8, 7, 7, 6, 6, 5, 5, 4],
      ),
      _KpiCard(
        title: 'Estoque baixo',
        value: lowStockCount.toString(),
        detail: 'Itens em alerta',
        icon: Icons.warning_rounded,
        tag: 'atenção',
        values: const [3, 4, 2, 5, 3, 6, 4, 5],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 3
            : width >= 720
            ? 2
            : 1;

        const gap = 14.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards.map((card) {
            return SizedBox(width: cardWidth, child: card);
          }).toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.tag,
    required this.values,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final String tag;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBackground(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor(context)),
        boxShadow: _softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: icon),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: _tagBackground(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: AppColors.wine700,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _titleColor(context),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              color: _bodyColor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(
              color: _mutedColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 26,
            child: CustomPaint(
              painter: _SparkLinePainter(values, color: AppColors.wine700),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMenu extends StatelessWidget {
  const _ReportMenu({required this.selected, required this.onChanged});

  final _ReportSection selected;
  final ValueChanged<_ReportSection> onChanged;

  List<_ReportOption> get _items {
    return [
      _ReportOption(_ReportSection.overview, 'Geral', Icons.dashboard_rounded),
      _ReportOption(
        _ReportSection.products,
        'Produtos',
        Icons.shopping_basket_rounded,
      ),
      _ReportOption(
        _ReportSection.categories,
        'Categorias',
        Icons.category_rounded,
      ),
      _ReportOption(
        _ReportSection.payments,
        'Pagamentos',
        Icons.credit_card_rounded,
      ),
      _ReportOption(
        _ReportSection.suppliers,
        'Fornecedores',
        Icons.local_shipping_rounded,
      ),
      _ReportOption(_ReportSection.lowStock, 'Estoque', Icons.warning_rounded),
      _ReportOption(
        _ReportSection.cash,
        'Caixa',
        Icons.account_balance_wallet_rounded,
      ),
      _ReportOption(_ReportSection.credit, 'Fiado', Icons.person_rounded),
      _ReportOption(
        _ReportSection.detailed,
        'Vendas',
        Icons.receipt_long_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return _LelecoPanel(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width >= 760
              ? 4
              : width >= 520
              ? 2
              : 1;
          const gap = 10.0;
          final buttonWidth = (width - gap * (columns - 1)) / columns;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: items.map((item) {
              return SizedBox(
                width: buttonWidth,
                child: _ReportMenuButton(
                  item: item,
                  active: selected == item.section,
                  onTap: () => onChanged(item.section),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ReportMenuButton extends StatelessWidget {
  const _ReportMenuButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _ReportOption item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.wine900 : _chipBackground(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? AppColors.wine900 : _borderColor(context),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 18,
              color: active ? AppColors.beige100 : AppColors.wine700,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? AppColors.beige100 : _titleColor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
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
    required this.cashMovements,
    required this.manualCashInputs,
    required this.manualCashOutputs,
    required this.manualCashBalance,
    required this.cashOutputCategoryTotals,
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
  final List<CashMovement> cashMovements;
  final double manualCashInputs;
  final double manualCashOutputs;
  final double manualCashBalance;
  final Map<CashMovementCategory, double> cashOutputCategoryTotals;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case _ReportSection.overview:
        return _OverviewDashboard(
          periodLabel: periodLabel,
          revenue: revenue,
          productTotals: productTotals,
          categoryTotals: categoryTotals,
          paymentTotals: paymentTotals,
          supplierTotals: supplierTotals,
          totalSupplierPurchases: totalSupplierPurchases,
          salesCount: sales.length,
        );

      case _ReportSection.products:
        return _PanelWithTable(
          title: 'Vendas por produto',
          subtitle: 'Período: $periodLabel',
          totalLabel: 'Produtos vendidos',
          totalValue: productTotals.length.toString(),
          headers: const ['Produto', 'Qtd vendida', 'Total vendido'],
          rows: productTotals.map((item) {
            return [
              item.name,
              _formatNumber(item.quantity),
              _formatMoney(item.total),
            ];
          }).toList(),
          emptyText: 'Nenhum produto vendido nesse período.',
        );

      case _ReportSection.categories:
        return _PanelWithTable(
          title: 'Vendas por categoria',
          subtitle: 'Período: $periodLabel',
          totalLabel: 'Categorias',
          totalValue: categoryTotals.length.toString(),
          headers: const ['Categoria', 'Qtd vendida', 'Total vendido'],
          rows: categoryTotals.map((item) {
            return [
              item.category,
              _formatNumber(item.quantity),
              _formatMoney(item.total),
            ];
          }).toList(),
          emptyText: 'Nenhuma categoria vendida nesse período.',
        );

      case _ReportSection.payments:
        final total = paymentTotals.values.fold<double>(0, (s, v) => s + v);

        return _PanelWithTable(
          title: 'Formas de pagamento',
          subtitle: 'Período: $periodLabel',
          totalLabel: 'Total recebido',
          totalValue: _formatMoney(total),
          headers: const ['Forma', 'Total'],
          rows: PaymentMethod.values.map((method) {
            return [method.label, _formatMoney(paymentTotals[method] ?? 0)];
          }).toList(),
          emptyText: 'Sem pagamentos nesse período.',
        );

      case _ReportSection.suppliers:
        return _PanelWithTable(
          title: 'Compras de fornecedores',
          subtitle: 'Período: $periodLabel',
          totalLabel: 'Total comprado',
          totalValue: _formatMoney(totalSupplierPurchases),
          headers: const [
            'Data',
            'Fornecedor',
            'Item',
            'Qtd',
            'Total',
            'Status',
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
          emptyText: 'Nenhuma compra de fornecedor nesse período.',
        );

      case _ReportSection.lowStock:
        return _PanelWithTable(
          title: 'Estoque baixo',
          subtitle: 'Situação atual do estoque',
          totalLabel: 'Itens em alerta',
          totalValue: lowStock.length.toString(),
          headers: const ['Código', 'Produto', 'Estoque', 'Mínimo'],
          rows: lowStock.map((product) {
            return [
              product.code,
              product.name,
              '${_formatNumber(product.stockQuantity)} ${product.unit.label}',
              '${_formatNumber(product.minStock)} ${product.unit.label}',
            ];
          }).toList(),
          emptyText: 'Nenhum produto em estoque baixo.',
        );

      case _ReportSection.cash:
        return _CashMovementsReportPanel(
          periodLabel: periodLabel,
          movements: cashMovements,
          inputs: manualCashInputs,
          outputs: manualCashOutputs,
          balance: manualCashBalance,
          outputCategoryTotals: cashOutputCategoryTotals,
        );
      case _ReportSection.credit:
        return _PanelWithTable(
          title: 'Fiado',
          subtitle: 'Resumo atual',
          totalLabel: 'Fiado aberto',
          totalValue: _formatMoney(openCredit),
          headers: const ['Resumo', 'Valor'],
          rows: [
            ['Total em aberto no fiado', _formatMoney(openCredit)],
            ['Detalhamento', 'Abra a aba Fiado para ver cliente por cliente'],
          ],
          emptyText: 'Nenhum fiado em aberto.',
        );

      case _ReportSection.detailed:
        return _PanelWithTable(
          title: 'Vendas detalhadas',
          subtitle: 'Período: $periodLabel',
          totalLabel: 'Vendas',
          totalValue: sales.length.toString(),
          headers: const [
            'Venda',
            'Data',
            'Hora',
            'Pagamento',
            'Itens',
            'Total',
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
          emptyText: 'Nenhuma venda nesse período.',
        );
    }
  }
}

class _OverviewDashboard extends StatelessWidget {
  const _OverviewDashboard({
    required this.periodLabel,
    required this.revenue,
    required this.productTotals,
    required this.categoryTotals,
    required this.paymentTotals,
    required this.supplierTotals,
    required this.totalSupplierPurchases,
    required this.salesCount,
  });

  final String periodLabel;
  final double revenue;
  final List<_ProductTotal> productTotals;
  final List<_CategoryTotal> categoryTotals;
  final Map<PaymentMethod, double> paymentTotals;
  final List<_SupplierTotal> supplierTotals;
  final double totalSupplierPurchases;
  final int salesCount;

  @override
  Widget build(BuildContext context) {
    final totalPayments = paymentTotals.values.fold<double>(0, (s, v) => s + v);
    final averageTicket = salesCount == 0 ? 0.0 : revenue / salesCount;

    final summary = _LelecoPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: Icons.analytics_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo financeiro',
                      style: TextStyle(
                        color: _titleColor(context),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Período: $periodLabel',
                      style: TextStyle(
                        color: _mutedColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 720
                  ? 4
                  : width >= 460
                  ? 2
                  : 1;

              const gap = 10.0;
              final cardWidth = (width - gap * (columns - 1)) / columns;

              final cards = [
                _OverviewMetricData(
                  icon: Icons.payments_rounded,
                  label: 'Faturamento',
                  value: _formatMoney(revenue),
                ),
                _OverviewMetricData(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Vendas',
                  value: salesCount.toString(),
                ),
                _OverviewMetricData(
                  icon: Icons.receipt_long_rounded,
                  label: 'Ticket médio',
                  value: _formatMoney(averageTicket),
                ),
                _OverviewMetricData(
                  icon: Icons.local_shipping_rounded,
                  label: 'Fornecedores',
                  value: _formatMoney(totalSupplierPurchases),
                ),
              ];

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: cards.map((card) {
                  return SizedBox(
                    width: cardWidth,
                    child: _OverviewMetricTile(data: card),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );

    final payments = _BreakdownPanel(
      title: 'Pagamentos',
      total: totalPayments,
      rows: PaymentMethod.values.map((method) {
        return _MiniRow(method.label, _formatMoney(paymentTotals[method] ?? 0));
      }).toList(),
    );

    final topProducts = _MiniListPanel(
      title: 'Top produtos',
      emptyText: 'Nenhum produto vendido.',
      rows: productTotals.take(5).map((item) {
        return _MiniRow(item.name, _formatMoney(item.total));
      }).toList(),
    );

    final categories = _MiniListPanel(
      title: 'Categorias',
      emptyText: 'Nenhuma categoria vendida.',
      rows: categoryTotals.take(5).map((item) {
        return _MiniRow(item.category, _formatMoney(item.total));
      }).toList(),
    );

    final suppliers = _MiniListPanel(
      title: 'Fornecedores',
      emptyText: 'Nenhuma compra registrada.',
      rows: supplierTotals.take(5).map((item) {
        return _MiniRow(item.supplierName, _formatMoney(item.total));
      }).toList(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;

        if (compact) {
          return Column(
            children: [
              summary,
              const SizedBox(height: 14),
              payments,
              const SizedBox(height: 14),
              topProducts,
              const SizedBox(height: 14),
              categories,
              const SizedBox(height: 14),
              suppliers,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                children: [summary, const SizedBox(height: 14), topProducts],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  payments,
                  const SizedBox(height: 14),
                  categories,
                  const SizedBox(height: 14),
                  suppliers,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewMetricData {
  const _OverviewMetricData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _OverviewMetricTile extends StatelessWidget {
  const _OverviewMetricTile({required this.data});

  final _OverviewMetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _cardBackground(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        children: [
          _IconBadge(icon: data.icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleColor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _mutedColor(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
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

class _PanelWithTable extends StatelessWidget {
  const _PanelWithTable({
    required this.title,
    required this.subtitle,
    required this.totalLabel,
    required this.totalValue,
    required this.headers,
    required this.rows,
    required this.emptyText,
  });

  final String title;
  final String subtitle;
  final String totalLabel;
  final String totalValue;
  final List<String> headers;
  final List<List<String>> rows;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return _LelecoPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: title,
            subtitle: subtitle,
            totalLabel: totalLabel,
            totalValue: totalValue,
          ),
          const SizedBox(height: 16),
          rows.isEmpty
              ? _EmptyState(text: emptyText)
              : _ReportTable(headers: headers, rows: rows),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    required this.totalLabel,
    required this.totalValue,
  });

  final String title;
  final String subtitle;
  final String totalLabel;
  final String totalValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;

        final titleBlock = Row(
          children: [
            _IconBadge(icon: Icons.analytics_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _titleColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _mutedColor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final totalBadge = Container(
          constraints: BoxConstraints(
            minWidth: compact ? 0 : 112,
            maxWidth: compact ? constraints.maxWidth : 170,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _tagBackground(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(
                totalLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _mutedColor(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                totalValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _titleColor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleBlock, const SizedBox(height: 12), totalBadge],
          );
        }

        return Row(
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            totalBadge,
          ],
        );
      },
    );
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _tagBackground(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _mutedColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.wine700,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.totalLabel,
    required this.totalValue,
    required this.values,
  });

  final String title;
  final String subtitle;
  final String totalLabel;
  final String totalValue;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return _LelecoPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: title,
            subtitle: subtitle,
            totalLabel: totalLabel,
            totalValue: totalValue,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: CustomPaint(
              painter: _BarChartPainter(
                values,
                color: AppColors.wine700,
                backgroundColor: _isDark(context)
                    ? Colors.white.withOpacity(0.08)
                    : AppColors.beige300.withOpacity(0.4),
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownPanel extends StatelessWidget {
  const _BreakdownPanel({
    required this.title,
    required this.total,
    required this.rows,
  });

  final String title;
  final double total;
  final List<_MiniRow> rows;

  @override
  Widget build(BuildContext context) {
    return _LelecoPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _titleColor(context),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 128,
                height: 128,
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: rows
                        .map((row) => _moneyFromText(row.value))
                        .toList(),
                    primary: AppColors.wine900,
                    secondary: AppColors.wine700,
                    soft: AppColors.beige300,
                    isDark: _isDark(context),
                  ),
                  child: Center(
                    child: Text(
                      _formatMoney(total),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _titleColor(context),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: rows.map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.wine700,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              row.label,
                              style: TextStyle(
                                color: _bodyColor(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            row.value,
                            style: TextStyle(
                              color: _titleColor(context),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniListPanel extends StatelessWidget {
  const _MiniListPanel({
    required this.title,
    required this.emptyText,
    required this.rows,
  });

  final String title;
  final String emptyText;
  final List<_MiniRow> rows;

  @override
  Widget build(BuildContext context) {
    return _LelecoPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _titleColor(context),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text(
              emptyText,
              style: TextStyle(
                color: _mutedColor(context),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            ...rows.map((row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _bodyColor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      row.value,
                      style: TextStyle(
                        color: AppColors.wine700,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.revenue,
    required this.purchases,
    required this.salesCount,
  });

  final double revenue;
  final double purchases;
  final int salesCount;

  @override
  Widget build(BuildContext context) {
    final balance = revenue - purchases;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBackground(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor(context)),
        boxShadow: _softShadow(context),
      ),
      child: Row(
        children: [
          const _IconBadge(icon: Icons.auto_graph_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              salesCount == 0
                  ? 'Sem vendas no período. Registre vendas para gerar análises do dia.'
                  : 'Resultado aproximado do período: ${_formatMoney(balance)} depois das compras registradas.',
              style: TextStyle(
                color: _bodyColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = headers.isEmpty ? 1 : headers.length;
        final minCellWidth = columnCount >= 6
            ? 132.0
            : columnCount >= 4
            ? 150.0
            : 190.0;

        final tableWidth = math.max(
          constraints.maxWidth,
          columnCount * minCellWidth,
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor(context)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  children: [
                    _ReportTableLine(cells: headers, header: true),
                    ...rows.map(
                      (row) => _ReportTableLine(cells: row, header: false),
                    ),
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

class _ReportTableLine extends StatelessWidget {
  const _ReportTableLine({required this.cells, required this.header});

  final List<String> cells;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final safeCells = cells.isEmpty ? const [''] : cells;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / safeCells.length;

        return Container(
          decoration: BoxDecoration(
            color: header ? AppColors.wine900 : _cardBackground(context),
            border: header
                ? null
                : Border(bottom: BorderSide(color: _borderColor(context))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: safeCells.map((cell) {
              return SizedBox(
                width: cellWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: header ? 14 : 14,
                    vertical: header ? 13 : 12,
                  ),
                  child: Text(
                    cell,
                    maxLines: header ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: header ? AppColors.beige100 : _bodyColor(context),
                      fontWeight: header ? FontWeight.w900 : FontWeight.w700,
                      fontSize: header ? 13 : 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _LelecoPanel extends StatelessWidget {
  const _LelecoPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _sectionBackground(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _borderColor(context)),
        boxShadow: _softShadow(context),
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: AppColors.beige100),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBackground(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.wine700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _bodyColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkLinePainter extends CustomPainter {
  _SparkLinePainter(this.values, {required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final range = maxValue - minValue == 0 ? 1 : maxValue - minValue;

    final path = Path();

    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height - ((values[i] - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkLinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter(
    this.values, {
    required this.color,
    required this.backgroundColor,
  });

  final List<double> values;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bars = values.isEmpty ? [0.0, 0, 0, 0, 0, 0] : values;
    final maxValue = bars.reduce(math.max) <= 0 ? 1 : bars.reduce(math.max);
    final barWidth = size.width / (bars.length * 1.8);

    final gridPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < bars.length; i++) {
      final height = (bars[i] / maxValue) * (size.height * 0.82);
      final x = i * (barWidth * 1.8) + barWidth * 0.35;
      final rect = Rect.fromLTWH(x, size.height - height, barWidth, height);

      final paint = Paint()..color = color.withOpacity(0.88);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.primary,
    required this.secondary,
    required this.soft,
    required this.isDark,
  });

  final List<double> values;
  final Color primary;
  final Color secondary;
  final Color soft;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final rect = Offset.zero & size;
    final stroke = size.width * 0.16;

    final basePaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.08) : soft.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawArc(rect.deflate(stroke), 0, math.pi * 2, false, basePaint);

    if (total <= 0) return;

    var start = -math.pi / 2;
    final colors = [
      primary,
      secondary,
      soft,
      primary.withOpacity(0.58),
      secondary.withOpacity(0.58),
    ];

    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * math.pi * 2;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect.deflate(stroke), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.soft != soft ||
        oldDelegate.isDark != isDark;
  }
}

class _ReportOption {
  const _ReportOption(this.section, this.label, this.icon);

  final _ReportSection section;
  final String label;
  final IconData icon;
}

class _MiniRow {
  const _MiniRow(this.label, this.value);

  final String label;
  final String value;
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
  return sales.fold<double>(0, (sum, sale) => sum + (sale.total as double));
}

Map<PaymentMethod, double> _paymentTotals(List<dynamic> sales) {
  final totals = <PaymentMethod, double>{};

  for (final sale in sales) {
    final method = sale.paymentMethod as PaymentMethod;
    totals[method] = (totals[method] ?? 0) + (sale.total as double);
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
  final categoryById = <String, String>{};

  for (final product in products) {
    categoryById[product.id] = product.category.label;
  }

  final map = <String, _CategoryTotal>{};

  for (final sale in sales) {
    for (final item in sale.items) {
      final productId = item.productId as String;
      final category = categoryById[productId] ?? 'Sem categoria';
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

bool _isDark(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark;
}

Color _pageBackground(BuildContext context) {
  return _isDark(context) ? AppColors.darkBackground : const Color(0xFFFBF6F0);
}

Color _sectionBackground(BuildContext context) {
  return _isDark(context) ? const Color(0xFF21171A) : const Color(0xFFFBF6F0);
}

Color _cardBackground(BuildContext context) {
  return _isDark(context) ? const Color(0xFF2A1D21) : const Color(0xFFFBF6F0);
}

Color _chipBackground(BuildContext context) {
  return _isDark(context)
      ? Colors.white.withOpacity(0.05)
      : const Color(0xFFFBF6F0);
}

Color _tagBackground(BuildContext context) {
  return _isDark(context)
      ? AppColors.wine700.withOpacity(0.18)
      : const Color(0xFFEADCCD);
}

Color _stripeColor(BuildContext context) {
  return _isDark(context)
      ? Colors.white.withOpacity(0.035)
      : Colors.transparent;
}

Color _titleColor(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface;
}

Color _bodyColor(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface.withOpacity(0.86);
}

Color _mutedColor(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface.withOpacity(0.58);
}

Color _borderColor(BuildContext context) {
  return _isDark(context)
      ? Colors.white.withOpacity(0.08)
      : const Color(0xFFD8C7B3);
}

List<BoxShadow> _softShadow(BuildContext context) {
  return [
    BoxShadow(
      color: Colors.black.withOpacity(_isDark(context) ? 0.18 : 0.035),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}

double _moneyFromText(String value) {
  final clean = value
      .replaceAll('R\$', '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .trim();

  return double.tryParse(clean) ?? 0;
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

  _ProductTotal copyWith({double? quantity, double? total}) {
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

  _CategoryTotal copyWith({double? quantity, double? total}) {
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

  _SupplierTotal copyWith({int? count, double? total}) {
    return _SupplierTotal(
      supplierName: supplierName,
      count: count ?? this.count,
      total: total ?? this.total,
    );
  }
}

class _ReportsPdfActionPanel extends StatelessWidget {
  const _ReportsPdfActionPanel({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _LelecoPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Exportar relatório em PDF',
              style: TextStyle(
                color: _titleColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Configurar PDF'),
          ),
        ],
      ),
    );
  }
}

enum _PdfReportTemplate { professional, complete, simple }

extension _PdfReportTemplateLabel on _PdfReportTemplate {
  String get label {
    switch (this) {
      case _PdfReportTemplate.professional:
        return 'Profissional';
      case _PdfReportTemplate.complete:
        return 'Completo';
      case _PdfReportTemplate.simple:
        return 'Simples';
    }
  }

  String get description {
    switch (this) {
      case _PdfReportTemplate.professional:
        return 'Resumo executivo bonito, feito para caber em 1 página.';
      case _PdfReportTemplate.complete:
        return 'Completo em 1 página: mostra todos os blocos com dados e compacta as tabelas.';
      case _PdfReportTemplate.simple:
        return 'Mais limpo, rápido e direto.';
    }
  }
}

class _PdfReportOptions {
  const _PdfReportOptions({
    required this.template,
    required this.includeSummary,
    required this.includePayments,
    required this.includeProducts,
    required this.includeCategories,
    required this.includePurchases,
    required this.includeLowStock,
    required this.includeSalesDetails,
    required this.includeCashMovements,
    required this.compactTables,
  });

  final _PdfReportTemplate template;
  final bool includeSummary;
  final bool includePayments;
  final bool includeProducts;
  final bool includeCategories;
  final bool includePurchases;
  final bool includeLowStock;
  final bool includeSalesDetails;
  final bool includeCashMovements;
  final bool compactTables;
}

Future<void> _showReportsPdfOptionsDialog({
  required BuildContext context,
  required String periodLabel,
  required List sales,
  required double revenue,
  required double averageTicket,
  required double openCredit,
  required double supplierPurchases,
  required int lowStockCount,
  required Map paymentTotals,
  required List productTotals,
  required List categoryTotals,
  required List purchases,
  required List lowStock,
}) async {
  var template = _PdfReportTemplate.professional;

  var includeSummary = true;
  var includePayments = true;
  var includeProducts = true;
  var includeCategories = true;
  var includePurchases = false;
  var includeLowStock = false;
  var includeSalesDetails = false;
  var includeCashMovements = true;
  var compactTables = true;

  void applyPreset(_PdfReportTemplate selected) {
    template = selected;

    switch (selected) {
      case _PdfReportTemplate.professional:
        includeSummary = true;
        includePayments = true;
        includeProducts = true;
        includeCategories = true;
        includePurchases = false;
        includeLowStock = false;
        includeSalesDetails = false;
        includeCashMovements = true;
        compactTables = true;
        break;
      case _PdfReportTemplate.complete:
        includeSummary = true;
        includePayments = true;
        includeProducts = true;
        includeCategories = true;
        includePurchases = true;
        includeLowStock = true;
        includeSalesDetails = true;
        includeCashMovements = true;
        compactTables = true;
        break;
      case _PdfReportTemplate.simple:
        includeSummary = true;
        includePayments = true;
        includeProducts = true;
        includeCategories = false;
        includePurchases = false;
        includeLowStock = false;
        includeSalesDetails = false;
        includeCashMovements = true;
        compactTables = true;
        break;
    }
  }

  final options = await showDialog<_PdfReportOptions>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Personalizar PDF'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<_PdfReportTemplate>(
                      initialValue: template,
                      decoration: const InputDecoration(
                        labelText: 'Modelo do relatório',
                        border: OutlineInputBorder(),
                      ),
                      items: _PdfReportTemplate.values.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => applyPreset(value));
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        template.description,
                        style: Theme.of(dialogContext).textTheme.bodySmall,
                      ),
                    ),
                    const Divider(height: 28),
                    CheckboxListTile(
                      value: includeSummary,
                      onChanged: (value) {
                        setDialogState(() => includeSummary = value ?? true);
                      },
                      title: const Text('Resumo geral'),
                      subtitle: const Text(
                        'Vendas, faturamento, ticket médio e estoque baixo',
                      ),
                    ),
                    CheckboxListTile(
                      value: includePayments,
                      onChanged: (value) {
                        setDialogState(() => includePayments = value ?? true);
                      },
                      title: const Text('Formas de pagamento'),
                    ),
                    CheckboxListTile(
                      value: includeProducts,
                      onChanged: (value) {
                        setDialogState(() => includeProducts = value ?? true);
                      },
                      title: const Text('Top produtos'),
                    ),
                    CheckboxListTile(
                      value: includeCategories,
                      onChanged: (value) {
                        setDialogState(() => includeCategories = value ?? true);
                      },
                      title: const Text('Categorias'),
                    ),
                    CheckboxListTile(
                      value: includePurchases,
                      onChanged: (value) {
                        setDialogState(() => includePurchases = value ?? true);
                      },
                      title: const Text('Compras de fornecedores'),
                    ),
                    CheckboxListTile(
                      value: includeLowStock,
                      onChanged: (value) {
                        setDialogState(() => includeLowStock = value ?? true);
                      },
                      title: const Text('Estoque baixo'),
                    ),
                    CheckboxListTile(
                      value: includeSalesDetails,
                      onChanged: (value) {
                        setDialogState(
                          () => includeSalesDetails = value ?? false,
                        );
                      },
                      title: const Text('Vendas detalhadas'),
                      subtitle: const Text('Pode deixar o PDF maior'),
                    ),
                    CheckboxListTile(
                      value: includeCashMovements,
                      onChanged: (value) {
                        setDialogState(
                          () => includeCashMovements = value ?? true,
                        );
                      },
                      title: const Text('Resumo do caixa'),
                      subtitle: const Text(
                        'Totais e saídas por motivo, sem listar tudo',
                      ),
                    ),
                    CheckboxListTile(
                      value: compactTables,
                      onChanged: (value) {
                        setDialogState(() => compactTables = value ?? false);
                      },
                      title: const Text('Tabelas compactas'),
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
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    _PdfReportOptions(
                      template: template,
                      includeSummary: includeSummary,
                      includePayments: includePayments,
                      includeProducts: includeProducts,
                      includeCategories: includeCategories,
                      includePurchases: includePurchases,
                      includeLowStock: includeLowStock,
                      includeSalesDetails: includeSalesDetails,
                      includeCashMovements: includeCashMovements,
                      compactTables: compactTables,
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Gerar PDF'),
              ),
            ],
          );
        },
      );
    },
  );

  if (options == null || !context.mounted) return;

  await _exportReportsPdf(
    context: context,
    periodLabel: periodLabel,
    sales: sales,
    revenue: revenue,
    averageTicket: averageTicket,
    openCredit: openCredit,
    supplierPurchases: supplierPurchases,
    lowStockCount: lowStockCount,
    paymentTotals: paymentTotals,
    productTotals: productTotals,
    categoryTotals: categoryTotals,
    purchases: purchases,
    lowStock: lowStock,
    options: options,
  );
}

Future<void> _exportReportsPdf({
  required BuildContext context,
  required String periodLabel,
  required List sales,
  required double revenue,
  required double averageTicket,
  required double openCredit,
  required double supplierPurchases,
  required int lowStockCount,
  required Map paymentTotals,
  required List productTotals,
  required List categoryTotals,
  required List purchases,
  required List lowStock,
  required _PdfReportOptions options,
}) async {
  try {
    String safeText(Object? Function() read, [String fallback = '-']) {
      try {
        final value = read();
        if (value == null) return fallback;
        final txt = value.toString().trim();
        return txt.isEmpty ? fallback : txt;
      } catch (_) {
        return fallback;
      }
    }

    double safeDouble(Object? Function() read) {
      try {
        final value = read();
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
      } catch (_) {
        return 0;
      }
    }

    final primary = options.template == _PdfReportTemplate.simple
        ? const PdfColor.fromInt(0xFF2B2B2B)
        : const PdfColor.fromInt(0xFF561C24);

    final secondary = options.template == _PdfReportTemplate.simple
        ? const PdfColor.fromInt(0xFFF1F1F1)
        : const PdfColor.fromInt(0xFFE8D8C4);

    final softSurface = options.template == _PdfReportTemplate.simple
        ? const PdfColor.fromInt(0xFFFAFAFA)
        : const PdfColor.fromInt(0xFFFFF8EF);

    final textMuted = const PdfColor.fromInt(0xFF6F625F);
    final white = const PdfColor.fromInt(0xFFFFFFFF);

    final document = pw.Document();

    final paymentRows = <List<String>>[];
    for (final method in PaymentMethod.values) {
      final value = ((paymentTotals[method] ?? 0) as num).toDouble();
      paymentRows.add([method.label, _formatMoney(value)]);
    }

    // PDF_CAIXA_OK_DADOS_START
    final cashPdfProvider = context.read<CashMovementProvider>();
    final cashPdfMovements = cashPdfProvider.todayMovements.toList();
    final cashPdfInputs = cashPdfProvider.todayInputs;
    final cashPdfOutputs = cashPdfProvider.todayOutputs;
    final cashPdfBalance = cashPdfProvider.todayBalance;

    final cashPdfInputCount = cashPdfMovements
        .where((movement) => movement.type == CashMovementType.input)
        .length;

    final cashPdfOutputCount = cashPdfMovements
        .where((movement) => movement.type == CashMovementType.output)
        .length;

    final cashPdfOutputTotals = <CashMovementCategory, double>{};
    final cashPdfOutputCounts = <CashMovementCategory, int>{};

    for (final movement in cashPdfMovements) {
      if (movement.type != CashMovementType.output) continue;

      cashPdfOutputTotals[movement.category] =
          (cashPdfOutputTotals[movement.category] ?? 0) + movement.amount;

      cashPdfOutputCounts[movement.category] =
          (cashPdfOutputCounts[movement.category] ?? 0) + 1;
    }

    final cashPdfSummaryRows = <List<String>>[
      [
        'Entradas no caixa',
        _formatMoney(cashPdfInputs),
        '$cashPdfInputCount lançamento(s)',
      ],
      [
        'Saídas no caixa',
        _formatMoney(cashPdfOutputs),
        '$cashPdfOutputCount lançamento(s)',
      ],
      ['Saldo do caixa', _formatMoney(cashPdfBalance), 'Entradas menos saídas'],
      [
        'Total de lançamentos',
        '${cashPdfMovements.length}',
        'Detalhes completos na tela Caixa',
      ],
    ];

    final cashPdfOutputRows = cashPdfOutputTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final cashPdfOutputTableRows = cashPdfOutputRows.map<List<String>>((entry) {
      final count = cashPdfOutputCounts[entry.key] ?? 0;

      return [
        entry.key.label,
        _formatMoney(entry.value),
        '$count lançamento(s)',
      ];
    }).toList();
    // PDF_CAIXA_OK_DADOS_END

    final productRows = <List<String>>[];
    for (final item in productTotals.take(options.compactTables ? 5 : 20)) {
      final dynamic p = item;
      productRows.add([
        safeText(() => p.name),
        _formatNumber(safeDouble(() => p.quantity)),
        _formatMoney(safeDouble(() => p.total)),
      ]);
    }

    final categoryRows = <List<String>>[];
    for (final item in categoryTotals.take(options.compactTables ? 5 : 20)) {
      final dynamic c = item;
      categoryRows.add([
        safeText(() => c.category),
        _formatNumber(safeDouble(() => c.quantity)),
        _formatMoney(safeDouble(() => c.total)),
      ]);
    }

    final purchaseRows = <List<String>>[];
    for (final item in purchases.take(options.compactTables ? 5 : 40)) {
      final dynamic p = item;
      purchaseRows.add([
        safeText(() {
          final date = p.purchaseDate;
          if (date is DateTime) return _formatDate(date);
          return date;
        }),
        safeText(() => p.supplierName),
        safeText(() => p.itemName),
        _formatNumber(safeDouble(() => p.quantity)),
        _formatMoney(safeDouble(() => p.totalCost)),
        safeText(() => p.paid == true ? 'Pago' : 'Em aberto'),
      ]);
    }

    final lowStockRows = <List<String>>[];
    for (final item in lowStock.take(options.compactTables ? 6 : 50)) {
      final dynamic p = item;
      lowStockRows.add([
        safeText(() => p.code),
        safeText(() => p.name),
        _formatNumber(safeDouble(() => p.stockQuantity)),
        _formatNumber(safeDouble(() => p.minStock)),
      ]);
    }

    final saleRows = <List<String>>[];
    for (final item in sales.take(options.compactTables ? 8 : 120)) {
      final dynamic sale = item;
      saleRows.add([
        safeText(() => sale.shortId, 'Venda'),
        safeText(() {
          final date = sale.createdAt;
          if (date is DateTime) {
            return '${_formatDate(date)} ${_formatTime(date)}';
          }
          return date;
        }),
        safeText(() => sale.paymentMethod.label),
        safeText(() => sale.totalItems),
        _formatMoney(safeDouble(() => sale.total)),
      ]);
    }

    pw.Widget metricCard(String title, String value, String subtitle) {
      return pw.Container(
        width: options.compactTables ? 103 : 150,
        padding: const pw.EdgeInsets.all(7),
        decoration: pw.BoxDecoration(
          color: softSurface,
          border: pw.Border.all(color: secondary, width: 1),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: textMuted,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: primary,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              subtitle,
              style: pw.TextStyle(color: textMuted, fontSize: 7),
            ),
          ],
        ),
      );
    }

    pw.Widget sectionTitle(String title, String subtitle) {
      return pw.Container(
        margin: pw.EdgeInsets.only(
          top: options.compactTables ? 4 : 10,
          bottom: options.compactTables ? 2 : 5,
        ),
        padding: const pw.EdgeInsets.only(left: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(color: primary, width: 4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                color: primary,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: pw.TextStyle(fontSize: 8, color: textMuted),
            ),
          ],
        ),
      );
    }

    pw.Widget dataTable({
      required List<String> headers,
      required List<List<String>> rows,
      required String emptyText,
    }) {
      if (rows.isEmpty) {
        return pw.Container(
          padding: options.compactTables
              ? const pw.EdgeInsets.all(5)
              : const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: softSurface,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            emptyText,
            style: pw.TextStyle(color: textMuted, fontSize: 9),
          ),
        );
      }

      return pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        border: pw.TableBorder.all(
          color: const PdfColor.fromInt(0xFFE6DED7),
          width: 0.5,
        ),
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: white,
          fontSize: options.compactTables ? 6 : 8,
        ),
        headerDecoration: pw.BoxDecoration(color: primary),
        cellStyle: pw.TextStyle(
          fontSize: options.compactTables ? 6 : 8,
          color: const PdfColor.fromInt(0xFF241A1C),
        ),
        oddRowDecoration: pw.BoxDecoration(color: softSurface),
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
        cellPadding: options.compactTables
            ? const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2)
            : const pw.EdgeInsets.all(6),
      );
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(14, 12, 14, 14),
        footer: (pdfContext) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFE6DED7),
                  width: 0.7,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Açougue do Leleco • Relatório ${options.template.label}',
                  style: pw.TextStyle(fontSize: 7, color: textMuted),
                ),
                pw.Text(
                  'Página ${pdfContext.pageNumber} de ${pdfContext.pagesCount}',
                  style: pw.TextStyle(fontSize: 7, color: textMuted),
                ),
              ],
            ),
          );
        },
        build: (_) {
          final widgets = <pw.Widget>[
            pw.Container(
              padding: const pw.EdgeInsets.all(9),
              decoration: pw.BoxDecoration(
                color: primary,
                borderRadius: pw.BorderRadius.circular(14),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'AÇOUGUE DO LELECO',
                    style: pw.TextStyle(
                      color: white,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Relatório Gerencial',
                    style: pw.TextStyle(
                      color: white,
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Período: $periodLabel',
                    style: pw.TextStyle(color: secondary, fontSize: 11),
                  ),
                  pw.Text(
                    'Gerado em: ${_formatDate(DateTime.now())} às ${_formatTime(DateTime.now())}',
                    style: pw.TextStyle(color: secondary, fontSize: 9),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
          ];

          if (options.includeSummary) {
            widgets.addAll([
              sectionTitle(
                'Resumo geral',
                'Visão rápida dos principais números do período.',
              ),
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  metricCard(
                    'Vendas',
                    sales.length.toString(),
                    'Quantidade no período',
                  ),
                  metricCard(
                    'Faturamento',
                    _formatMoney(revenue),
                    'Total vendido',
                  ),
                  metricCard(
                    'Ticket médio',
                    _formatMoney(averageTicket),
                    'Média por venda',
                  ),
                  metricCard(
                    'Fiado aberto',
                    _formatMoney(openCredit),
                    'Clientes em aberto',
                  ),
                  metricCard(
                    'Fornecedores',
                    _formatMoney(supplierPurchases),
                    'Compras no período',
                  ),
                  metricCard(
                    'Estoque baixo',
                    lowStockCount.toString(),
                    'Itens para atenção',
                  ),
                ],
              ),
            ]);
          }

          if (options.includePayments) {
            widgets.addAll([
              sectionTitle(
                'Formas de pagamento',
                'Distribuição do faturamento por tipo de pagamento.',
              ),
              dataTable(
                headers: const ['Forma', 'Total'],
                rows: paymentRows,
                emptyText: 'Nenhum pagamento registrado no período.',
              ),
            ]);
          }

          // PDF_CAIXA_OK_SECAO_START
          if (options.includeCashMovements) {
            widgets.addAll([
              pw.SizedBox(height: 8),
              sectionTitle(
                'Controle do caixa',
                'Resumo das entradas e saídas do caixa do caixa.',
              ),
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  metricCard(
                    'Entradas no caixa',
                    _formatMoney(cashPdfInputs),
                    '$cashPdfInputCount lançamento(s)',
                  ),
                  metricCard(
                    'Saídas no caixa',
                    _formatMoney(cashPdfOutputs),
                    '$cashPdfOutputCount lançamento(s)',
                  ),
                  metricCard(
                    'Saldo do caixa',
                    _formatMoney(cashPdfBalance),
                    'Entradas menos saídas',
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              dataTable(
                headers: const ['Indicador', 'Valor', 'Observação'],
                rows: cashPdfSummaryRows,
                emptyText: 'Nenhuma movimentação no caixa no caixa.',
              ),
              pw.SizedBox(height: 7),
              dataTable(
                headers: const ['Saídas agrupadas por motivo', 'Total', 'Qtd.'],
                rows: cashPdfOutputTableRows,
                emptyText: 'Nenhuma saída registrada hoje.',
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'O PDF mostra o resumo do caixa para não ficar grande. O histórico completo fica na tela Caixa.',
                style: pw.TextStyle(fontSize: 7, color: textMuted),
              ),
            ]);
          }
          // PDF_CAIXA_OK_SECAO_END

          if (options.includeProducts &&
              (options.template != _PdfReportTemplate.complete ||
                  productRows.isNotEmpty)) {
            widgets.addAll([
              sectionTitle(
                'Top produtos',
                'Produtos com melhor desempenho no período.',
              ),
              dataTable(
                headers: const ['Produto', 'Quantidade', 'Total'],
                rows: productRows,
                emptyText: 'Nenhum produto vendido no período.',
              ),
            ]);
          }

          if (options.includeCategories &&
              (options.template != _PdfReportTemplate.complete ||
                  categoryRows.isNotEmpty)) {
            widgets.addAll([
              sectionTitle('Categorias', 'Resultado separado por categoria.'),
              dataTable(
                headers: const ['Categoria', 'Quantidade', 'Total'],
                rows: categoryRows,
                emptyText: 'Nenhuma categoria registrada no período.',
              ),
            ]);
          }

          if (options.includePurchases &&
              (options.template != _PdfReportTemplate.complete ||
                  purchaseRows.isNotEmpty)) {
            widgets.addAll([
              sectionTitle(
                'Compras de fornecedores',
                'Entradas e compras registradas no período.',
              ),
              dataTable(
                headers: const [
                  'Data',
                  'Fornecedor',
                  'Item',
                  'Qtd',
                  'Total',
                  'Status',
                ],
                rows: purchaseRows,
                emptyText: 'Nenhuma compra registrada no período.',
              ),
            ]);
          }

          if (options.includeLowStock &&
              (options.template != _PdfReportTemplate.complete ||
                  lowStockRows.isNotEmpty)) {
            widgets.addAll([
              sectionTitle(
                'Estoque baixo',
                'Produtos que precisam de atenção para reposição.',
              ),
              dataTable(
                headers: const ['Código', 'Produto', 'Estoque', 'Mínimo'],
                rows: lowStockRows,
                emptyText: 'Nenhum produto em estoque baixo.',
              ),
            ]);
          }

          if (options.includeSalesDetails &&
              (options.template != _PdfReportTemplate.complete ||
                  saleRows.isNotEmpty)) {
            widgets.addAll([
              sectionTitle(
                'Vendas detalhadas',
                'Lista das vendas incluídas no período selecionado.',
              ),
              dataTable(
                headers: const [
                  'Venda',
                  'Data/Hora',
                  'Pagamento',
                  'Itens',
                  'Total',
                ],
                rows: saleRows,
                emptyText: 'Nenhuma venda registrada no período.',
              ),
            ]);
          }

          return widgets;
        },
      ),
    );

    final bytes = await document.save();
    final outputDir = await _reportsOutputDirectory();
    final fileName =
        'relatorio_${options.template.label.toLowerCase()}_${_reportsFileTimestamp(DateTime.now())}.pdf'
            .replaceAll(' ', '_');
    final file = File('${outputDir.path}${Platform.pathSeparator}$fileName');

    await file.writeAsBytes(bytes, flush: true);

    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('PDF gerado com sucesso'),
            content: SelectableText(
              'Modelo: ${options.template.label}\n\nArquivo salvo em:\n${file.path}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  } catch (error, stackTrace) {
    debugPrint('ERRO AO GERAR PDF: $error');
    debugPrintStack(stackTrace: stackTrace);

    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Erro ao gerar PDF'),
            content: SelectableText(error.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}

Future<Directory> _reportsOutputDirectory() async {
  final home =
      Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      Directory.current.path;

  final downloads = Directory('$home${Platform.pathSeparator}Downloads');
  final baseDir = await downloads.exists() ? downloads : Directory.current;

  final outputDir = Directory(
    '${baseDir.path}${Platform.pathSeparator}Relatorios_Acougue_Do_Leleco',
  );

  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  return outputDir;
}

String _reportsFileTimestamp(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');

  return '${date.year}-${two(date.month)}-${two(date.day)}_'
      '${two(date.hour)}-${two(date.minute)}-${two(date.second)}';
}

class _CashFlowSummaryPanel extends StatelessWidget {
  const _CashFlowSummaryPanel({
    required this.inputs,
    required this.outputs,
    required this.balance,
  });

  final double inputs;
  final double outputs;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return _LelecoPanel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final cards = [
            _CashReportMiniCard(
              title: 'Entradas no caixa',
              value: _formatMoney(inputs),
              icon: Icons.south_west_rounded,
              color: Colors.green.shade700,
              detail: 'Dinheiro que entrou fora das vendas',
            ),
            _CashReportMiniCard(
              title: 'Saídas do caixa',
              value: _formatMoney(outputs),
              icon: Icons.north_east_rounded,
              color: Colors.red.shade700,
              detail: 'Compras, retiradas e despesas',
            ),
            _CashReportMiniCard(
              title: 'Saldo do caixa',
              value: _formatMoney(balance),
              icon: Icons.account_balance_wallet_rounded,
              color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
              detail: 'Entradas menos saídas manuais',
            ),
          ];

          if (compact) {
            return Column(
              children: cards
                  .map(
                    (card) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: card,
                    ),
                  )
                  .toList(),
            );
          }

          return Row(
            children: cards
                .map(
                  (card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: card,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _CashReportMiniCard extends StatelessWidget {
  const _CashReportMiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.detail,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _mutedColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _mutedColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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

class _CashMovementsReportPanel extends StatelessWidget {
  const _CashMovementsReportPanel({
    required this.periodLabel,
    required this.movements,
    required this.inputs,
    required this.outputs,
    required this.balance,
    required this.outputCategoryTotals,
  });

  final String periodLabel;
  final List<CashMovement> movements;
  final double inputs;
  final double outputs;
  final double balance;
  final Map<CashMovementCategory, double> outputCategoryTotals;

  @override
  Widget build(BuildContext context) {
    final categoryRows = outputCategoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final movementRows = movements.map((movement) {
      final sign = movement.type == CashMovementType.input ? '+' : '-';

      return [
        _formatDate(movement.createdAt),
        _formatTime(movement.createdAt),
        movement.type.label,
        movement.category.label,
        movement.paymentMethod.label,
        movement.reason.isEmpty ? movement.category.label : movement.reason,
        '$sign ${_formatMoney(movement.amount)}',
      ];
    }).toList();

    return Column(
      children: [
        _LelecoPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PanelHeader(
                title: 'Controle do caixa',
                subtitle: 'Entradas e saídas manuais • $periodLabel',
                totalLabel: 'Saldo do caixa',
                totalValue: _formatMoney(balance),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;

                  final cards = [
                    _OverviewMetricData(
                      icon: Icons.south_west_rounded,
                      label: 'Entradas no caixa',
                      value: _formatMoney(inputs),
                    ),
                    _OverviewMetricData(
                      icon: Icons.north_east_rounded,
                      label: 'Saídas no caixa',
                      value: _formatMoney(outputs),
                    ),
                    _OverviewMetricData(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Saldo do caixa',
                      value: _formatMoney(balance),
                    ),
                  ];

                  if (compact) {
                    return Column(
                      children: cards
                          .map(
                            (card) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _OverviewMetricTile(data: card),
                            ),
                          )
                          .toList(),
                    );
                  }

                  return Row(
                    children: cards
                        .map(
                          (card) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: _OverviewMetricTile(data: card),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PanelWithTable(
          title: 'Saídas por motivo',
          subtitle: 'Categorias de dinheiro que saiu do caixa',
          totalLabel: 'Total de saídas',
          totalValue: _formatMoney(outputs),
          headers: const ['Motivo', 'Total'],
          rows: categoryRows
              .map((entry) => [entry.key.label, _formatMoney(entry.value)])
              .toList(),
          emptyText: 'Nenhuma saída registrada nesse período.',
        ),
        const SizedBox(height: 14),
        _PanelWithTable(
          title: 'Histórico do caixa',
          subtitle: 'Tudo que entrou ou saiu manualmente',
          totalLabel: 'Registros',
          totalValue: movements.length.toString(),
          headers: const [
            'Data',
            'Hora',
            'Tipo',
            'Categoria',
            'Forma',
            'Motivo',
            'Valor',
          ],
          rows: movementRows,
          emptyText: 'Nenhuma movimentação no caixa nesse período.',
        ),
      ],
    );
  }
}

List<CashMovement> _filterCashMovementsByPeriod(
  List<CashMovement> movements,
  _ReportPeriod period,
) {
  final now = DateTime.now();

  DateTime? start;

  switch (period) {
    case _ReportPeriod.today:
      start = DateTime(now.year, now.month, now.day);
      break;
    case _ReportPeriod.sevenDays:
      start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));
      break;
    case _ReportPeriod.thirtyDays:
      start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 29));
      break;
    case _ReportPeriod.all:
      start = null;
      break;
  }

  final result = movements.where((movement) {
    if (start == null) return true;
    return !movement.createdAt.isBefore(start);
  }).toList();

  result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return result;
}

double _cashMovementTotal(List<CashMovement> movements, CashMovementType type) {
  return movements
      .where((movement) => movement.type == type)
      .fold(0.0, (total, movement) => total + movement.amount);
}

Map<CashMovementCategory, double> _cashOutputTotalsByCategory(
  List<CashMovement> movements,
) {
  final result = <CashMovementCategory, double>{};

  for (final movement in movements) {
    if (movement.type != CashMovementType.output) continue;

    result[movement.category] =
        (result[movement.category] ?? 0) + movement.amount;
  }

  return result;
}
