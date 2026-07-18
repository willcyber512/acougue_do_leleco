import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/payment_method.dart';
import '../../models/sale.dart';
import '../../models/cash_movement.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/cash_movement_provider.dart';
import '../../widgets/leleco_metric_card.dart';
import '../../widgets/sale_receipt_dialog.dart';
import '../../services/cash_sale_sync.dart';
import '../../providers/customers_provider.dart';

List<SaleRecord> _cashOnlySales(Iterable<SaleRecord> sales) {
  final result = sales
      .where((sale) => sale.paymentMethod != PaymentMethod.fiado)
      .toList();

  result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return result;
}

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
        final visibleSales = showOnlyToday
            ? _cashOnlySales(sales.todaySales)
            : _cashOnlySales(sales.sales);
        final validSales = visibleSales
            .where((sale) => !sale.isCanceled)
            .toList();

        final totalVisible = validSales.fold<double>(
          0,
          (total, sale) => total + sale.total,
        );

        final canceledCount = visibleSales
            .where((sale) => sale.isCanceled)
            .length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 980
                ? 4
                : width >= 640
                ? 2
                : 1;

            const gap = 16.0;
            final metricWidth = (width - gap * (columns - 1)) / columns;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: metricWidth,
                        child: LelecoMetricCard(
                          icon: Icons.payments_rounded,
                          title: showOnlyToday
                              ? 'Faturamento hoje'
                              : 'Faturamento total',
                          value: _formatMoney(totalVisible),
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: LelecoMetricCard(
                          icon: Icons.receipt_long_rounded,
                          title: showOnlyToday
                              ? 'Vendas válidas hoje'
                              : 'Vendas válidas',
                          value: validSales.length.toString(),
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: LelecoMetricCard(
                          icon: Icons.cancel_rounded,
                          title: 'Canceladas',
                          value: canceledCount.toString(),
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: LelecoMetricCard(
                          icon: Icons.pix_rounded,
                          title: 'Pix',
                          value: _formatMoney(
                            _sumByMethod(validSales, PaymentMethod.pix),
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
                  const _CashMovementsPanel(),
                  const SizedBox(height: 14),
                  _PaymentSummary(sales: validSales),
                  const SizedBox(height: 16),
                  if (visibleSales.isEmpty)
                    const SizedBox(height: 260, child: _EmptyCash())
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleSales.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _SaleCard(sale: visibleSales[index]);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

List<SaleRecord> _cashRegisterSales(List<SaleRecord> sales) {
  return sales
      .where((sale) => sale.paymentMethod != PaymentMethod.fiado)
      .toList();
}

class _CashToolbar extends StatelessWidget {
  const _CashToolbar({required this.showOnlyToday, required this.onChanged});

  final bool showOnlyToday;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
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
        Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.beige100.withOpacity(0.08)
                : AppColors.wine900.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark
                  ? AppColors.beige100.withOpacity(0.10)
                  : AppColors.wine900.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_rounded,
                size: 18,
                color: isDark ? AppColors.beige100 : AppColors.wine700,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Cancelamento devolve o estoque automaticamente',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.beige100 : AppColors.wine900,
                  ),
                ),
              ),
            ],
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
  const _PaymentChip({required this.label, required this.value});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openSaleDetails(context, sale),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;

              final icon = Container(
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
              );

              final info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Venda #${sale.shortId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDateTime(sale.createdAt)} • ${sale.paymentMethod.label}${sale.customerName == null ? '' : ' • ${sale.customerName}'}',
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );

              final status = Container(
                width: 108,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(0.18)),
                ),
                child: Text(
                  statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );

              final total = Text(
                _formatMoney(sale.total),
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: sale.isCanceled
                      ? AppColors.danger
                      : isDark
                      ? AppColors.beige100
                      : AppColors.wine700,
                  decoration: sale.isCanceled
                      ? TextDecoration.lineThrough
                      : null,
                ),
              );

              final actions = Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (!sale.isCanceled)
                    IconButton(
                      tooltip: 'Cancelar venda',
                      onPressed: () => _cancelSaleFlow(context, sale),
                      icon: const Icon(Icons.cancel_outlined),
                    ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        icon,
                        const SizedBox(width: 14),
                        Expanded(child: info),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [status, total, actions],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  icon,
                  const SizedBox(width: 16),
                  Expanded(child: info),
                  const SizedBox(width: 12),
                  status,
                  const SizedBox(width: 12),
                  SizedBox(width: 125, child: total),
                  const SizedBox(width: 8),
                  actions,
                ],
              );
            },
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
    return const Center(child: Text('Nenhuma venda recebida encontrada.'));
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
                  _DetailBox(title: 'Total', value: _formatMoney(sale.total)),
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
          OutlinedButton.icon(
            onPressed: () => showSaleReceiptDialog(context, sale),
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('Comprovante'),
          ),
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
  const _DetailBox({required this.title, required this.value});

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
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

Future<void> _cancelSaleFlow(BuildContext context, SaleRecord sale) async {
  final sales = context.read<SalesProvider>();
  final inventory = context.read<InventoryProvider>();
  final customers = context.read<CustomersProvider>();

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

  if (canceled) {
    removeSaleCashMovement(context, currentSale);

    if (currentSale.paymentMethod == PaymentMethod.fiado) {
      customers.deleteEntriesBySaleId(currentSale.id);
    }
  }

  if (!canceled) {
    _showMessage(context, 'Não foi possível cancelar a venda.');
    return;
  }

  _showMessage(
    context,
    'Venda #${currentSale.shortId} cancelada e estoque devolvido.',
  );
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
    ..showSnackBar(SnackBar(content: Text(message)));
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

class _CashMovementsPanel extends StatefulWidget {
  const _CashMovementsPanel();

  @override
  State<_CashMovementsPanel> createState() => _CashMovementsPanelState();
}

class _CashMovementsPanelState extends State<_CashMovementsPanel> {
  @override
  Widget build(BuildContext context) {
    final cash = context.read<CashMovementProvider>();
    final movements = cash.todayMovements.take(10).toList();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Controle manual do caixa',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Registre dinheiro que entrou ou saiu fora das vendas.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _CashMovementSummaryCard(
                    title: 'Entradas manuais',
                    value: cash.todayInputs,
                    icon: Icons.south_west_rounded,
                    color: Colors.green.shade700,
                    subtitle: 'Reforços e recebimentos extras',
                  ),
                  _CashMovementSummaryCard(
                    title: 'Saídas manuais',
                    value: cash.todayOutputs,
                    icon: Icons.north_east_rounded,
                    color: Colors.red.shade700,
                    subtitle: 'Compras, retiradas e despesas',
                  ),
                  _CashMovementSummaryCard(
                    title: 'Saldo manual',
                    value: cash.todayBalance,
                    icon: Icons.calculate_rounded,
                    color: cash.todayBalance >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    subtitle: 'Entradas menos saídas',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      await _showCashMovementDialog(
                        context,
                        initialType: CashMovementType.output,
                      );

                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    label: const Text('Registrar saída'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _showCashMovementDialog(
                        context,
                        initialType: CashMovementType.input,
                      );

                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Registrar entrada'),
                  ),
                ],
              ),
              const Divider(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Histórico de hoje',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${movements.length} registro(s)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (movements.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nenhuma entrada ou saída manual registrada hoje.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ...movements.map(
                  (movement) => _CashMovementTile(
                    movement: movement,
                    onChanged: () {
                      if (mounted) setState(() {});
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashMovementSummaryCard extends StatelessWidget {
  const _CashMovementSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatMoney(value),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _CashMovementTile extends StatelessWidget {
  const _CashMovementTile({required this.movement, required this.onChanged});

  final CashMovement movement;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final isInput = movement.type == CashMovementType.input;
    final color = isInput ? Colors.green.shade700 : Colors.red.shade700;
    final sign = isInput ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.10),
            child: Icon(
              isInput ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.reason.isEmpty
                      ? movement.category.label
                      : movement.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${movement.type.label} • ${movement.category.label} • ${movement.paymentMethod.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (movement.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    movement.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign ${_formatMoney(movement.amount)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 36),
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Excluir lançamento?'),
                        content: Text(
                          'Remover este registro do caixa?\n\n'
                          '${movement.reason.isEmpty ? movement.category.label : movement.reason}\n'
                          '${_formatMoney(movement.amount)}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Excluir'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed != true) return;

                  context.read<CashMovementProvider>().deleteMovement(
                    movement.id,
                  );

                  onChanged();
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Excluir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CashMovementDraft {
  const _CashMovementDraft({
    required this.type,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.reason,
    required this.description,
  });

  final CashMovementType type;
  final CashMovementCategory category;
  final double amount;
  final PaymentMethod paymentMethod;
  final String reason;
  final String description;
}

Future<void> _showCashMovementDialog(
  BuildContext context, {
  required CashMovementType initialType,
}) async {
  final cashProvider = context.read<CashMovementProvider>();

  final amountController = TextEditingController();
  final reasonController = TextEditingController();
  final descriptionController = TextEditingController();

  var type = initialType;
  var category = initialType == CashMovementType.output
      ? CashMovementCategory.expense
      : CashMovementCategory.cashIn;
  var paymentMethod = PaymentMethod.dinheiro;
  String? errorMessage;

  List<CashMovementCategory> categoriesForType(CashMovementType selectedType) {
    if (selectedType == CashMovementType.output) {
      return const [
        CashMovementCategory.stock,
        CashMovementCategory.market,
        CashMovementCategory.supplier,
        CashMovementCategory.employee,
        CashMovementCategory.ownerWithdrawal,
        CashMovementCategory.expense,
        CashMovementCategory.cashOut,
        CashMovementCategory.other,
      ];
    }

    return const [
      CashMovementCategory.cashIn,
      CashMovementCategory.creditPayment,
      CashMovementCategory.adjustment,
      CashMovementCategory.other,
    ];
  }

  final paymentMethods = PaymentMethod.values
      .where((method) => method != PaymentMethod.fiado)
      .toList();

  final draft = await showDialog<_CashMovementDraft>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isOutput = type == CashMovementType.output;
          final color = isOutput ? Colors.red.shade700 : Colors.green.shade700;
          final categories = categoriesForType(type);

          if (!categories.contains(category)) {
            category = categories.first;
          }

          return AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(
                    isOutput
                        ? Icons.remove_circle_outline_rounded
                        : Icons.add_circle_outline_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isOutput ? 'Registrar saída' : 'Registrar entrada',
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.18)),
                      ),
                      child: Text(
                        isOutput
                            ? 'Use para qualquer dinheiro que saiu: sal grosso, carvão, fornecedor, funcionário, retirada ou despesa.'
                            : 'Use para dinheiro extra que entrou no caixa fora das vendas.',
                        style: Theme.of(dialogContext).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            selected: type == CashMovementType.output,
                            label: const Text('Saída'),
                            avatar: const Icon(Icons.north_east_rounded),
                            onSelected: (_) {
                              setDialogState(() {
                                type = CashMovementType.output;
                                category = CashMovementCategory.expense;
                                errorMessage = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            selected: type == CashMovementType.input,
                            label: const Text('Entrada'),
                            avatar: const Icon(Icons.south_west_rounded),
                            onSelected: (_) {
                              setDialogState(() {
                                type = CashMovementType.input;
                                category = CashMovementCategory.cashIn;
                                errorMessage = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    TextField(
                      controller: amountController,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),

                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Motivo rápido',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CashMovementCategory>(
                          value: category,
                          isExpanded: true,
                          items: categories.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              category = value;
                              errorMessage = null;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Forma real do dinheiro',
                        helperText:
                            'Fiado não aparece aqui porque não é dinheiro saindo/entrando.',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          value: paymentMethod,
                          isExpanded: true,
                          items: paymentMethods.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              paymentMethod = value;
                              errorMessage = null;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'O que aconteceu?',
                        hintText: 'Ex: comprei 4 sal grosso',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observação opcional',
                        hintText: 'Ex: comprado no mercado da esquina',
                        border: OutlineInputBorder(),
                        filled: true,
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
                  final amount = _parseMoneyInput(amountController.text);
                  final reason = reasonController.text.trim();

                  if (amount <= 0) {
                    setDialogState(() {
                      errorMessage = 'Informe um valor válido.';
                    });
                    return;
                  }

                  if (reason.isEmpty) {
                    setDialogState(() {
                      errorMessage = 'Explique o que aconteceu.';
                    });
                    return;
                  }

                  Navigator.of(dialogContext).pop(
                    _CashMovementDraft(
                      type: type,
                      category: category,
                      amount: amount,
                      paymentMethod: paymentMethod,
                      reason: reason,
                      description: descriptionController.text.trim(),
                    ),
                  );
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Salvar'),
              ),
            ],
          );
        },
      );
    },
  );

  amountController.dispose();
  reasonController.dispose();
  descriptionController.dispose();

  if (draft == null) return;

  await Future<void>.delayed(const Duration(milliseconds: 120));

  cashProvider.addMovement(
    type: draft.type,
    category: draft.category,
    amount: draft.amount,
    paymentMethod: draft.paymentMethod,
    reason: draft.reason,
    description: draft.description,
  );
}

double _parseMoneyInput(String value) {
  final cleaned = value
      .replaceAll('R\$', '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .trim();

  return double.tryParse(cleaned) ?? 0;
}
