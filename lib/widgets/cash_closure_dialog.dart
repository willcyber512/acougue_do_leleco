import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/cash_closure.dart';
import '../models/payment_method.dart';
import '../models/sale.dart';
import '../providers/cash_closure_provider.dart';
import '../providers/sales_provider.dart';

Future<void> showCashClosureDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const CashClosureDialog(),
  );
}

Future<void> showCashClosuresHistoryDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const CashClosuresHistoryDialog(),
  );
}

class CashClosureDialog extends StatefulWidget {
  const CashClosureDialog({super.key});

  @override
  State<CashClosureDialog> createState() => _CashClosureDialogState();
}

class _CashClosureDialogState extends State<CashClosureDialog> {
  late final TextEditingController openingController;
  late final TextEditingController countedController;
  late final TextEditingController cashInController;
  late final TextEditingController cashOutController;
  late final TextEditingController notesController;

  @override
  void initState() {
    super.initState();

    final closure = context.read<CashClosureProvider>().closureForDay(
          DateTime.now(),
        );

    openingController = TextEditingController(
      text: closure == null ? '0,00' : _moneyInput(closure.openingAmount),
    );

    countedController = TextEditingController(
      text: closure == null ? '' : _moneyInput(closure.countedAmount),
    );

    cashInController = TextEditingController(
      text: closure == null ? '0,00' : _moneyInput(closure.cashInAmount),
    );

    cashOutController = TextEditingController(
      text: closure == null ? '0,00' : _moneyInput(closure.cashOutAmount),
    );

    notesController = TextEditingController(text: closure?.notes ?? '');
  }

  @override
  void dispose() {
    openingController.dispose();
    countedController.dispose();
    cashInController.dispose();
    cashOutController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SalesProvider, CashClosureProvider>(
      builder: (context, salesProvider, closureProvider, _) {
        final now = DateTime.now();

        final summary = _DailyCashSummary.fromSales(
          salesProvider.sales,
          now,
        );

        final openingAmount = _parseMoney(openingController.text);
        final countedAmount = _parseMoney(countedController.text);
        final cashInAmount = _parseMoney(cashInController.text);
        final cashOutAmount = _parseMoney(cashOutController.text);

        final expectedCash =
            openingAmount + summary.moneySales + cashInAmount - cashOutAmount;

        final difference = countedAmount - expectedCash;
        final existingClosure = closureProvider.closureForDay(now);

        return AlertDialog(
          title: Text(
            existingClosure == null
                ? 'Fechamento completo do caixa'
                : 'Editar fechamento do caixa',
          ),
          content: SizedBox(
            width: 980,
            height: 700,
            child: ListView(
              children: [
                _ClosureHeader(
                  day: now,
                  existingClosure: existingClosure,
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  icon: Icons.receipt_long_rounded,
                  title: 'Resumo das vendas',
                  subtitle: 'Valores calculados automaticamente pelas vendas do dia.',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _MetricBox(
                      icon: Icons.receipt_long_rounded,
                      title: 'Vendas finalizadas',
                      value: summary.salesCount.toString(),
                    ),
                    _MetricBox(
                      icon: Icons.payments_rounded,
                      title: 'Dinheiro',
                      value: _formatMoney(summary.moneySales),
                    ),
                    _MetricBox(
                      icon: Icons.pix_rounded,
                      title: 'Pix',
                      value: _formatMoney(summary.pixSales),
                    ),
                    _MetricBox(
                      icon: Icons.credit_card_rounded,
                      title: 'Débito',
                      value: _formatMoney(summary.debitSales),
                    ),
                    _MetricBox(
                      icon: Icons.credit_score_rounded,
                      title: 'Crédito',
                      value: _formatMoney(summary.creditSales),
                    ),
                    _MetricBox(
                      icon: Icons.person_rounded,
                      title: 'Fiado',
                      value: _formatMoney(summary.fiadoSales),
                    ),
                    _MetricBox(
                      icon: Icons.cancel_rounded,
                      title: 'Canceladas',
                      value: _formatMoney(summary.canceledSales),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Dinheiro físico do caixa',
                  subtitle:
                      'Informe abertura, reforços, sangrias e o valor contado no fim do dia.',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _MoneyField(
                      width: 220,
                      controller: openingController,
                      label: 'Valor inicial',
                      hint: '0,00',
                      onChanged: () => setState(() {}),
                    ),
                    _MoneyField(
                      width: 220,
                      controller: cashInController,
                      label: 'Reforço / entrada',
                      hint: '0,00',
                      onChanged: () => setState(() {}),
                    ),
                    _MoneyField(
                      width: 220,
                      controller: cashOutController,
                      label: 'Sangria / retirada',
                      hint: '0,00',
                      onChanged: () => setState(() {}),
                    ),
                    _MoneyField(
                      width: 220,
                      controller: countedController,
                      label: 'Dinheiro contado',
                      hint: 'Ex: 350,00',
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;

                    final cards = [
                      _ResultCard(
                        title: 'Dinheiro esperado',
                        value: _formatMoney(expectedCash),
                        description:
                            'Inicial + dinheiro vendido + reforços - sangrias',
                        color: AppColors.wine900,
                      ),
                      _ResultCard(
                        title: _differenceTitle(difference),
                        value: _formatMoney(difference),
                        description: 'Contado - esperado',
                        color: _differenceColor(difference),
                      ),
                    ];

                    if (compact) {
                      return Column(
                        children: [
                          cards[0],
                          const SizedBox(height: 12),
                          cards[1],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 14),
                        Expanded(child: cards[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observações do fechamento',
                    hintText:
                        'Ex: Foi feita sangria para pagamento de fornecedor.',
                  ),
                ),
                const SizedBox(height: 18),
                _TotalSummary(
                  summary: summary,
                  openingAmount: openingAmount,
                  cashInAmount: cashInAmount,
                  cashOutAmount: cashOutAmount,
                  expectedCash: expectedCash,
                  countedAmount: countedAmount,
                  difference: difference,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                final closure = CashClosure(
                  id: existingClosure?.id ?? now.microsecondsSinceEpoch.toString(),
                  dayKey: cashClosureDayKey(now),
                  openingAmount: openingAmount,
                  countedAmount: countedAmount,
                  moneySales: summary.moneySales,
                  pixSales: summary.pixSales,
                  debitSales: summary.debitSales,
                  creditSales: summary.creditSales,
                  fiadoSales: summary.fiadoSales,
                  canceledSales: summary.canceledSales,
                  salesCount: summary.salesCount,
                  notes: notesController.text.trim(),
                  createdAt: now,
                  cashInAmount: cashInAmount,
                  cashOutAmount: cashOutAmount,
                );

                closureProvider.saveClosure(closure);

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Fechamento completo do caixa salvo.'),
                    ),
                  );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Salvar fechamento'),
            ),
          ],
        );
      },
    );
  }
}

class CashClosuresHistoryDialog extends StatelessWidget {
  const CashClosuresHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CashClosureProvider>(
      builder: (context, provider, _) {
        final closures = provider.closures;

        return AlertDialog(
          title: const Text('Histórico de fechamentos'),
          content: SizedBox(
            width: 940,
            height: 620,
            child: closures.isEmpty
                ? const Center(
                    child: Text('Nenhum fechamento registrado ainda.'),
                  )
                : ListView.separated(
                    itemCount: closures.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _ClosureHistoryTile(closure: closures[index]);
                    },
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

class _ClosureHeader extends StatelessWidget {
  const _ClosureHeader({
    required this.day,
    required this.existingClosure,
  });

  final DateTime day;
  final CashClosure? existingClosure;

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
                Icons.point_of_sale_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caixa de ${_formatDate(day)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    existingClosure == null
                        ? 'Nenhum fechamento salvo para hoje.'
                        : 'Já existe fechamento salvo. Você está editando.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.wine700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.width,
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  final double width;
  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'R\$ ',
          hintText: hint,
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 205,
      height: 120,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.wine700.withOpacity(isDark ? 0.28 : 0.12),
          ),
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
                  ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.value,
    required this.description,
    required this.color,
  });

  final String title;
  final String value;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
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
            child: Icon(
              Icons.calculate_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.beige100,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
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
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.beige100,
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

class _TotalSummary extends StatelessWidget {
  const _TotalSummary({
    required this.summary,
    required this.openingAmount,
    required this.cashInAmount,
    required this.cashOutAmount,
    required this.expectedCash,
    required this.countedAmount,
    required this.difference,
  });

  final _DailyCashSummary summary;
  final double openingAmount;
  final double cashInAmount;
  final double cashOutAmount;
  final double expectedCash;
  final double countedAmount;
  final double difference;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conferência final',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 12),
            _SummaryLine('Valor inicial', openingAmount),
            _SummaryLine('Vendas em dinheiro', summary.moneySales),
            _SummaryLine('Reforços / entradas', cashInAmount),
            _SummaryLine('Sangrias / retiradas', -cashOutAmount),
            const Divider(),
            _SummaryLine('Dinheiro esperado', expectedCash, strong: true),
            _SummaryLine('Dinheiro contado', countedAmount, strong: true),
            _SummaryLine('Diferença', difference, strong: true),
            const Divider(),
            _SummaryLine('Pix', summary.pixSales),
            _SummaryLine('Débito', summary.debitSales),
            _SummaryLine('Crédito', summary.creditSales),
            _SummaryLine('Fiado', summary.fiadoSales),
            _SummaryLine('Canceladas', summary.canceledSales),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine(
    this.label,
    this.value, {
    this.strong = false,
  });

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            _formatMoney(value),
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosureHistoryTile extends StatelessWidget {
  const _ClosureHistoryTile({required this.closure});

  final CashClosure closure;

  @override
  Widget build(BuildContext context) {
    final color = _differenceColor(closure.difference);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.point_of_sale_rounded,
                    color: AppColors.beige100,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fechamento ${closure.dayKey}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${closure.salesCount} venda(s) • ${closure.statusLabel}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatMoney(closure.difference),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Excluir fechamento',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Excluir fechamento?'),
                          content: const Text(
                            'Essa ação remove apenas o fechamento salvo. As vendas não serão apagadas.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmed != true || !context.mounted) return;

                    context
                        .read<CashClosureProvider>()
                        .deleteClosure(closure.id);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HistoryChip(
                  label: 'Inicial',
                  value: _formatMoney(closure.openingAmount),
                ),
                _HistoryChip(
                  label: 'Dinheiro',
                  value: _formatMoney(closure.moneySales),
                ),
                _HistoryChip(
                  label: 'Reforço',
                  value: _formatMoney(closure.cashInAmount),
                ),
                _HistoryChip(
                  label: 'Sangria',
                  value: _formatMoney(closure.cashOutAmount),
                ),
                _HistoryChip(
                  label: 'Esperado',
                  value: _formatMoney(closure.expectedCash),
                ),
                _HistoryChip(
                  label: 'Contado',
                  value: _formatMoney(closure.countedAmount),
                ),
                _HistoryChip(
                  label: 'Pix',
                  value: _formatMoney(closure.pixSales),
                ),
                _HistoryChip(
                  label: 'Débito',
                  value: _formatMoney(closure.debitSales),
                ),
                _HistoryChip(
                  label: 'Crédito',
                  value: _formatMoney(closure.creditSales),
                ),
                _HistoryChip(
                  label: 'Fiado',
                  value: _formatMoney(closure.fiadoSales),
                ),
              ],
            ),
            if (closure.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Obs.: ${closure.notes}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.beige100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DailyCashSummary {
  const _DailyCashSummary({
    required this.salesCount,
    required this.moneySales,
    required this.pixSales,
    required this.debitSales,
    required this.creditSales,
    required this.fiadoSales,
    required this.canceledSales,
  });

  final int salesCount;
  final double moneySales;
  final double pixSales;
  final double debitSales;
  final double creditSales;
  final double fiadoSales;
  final double canceledSales;

  factory _DailyCashSummary.fromSales(
    List<SaleRecord> sales,
    DateTime day,
  ) {
    final daySales = sales.where((sale) {
      return _sameDay(sale.createdAt, day);
    }).toList();

    final validSales = daySales.where((sale) => !sale.isCanceled).toList();
    final canceledSales = daySales.where((sale) => sale.isCanceled).toList();

    return _DailyCashSummary(
      salesCount: validSales.length,
      moneySales: _sumByMethod(validSales, PaymentMethod.dinheiro),
      pixSales: _sumByMethod(validSales, PaymentMethod.pix),
      debitSales: _sumByMethod(validSales, PaymentMethod.debito),
      creditSales: _sumByMethod(validSales, PaymentMethod.credito),
      fiadoSales: _sumByMethod(validSales, PaymentMethod.fiado),
      canceledSales: canceledSales.fold<double>(
        0,
        (total, sale) => total + sale.total,
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

double _sumByMethod(List<SaleRecord> sales, PaymentMethod method) {
  return sales
      .where((sale) => sale.paymentMethod == method)
      .fold<double>(0, (total, sale) => total + sale.total);
}

double _parseMoney(String value) {
  final text = value
      .trim()
      .replaceAll('R\$', '')
      .replaceAll('.', '')
      .replaceAll(',', '.');

  return double.tryParse(text) ?? 0;
}

String _formatMoney(double value) {
  final fixed = value.abs().toStringAsFixed(2).replaceAll('.', ',');
  final signal = value < 0 ? '-' : '';

  return '${signal}R\$ $fixed';
}

String _moneyInput(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();

  return '$day/$month/$year';
}

String _differenceTitle(double difference) {
  if (difference.abs() < 0.01) return 'Caixa batendo';
  if (difference > 0) return 'Sobra no caixa';

  return 'Falta no caixa';
}

Color _differenceColor(double difference) {
  if (difference.abs() < 0.01) return AppColors.success;
  if (difference > 0) return AppColors.warning;

  return AppColors.danger;
}
