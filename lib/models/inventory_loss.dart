enum InventoryLossType {
  expired,
  discarded,
  damaged,
  stockAdjustment,
}

extension InventoryLossTypeLabel on InventoryLossType {
  String get label {
    switch (this) {
      case InventoryLossType.expired:
        return 'Vencido';
      case InventoryLossType.discarded:
        return 'Descartado';
      case InventoryLossType.damaged:
        return 'Quebra/perda';
      case InventoryLossType.stockAdjustment:
        return 'Ajuste de estoque';
    }
  }
}

InventoryLossType inventoryLossTypeFromName(String? value) {
  return InventoryLossType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => InventoryLossType.discarded,
  );
}

class InventoryLoss {
  const InventoryLoss({
    required this.id,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.quantity,
    required this.unitLabel,
    required this.salePriceAtTime,
    required this.type,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productCode;
  final String productName;
  final double quantity;
  final String unitLabel;
  final double salePriceAtTime;
  final InventoryLossType type;
  final String reason;
  final DateTime createdAt;

  double get estimatedValue => quantity * salePriceAtTime;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productCode': productCode,
      'productName': productName,
      'quantity': quantity,
      'unitLabel': unitLabel,
      'salePriceAtTime': salePriceAtTime,
      'type': type.name,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InventoryLoss.fromMap(Map<String, dynamic> map) {
    return InventoryLoss(
      id: map['id']?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      productCode: map['productCode']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      quantity: _toDouble(map['quantity']),
      unitLabel: map['unitLabel']?.toString() ?? '',
      salePriceAtTime: _toDouble(map['salePriceAtTime']),
      type: inventoryLossTypeFromName(map['type']?.toString()),
      reason: map['reason']?.toString() ?? '',
      createdAt: _toDate(map['createdAt']),
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
