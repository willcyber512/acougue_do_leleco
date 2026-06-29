import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inventory_event.dart';
import '../models/inventory_loss.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/product_unit.dart';
import '../models/sale.dart';
import '../models/sale_cart_item.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider() {
    _loadData();
  }

  static const String _productsStorageKey = 'leleco_inventory_products_v1';
  static const String _eventsStorageKey = 'leleco_inventory_events_v1';
  static const String _lossesStorageKey = 'leleco_inventory_losses_v1';

  final List<Product> _products = [];
  final List<InventoryEvent> _events = [];
  final List<InventoryLoss> _losses = [];

  bool _isLoading = true;
  String _searchTerm = '';
  ProductCategory? _selectedCategory;

  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;
  ProductCategory? get selectedCategory => _selectedCategory;

  List<Product> get products {
    return List.unmodifiable(_products.where((product) => !product.isDeleted));
  }

  List<Product> get deletedProducts {
    final result = _products.where((product) => product.isDeleted).toList();

    result.sort((a, b) {
      final aDate = a.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return result;
  }

  List<InventoryEvent> get events {
    final result = [..._events];
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  List<InventoryLoss> get losses {
    final result = [..._losses];
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  List<InventoryEvent> eventsForProduct(String productId) {
    final result = _events.where((event) => event.productId == productId).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  List<InventoryLoss> lossesForProduct(String productId) {
    final result = _losses.where((loss) => loss.productId == productId).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  int get deletedProductsCount => deletedProducts.length;
  int get eventsCount => _events.length;
  int get lossesCount => _losses.length;

  double get lossesEstimatedValue {
    return _losses.fold(
      0.0,
      (total, loss) => total + loss.estimatedValue,
    );
  }

  List<Product> get filteredProducts {
    final term = _searchTerm.trim().toLowerCase();

    final result = _products.where((product) {
      if (product.isDeleted) return false;

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

  int get totalProducts => products.length;

  int get lowStockCount {
    return products.where((product) => product.isLowStock).length;
  }

  int get favoriteCount {
    return products.where((product) => product.favorite).length;
  }

  double get stockValue {
    return products.fold(
      0.0,
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

    _addEvent(
      type: InventoryEventType.created,
      product: product,
      description: 'Produto "${product.name}" foi cadastrado no estoque.',
    );

    _saveAllAndNotify();
  }

  void updateProduct(Product product) {
    final index = _products.indexWhere((item) => item.id == product.id);

    if (index == -1) return;

    _products[index] = product.copyWith(updatedAt: DateTime.now());

    _addEvent(
      type: InventoryEventType.updated,
      product: _products[index],
      description: 'Produto "${product.name}" foi editado.',
    );

    _saveAllAndNotify();
  }

  void toggleFavorite(String productId) {
    final index = _products.indexWhere((item) => item.id == productId);

    if (index == -1) return;

    final product = _products[index];
    final willBeFavorite = !product.favorite;

    _products[index] = product.copyWith(
      favorite: willBeFavorite,
      updatedAt: DateTime.now(),
    );

    _addEvent(
      type: willBeFavorite
          ? InventoryEventType.favorited
          : InventoryEventType.unfavorited,
      product: _products[index],
      description: willBeFavorite
          ? 'Produto "${product.name}" foi marcado como favorito.'
          : 'Produto "${product.name}" foi removido dos favoritos.',
    );

    _saveAllAndNotify();
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

    _addEvent(
      type: InventoryEventType.replenished,
      product: _products[index],
      quantity: quantity,
      description:
          'Entrada de ${_formatNumber(quantity)} ${product.unit.label} em "${product.name}".',
    );

    _saveAllAndNotify();
  }

  bool registerLoss({
    required String productId,
    required double quantity,
    required InventoryLossType type,
    required String reason,
  }) {
    if (quantity <= 0) return false;

    final index = _products.indexWhere((item) => item.id == productId);

    if (index == -1) return false;

    final product = _products[index];

    if (product.isDeleted || product.stockQuantity <= 0) {
      return false;
    }

    final lossQuantity =
        quantity > product.stockQuantity ? product.stockQuantity : quantity;

    final now = DateTime.now();

    final loss = InventoryLoss(
      id: now.microsecondsSinceEpoch.toString(),
      productId: product.id,
      productCode: product.code,
      productName: product.name,
      quantity: lossQuantity,
      unitLabel: product.unit.label,
      salePriceAtTime: product.salePrice,
      type: type,
      reason: reason,
      createdAt: now,
    );

    _losses.add(loss);

    _products[index] = product.copyWith(
      stockQuantity: product.stockQuantity - lossQuantity,
      updatedAt: now,
    );

    _addEvent(
      type: InventoryEventType.lossRegistered,
      product: _products[index],
      quantity: lossQuantity,
      description:
          'Perda registrada: ${_formatNumber(lossQuantity)} ${product.unit.label} de "${product.name}" (${type.label}).',
    );

    _saveAllAndNotify();
    return true;
  }


  String? validateSaleItems(List<SaleCartItem> items) {
    if (items.isEmpty) return 'Adicione produtos ao carrinho.';

    for (final item in items) {
      final index = _products.indexWhere(
        (product) => product.id == item.product.id && !product.isDeleted,
      );

      if (index == -1) {
        return 'Produto "${item.product.name}" não encontrado no estoque.';
      }

      final currentProduct = _products[index];

      if (currentProduct.stockQuantity < item.quantity) {
        return 'Estoque insuficiente para "${currentProduct.name}". Disponível: ${_formatNumber(currentProduct.stockQuantity)} ${currentProduct.unit.label}.';
      }
    }

    return null;
  }

  bool deductSaleRecord(SaleRecord sale) {
    for (final item in sale.items) {
      final index = _products.indexWhere(
        (product) => product.id == item.productId && !product.isDeleted,
      );

      if (index == -1) return false;

      final product = _products[index];

      if (product.stockQuantity < item.quantity) return false;
    }

    for (final item in sale.items) {
      final index = _products.indexWhere(
        (product) => product.id == item.productId && !product.isDeleted,
      );

      final product = _products[index];

      _products[index] = product.copyWith(
        stockQuantity: product.stockQuantity - item.quantity,
        updatedAt: sale.createdAt,
      );

      _addEvent(
        type: InventoryEventType.saleDeducted,
        product: _products[index],
        quantity: item.quantity,
        description:
            'Venda #${sale.shortId} baixou ${_formatNumber(item.quantity)} ${product.unit.label} de "${product.name}".',
      );
    }

    _saveAllAndNotify();
    return true;
  }

  void moveProductToTrash(String productId) {
    final index = _products.indexWhere((item) => item.id == productId);

    if (index == -1) return;

    final product = _products[index];

    _products[index] = product.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _addEvent(
      type: InventoryEventType.movedToTrash,
      product: product,
      description: 'Produto "${product.name}" foi movido para a lixeira.',
    );

    _saveAllAndNotify();
  }

  void restoreProduct(String productId) {
    final index = _products.indexWhere((item) => item.id == productId);

    if (index == -1) return;

    final product = _products[index];

    _products[index] = product.copyWith(
      clearDeletedAt: true,
      updatedAt: DateTime.now(),
    );

    _addEvent(
      type: InventoryEventType.restored,
      product: _products[index],
      description: 'Produto "${product.name}" foi restaurado da lixeira.',
    );

    _saveAllAndNotify();
  }

  void deleteProductForever(String productId) {
    final index = _products.indexWhere((product) => product.id == productId);

    if (index == -1) return;

    final product = _products[index];

    _addEvent(
      type: InventoryEventType.deletedForever,
      product: product,
      description:
          'Produto "${product.name}" foi excluído definitivamente do sistema.',
    );

    _products.removeAt(index);
    _saveAllAndNotify();
  }

  void emptyTrash() {
    final deletedCount = deletedProducts.length;

    if (deletedCount == 0) return;

    _products.removeWhere((product) => product.isDeleted);

    _addEvent(
      type: InventoryEventType.emptiedTrash,
      description: 'A lixeira foi esvaziada. $deletedCount produto(s) removido(s).',
    );

    _saveAllAndNotify();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await _loadProducts(prefs);
      await _loadEvents(prefs);
      await _loadLosses(prefs);
    } catch (_) {
      _products.clear();
      _events.clear();
      _losses.clear();
      _loadMockProducts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProducts(SharedPreferences prefs) async {
    final savedProducts = prefs.getString(_productsStorageKey);

    if (savedProducts == null || savedProducts.trim().isEmpty) {
      _loadMockProducts();
      await _saveProducts();
      return;
    }

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

  Future<void> _loadEvents(SharedPreferences prefs) async {
    final savedEvents = prefs.getString(_eventsStorageKey);

    if (savedEvents == null || savedEvents.trim().isEmpty) {
      return;
    }

    final decoded = jsonDecode(savedEvents);

    if (decoded is List) {
      _events
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
                (item) => InventoryEvent.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              ),
        );
    }
  }

  Future<void> _loadLosses(SharedPreferences prefs) async {
    final savedLosses = prefs.getString(_lossesStorageKey);

    if (savedLosses == null || savedLosses.trim().isEmpty) {
      return;
    }

    final decoded = jsonDecode(savedLosses);

    if (decoded is List) {
      _losses
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
                (item) => InventoryLoss.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              ),
        );
    }
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _products.map((product) => product.toMap()).toList(),
    );

    await prefs.setString(_productsStorageKey, encoded);
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _events.map((event) => event.toMap()).toList(),
    );

    await prefs.setString(_eventsStorageKey, encoded);
  }

  Future<void> _saveLosses() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _losses.map((loss) => loss.toMap()).toList(),
    );

    await prefs.setString(_lossesStorageKey, encoded);
  }

  void _saveAllAndNotify() {
    notifyListeners();
    _saveProducts();
    _saveEvents();
    _saveLosses();
  }

  void _addEvent({
    required InventoryEventType type,
    required String description,
    Product? product,
    double? quantity,
  }) {
    final now = DateTime.now();

    _events.add(
      InventoryEvent(
        id: now.microsecondsSinceEpoch.toString(),
        type: type,
        description: description,
        createdAt: now,
        productId: product?.id,
        productCode: product?.code,
        productName: product?.name,
        quantity: quantity,
      ),
    );
  }

  void _loadMockProducts() {
    final now = DateTime.now();

    _products
      ..clear()
      ..addAll([
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

  String _formatNumber(double value) {
    return value.toStringAsFixed(3).replaceAll('.', ',');
  }
}
