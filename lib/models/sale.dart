import 'payment_method.dart';
import 'product_unit.dart';
import 'sale_cart_item.dart';

class SaleRecordItem {
  const SaleRecordItem({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.unitLabel,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String productCode;
  final String productName;
  final String unitLabel;
  final double quantity;
  final double unitPrice;

  double get subtotal => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productCode': productCode,
      'productName': productName,
      'unitLabel': unitLabel,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory SaleRecordItem.fromMap(Map<String, dynamic> map) {
    return SaleRecordItem(
      productId: map['productId']?.toString() ?? '',
      productCode: map['productCode']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      unitLabel: map['unitLabel']?.toString() ?? '',
      quantity: _toDouble(map['quantity']),
      unitPrice: _toDouble(map['unitPrice']),
    );
  }
}

class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.items,
    required this.paymentMethod,
    required this.total,
    required this.createdAt,
  });

  final String id;
  final List<SaleRecordItem> items;
  final PaymentMethod paymentMethod;
  final double total;
  final DateTime createdAt;

  String get shortId {
    if (id.length <= 6) return id;
    return id.substring(id.length - 6);
  }

  int get totalItems {
    return items.fold(
      0,
      (total, item) => total + item.quantity.round(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'paymentMethod': paymentMethod.name,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SaleRecord.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];

    return SaleRecord(
      id: map['id']?.toString() ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) => SaleRecordItem.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : [],
      paymentMethod: paymentMethodFromName(map['paymentMethod']?.toString()),
      total: _toDouble(map['total']),
      createdAt: _toDate(map['createdAt']),
    );
  }

  factory SaleRecord.fromCart({
    required List<SaleCartItem> cartItems,
    required PaymentMethod paymentMethod,
    required DateTime createdAt,
  }) {
    final items = cartItems.map((cartItem) {
      return SaleRecordItem(
        productId: cartItem.product.id,
        productCode: cartItem.product.code,
        productName: cartItem.product.name,
        unitLabel: cartItem.product.unit.label,
        quantity: cartItem.quantity,
        unitPrice: cartItem.product.salePrice,
      );
    }).toList();

    final total = items.fold(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    return SaleRecord(
      id: createdAt.microsecondsSinceEpoch.toString(),
      items: items,
      paymentMethod: paymentMethod,
      total: total,
      createdAt: createdAt,
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();

  final text = value?.toString().replaceAll(',', '.') ?? '';
  return double.tryParse(text) ?? 0;
}

DateTime _toDate(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
