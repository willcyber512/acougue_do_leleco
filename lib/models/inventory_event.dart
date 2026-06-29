enum InventoryEventType {
  created,
  updated,
  favorited,
  unfavorited,
  replenished,
  saleDeducted,
  lossRegistered,
  movedToTrash,
  restored,
  deletedForever,
  emptiedTrash,
}

extension InventoryEventTypeLabel on InventoryEventType {
  String get label {
    switch (this) {
      case InventoryEventType.created:
        return 'Produto criado';
      case InventoryEventType.updated:
        return 'Produto editado';
      case InventoryEventType.favorited:
        return 'Favoritado';
      case InventoryEventType.unfavorited:
        return 'Desfavoritado';
      case InventoryEventType.replenished:
        return 'Estoque reposto';
      case InventoryEventType.saleDeducted:
        return 'Baixa por venda';
      case InventoryEventType.lossRegistered:
        return 'Perda registrada';
      case InventoryEventType.movedToTrash:
        return 'Movido para lixeira';
      case InventoryEventType.restored:
        return 'Restaurado';
      case InventoryEventType.deletedForever:
        return 'Excluído definitivamente';
      case InventoryEventType.emptiedTrash:
        return 'Lixeira esvaziada';
    }
  }
}

InventoryEventType inventoryEventTypeFromName(String? value) {
  return InventoryEventType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => InventoryEventType.updated,
  );
}

class InventoryEvent {
  const InventoryEvent({
    required this.id,
    required this.type,
    required this.description,
    required this.createdAt,
    this.productId,
    this.productCode,
    this.productName,
    this.quantity,
  });

  final String id;
  final InventoryEventType type;
  final String description;
  final DateTime createdAt;
  final String? productId;
  final String? productCode;
  final String? productName;
  final double? quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'productId': productId,
      'productCode': productCode,
      'productName': productName,
      'quantity': quantity,
    };
  }

  factory InventoryEvent.fromMap(Map<String, dynamic> map) {
    return InventoryEvent(
      id: map['id']?.toString() ?? '',
      type: inventoryEventTypeFromName(map['type']?.toString()),
      description: map['description']?.toString() ?? '',
      createdAt: _toDate(map['createdAt']),
      productId: map['productId']?.toString(),
      productCode: map['productCode']?.toString(),
      productName: map['productName']?.toString(),
      quantity: _toNullableDouble(map['quantity']),
    );
  }

  static DateTime _toDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    final text = value.toString().replaceAll(',', '.');

    if (text.isEmpty || text == 'null') return null;

    return double.tryParse(text);
  }
}
