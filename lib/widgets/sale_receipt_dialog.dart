import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../models/payment_method.dart';
import '../models/sale.dart';
import '../services/receipt_pdf_service.dart';

Future<void> showSaleReceiptDialog(
  BuildContext context,
  SaleRecord sale,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return SaleReceiptDialog(sale: sale);
    },
  );
}

class SaleReceiptDialog extends StatelessWidget {
  const SaleReceiptDialog({super.key, required this.sale});

  final SaleRecord sale;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Comprovante #${sale.shortId}'),
      content: SizedBox(
        width: 560,
        height: 560,
        child: SelectionArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReceiptHeader(sale: sale),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Itens da venda',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ...sale.items.map((item) => _ReceiptItemTile(item: item)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _ReceiptTotal(sale: sale),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: _buildReceiptText(sale)),
            );

            if (!context.mounted) return;

            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                const SnackBar(content: Text('Comprovante copiado.')),
              );
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copiar'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            await ReceiptPdfService.openReceiptPdf(sale);
          },
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: const Text('PDF'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  const _ReceiptHeader({required this.sale});

  final SaleRecord sale;

  @override
  Widget build(BuildContext context) {
    final statusColor = sale.isCanceled ? AppColors.danger : AppColors.success;
    final statusText = sale.isCanceled ? 'Cancelada' : 'Finalizada';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.wine900,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Image.asset(
                  'assets/logo/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'AL',
                        style: TextStyle(
                          color: AppColors.beige100,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Açougue do Leleco',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text('Venda #${sale.shortId}'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _InfoRow(label: 'Data', value: _formatDateTime(sale.createdAt)),
        _InfoRow(label: 'Pagamento', value: sale.paymentMethod.label),
        if (sale.customerName != null)
          _InfoRow(label: 'Cliente', value: sale.customerName!),
        _InfoRow(label: 'Status', value: statusText, color: statusColor),
        if (sale.isCanceled) ...[
          _InfoRow(
            label: 'Cancelada em',
            value: _formatDateTime(sale.canceledAt!),
            color: AppColors.danger,
          ),
          _InfoRow(
            label: 'Motivo',
            value: sale.cancelReason ?? 'Cancelamento manual',
            color: AppColors.danger,
          ),
        ],
      ],
    );
  }
}

class _ReceiptItemTile extends StatelessWidget {
  const _ReceiptItemTile({required this.item});

  final SaleRecordItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceAlt
            : AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Código ${item.productCode} • ${_formatNumber(item.quantity)} ${item.unitLabel} x ${_formatMoney(item.unitPrice)}',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatMoney(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ReceiptTotal extends StatelessWidget {
  const _ReceiptTotal({required this.sale});

  final SaleRecord sale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sale.hasDiscount) ...[
            _ReceiptTotalLine(
              label: 'Subtotal',
              value: _formatMoney(sale.grossTotal),
            ),
            const SizedBox(height: 4),
            _ReceiptTotalLine(
              label: 'Desconto',
              value: '- ${_formatMoney(sale.safeDiscountAmount)}',
            ),
            const SizedBox(height: 8),
          ],
          const Text(
            'Total',
            style: TextStyle(
              color: AppColors.beige100,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatMoney(sale.total),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.beige100,
              fontWeight: FontWeight.w900,
              decoration: sale.isCanceled ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptTotalLine extends StatelessWidget {
  const _ReceiptTotalLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.beige100,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.beige100,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w900, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

String _buildReceiptText(SaleRecord sale) {
  final buffer = StringBuffer();

  buffer.writeln('AÇOUGUE DO LELECO');
  buffer.writeln('COMPROVANTE DE VENDA');
  buffer.writeln('Venda #${sale.shortId}');
  buffer.writeln('Data: ${_formatDateTime(sale.createdAt)}');
  buffer.writeln('Pagamento: ${sale.paymentMethod.label}');

  if (sale.customerName != null) {
    buffer.writeln('Cliente: ${sale.customerName}');
  }

  buffer.writeln('Status: ${sale.isCanceled ? 'Cancelada' : 'Finalizada'}');

  if (sale.isCanceled) {
    buffer.writeln('Cancelada em: ${_formatDateTime(sale.canceledAt!)}');
    buffer.writeln('Motivo: ${sale.cancelReason ?? 'Cancelamento manual'}');
  }

  buffer.writeln('-----------------------------');

  for (final item in sale.items) {
    buffer.writeln(item.productName);
    buffer.writeln(
      '${_formatNumber(item.quantity)} ${item.unitLabel} x ${_formatMoney(item.unitPrice)} = ${_formatMoney(item.subtotal)}',
    );
  }

  buffer.writeln('-----------------------------');
  buffer.writeln('TOTAL: ${_formatMoney(sale.total)}');

  return buffer.toString();
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
