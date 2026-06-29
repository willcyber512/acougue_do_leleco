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
}
