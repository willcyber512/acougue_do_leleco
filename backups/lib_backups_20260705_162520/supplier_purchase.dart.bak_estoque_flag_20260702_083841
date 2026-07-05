import 'product_category.dart';
import 'product_unit.dart';

class SupplierPurchase {
  const SupplierPurchase({
    required this.id,
    required this.supplierName,
    required this.itemName,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.unitCost,
    required this.purchaseDate,
    required this.paid,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.documentNumber,
  });

  final String id;
  final String supplierName;
  final String itemName;
  final ProductCategory category;
  final ProductUnit unit;
  final double quantity;
  final double unitCost;
  final DateTime purchaseDate;
  final bool paid;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? documentNumber;

  double get totalCost => quantity * unitCost;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierName': supplierName,
      'itemName': itemName,
      'category': category.name,
      'unit': unit.name,
      'quantity': quantity,
      'unitCost': unitCost,
      'purchaseDate': purchaseDate.toIso8601String(),
      'paid': paid,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'documentNumber': documentNumber,
    };
  }

  factory SupplierPurchase.fromMap(Map<String, dynamic> map) {
    return SupplierPurchase(
      id: map['id']?.toString() ?? '',
      supplierName: map['supplierName']?.toString() ?? '',
      itemName: map['itemName']?.toString() ?? '',
      category: productCategoryFromName(map['category']?.toString()),
      unit: productUnitFromName(map['unit']?.toString()),
      quantity: _toDouble(map['quantity']),
      unitCost: _toDouble(map['unitCost']),
      purchaseDate: _toDate(map['purchaseDate']),
      paid: _toBool(map['paid']),
      notes: map['notes']?.toString() ?? '',
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
      documentNumber: map['documentNumber']?.toString(),
    );
  }

  SupplierPurchase copyWith({
    String? supplierName,
    String? itemName,
    ProductCategory? category,
    ProductUnit? unit,
    double? quantity,
    double? unitCost,
    DateTime? purchaseDate,
    bool? paid,
    String? notes,
    DateTime? updatedAt,
    String? documentNumber,
  }) {
    return SupplierPurchase(
      id: id,
      supplierName: supplierName ?? this.supplierName,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      paid: paid ?? this.paid,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      documentNumber: documentNumber ?? this.documentNumber,
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
