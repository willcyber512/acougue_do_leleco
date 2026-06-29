import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/sale_cart_item.dart';

enum PaymentMethod {
  dinheiro,
  pix,
  debito,
  credito,
  fiado,
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.dinheiro:
        return 'Dinheiro';
      case PaymentMethod.pix:
        return 'Pix';
      case PaymentMethod.debito:
        return 'Débito';
      case PaymentMethod.credito:
        return 'Crédito';
      case PaymentMethod.fiado:
        return 'Fiado';
    }
  }
}

class SalesProvider extends ChangeNotifier {
  final List<SaleCartItem> _items = [];

  PaymentMethod _paymentMethod = PaymentMethod.dinheiro;
  String _searchTerm = '';

  List<SaleCartItem> get items => List.unmodifiable(_items);
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

    final index = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index == -1) {
      _items.add(
        SaleCartItem(
          product: product,
          quantity: quantity,
        ),
      );
    } else {
      final current = _items[index];

      _items[index] = current.copyWith(
        quantity: current.quantity + quantity,
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
      _items[index] = _items[index].copyWith(quantity: quantity);
    }

    notifyListeners();
  }

  void increaseQuantity(String productId) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );

    if (index == -1) return;

    final item = _items[index];

    _items[index] = item.copyWith(quantity: item.quantity + 1);

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

  bool finishSale() {
    if (_items.isEmpty) return false;

    clearCart();
    return true;
  }
}
