import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment_method.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_cart_item.dart';

export '../models/payment_method.dart';

class SalesProvider extends ChangeNotifier {
  SalesProvider() {
    _loadSales();
  }

  static const String _salesStorageKey = 'leleco_sales_records_v1';

  final List<SaleCartItem> _items = [];
  final List<SaleRecord> _sales = [];

  PaymentMethod _paymentMethod = PaymentMethod.dinheiro;
  String _searchTerm = '';

  List<SaleCartItem> get items => List.unmodifiable(_items);
  List<SaleRecord> get sales => List.unmodifiable(_sortedSales());

  PaymentMethod get paymentMethod => _paymentMethod;
  String get searchTerm => _searchTerm;

  bool get hasItems => _items.isNotEmpty;

  int get totalItems {
    return _items.fold(
      0,
      (total, item) => total + item.quantity.round(),
    );
  }

  double get total {
    return _items.fold(
      0.0,
      (total, item) => total + item.subtotal,
    );
  }

  List<SaleRecord> get completedSales {
    return _sales.where((sale) => !sale.isCanceled).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<SaleRecord> get todaySales {
    final now = DateTime.now();

    return _sales.where((sale) {
      return sale.createdAt.year == now.year &&
          sale.createdAt.month == now.month &&
          sale.createdAt.day == now.day;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<SaleRecord> get todayCompletedSales {
    return todaySales.where((sale) => !sale.isCanceled).toList();
  }

  int get todaySalesCount => todayCompletedSales.length;

  double get todayRevenue {
    return todayCompletedSales.fold(
      0.0,
      (total, sale) => total + sale.total,
    );
  }

  double get todayFiadoTotal {
    return todayCompletedSales
        .where((sale) => sale.paymentMethod == PaymentMethod.fiado)
        .fold(0.0, (total, sale) => total + sale.total);
  }

  SaleRecord? findSaleById(String saleId) {
    try {
      return _sales.firstWhere((sale) => sale.id == saleId);
    } catch (_) {
      return null;
    }
  }

  void setSearchTerm(String value) {
    _searchTerm = value;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void addProduct(Product product, {double quantity = 1}) {
    if (quantity <= 0) return;
    if (product.stockQuantity <= 0) return;

    final index = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index == -1) {
      final safeQuantity =
          quantity > product.stockQuantity ? product.stockQuantity : quantity;

      _items.add(
        SaleCartItem(
          product: product,
          quantity: safeQuantity,
        ),
      );
    } else {
      final current = _items[index];
      final newQuantity = current.quantity + quantity;
      final safeQuantity =
          newQuantity > product.stockQuantity ? product.stockQuantity : newQuantity;

      _items[index] = current.copyWith(
        quantity: safeQuantity,
      );
    }

    _searchTerm = '';
    notifyListeners();
  }

  void updateQuantity(String productId, double quantity) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );

    if (index == -1) return;

    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      final product = _items[index].product;
      final safeQuantity =
          quantity > product.stockQuantity ? product.stockQuantity : quantity;

      _items[index] = _items[index].copyWith(quantity: safeQuantity);
    }

    notifyListeners();
  }

  void increaseQuantity(String productId) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );

    if (index == -1) return;

    final item = _items[index];
    final newQuantity = item.quantity + 1;

    if (newQuantity > item.product.stockQuantity) return;

    _items[index] = item.copyWith(quantity: newQuantity);

    notifyListeners();
  }

  void decreaseQuantity(String productId) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );

    if (index == -1) return;

    final item = _items[index];
    final newQuantity = item.quantity - 1;

    if (newQuantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = item.copyWith(quantity: newQuantity);
    }

    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _searchTerm = '';
    _paymentMethod = PaymentMethod.dinheiro;
    notifyListeners();
  }

  SaleRecord? createSaleRecord({
    String? customerId,
    String? customerName,
  }) {
    if (_items.isEmpty) return null;

    return SaleRecord.fromCart(
      cartItems: _items,
      paymentMethod: _paymentMethod,
      createdAt: DateTime.now(),
      customerId: customerId,
      customerName: customerName,
    );
  }

  void completeSale(SaleRecord sale) {
    _sales.insert(0, sale);

    _items.clear();
    _searchTerm = '';
    _paymentMethod = PaymentMethod.dinheiro;

    _saveSales();
    notifyListeners();
  }

  bool cancelSale(String saleId, String reason) {
    final index = _sales.indexWhere((sale) => sale.id == saleId);

    if (index == -1) return false;
    if (_sales[index].isCanceled) return false;

    _sales[index] = _sales[index].copyWith(
      canceledAt: DateTime.now(),
      cancelReason: reason.trim().isEmpty ? 'Cancelamento manual' : reason.trim(),
    );

    _saveSales();
    notifyListeners();

    return true;
  }

  SaleRecord? finishSale() {
    final sale = createSaleRecord();

    if (sale == null) return null;

    completeSale(sale);
    return sale;
  }

  Future<void> _loadSales() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSales = prefs.getString(_salesStorageKey);

    if (savedSales == null || savedSales.trim().isEmpty) {
      return;
    }

    final decoded = jsonDecode(savedSales);

    if (decoded is List) {
      _sales
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
                (item) => SaleRecord.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              ),
        );
    }

    notifyListeners();
  }

  Future<void> _saveSales() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _sales.map((sale) => sale.toMap()).toList(),
    );

    await prefs.setString(_salesStorageKey, encoded);
  }

  List<SaleRecord> _sortedSales() {
    final result = [..._sales];
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
}
