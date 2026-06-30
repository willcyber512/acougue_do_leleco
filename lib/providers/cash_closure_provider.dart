import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cash_closure.dart';

class CashClosureProvider extends ChangeNotifier {
  CashClosureProvider() {
    _loadData();
  }

  static const String storageKey = 'leleco_cash_closures_v1';

  final List<CashClosure> _closures = [];

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  List<CashClosure> get closures {
    final result = [..._closures];

    result.sort((a, b) {
      return b.dayKey.compareTo(a.dayKey);
    });

    return List.unmodifiable(result);
  }

  CashClosure? closureForDay(DateTime day) {
    final key = cashClosureDayKey(day);

    try {
      return _closures.firstWhere((closure) => closure.dayKey == key);
    } catch (_) {
      return null;
    }
  }

  void saveClosure(CashClosure closure) {
    final index = _closures.indexWhere((item) => item.dayKey == closure.dayKey);

    if (index == -1) {
      _closures.add(closure);
    } else {
      _closures[index] = closure;
    }

    _saveAndNotify();
  }

  void deleteClosure(String id) {
    _closures.removeWhere((closure) => closure.id == id);
    _saveAndNotify();
  }

  Future<void> reloadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    _closures.clear();

    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);

      if (saved != null && saved.trim().isNotEmpty) {
        final decoded = jsonDecode(saved);

        if (decoded is List) {
          _closures
            ..clear()
            ..addAll(
              decoded.whereType<Map>().map(
                    (item) => CashClosure.fromMap(
                      Map<String, dynamic>.from(item),
                    ),
                  ),
            );
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _closures.map((closure) => closure.toMap()).toList(),
    );

    await prefs.setString(storageKey, encoded);
  }

  void _saveAndNotify() {
    notifyListeners();
    _saveData();
  }
}
