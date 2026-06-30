enum RamuzaBarcodeStatus {
  success,
  productNotFound,
  productDeleted,
  stockEmpty,
  invalidQuantity,
  canceledQuickRegister,
}

extension RamuzaBarcodeStatusLabel on RamuzaBarcodeStatus {
  String get label {
    switch (this) {
      case RamuzaBarcodeStatus.success:
        return 'Sucesso';
      case RamuzaBarcodeStatus.productNotFound:
        return 'Produto não cadastrado';
      case RamuzaBarcodeStatus.productDeleted:
        return 'Produto na lixeira';
      case RamuzaBarcodeStatus.stockEmpty:
        return 'Estoque zerado';
      case RamuzaBarcodeStatus.invalidQuantity:
        return 'Quantidade inválida';
      case RamuzaBarcodeStatus.canceledQuickRegister:
        return 'Cadastro cancelado';
    }
  }
}

RamuzaBarcodeStatus ramuzaBarcodeStatusFromName(String? value) {
  return RamuzaBarcodeStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => RamuzaBarcodeStatus.productNotFound,
  );
}

class RamuzaBarcodeEvent {
  const RamuzaBarcodeEvent({
    required this.id,
    required this.rawBarcode,
    required this.digits,
    required this.productCode,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.message,
    required this.screen,
    required this.createdAt,
  });

  final String id;
  final String rawBarcode;
  final String digits;
  final String productCode;
  final String? productName;
  final double? quantity;
  final double? totalPrice;
  final RamuzaBarcodeStatus status;
  final String message;
  final String screen;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rawBarcode': rawBarcode,
      'digits': digits,
      'productCode': productCode,
      'productName': productName,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'status': status.name,
      'message': message,
      'screen': screen,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RamuzaBarcodeEvent.fromMap(Map<String, dynamic> map) {
    return RamuzaBarcodeEvent(
      id: map['id']?.toString() ?? '',
      rawBarcode: map['rawBarcode']?.toString() ?? '',
      digits: map['digits']?.toString() ?? '',
      productCode: map['productCode']?.toString() ?? '',
      productName: map['productName']?.toString(),
      quantity: _toNullableDouble(map['quantity']),
      totalPrice: _toNullableDouble(map['totalPrice']),
      status: ramuzaBarcodeStatusFromName(map['status']?.toString()),
      message: map['message']?.toString() ?? '',
      screen: map['screen']?.toString() ?? '',
      createdAt: _toDate(map['createdAt']),
    );
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    final text = value.toString().replaceAll(',', '.');
    return double.tryParse(text);
  }

  static DateTime _toDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
