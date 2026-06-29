import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/product_category.dart';
import '../models/product_unit.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider() {
    _loadProducts();
  }

  static const String _storageKey = 'leleco_inventory_products_v1';

  final List<Product> _products = [];

  bool _isLoading = true;
  String _searchTerm = '';
  ProductCategory? _selectedCategory;

  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;
  ProductCategory? get selectedCategory => _selectedCategory;

  List<Product> get products => List.unmodifiable(_products);

  List<Product> get filteredProducts {
    final term = _searchTerm.trim().toLowerCase();

    final result = _products.where((product) {
      final matchesSearch = term.isEmpty ||
          product.name.toLowerCase().contains(term) ||
          product.code.toLowerCase().contains(term) ||
          product.category.label.toLowerCase().contains(term);

      final matchesCategory =
          _selectedCategory == null || product.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    result.sort((a, b) {
      if (a.favorite != b.favorite) {
        return a.favorite ? -1 : 1;
      }

      return a.name.compareTo(b.name);
    });

    return result;
  }

  int get totalProducts => _products.length;

  int get lowStockCount {
    return _products.where((product) => product.isLowStock).length;
  }

  int get favoriteCount {
    return _products.where((product) => product.favorite).length;
  }

  double get stockValue {
    return _products.fold(
      0,
      (total, product) => total + (product.salePrice * product.stockQuantity),
    );
  }

  void setSearchTerm(String value) {
    _searchTerm = value;
    notifyListeners();
  }

  void setCategory(ProductCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void addProduct(Product product) {
    _products.insert(0, product);
    _saveAndNotify();
  }

  void updateProduct(Product product) {
    final index = _products.indexWhere((item) => item.id == product.id);

    if (index == -1) return;

    _products[index] = product.copyWith(updatedAt: DateTime.now());
    _saveAndNotify();
  }

  void toggleFavorite(String productId) {
    final index = _products.indexWhere((item) => item.id == productId);

    if (index == -1) return;

    final product = _products[index];

    _products[index] = product.copyWith(
      favorite: !product.favorite,
      updatedAt: DateTime.now(),
    );

    _saveAndNotify();
  }

  void replenishProduct(String productId, double quantity) {
    if (quantity <= 0) return;

    final index = _products.indexWhere((item) => item.id == productId);

    if (index == -1) return;

    final product = _products[index];

    _products[index] = product.copyWith(
      stockQuantity: product.stockQuantity + quantity,
      updatedAt: DateTime.now(),
    );

    _saveAndNotify();
  }

  Future<void> _loadProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedProducts = prefs.getString(_storageKey);

      if (savedProducts == null || savedProducts.trim().isEmpty) {
        _loadMockProducts();
        await _saveProducts();
      } else {
        final decoded = jsonDecode(savedProducts);

        if (decoded is List) {
          _products
            ..clear()
            ..addAll(
              decoded.whereType<Map>().map(
                    (item) => Product.fromMap(
                      Map<String, dynamic>.from(item),
                    ),
                  ),
            );
        }

        if (_products.isEmpty) {
          _loadMockProducts();
          await _saveProducts();
        }
      }
    } catch (_) {
      _products.clear();
      _loadMockProducts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _products.map((product) => product.toMap()).toList(),
    );

    await prefs.setString(_storageKey, encoded);
  }

  void _saveAndNotify() {
    notifyListeners();
    _saveProducts();
  }

  void _loadMockProducts() {
    final now = DateTime.now();

    _products.addAll([
      Product(
        id: '1',
        code: '1001',
        name: 'Picanha',
        category: ProductCategory.bovina,
        unit: ProductUnit.kg,
        salePrice: 69.90,
        costPrice: 52.00,
        stockQuantity: 18.5,
        minStock: 5,
        favorite: true,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: '2',
        code: '1002',
        name: 'Coxão mole',
        category: ProductCategory.bovina,
        unit: ProductUnit.kg,
        salePrice: 39.90,
        costPrice: 29.00,
        stockQuantity: 3.2,
        minStock: 5,
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: '3',
        code: '2001',
        name: 'Frango inteiro',
        category: ProductCategory.frango,
        unit: ProductUnit.kg,
        salePrice: 13.99,
        costPrice: 9.50,
        stockQuantity: 25,
        minStock: 8,
        favorite: true,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: '4',
        code: '2002',
        name: 'Coxinha da asa',
        category: ProductCategory.frango,
        unit: ProductUnit.kg,
        salePrice: 18.90,
        costPrice: 13.00,
        stockQuantity: 4,
        minStock: 6,
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: '5',
        code: '3001',
        name: 'Bisteca suína',
        category: ProductCategory.suina,
        unit: ProductUnit.kg,
        salePrice: 24.90,
        costPrice: 17.00,
        stockQuantity: 12,
        minStock: 4,
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: '6',
        code: '4001',
        name: 'Charque',
        category: ProductCategory.charque,
        unit: ProductUnit.kg,
        salePrice: 49.90,
        costPrice: 35.00,
        stockQuantity: 2.5,
        minStock: 3,
        favorite: true,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: '7',
        code: '5001',
        name: 'Carvão 3kg',
        category: ProductCategory.carvao,
        unit: ProductUnit.pacote,
        salePrice: 15.00,
        costPrice: 10.00,
        stockQuantity: 30,
        minStock: 10,
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
      Product(
        id: '8',
        code: '6001',
        name: 'Sal grosso',
        category: ProductCategory.temperos,
        unit: ProductUnit.pacote,
        salePrice: 4.50,
        costPrice: 2.80,
        stockQuantity: 40,
        minStock: 10,
        favorite: false,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  }
}
