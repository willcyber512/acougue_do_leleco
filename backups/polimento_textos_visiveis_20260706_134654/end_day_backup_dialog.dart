import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/customers_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/ramuza_barcode_log_provider.dart';
import '../providers/sales_provider.dart';

Future<void> showEndDayBackupDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const EndDayBackupDialog(),
  );
}

class EndDayBackupDialog extends StatefulWidget {
  const EndDayBackupDialog({super.key});

  @override
  State<EndDayBackupDialog> createState() => _EndDayBackupDialogState();
}

class _EndDayBackupDialogState extends State<EndDayBackupDialog> {
  bool isCopyingBackup = false;
  bool isCopyingSummary = false;

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final sales = context.watch<SalesProvider>();
    final customers = context.watch<CustomersProvider>();
    final ramuzaLog = context.watch<RamuzaBarcodeLogProvider>();

    final activeProducts = inventory.products.where((product) {
      return !product.isDeleted;
    }).toList();

    final lowStockProducts = activeProducts.where((product) {
      return product.isLowStock;
    }).length;

    final emptyStockProducts = activeProducts.where((product) {
      return product.stockQuantity <= 0;
    }).length;

    return AlertDialog(
      title: const Text('Backup / Fim do dia'),
      content: SizedBox(
        width: 900,
        height: 620,
        child: Column(
          children: [
            _HeaderCard(
              todaySales: sales.todaySales.length,
              todayRevenue: sales.todayRevenue,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryPanel(
                      activeProducts: activeProducts.length,
                      lowStockProducts: lowStockProducts,
                      emptyStockProducts: emptyStockProducts,
                      todaySales: sales.todaySales.length,
                      todayRevenue: sales.todayRevenue,
                      openCredit: customers.totalOpenCredit,
                      ramuzaSuccess: ramuzaLog.successCount,
                      ramuzaErrors: ramuzaLog.errorCount,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: _InstructionsPanel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: isCopyingSummary
              ? null
              : () async {
                  await _copySummary(context);
                },
          icon: const Icon(Icons.description_rounded),
          label: Text(isCopyingSummary ? 'Copiando...' : 'Copiar resumo'),
        ),
        OutlinedButton.icon(
          onPressed: isCopyingBackup
              ? null
              : () async {
                  await _copyBackup(context);
                },
          icon: const Icon(Icons.backup_rounded),
          label: Text(isCopyingBackup ? 'Gerando...' : 'Copiar backup completo'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Future<void> _copySummary(BuildContext context) async {
    setState(() => isCopyingSummary = true);

    final summary = _buildSummaryText(context);

    await Clipboard.setData(ClipboardData(text: summary));

    if (!mounted) return;

    setState(() => isCopyingSummary = false);

    _showMessage(context, 'Resumo do fim do dia copiado.');
  }

  Future<void> _copyBackup(BuildContext context) async {
    setState(() => isCopyingBackup = true);

    final payload = await _buildBackupPayload(context);
    const encoder = JsonEncoder.withIndent('  ');
    final backupText = encoder.convert(payload);

    await Clipboard.setData(ClipboardData(text: backupText));

    if (!mounted) return;

    setState(() => isCopyingBackup = false);

    _showMessage(context, 'Backup completo copiado. Cole e salve em um arquivo .json.');
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.todaySales,
    required this.todayRevenue,
  });

  final int todaySales;
  final double todayRevenue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.wine900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.backup_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fechamento seguro do dia',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$todaySales venda(s) hoje • ${_formatMoney(todayRevenue)} faturado',
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

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.activeProducts,
    required this.lowStockProducts,
    required this.emptyStockProducts,
    required this.todaySales,
    required this.todayRevenue,
    required this.openCredit,
    required this.ramuzaSuccess,
    required this.ramuzaErrors,
  });

  final int activeProducts;
  final int lowStockProducts;
  final int emptyStockProducts;
  final int todaySales;
  final double todayRevenue;
  final double openCredit;
  final int ramuzaSuccess;
  final int ramuzaErrors;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Resumo para conferir',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          _InfoTile(
            icon: Icons.point_of_sale_rounded,
            label: 'Vendas hoje',
            value: todaySales.toString(),
          ),
          _InfoTile(
            icon: Icons.payments_rounded,
            label: 'Faturamento hoje',
            value: _formatMoney(todayRevenue),
          ),
          _InfoTile(
            icon: Icons.person_rounded,
            label: 'Fiado aberto',
            value: _formatMoney(openCredit),
          ),
          _InfoTile(
            icon: Icons.inventory_2_rounded,
            label: 'Produtos ativos',
            value: activeProducts.toString(),
          ),
          _InfoTile(
            icon: Icons.warning_rounded,
            label: 'Estoque baixo',
            value: lowStockProducts.toString(),
          ),
          _InfoTile(
            icon: Icons.remove_circle_rounded,
            label: 'Estoque zerado',
            value: emptyStockProducts.toString(),
          ),
          _InfoTile(
            icon: Icons.qr_code_scanner_rounded,
            label: 'balança OK',
            value: ramuzaSuccess.toString(),
          ),
          _InfoTile(
            icon: Icons.error_rounded,
            label: 'balança falhas',
            value: ramuzaErrors.toString(),
          ),
        ],
      ),
    );
  }
}

class _InstructionsPanel extends StatelessWidget {
  const _InstructionsPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Como usar no fim do dia',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '1. Confira o caixa normalmente.\n'
            '2. Clique em "Copiar resumo" para salvar o resumo do dia.\n'
            '3. Clique em "Copiar backup completo".\n'
            '4. Cole em um arquivo de texto.\n'
            '5. Salve com nome parecido com:\n'
            'backup-acougue-leleco-2026-06-30.json\n\n'
            'Esse backup guarda os dados locais do sistema. Ele é importante antes de trocar de computador, limpar navegador ou testar importação da balança.',
            style: TextStyle(fontWeight: FontWeight.w700, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

Future<Map<String, dynamic>> _buildBackupPayload(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();

  final inventory = context.read<InventoryProvider>();
  final sales = context.read<SalesProvider>();
  final customers = context.read<CustomersProvider>();
  final ramuzaLog = context.read<RamuzaBarcodeLogProvider>();

  final activeProducts = inventory.products.where((product) {
    return !product.isDeleted;
  }).toList();

  final lowStockProducts = activeProducts.where((product) {
    return product.isLowStock;
  }).length;

  final emptyStockProducts = activeProducts.where((product) {
    return product.stockQuantity <= 0;
  }).length;

  final data = <String, dynamic>{};

  for (final key in _backupKeys) {
    if (prefs.containsKey(key)) {
      data[key] = prefs.get(key);
    }
  }

  return {
    'app': AppConstants.appName,
    'version': AppConstants.appVersion,
    'type': 'end_day_backup',
    'createdAt': DateTime.now().toIso8601String(),
    'summary': {
      'todaySales': sales.todaySales.length,
      'todayRevenue': sales.todayRevenue,
      'openCredit': customers.totalOpenCredit,
      'activeProducts': activeProducts.length,
      'lowStockProducts': lowStockProducts,
      'emptyStockProducts': emptyStockProducts,
      'ramuzaSuccess': ramuzaLog.successCount,
      'ramuzaErrors': ramuzaLog.errorCount,
    },
    'data': data,
  };
}

String _buildSummaryText(BuildContext context) {
  final inventory = context.read<InventoryProvider>();
  final sales = context.read<SalesProvider>();
  final customers = context.read<CustomersProvider>();
  final ramuzaLog = context.read<RamuzaBarcodeLogProvider>();

  final activeProducts = inventory.products.where((product) {
    return !product.isDeleted;
  }).toList();

  final lowStockProducts = activeProducts.where((product) {
    return product.isLowStock;
  }).length;

  final emptyStockProducts = activeProducts.where((product) {
    return product.stockQuantity <= 0;
  }).length;

  final now = DateTime.now();

  final buffer = StringBuffer();

  buffer.writeln('RESUMO DO DIA - ${AppConstants.appName}');
  buffer.writeln('Data: ${_formatDateTime(now)}');
  buffer.writeln('Versão: ${AppConstants.appVersion}');
  buffer.writeln('');
  buffer.writeln('Vendas hoje: ${sales.todaySales.length}');
  buffer.writeln('Faturamento hoje: ${_formatMoney(sales.todayRevenue)}');
  buffer.writeln('Fiado aberto: ${_formatMoney(customers.totalOpenCredit)}');
  buffer.writeln('');
  buffer.writeln('Produtos ativos: ${activeProducts.length}');
  buffer.writeln('Estoque baixo: $lowStockProducts');
  buffer.writeln('Estoque zerado: $emptyStockProducts');
  buffer.writeln('');
  buffer.writeln('balança OK: ${ramuzaLog.successCount}');
  buffer.writeln('balança falhas: ${ramuzaLog.errorCount}');

  return buffer.toString();
}

const List<String> _backupKeys = [
  'leleco_inventory_products_v1',
  'leleco_inventory_events_v1',
  'leleco_inventory_losses_v1',
  'leleco_sales_records_v1',
  'leleco_customers_v1',
  'leleco_credit_entries_v1',
  'leleco_internal_notes_v1',
  'leleco_cash_closures_v1',
  'leleco_dashboard_shortcuts_v1',
  'leleco_ramuza_barcode_settings_v1',
  'leleco_ramuza_barcode_events_v1',
];

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

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}
