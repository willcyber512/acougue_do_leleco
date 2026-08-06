import 'package:flutter/material.dart';

import '../models/payment_method.dart';
import '../models/sale_payment.dart';

Future<List<SalePayment>?> showMixedPaymentDialog({
  required BuildContext context,
  required double total,
}) {
  return showDialog<List<SalePayment>>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _MixedPaymentDialog(total: total),
  );
}

class _MixedPaymentDialog extends StatefulWidget {
  const _MixedPaymentDialog({required this.total});

  final double total;

  @override
  State<_MixedPaymentDialog> createState() => _MixedPaymentDialogState();
}

class _MixedPaymentDialogState extends State<_MixedPaymentDialog> {
  final Map<PaymentMethod, TextEditingController> controllers = {
    for (final method in immediatePaymentMethods)
      method: TextEditingController(),
  };

  String? errorText;

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  double get paidTotal {
    return controllers.entries.fold(0.0, (total, entry) {
      return total + _parseMoney(entry.value.text);
    });
  }

  double get remaining {
    final value = widget.total - paidTotal;
    if (value.abs() < 0.01) return 0;
    return value;
  }

  List<SalePayment> get parts {
    return controllers.entries
        .map((entry) {
          return SalePayment(
            method: entry.key,
            amount: _parseMoney(entry.value.text),
          );
        })
        .where((payment) => payment.amount > 0.004)
        .toList();
  }

  void fillRemaining(PaymentMethod method) {
    final current = _parseMoney(controllers[method]?.text ?? '');
    final withoutThis = paidTotal - current;
    final value = widget.total - withoutThis;

    controllers[method]?.text = value <= 0 ? '' : _formatMoneyInput(value);

    setState(() => errorText = null);
  }

  void confirm() {
    final cleanParts = parts;
    final diff = (paidTotal - widget.total).abs();

    if (cleanParts.length < 2) {
      setState(() {
        errorText = 'Use pelo menos duas formas de pagamento.';
      });
      return;
    }

    if (diff > 0.01) {
      setState(() {
        errorText =
            'A soma precisa fechar em ${_formatMoney(widget.total)}. Falta/sobra ${_formatMoney(remaining.abs())}.';
      });
      return;
    }

    Navigator.of(context).pop(cleanParts);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diffColor = remaining == 0
        ? Colors.green
        : remaining > 0
        ? Colors.orange
        : Colors.red;

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Pagamento misto')),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryBox(
                total: widget.total,
                paid: paidTotal,
                remaining: remaining,
                diffColor: diffColor,
              ),
              const SizedBox(height: 14),
              for (final method in immediatePaymentMethods) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controllers[method],
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() => errorText = null),
                        decoration: InputDecoration(
                          labelText: method.label,
                          prefixText: 'R\$ ',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => fillRemaining(method),
                      child: const Text('Restante'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (errorText != null) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    errorText!,
                    style: TextStyle(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Fiado continua separado. Pagamento misto é só para dinheiro, Pix, débito e crédito.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: confirm,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Confirmar pagamento'),
        ),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.total,
    required this.paid,
    required this.remaining,
    required this.diffColor,
  });

  final double total;
  final double paid;
  final double remaining;
  final Color diffColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _Line(label: 'Total da venda', value: _formatMoney(total)),
            _Line(label: 'Informado', value: _formatMoney(paid)),
            _Line(
              label: remaining >= 0 ? 'Falta' : 'Sobra',
              value: _formatMoney(remaining.abs()),
              color: diffColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: FontWeight.w900, color: color);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

double _parseMoney(String value) {
  final clean = value
      .trim()
      .replaceAll('R\$', '')
      .replaceAll(' ', '')
      .replaceAll('.', '')
      .replaceAll(',', '.');

  return double.tryParse(clean) ?? 0;
}

String _formatMoney(double value) {
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatMoneyInput(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}
