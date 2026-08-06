import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/cash_movement.dart';
import '../models/payment_method.dart';
import '../models/sale.dart';
import '../providers/cash_movement_provider.dart';

String saleCashReferenceId(String saleId) {
  return 'sale:$saleId';
}

void syncSaleCashMovement(BuildContext context, SaleRecord sale) {
  final cash = context.read<CashMovementProvider>();
  final referenceId = saleCashReferenceId(sale.id);

  cash.deleteMovementsByReferenceId(referenceId);

  if (sale.isCanceled) return;
  if (sale.total <= 0) return;

  final parts = sale.effectivePaymentParts.where((payment) {
    return payment.isImmediate && payment.amount > 0.004;
  }).toList();

  if (parts.isEmpty) return;

  for (final payment in parts) {
    cash.addMovement(
      type: CashMovementType.input,
      category: CashMovementCategory.sale,
      amount: payment.amount,
      paymentMethod: payment.method,
      reason: 'Venda #${sale.shortId}',
      description: sale.isMixedPayment
          ? '${sale.totalItems} item(ns) • Pagamento misto • ${payment.method.label}: R\$ ${payment.amount.toStringAsFixed(2).replaceAll('.', ',')}'
          : '${sale.totalItems} item(ns) • ${payment.method.label}',
      referenceId: referenceId,
      personName: sale.customerName,
      createdAt: sale.createdAt,
    );
  }
}

void removeSaleCashMovement(BuildContext context, SaleRecord sale) {
  context.read<CashMovementProvider>().deleteMovementsByReferenceId(
    saleCashReferenceId(sale.id),
  );
}
