import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/customers_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/ramuza_barcode_log_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();
    final inventory = context.watch<InventoryProvider>();
    final customers = context.watch<CustomersProvider>();
    final ramuzaLog = context.watch<RamuzaBarcodeLogProvider>();

    final lowStock = inventory.products.where((product) {
      return !product.isDeleted && product.isLowStock;
    }).length;

    final todayRamuza = ramuzaLog.events.where((event) {
      final now = DateTime.now();
      final date = event.createdAt;

      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length;

    return AlertDialog(
      title: const Text('Relatório PDF do dia'),
      content: SizedBox(
        width: 720,
        height: 460,
        child: Column(
          children: [
            _HeaderCard(
              salesCount: sales.todaySales.length,
              revenue: sales.todayRevenue,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
                children: [
                  _MetricTile(
                    icon: Icons.point_of_sale_rounded,
                    label: 'Vendas hoje',
                    value: sales.todaySales.length.toString(),
                  ),
                  _MetricTile(
                    icon: Icons.payments_rounded,
                    label: 'Faturamento',
                    value: _formatMoney(sales.todayRevenue),
                  ),
                  _MetricTile(
                    icon: Icons.person_rounded,
                    label: 'Fiado aberto',
                    value: _formatMoney(customers.totalOpenCredit),
                  ),
                  _MetricTile(
                    icon: Icons.warning_rounded,
                    label: 'Estoque baixo',
                    value: lowStock.toString(),
                  ),
                  _MetricTile(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Leituras Ramuza hoje',
                    value: todayRamuza.toString(),
                  ),
                  _MetricTile(
                    icon: Icons.inventory_2_rounded,
                    label: 'Produtos ativos',
                    value: inventory.products
                        .where((product) => !product.isDeleted)
                        .length
                        .toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'O PDF será aberto para imprimir ou salvar. No navegador, escolha “Salvar como PDF”.',
              style: TextStyle(fontWeight: FontWeight.w700),
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
                    ramuzaEvents: ramuzaLog.events,
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.wine700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}
