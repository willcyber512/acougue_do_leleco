import 'payment_method.dart';

class SalePayment {
  const SalePayment({required this.method, required this.amount});

  final PaymentMethod method;
  final double amount;

  bool get isImmediate =>
      method != PaymentMethod.fiado && method != PaymentMethod.misto;

  Map<String, dynamic> toMap() {
    return {'method': method.name, 'amount': amount};
  }

  factory SalePayment.fromMap(Map<String, dynamic> map) {
    return SalePayment(
      method: paymentMethodFromName(map['method']?.toString()),
      amount: _toDouble(map['amount']),
    );
  }

  SalePayment copyWith({PaymentMethod? method, double? amount}) {
    return SalePayment(
      method: method ?? this.method,
      amount: amount ?? this.amount,
    );
  }
}

double salePaymentsTotal(List<SalePayment> payments) {
  return payments.fold(0.0, (total, payment) => total + payment.amount);
}

List<SalePayment> normalizeSalePayments({
  required List<SalePayment> payments,
  required PaymentMethod fallbackMethod,
  required double total,
}) {
  if (total <= 0) return const [];

  final clean = payments.where((payment) {
    return payment.amount > 0.004 &&
        payment.method != PaymentMethod.fiado &&
        payment.method != PaymentMethod.misto;
  }).toList();

  if (clean.isEmpty) {
    return [SalePayment(method: fallbackMethod, amount: total)];
  }

  return clean;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();

  final text = value?.toString().replaceAll(',', '.') ?? '';
  return double.tryParse(text) ?? 0;
}
