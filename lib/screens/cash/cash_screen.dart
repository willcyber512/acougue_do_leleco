import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/payment_method.dart';
import '../../models/sale.dart';
import '../../providers/inventory_provider.dart';
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
        final validSales = visibleSales.where((sale) => !sale.isCanceled).toList();

        final totalVisible = validSales.fold(
          0.0,
          (total, sale) => total + sale.total,
        );

        final canceledCount = visibleSales.where((sale) => sale.isCanceled).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.payments_rounded,
                    title: showOnlyToday ? 'Faturamento hoje' : 'Faturamento total',
                    value: _formatMoney(totalVisible),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.receipt_long_rounded,
                    title: showOnlyToday ? 'Vendas válidas hoje' : 'Vendas válidas',
                    value: validSales.length.toString(),
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
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.pix_rounded,
                    title: 'Pix',
                    value: _formatMoney(_sumByMethod(validSales, PaymentMethod.pix)),
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
            _PaymentSummary(sales: validSales),
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
            'Cancelamento devolve o estoque automaticamente',
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
    final statusColor = sale.isCanceled ? AppColors.danger : AppColors.success;
    final statusText = sale.isCanceled ? 'Cancelada' : 'Finalizada';

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
                  color: sale.isCanceled ? AppColors.danger : AppColors.wine900,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  sale.isCanceled
                      ? Icons.cancel_rounded
                      : Icons.receipt_long_rounded,
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
              Container(
                width: 105,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 125,
                child: Text(
                  _formatMoney(sale.total),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: sale.isCanceled ? AppColors.danger : AppColors.wine700,
                        decoration:
                            sale.isCanceled ? TextDecoration.lineThrough : null,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              if (!sale.isCanceled)
                IconButton(
                  tooltip: 'Cancelar venda',
                  onPressed: () => _cancelSaleFlow(context, sale),
                  icon: const Icon(Icons.cancel_outlined),
                ),
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
          height: 500,
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
              if (sale.isCanceled) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Venda cancelada em ${_formatDateTime(sale.canceledAt!)}.\nMotivo: ${sale.cancelReason ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
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
          if (!sale.isCanceled)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _cancelSaleFlow(context, sale);
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar venda'),
            ),
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

Future<void> _cancelSaleFlow(BuildContext context, SaleRecord sale) async {
  final sales = context.read<SalesProvider>();
  final inventory = context.read<InventoryProvider>();

  final currentSale = sales.findSaleById(sale.id);

  if (currentSale == null) {
    _showMessage(context, 'Venda não encontrada.');
    return;
  }

  if (currentSale.isCanceled) {
    _showMessage(context, 'Essa venda já foi cancelada.');
    return;
  }

  final reason = await _askCancelReason(context);

  if (reason == null) return;

  final restored = inventory.restoreSaleRecordStock(currentSale);

  if (!restored) {
    _showMessage(context, 'Não foi possível devolver o estoque dessa venda.');
    return;
  }

  final canceled = sales.cancelSale(currentSale.id, reason);

  if (!canceled) {
    _showMessage(context, 'Não foi possível cancelar a venda.');
    return;
  }

  _showMessage(context, 'Venda #${currentSale.shortId} cancelada e estoque devolvido.');
}

Future<String?> _askCancelReason(BuildContext context) async {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Cancelar venda?'),
        content: SizedBox(
          width: 440,
          child: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo do cancelamento',
              hintText: 'Ex: cliente desistiu, erro no lançamento...',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim().isEmpty
                  ? 'Cancelamento manual'
                  : controller.text.trim();

              Navigator.of(dialogContext).pop(reason);
            },
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      );
    },
  );
}

double _sumByMethod(List<SaleRecord> sales, PaymentMethod method) {
  return sales
      .where((sale) => sale.paymentMethod == method && !sale.isCanceled)
      .fold(0.0, (total, sale) => total + sale.total);
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
