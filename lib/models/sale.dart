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
    this.discountAmount = 0,
    required this.createdAt,
    this.customerId,
    this.customerName,
    this.canceledAt,
    this.cancelReason,
  });

  final String id;
  final List<SaleRecordItem> items;
  final PaymentMethod paymentMethod;
  final double total;
  final double discountAmount;
  final DateTime createdAt;
  final String? customerId;
  final String? customerName;
  final DateTime? canceledAt;
  final String? cancelReason;

  bool get isCanceled => canceledAt != null;

  double get grossTotal {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get safeDiscountAmount {
    return _clampDiscount(discountAmount, grossTotal);
  }

  bool get hasDiscount => safeDiscountAmount > 0.004;

  String get shortId {
    if (id.length <= 6) return id;
    return id.substring(id.length - 6);
  }

  int get totalItems {
    return items.fold(0, (total, item) => total + item.quantity.round());
  }

  SaleRecord copyWith({
    String? id,
    List<SaleRecordItem>? items,
    PaymentMethod? paymentMethod,
    double? total,
    double? discountAmount,
    DateTime? createdAt,
    String? customerId,
    String? customerName,
    DateTime? canceledAt,
    String? cancelReason,
  }) {
    return SaleRecord(
      id: id ?? this.id,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      total: total ?? this.total,
      discountAmount: discountAmount ?? this.discountAmount,
      createdAt: createdAt ?? this.createdAt,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      canceledAt: canceledAt ?? this.canceledAt,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((item) => item.toMap()).toList(),
      'paymentMethod': paymentMethod.name,
      'total': total,
      'discountAmount': discountAmount,
      'createdAt': createdAt.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'canceledAt': canceledAt?.toIso8601String(),
      'cancelReason': cancelReason,
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
                  (item) =>
                      SaleRecordItem.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : [],
      paymentMethod: paymentMethodFromName(map['paymentMethod']?.toString()),
      total: _toDouble(map['total']),
      discountAmount: _toDouble(map['discountAmount']),
      createdAt: _toDate(map['createdAt']),
      customerId: map['customerId']?.toString(),
      customerName: map['customerName']?.toString(),
      canceledAt: _toNullableDate(map['canceledAt']),
      cancelReason: map['cancelReason']?.toString(),
    );
  }

  factory SaleRecord.fromCart({
    required List<SaleCartItem> cartItems,
    required PaymentMethod paymentMethod,
    required DateTime createdAt,
    double discountAmount = 0,
    String? customerId,
    String? customerName,
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

    final grossTotal = items.fold(0.0, (sum, item) => sum + item.subtotal);

    final safeDiscount = _clampDiscount(discountAmount, grossTotal);
    final total = grossTotal - safeDiscount;

    return SaleRecord(
      id: createdAt.microsecondsSinceEpoch.toString(),
      items: items,
      paymentMethod: paymentMethod,
      total: total,
      discountAmount: safeDiscount,
      createdAt: createdAt,
      customerId: customerId,
      customerName: customerName,
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

DateTime? _toNullableDate(dynamic value) {
  final text = value?.toString();

  if (text == null || text.isEmpty || text == 'null') {
    return null;
  }

  return DateTime.tryParse(text);
}

double _clampDiscount(double value, double subtotal) {
  if (value <= 0 || subtotal <= 0) return 0;
  if (value > subtotal) return subtotal;
  return value;
}
