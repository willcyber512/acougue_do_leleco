import 'product_category.dart';
import 'product_unit.dart';

class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
    required this.salePrice,
    required this.costPrice,
    required this.stockQuantity,
    required this.minStock,
    required this.favorite,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
  });

  final String id;
  final String code;
  final String name;
  final ProductCategory category;
  final ProductUnit unit;
  final double salePrice;
  final double costPrice;
  final double stockQuantity;
  final double minStock;
  final bool favorite;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLowStock => stockQuantity <= minStock;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category.name,
      'unit': unit.name,
      'salePrice': salePrice,
      'costPrice': costPrice,
      'stockQuantity': stockQuantity,
      'minStock': minStock,
      'favorite': favorite,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: productCategoryFromName(map['category']?.toString()),
      unit: productUnitFromName(map['unit']?.toString()),
      salePrice: _toDouble(map['salePrice']),
      costPrice: _toDouble(map['costPrice']),
      stockQuantity: _toDouble(map['stockQuantity']),
      minStock: _toDouble(map['minStock']),
      favorite: _toBool(map['favorite']),
      imagePath: map['imagePath']?.toString(),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  Product copyWith({
    String? id,
    String? code,
    String? name,
    ProductCategory? category,
    ProductUnit? unit,
    double? salePrice,
    double? costPrice,
    double? stockQuantity,
    double? minStock,
    bool? favorite,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      salePrice: salePrice ?? this.salePrice,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minStock: minStock ?? this.minStock,
      favorite: favorite ?? this.favorite,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    final text = value?.toString().replaceAll(',', '.') ?? '';
    return double.tryParse(text) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;

    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime _toDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
