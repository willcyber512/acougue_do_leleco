import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/supplier_purchase.dart';

class SuppliersProvider extends ChangeNotifier {
  SuppliersProvider() {
    _loadData();
  }

  static const String storageKey = 'leleco_supplier_purchases_v1';

  final List<SupplierPurchase> _purchases = [];

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  List<SupplierPurchase> get purchases {
    final result = [..._purchases];
    result.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    return List.unmodifiable(result);
  }

  double get totalPurchased {
    return _purchases.fold<double>(
      0,
      (total, purchase) => total + purchase.totalCost,
    );
  }

  double get openAmount {
    return _purchases.where((purchase) => !purchase.paid).fold<double>(
          0,
          (total, purchase) => total + purchase.totalCost,
        );
  }

  int get suppliersCount {
    return _purchases
        .map((purchase) => purchase.supplierName.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;
  }

  List<SupplierPurchase> purchasesForPeriod({
    DateTime? start,
    DateTime? end,
  }) {
    return purchases.where((purchase) {
      final date = purchase.purchaseDate;

      if (start != null && date.isBefore(start)) return false;
      if (end != null && date.isAfter(end)) return false;

      return true;
    }).toList();
  }

  void addPurchase(SupplierPurchase purchase) {
    _purchases.insert(0, purchase);

    _saveAllAndNotify();
  }

  void updatePurchase(SupplierPurchase purchase) {
    final index = _purchases.indexWhere((item) => item.id == purchase.id);

    if (index == -1) return;

    _purchases[index] = purchase.copyWith(updatedAt: DateTime.now());

    _saveAllAndNotify();
  }

  void deletePurchase(String purchaseId) {
    _purchases.removeWhere((purchase) => purchase.id == purchaseId);

    _saveAllAndNotify();
  }

  Future<void> reloadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    _purchases.clear();

    await _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        _purchases
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map(
                  (item) => SupplierPurchase.fromMap(
                    item.map(
                      (key, value) => MapEntry(key.toString(), value),
                    ),
                  ),
                ),
          );
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAllAndNotify() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      storageKey,
      jsonEncode(_purchases.map((purchase) => purchase.toMap()).toList()),
    );

    notifyListeners();
  }
}
