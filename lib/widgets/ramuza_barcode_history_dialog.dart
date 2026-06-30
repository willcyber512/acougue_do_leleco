import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/ramuza_barcode_event.dart';
import '../providers/ramuza_barcode_log_provider.dart';

Future<void> showRamuzaBarcodeHistoryDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return const RamuzaBarcodeHistoryDialog();
    },
  );
}

class RamuzaBarcodeHistoryDialog extends StatelessWidget {
  const RamuzaBarcodeHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RamuzaBarcodeLogProvider>(
      builder: (context, provider, _) {
        final events = provider.events;

        return AlertDialog(
          title: const Text('Leituras Ramuza'),
          content: SizedBox(
            width: 920,
            height: 620,
            child: Column(
              children: [
                _SummaryHeader(provider: provider),
                const SizedBox(height: 14),
                Expanded(
                  child: events.isEmpty
                      ? const Center(
                          child: Text('Nenhuma etiqueta lida ainda.'),
                        )
                      : ListView.separated(
                          itemCount: events.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _BarcodeEventTile(event: events[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: events.isEmpty
                  ? null
                  : () => _confirmClear(context, provider),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Limpar histórico'),
            ),
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

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.provider});

  final RamuzaBarcodeLogProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _Metric(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Leituras',
              value: provider.totalEvents.toString(),
              color: AppColors.wine900,
            ),
            const SizedBox(width: 12),
            _Metric(
              icon: Icons.check_circle_rounded,
              label: 'Sucesso',
              value: provider.successCount.toString(),
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            _Metric(
              icon: Icons.warning_rounded,
              label: 'Falhas',
              value: provider.errorCount.toString(),
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: AppColors.beige100),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodeEventTile extends StatelessWidget {
  const _BarcodeEventTile({required this.event});

  final RamuzaBarcodeEvent event;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(event.status);

    return Card(
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            event.status == RamuzaBarcodeStatus.success
                ? Icons.check_rounded
                : Icons.warning_rounded,
            color: AppColors.beige100,
          ),
        ),
        title: Text(
          event.productName == null || event.productName!.isEmpty
              ? 'PLU ${event.productCode}'
              : event.productName!,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${event.status.label} • ${event.screen} • ${_formatDateTime(event.createdAt)}',
        ),
        trailing: Text(
          event.quantity == null ? '' : _formatNumber(event.quantity!),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          _InfoLine(label: 'Mensagem', value: event.message),
          _InfoLine(label: 'Código lido', value: event.rawBarcode),
          _InfoLine(label: 'Dígitos', value: event.digits),
          _InfoLine(label: 'PLU', value: event.productCode),
          if (event.productName != null)
            _InfoLine(label: 'Produto', value: event.productName!),
          if (event.quantity != null)
            _InfoLine(label: 'Quantidade', value: _formatNumber(event.quantity!)),
          if (event.totalPrice != null)
            _InfoLine(label: 'Valor total', value: _formatMoney(event.totalPrice!)),
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
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmClear(
  BuildContext context,
  RamuzaBarcodeLogProvider provider,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Limpar histórico?'),
        content: const Text('Todas as leituras Ramuza registradas serão apagadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  provider.clearEvents();
}

Color _statusColor(RamuzaBarcodeStatus status) {
  switch (status) {
    case RamuzaBarcodeStatus.success:
      return AppColors.success;
    case RamuzaBarcodeStatus.productNotFound:
      return AppColors.warning;
    case RamuzaBarcodeStatus.productDeleted:
      return AppColors.danger;
    case RamuzaBarcodeStatus.stockEmpty:
      return AppColors.warning;
    case RamuzaBarcodeStatus.invalidQuantity:
      return AppColors.danger;
    case RamuzaBarcodeStatus.canceledQuickRegister:
      return AppColors.warning;
  }
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
