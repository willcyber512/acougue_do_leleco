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
    builder: (dialogContext) {
      return const CashClosureDialog();
    },
  );
}

Future<void> showCashClosuresHistoryDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return const CashClosuresHistoryDialog();
    },
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

    notesController = TextEditingController(text: closure?.notes ?? '');
  }

  @override
  void dispose() {
    openingController.dispose();
    countedController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SalesProvider, CashClosureProvider>(
      builder: (context, salesProvider, closureProvider, _) {
        final summary = _DailyCashSummary.fromSales(
          salesProvider.sales,
          DateTime.now(),
        );

        final openingAmount = _parseMoney(openingController.text);
        final countedAmount = _parseMoney(countedController.text);
        final expectedCash = openingAmount + summary.moneySales;
        final difference = countedAmount - expectedCash;
        final existingClosure = closureProvider.closureForDay(DateTime.now());

        return AlertDialog(
          title: Text(
            existingClosure == null
                ? 'Fechar caixa do dia'
                : 'Editar fechamento do dia',
          ),
          content: SizedBox(
            width: 940,
            height: 650,
            child: ListView(
              children: [
                _ClosureHeader(
                  day: DateTime.now(),
                  existingClosure: existingClosure,
                ),
                const SizedBox(height: 16),
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
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: openingController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Valor inicial no caixa',
                          prefixText: 'R\$ ',
                          hintText: '0,00',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: countedController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Dinheiro contado no caixa',
                          prefixText: 'R\$ ',
                          hintText: 'Ex: 350,00',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ResultCard(
                        title: 'Dinheiro esperado',
                        value: _formatMoney(expectedCash),
                        color: AppColors.wine900,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ResultCard(
                        title: difference == 0
                            ? 'Caixa batendo'
                            : difference > 0
                                ? 'Sobra no caixa'
                                : 'Falta no caixa',
                        value: _formatMoney(difference),
                        color: difference == 0
                            ? AppColors.success
                            : difference > 0
                                ? AppColors.warning
                                : AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    hintText: 'Ex: Caixa conferido no fim do expediente.',
                  ),
                ),
                const SizedBox(height: 18),
                _TotalSummary(summary: summary),
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
                final now = DateTime.now();

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
                );

                closureProvider.saveClosure(closure);

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Fechamento do caixa salvo.'),
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
            width: 900,
            height: 580,
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
                        ? 'Ainda não existe fechamento salvo para hoje.'
                        : 'Já existe fechamento salvo. Ao salvar, ele será atualizado.',
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
    return SizedBox(
      width: 290,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.wine900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.beige100),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.beige100,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.beige100,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalSummary extends StatelessWidget {
  const _TotalSummary({required this.summary});

  final _DailyCashSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: _InfoLine(
                label: 'Total vendido',
                value: _formatMoney(summary.totalSold),
              ),
            ),
            Expanded(
              child: _InfoLine(
                label: 'Canceladas',
                value: _formatMoney(summary.canceledSales),
              ),
            ),
            Expanded(
              child: _InfoLine(
                label: 'Data',
                value: _formatDate(DateTime.now()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosureHistoryTile extends StatelessWidget {
  const _ClosureHistoryTile({required this.closure});

  final CashClosure closure;

  @override
  Widget build(BuildContext context) {
    final color = closure.difference == 0
        ? AppColors.success
        : closure.difference > 0
            ? AppColors.warning
            : AppColors.danger;

    return Card(
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lock_clock_rounded,
            color: AppColors.beige100,
          ),
        ),
        title: Text(
          'Fechamento ${_formatDayKey(closure.dayKey)}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${closure.salesCount} venda(s) • Diferença ${_formatMoney(closure.difference)}',
        ),
        trailing: Text(
          _formatMoney(closure.totalSold),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          _InfoLine(label: 'Valor inicial', value: _formatMoney(closure.openingAmount)),
          _InfoLine(label: 'Dinheiro vendido', value: _formatMoney(closure.moneySales)),
          _InfoLine(label: 'Dinheiro esperado', value: _formatMoney(closure.expectedCash)),
          _InfoLine(label: 'Dinheiro contado', value: _formatMoney(closure.countedAmount)),
          _InfoLine(label: 'Diferença', value: _formatMoney(closure.difference)),
          _InfoLine(label: 'Pix', value: _formatMoney(closure.pixSales)),
          _InfoLine(label: 'Débito', value: _formatMoney(closure.debitSales)),
          _InfoLine(label: 'Crédito', value: _formatMoney(closure.creditSales)),
          _InfoLine(label: 'Fiado', value: _formatMoney(closure.fiadoSales)),
          if (closure.notes.isNotEmpty)
            _InfoLine(label: 'Observações', value: closure.notes),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                context.read<CashClosureProvider>().deleteClosure(closure.id);
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Excluir'),
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyCashSummary {
  const _DailyCashSummary({
    required this.moneySales,
    required this.pixSales,
    required this.debitSales,
    required this.creditSales,
    required this.fiadoSales,
    required this.canceledSales,
    required this.salesCount,
  });

  final double moneySales;
  final double pixSales;
  final double debitSales;
  final double creditSales;
  final double fiadoSales;
  final double canceledSales;
  final int salesCount;

  double get totalSold {
    return moneySales + pixSales + debitSales + creditSales + fiadoSales;
  }

  factory _DailyCashSummary.fromSales(List<SaleRecord> sales, DateTime day) {
    var moneySales = 0.0;
    var pixSales = 0.0;
    var debitSales = 0.0;
    var creditSales = 0.0;
    var fiadoSales = 0.0;
    var canceledSales = 0.0;
    var salesCount = 0;

    for (final sale in sales) {
      if (!_sameDay(sale.createdAt, day)) continue;

      if (sale.isCanceled) {
        canceledSales += sale.total;
        continue;
      }

      salesCount++;

      switch (sale.paymentMethod) {
        case PaymentMethod.dinheiro:
          moneySales += sale.total;
          break;
        case PaymentMethod.pix:
          pixSales += sale.total;
          break;
        case PaymentMethod.debito:
          debitSales += sale.total;
          break;
        case PaymentMethod.credito:
          creditSales += sale.total;
          break;
        case PaymentMethod.fiado:
          fiadoSales += sale.total;
          break;
      }
    }

    return _DailyCashSummary(
      moneySales: moneySales,
      pixSales: pixSales,
      debitSales: debitSales,
      creditSales: creditSales,
      fiadoSales: fiadoSales,
      canceledSales: canceledSales,
      salesCount: salesCount,
    );
  }
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

double _parseMoney(String value) {
  final normalized = value
      .trim()
      .replaceAll('R\$', '')
      .replaceAll('.', '')
      .replaceAll(',', '.');

  return double.tryParse(normalized) ?? 0;
}

String _moneyInput(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String _formatMoney(double value) {
  final fixed = value.abs().toStringAsFixed(2).replaceAll('.', ',');
  final prefix = value < 0 ? '-R\$ ' : 'R\$ ';

  return '$prefix$fixed';
}

String _formatDate(DateTime value) {
  final day = _two(value.day);
  final month = _two(value.month);
  final year = value.year;

  return '$day/$month/$year';
}

String _formatDayKey(String value) {
  final parts = value.split('-');

  if (parts.length != 3) return value;

  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}
