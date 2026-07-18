import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/credit_entry.dart';
import '../models/customer.dart';
import '../models/payment_method.dart';
import '../models/sale.dart';

class CustomersProvider extends ChangeNotifier {
  CustomersProvider() {
    _loadData();
  }

  static const String _customersStorageKey = 'leleco_customers_v1';
  static const String _entriesStorageKey = 'leleco_credit_entries_v1';

  final List<Customer> _customers = [];
  final List<CreditEntry> _entries = [];

  bool _isLoading = true;
  String _searchTerm = '';

  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;

  List<Customer> get customers {
    final result = [..._customers];
    result.sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(result);
  }

  List<Customer> get filteredCustomers {
    final term = _searchTerm.trim().toLowerCase();

    final result = _customers.where((customer) {
      if (term.isEmpty) return true;

      return customer.name.toLowerCase().contains(term) ||
          (customer.phone ?? '').toLowerCase().contains(term);
    }).toList();

    result.sort((a, b) {
      final balanceA = balanceForCustomer(a.id);
      final balanceB = balanceForCustomer(b.id);

      if (balanceA != balanceB) {
        return balanceB.compareTo(balanceA);
      }

      return a.name.compareTo(b.name);
    });

    return List.unmodifiable(result);
  }

  List<CreditEntry> get entries {
    final result = [..._entries];
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  int get totalCustomers => _customers.length;

  int get customersWithDebt {
    return _customers.where((customer) {
      return balanceForCustomer(customer.id) > 0.009;
    }).length;
  }

  double get totalOpenCredit {
    return _customers.fold(
      0.0,
      (total, customer) => total + balanceForCustomer(customer.id),
    );
  }

  double get paymentsReceivedToday {
    final now = DateTime.now();

    return _entries
        .where((entry) {
          return entry.type == CreditEntryType.payment &&
              entry.createdAt.year == now.year &&
              entry.createdAt.month == now.month &&
              entry.createdAt.day == now.day;
        })
        .fold(0.0, (total, entry) => total + entry.amount);
  }

  Future<void> reloadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    _customers.clear();
    _entries.clear();

    await _loadData();
  }

  void setSearchTerm(String value) {
    _searchTerm = value;
    notifyListeners();
  }

  Customer? findCustomerById(String customerId) {
    try {
      return _customers.firstWhere((customer) => customer.id == customerId);
    } catch (_) {
      return null;
    }
  }

  double balanceForCustomer(String customerId) {
    return _entries.where((entry) => entry.customerId == customerId).fold(0.0, (
      total,
      entry,
    ) {
      if (entry.type == CreditEntryType.purchase) {
        return total + entry.amount;
      }

      return total - entry.amount;
    });
  }

  List<CreditEntry> entriesForCustomer(String customerId) {
    final result = _entries
        .where((entry) => entry.customerId == customerId)
        .toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  Customer addCustomer({required String name, String? phone, String? notes}) {
    final now = DateTime.now();

    final customer = Customer(
      id: now.microsecondsSinceEpoch.toString(),
      name: name.trim(),
      phone: _emptyToNull(phone),
      notes: _emptyToNull(notes),
      createdAt: now,
      updatedAt: now,
    );

    _customers.insert(0, customer);
    _saveAllAndNotify();

    return customer;
  }

  void updateCustomer(Customer customer) {
    final index = _customers.indexWhere((item) => item.id == customer.id);

    if (index == -1) return;

    _customers[index] = customer.copyWith(updatedAt: DateTime.now());
    _saveAllAndNotify();
  }

  void registerPurchase(SaleRecord sale, Customer customer) {
    if (sale.paymentMethod != PaymentMethod.fiado) return;
    if (sale.total <= 0) return;

    final entry = CreditEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      customerId: customer.id,
      customerName: customer.name,
      type: CreditEntryType.purchase,
      amount: sale.total,
      description: 'Compra fiado da venda #${sale.shortId}',
      createdAt: sale.createdAt,
      saleId: sale.id,
    );

    _entries.insert(0, entry);
    _saveAllAndNotify();
  }

  void registerPayment({
    required String customerId,
    required double amount,
    PaymentMethod paymentMethod = PaymentMethod.dinheiro,
    String? description,
  }) {
    if (amount <= 0) return;

    final customer = findCustomerById(customerId);

    if (customer == null) return;

    final balance = balanceForCustomer(customerId);
    final safeAmount = amount > balance ? balance : amount;

    if (safeAmount <= 0) return;

    final now = DateTime.now();

    final entry = CreditEntry(
      id: now.microsecondsSinceEpoch.toString(),
      customerId: customer.id,
      customerName: customer.name,
      type: CreditEntryType.payment,
      amount: safeAmount,
      description: _emptyToNull(description) ?? 'Pagamento recebido',
      createdAt: now,
      paymentMethod: paymentMethod,
    );

    _entries.insert(0, entry);
    _saveAllAndNotify();
  }

  void deleteEntriesBySaleId(String saleId) {
    final cleanSaleId = saleId.trim();

    if (cleanSaleId.isEmpty) return;

    final before = _entries.length;

    _entries.removeWhere((entry) => entry.saleId == cleanSaleId);

    if (_entries.length == before) return;

    _saveAllAndNotify();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await _loadCustomers(prefs);
      await _loadEntries(prefs);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCustomers(SharedPreferences prefs) async {
    final saved = prefs.getString(_customersStorageKey);

    if (saved == null || saved.trim().isEmpty) return;

    final decoded = jsonDecode(saved);

    if (decoded is List) {
      _customers
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
            (item) => Customer.fromMap(Map<String, dynamic>.from(item)),
          ),
        );
    }
  }

  Future<void> _loadEntries(SharedPreferences prefs) async {
    final saved = prefs.getString(_entriesStorageKey);

    if (saved == null || saved.trim().isEmpty) return;

    final decoded = jsonDecode(saved);

    if (decoded is List) {
      _entries
        ..clear()
        ..addAll(
          decoded.whereType<Map>().map(
            (item) => CreditEntry.fromMap(Map<String, dynamic>.from(item)),
          ),
        );
    }
  }

  Future<void> _saveCustomers() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _customers.map((customer) => customer.toMap()).toList(),
    );

    await prefs.setString(_customersStorageKey, encoded);
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(_entries.map((entry) => entry.toMap()).toList());

    await prefs.setString(_entriesStorageKey, encoded);
  }

  void _saveAllAndNotify() {
    notifyListeners();
    _saveCustomers();
    _saveEntries();
  }

  String? _emptyToNull(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) return null;

    return text;
  }
}
