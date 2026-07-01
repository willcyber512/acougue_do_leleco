import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cash_closure.dart';

class CashClosureProvider extends ChangeNotifier {
  CashClosureProvider() {
    _loadData();
  }

  static const String _storageKey = 'leleco_cash_closures_v1';

  final List<CashClosure> _closures = [];

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  List<CashClosure> get closures {
    final result = [..._closures];

    result.sort((a, b) => b.dayKey.compareTo(a.dayKey));

    return List.unmodifiable(result);
  }

  CashClosure? closureForDay(DateTime date) {
    final key = cashClosureDayKey(date);

    try {
      return _closures.firstWhere((closure) => closure.dayKey == key);
    } catch (_) {
      return null;
    }
  }

  void saveClosure(CashClosure closure) {
    final index = _closures.indexWhere((item) => item.id == closure.id);

    if (index == -1) {
      final sameDayIndex = _closures.indexWhere(
        (item) => item.dayKey == closure.dayKey,
      );

      if (sameDayIndex == -1) {
        _closures.insert(0, closure);
      } else {
        _closures[sameDayIndex] = closure;
      }
    } else {
      _closures[index] = closure;
    }

    _saveAllAndNotify();
  }

  void deleteClosure(String closureId) {
    _closures.removeWhere((closure) => closure.id == closureId);

    _saveAllAndNotify();
  }

  Future<void> reloadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    _closures.clear();

    await _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        _closures
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map((item) => CashClosure.fromMap(
                      item.map(
                        (key, value) => MapEntry(key.toString(), value),
                      ),
                    )),
          );
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAllAndNotify() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _closures.map((closure) => closure.toMap()).toList(),
    );

    await prefs.setString(_storageKey, encoded);

    notifyListeners();
  }
}
