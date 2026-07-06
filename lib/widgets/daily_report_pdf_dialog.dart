import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/customers_provider.dart';
import '../providers/cash_closure_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/sales_provider.dart';
import '../services/daily_report_pdf_service.dart';

Future<void> showDailyReportPdfDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const DailyReportPdfDialog(),
  );
}

class DailyReportPdfDialog extends StatefulWidget {
  const DailyReportPdfDialog({super.key});

  @override
  State<DailyReportPdfDialog> createState() => _DailyReportPdfDialogState();
}

class _DailyReportPdfDialogState extends State<DailyReportPdfDialog> {
  bool isGenerating = false;

  bool keepOnePage = true;
  bool includeSummary = true;
  bool includePaymentTotals = true;
  bool includeProductSales = true;
  bool includeCategorySales = false;
  bool includeDetailedSales = false;
  bool includeLowStock = false;
  bool includeCashClosure = false;

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();
    final inventory = context.watch<InventoryProvider>();
    final customers = context.watch<CustomersProvider>();
    final closures = context.watch<CashClosureProvider>();
    final todayClosure = closures.closureForDay(DateTime.now());

    final lowStock = inventory.products.where((product) {
      return !product.isDeleted && product.isLowStock;
    }).length;

    final averageTicket = sales.todaySales.isEmpty
        ? 0.0
        : sales.todayRevenue / sales.todaySales.length;

    return AlertDialog(
      title: const Text('Relatório PDF do dia'),
      content: SizedBox(
        width: 760,
        height: 580,
        child: Column(
          children: [
            _HeaderCard(
              salesCount: sales.todaySales.length,
              revenue: sales.todayRevenue,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _PreviewMetrics(
                    salesCount: sales.todaySales.length,
                    revenue: sales.todayRevenue,
                    averageTicket: averageTicket,
                    lowStock: lowStock,
                    openCredit: customers.totalOpenCredit,
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    value: keepOnePage,
                    onChanged: (value) {
                      setState(() => keepOnePage = value);
                    },
                    title: const Text(
                      'Manter PDF enxuto para 1 folha',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text(
                      'Limita algumas listas para o relatório não ficar gigante.',
                    ),
                  ),
                  const Divider(),
                  _OptionTile(
                    value: includeSummary,
                    title: 'Resumo geral',
                    subtitle: 'Vendas, faturamento, ticket médio e fiado aberto.',
                    onChanged: (value) {
                      setState(() => includeSummary = value);
                    },
                  ),
                  _OptionTile(
                    value: includePaymentTotals,
                    title: 'Totais por pagamento',
                    subtitle: 'Dinheiro, Pix, cartão e fiado.',
                    onChanged: (value) {
                      setState(() => includePaymentTotals = value);
                    },
                  ),
                  _OptionTile(
                    value: includeProductSales,
                    title: 'Vendas por produto',
                    subtitle: 'Produtos vendidos e total por produto.',
                    onChanged: (value) {
                      setState(() => includeProductSales = value);
                    },
                  ),
                  _OptionTile(
                    value: includeCategorySales,
                    title: 'Vendas por categoria',
                    subtitle: 'Bovina, suína, frango, linguiça e outras.',
                    onChanged: (value) {
                      setState(() => includeCategorySales = value);
                    },
                  ),
                  _OptionTile(
                    value: includeDetailedSales,
                    title: 'Vendas detalhadas',
                    subtitle: 'Lista das vendas com horário e forma de pagamento.',
                    onChanged: (value) {
                      setState(() => includeDetailedSales = value);
                    },
                  ),
                  _OptionTile(
                    value: includeLowStock,
                    title: 'Estoque baixo',
                    subtitle: 'Produtos que precisam de atenção.',
                    onChanged: (value) {
                      setState(() => includeLowStock = value);
                    },
                  ),
                  _OptionTile(
                    value: includeCashClosure,
                    title: 'Fechamento de caixa',
                    subtitle: todayClosure == null
                        ? 'Ainda não há fechamento salvo para hoje.'
                        : 'Inclui valor inicial, sangria, reforço, esperado e diferença.',
                    onChanged: (value) {
                      setState(() => includeCashClosure = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A parte da balança não entra no PDF de fechamento. Ela continua disponível no histórico próprio da balança.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isGenerating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: isGenerating
              ? null
              : () async {
                  setState(() => isGenerating = true);

                  await DailyReportPdfService.openDailyReport(
                    sales: sales.todaySales,
                    products: inventory.products,
                    openCredit: customers.totalOpenCredit,
                    cashClosure: todayClosure,
                    options: DailyReportPdfOptions(
                      keepOnePage: keepOnePage,
                      includeSummary: includeSummary,
                      includePaymentTotals: includePaymentTotals,
                      includeProductSales: includeProductSales,
                      includeCategorySales: includeCategorySales,
                      includeDetailedSales: includeDetailedSales,
                      includeLowStock: includeLowStock,
                      includeCashClosure: includeCashClosure,
                    ),
                  );

                  if (!mounted) return;

                  setState(() => isGenerating = false);
                },
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: Text(isGenerating ? 'Gerando...' : 'Gerar PDF'),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.salesCount,
    required this.revenue,
  });

  final int salesCount;
  final double revenue;

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
                Icons.picture_as_pdf_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '$salesCount venda(s) hoje • ${_formatMoney(revenue)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

class _PreviewMetrics extends StatelessWidget {
  const _PreviewMetrics({
    required this.salesCount,
    required this.revenue,
    required this.averageTicket,
    required this.lowStock,
    required this.openCredit,
  });

  final int salesCount;
  final double revenue;
  final double averageTicket;
  final int lowStock;
  final double openCredit;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SmallMetric(label: 'Vendas', value: salesCount.toString()),
        _SmallMetric(label: 'Faturamento', value: _formatMoney(revenue)),
        _SmallMetric(label: 'Ticket médio', value: _formatMoney(averageTicket)),
        _SmallMetric(label: 'Fiado aberto', value: _formatMoney(openCredit)),
        _SmallMetric(label: 'Estoque baixo', value: lowStock.toString()),
      ],
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 135,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (newValue) => onChanged(newValue ?? false),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(subtitle),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}
