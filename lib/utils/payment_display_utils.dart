import '../models/payment_method.dart';
import '../models/sale.dart';

String paymentMethodDisplay(PaymentMethod method) {
  return method.label;
}

String salePaymentDisplay(SaleRecord sale) {
  return sale.paymentSummary;
}

String salePaymentDetails(SaleRecord sale) {
  final parts = sale.effectivePaymentParts.where((payment) {
    return payment.amount > 0.004 &&
        payment.method != PaymentMethod.fiado &&
        payment.method != PaymentMethod.misto;
  }).toList();

  if (parts.isEmpty) return sale.paymentLabel;

  return parts
      .map(
        (payment) =>
            '${payment.method.label}: R\$ ${payment.amount.toStringAsFixed(2).replaceAll('.', ',')}',
      )
      .join(' • ');
}
