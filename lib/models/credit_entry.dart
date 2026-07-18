import 'payment_method.dart';

enum CreditEntryType { purchase, payment }

extension CreditEntryTypeLabel on CreditEntryType {
  String get label {
    switch (this) {
      case CreditEntryType.purchase:
        return 'Compra fiado';
      case CreditEntryType.payment:
        return 'Pagamento recebido';
    }
  }
}

CreditEntryType creditEntryTypeFromName(String? value) {
  return CreditEntryType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => CreditEntryType.purchase,
  );
}

class CreditEntry {
  const CreditEntry({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.paymentMethod = PaymentMethod.dinheiro,
    this.cashMovementReferenceId,
    this.saleId,
  });

  final String id;
  final String customerId;
  final String customerName;
  final CreditEntryType type;
  final double amount;
  final String description;
  final DateTime createdAt;
  final PaymentMethod paymentMethod;
  final String? cashMovementReferenceId;
  final String? saleId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'type': type.name,
      'amount': amount,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'paymentMethod': paymentMethod.name,
      'cashMovementReferenceId': cashMovementReferenceId,
      'saleId': saleId,
    };
  }

  factory CreditEntry.fromMap(Map<String, dynamic> map) {
    return CreditEntry(
      id: map['id']?.toString() ?? '',
      customerId: map['customerId']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      type: creditEntryTypeFromName(map['type']?.toString()),
      amount: _toDouble(map['amount']),
      description: map['description']?.toString() ?? '',
      createdAt: _toDate(map['createdAt']),
      paymentMethod: paymentMethodFromName(map['paymentMethod']?.toString()),
      cashMovementReferenceId: map['cashMovementReferenceId']?.toString(),
      saleId: map['saleId']?.toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    final text = value?.toString().replaceAll(',', '.') ?? '';
    return double.tryParse(text) ?? 0;
  }

  static DateTime _toDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
