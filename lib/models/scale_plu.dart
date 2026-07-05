class ScalePlu {
  final String id;
  final String productId;
  final String pluCode;
  final String barcode;
  final String name;
  final double pricePerKg;
  final bool isWeightProduct;
  final bool isActive;

  const ScalePlu({
    required this.id,
    required this.productId,
    required this.pluCode,
    required this.barcode,
    required this.name,
    required this.pricePerKg,
    required this.isWeightProduct,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'pluCode': pluCode,
      'barcode': barcode,
      'name': name,
      'pricePerKg': pricePerKg,
      'isWeightProduct': isWeightProduct,
      'isActive': isActive,
    };
  }

  factory ScalePlu.fromMap(Map<String, dynamic> map) {
    return ScalePlu(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      pluCode: map['pluCode'] ?? '',
      barcode: map['barcode'] ?? '',
      name: map['name'] ?? '',
      pricePerKg: (map['pricePerKg'] ?? 0).toDouble(),
      isWeightProduct: map['isWeightProduct'] ?? true,
      isActive: map['isActive'] ?? true,
    );
  }

  ScalePlu copyWith({
    String? id,
    String? productId,
    String? pluCode,
    String? barcode,
    String? name,
    double? pricePerKg,
    bool? isWeightProduct,
    bool? isActive,
  }) {
    return ScalePlu(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      pluCode: pluCode ?? this.pluCode,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      isWeightProduct: isWeightProduct ?? this.isWeightProduct,
      isActive: isActive ?? this.isActive,
    );
  }
}
