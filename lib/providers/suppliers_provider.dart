import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/supplier_profile.dart';
import '../models/supplier_purchase.dart';

class SuppliersProvider extends ChangeNotifier {
  SuppliersProvider() {
    _loadData();
  }

  static const String purchasesStorageKey = 'leleco_supplier_purchases_v1';
  static const String suppliersStorageKey = 'leleco_suppliers_v1';

  /// Mantém compatibilidade com códigos antigos.
  static const String storageKey = purchasesStorageKey;

  final List<SupplierPurchase> _purchases = [];
  final List<SupplierProfile> _suppliers = [];

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  List<SupplierPurchase> get purchases {
    final result = [..._purchases];
    result.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    return List.unmodifiable(result);
  }

  List<SupplierProfile> get suppliers {
    final result = [..._suppliers];

    result.sort((a, b) {
      if (a.active != b.active) return a.active ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

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
    return _suppliers.where((supplier) => supplier.active).length;
  }

  SupplierProfile? supplierByName(String name) {
    final normalized = _normalize(name);

    for (final supplier in _suppliers) {
      if (_normalize(supplier.name) == normalized) return supplier;
    }

    return null;
  }

  List<SupplierPurchase> purchasesForSupplier(String supplierName) {
    final normalized = _normalize(supplierName);

    return purchases.where((purchase) {
      return _normalize(purchase.supplierName) == normalized;
    }).toList();
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

  void addSupplier(SupplierProfile supplier) {
    final existingIndex = _suppliers.indexWhere(
      (item) => _normalize(item.name) == _normalize(supplier.name),
    );

    if (existingIndex == -1) {
      _suppliers.insert(0, supplier);
    } else {
      _suppliers[existingIndex] = supplier.copyWith(
        updatedAt: DateTime.now(),
      );
    }

    _saveAllAndNotify();
  }

  void updateSupplier(SupplierProfile supplier) {
    final index = _suppliers.indexWhere((item) => item.id == supplier.id);

    if (index == -1) {
      addSupplier(supplier);
      return;
    }

    _suppliers[index] = supplier.copyWith(updatedAt: DateTime.now());

    _saveAllAndNotify();
  }

  void toggleSupplierActive(String supplierId) {
    final index = _suppliers.indexWhere((item) => item.id == supplierId);

    if (index == -1) return;

    final supplier = _suppliers[index];

    _suppliers[index] = supplier.copyWith(
      active: !supplier.active,
      updatedAt: DateTime.now(),
    );

    _saveAllAndNotify();
  }

  void deleteSupplier(String supplierId) {
    _suppliers.removeWhere((supplier) => supplier.id == supplierId);

    _saveAllAndNotify();
  }

  void addPurchase(SupplierPurchase purchase) {
    _ensureSupplierFromPurchase(purchase);
    _purchases.insert(0, purchase);

    _saveAllAndNotify();
  }

  void updatePurchase(SupplierPurchase purchase) {
    final index = _purchases.indexWhere((item) => item.id == purchase.id);

    if (index == -1) return;

    _ensureSupplierFromPurchase(purchase);
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
    _suppliers.clear();

    await _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final rawPurchases = prefs.getString(purchasesStorageKey);
    final rawSuppliers = prefs.getString(suppliersStorageKey);

    if (rawPurchases != null && rawPurchases.isNotEmpty) {
      final decoded = jsonDecode(rawPurchases);

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

    if (rawSuppliers != null && rawSuppliers.isNotEmpty) {
      final decoded = jsonDecode(rawSuppliers);

      if (decoded is List) {
        _suppliers
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map(
                  (item) => SupplierProfile.fromMap(
                    item.map(
                      (key, value) => MapEntry(key.toString(), value),
                    ),
                  ),
                ),
          );
      }
    }

    final inferred = _inferSuppliersFromPurchases();

    if (inferred) {
      await _saveData();
    }

    _isLoading = false;
    notifyListeners();
  }

  bool _inferSuppliersFromPurchases() {
    var changed = false;

    for (final purchase in _purchases) {
      final name = purchase.supplierName.trim();

      if (name.isEmpty) continue;

      final exists = _suppliers.any(
        (supplier) => _normalize(supplier.name) == _normalize(name),
      );

      if (exists) continue;

      _suppliers.add(
        SupplierProfile(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          phone: '',
          responsible: '',
          city: '',
          address: '',
          notes: '',
          active: true,
          createdAt: purchase.createdAt,
          updatedAt: purchase.updatedAt,
        ),
      );

      changed = true;
    }

    return changed;
  }

  void _ensureSupplierFromPurchase(SupplierPurchase purchase) {
    final name = purchase.supplierName.trim();

    if (name.isEmpty) return;

    final exists = _suppliers.any(
      (supplier) => _normalize(supplier.name) == _normalize(name),
    );

    if (exists) return;

    final now = DateTime.now();

    _suppliers.add(
      SupplierProfile(
        id: now.microsecondsSinceEpoch.toString(),
        name: name,
        phone: '',
        responsible: '',
        city: '',
        address: '',
        notes: '',
        active: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _saveAllAndNotify() async {
    await _saveData();

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      purchasesStorageKey,
      jsonEncode(_purchases.map((purchase) => purchase.toMap()).toList()),
    );

    await prefs.setString(
      suppliersStorageKey,
      jsonEncode(_suppliers.map((supplier) => supplier.toMap()).toList()),
    );
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
