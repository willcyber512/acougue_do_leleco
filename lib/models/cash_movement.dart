import 'payment_method.dart';

enum CashMovementType { input, output }

extension CashMovementTypeLabel on CashMovementType {
  String get label {
    switch (this) {
      case CashMovementType.input:
        return 'Entrada';
      case CashMovementType.output:
        return 'Saída';
    }
  }
}

enum CashMovementCategory {
  sale,
  creditPayment,
  supplier,
  stock,
  market,
  employee,
  ownerWithdrawal,
  expense,
  cashIn,
  cashOut,
  adjustment,
  other,
}

extension CashMovementCategoryLabel on CashMovementCategory {
  String get label {
    switch (this) {
      case CashMovementCategory.sale:
        return 'Venda';
      case CashMovementCategory.creditPayment:
        return 'Pagamento de fiado';
      case CashMovementCategory.supplier:
        return 'Fornecedor';
      case CashMovementCategory.stock:
        return 'Reposição/estoque';
      case CashMovementCategory.market:
        return 'Mercado';
      case CashMovementCategory.employee:
        return 'Funcionário';
      case CashMovementCategory.ownerWithdrawal:
        return 'Retirada da dona';
      case CashMovementCategory.expense:
        return 'Despesa';
      case CashMovementCategory.cashIn:
        return 'Reforço no caixa';
      case CashMovementCategory.cashOut:
        return 'Sangria';
      case CashMovementCategory.adjustment:
        return 'Ajuste';
      case CashMovementCategory.other:
        return 'Outros';
    }
  }
}

class CashMovement {
  const CashMovement({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.paymentMethod,
    required this.reason,
    required this.description,
    required this.createdAt,
    this.referenceId,
    this.personName,
  });

  final String id;
  final CashMovementType type;
  final CashMovementCategory category;
  final double amount;
  final PaymentMethod paymentMethod;
  final String reason;
  final String description;
  final DateTime createdAt;
  final String? referenceId;
  final String? personName;

  bool get isInput => type == CashMovementType.input;
  bool get isOutput => type == CashMovementType.output;

  CashMovement copyWith({
    String? id,
    CashMovementType? type,
    CashMovementCategory? category,
    double? amount,
    PaymentMethod? paymentMethod,
    String? reason,
    String? description,
    DateTime? createdAt,
    String? referenceId,
    String? personName,
  }) {
    return CashMovement(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      referenceId: referenceId ?? this.referenceId,
      personName: personName ?? this.personName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'category': category.name,
      'amount': amount,
      'paymentMethod': paymentMethod.name,
      'reason': reason,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'referenceId': referenceId,
      'personName': personName,
    };
  }

  factory CashMovement.fromMap(Map<String, dynamic> map) {
    CashMovementType parseType(String? value) {
      return CashMovementType.values.firstWhere(
        (item) => item.name == value,
        orElse: () => CashMovementType.output,
      );
    }

    CashMovementCategory parseCategory(String? value) {
      return CashMovementCategory.values.firstWhere(
        (item) => item.name == value,
        orElse: () => CashMovementCategory.other,
      );
    }

    PaymentMethod parsePayment(String? value) {
      return PaymentMethod.values.firstWhere(
        (item) => item.name == value,
        orElse: () => PaymentMethod.dinheiro,
      );
    }

    return CashMovement(
      id:
          map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: parseType(map['type']?.toString()),
      category: parseCategory(map['category']?.toString()),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: parsePayment(map['paymentMethod']?.toString()),
      reason: map['reason']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      referenceId: map['referenceId']?.toString(),
      personName: map['personName']?.toString(),
    );
  }
}
