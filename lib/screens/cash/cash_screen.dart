import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/payment_method.dart';
import '../../models/sale.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/leleco_metric_card.dart';

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  bool showOnlyToday = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, sales, _) {
        final visibleSales = showOnlyToday ? sales.todaySales : sales.sales;
        final totalVisible = visibleSales.fold(
          0.0,
          (total, sale) => total + sale.total,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 230,
                  child: LelecoMetricCard(
                    icon: Icons.payments_rounded,
                    title: showOnlyToday ? 'Faturamento hoje' : 'Faturamento total',
                    value: _formatMoney(totalVisible),
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: LelecoMetricCard(
                    icon: Icons.receipt_long_rounded,
                    title: showOnlyToday ? 'Vendas hoje' : 'Vendas totais',
                    value: visibleSales.length.toString(),
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: LelecoMetricCard(
                    icon: Icons.pix_rounded,
                    title: 'Pix',
                    value: _formatMoney(_sumByMethod(visibleSales, PaymentMethod.pix)),
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: LelecoMetricCard(
                    icon: Icons.credit_card_rounded,
                    title: 'Cartões',
                    value: _formatMoney(
                      _sumByMethod(visibleSales, PaymentMethod.debito) +
                          _sumByMethod(visibleSales, PaymentMethod.credito),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _CashToolbar(
              showOnlyToday: showOnlyToday,
              onChanged: (value) {
                setState(() => showOnlyToday = value);
              },
            ),
            const SizedBox(height: 16),
            _PaymentSummary(sales: visibleSales),
            const SizedBox(height: 16),
            Expanded(
              child: visibleSales.isEmpty
                  ? const _EmptyCash()
                  : ListView.separated(
                      itemCount: visibleSales.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _SaleCard(sale: visibleSales[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CashToolbar extends StatelessWidget {
  const _CashToolbar({
    required this.showOnlyToday,
    required this.onChanged,
  });

  final bool showOnlyToday;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              icon: Icon(Icons.today_rounded),
              label: Text('Hoje'),
            ),
            ButtonSegment(
              value: false,
              icon: Icon(Icons.list_alt_rounded),
              label: Text('Todas'),
            ),
          ],
          selected: {showOnlyToday},
          onSelectionChanged: (values) {
            onChanged(values.first);
          },
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.wine900.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Modo caixa: visualização das vendas finalizadas',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.sales});

  final List<SaleRecord> sales;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: PaymentMethod.values.map((method) {
        return _PaymentChip(
          label: method.label,
          value: _formatMoney(_sumByMethod(sales, method)),
        );
      }).toList(),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale});

  final SaleRecord sale;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openSaleDetails(context, sale),
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
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.beige100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venda #${sale.shortId}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDateTime(sale.createdAt)} • ${sale.paymentMethod.label}',
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  '${sale.items.length} item(ns)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(
                width: 140,
                child: Text(
                  _formatMoney(sale.total),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.wine700,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCash extends StatelessWidget {
  const _EmptyCash();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Nenhuma venda encontrada.'),
    );
  }
}

Future<void> _openSaleDetails(BuildContext context, SaleRecord sale) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Detalhes da venda #${sale.shortId}'),
        content: SizedBox(
          width: 760,
          height: 460,
          child: Column(
            children: [
              Row(
                children: [
                  _DetailBox(
                    title: 'Data',
                    value: _formatDateTime(sale.createdAt),
                  ),
                  const SizedBox(width: 12),
                  _DetailBox(
                    title: 'Pagamento',
                    value: sale.paymentMethod.label,
                  ),
                  const SizedBox(width: 12),
                  _DetailBox(
                    title: 'Total',
                    value: _formatMoney(sale.total),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: sale.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = sale.items[index];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.wine900,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.shopping_basket_rounded,
                                color: AppColors.beige100,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Código ${item.productCode} • ${_formatNumber(item.quantity)} ${item.unitLabel} x ${_formatMoney(item.unitPrice)}',
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatMoney(item.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}

class _DetailBox extends StatelessWidget {
  const _DetailBox({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
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
