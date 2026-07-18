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
  if (sale.paymentMethod == PaymentMethod.fiado) return;
  if (sale.total <= 0) return;

  cash.addMovement(
    type: CashMovementType.input,
    category: CashMovementCategory.sale,
    amount: sale.total,
    paymentMethod: sale.paymentMethod,
    reason: 'Venda #${sale.shortId}',
    description: '${sale.totalItems} item(ns) • ${sale.paymentMethod.label}',
    referenceId: referenceId,
    personName: sale.customerName,
    createdAt: sale.createdAt,
  );
}

void removeSaleCashMovement(BuildContext context, SaleRecord sale) {
  context.read<CashMovementProvider>().deleteMovementsByReferenceId(
    saleCashReferenceId(sale.id),
  );
}
