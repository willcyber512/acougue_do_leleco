import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cash_movement.dart';
import '../models/payment_method.dart';

class CashMovementProvider extends ChangeNotifier {
  CashMovementProvider() {
    _loadData();
  }

  static const String storageKey = 'leleco_cash_movements_v1';

  final List<CashMovement> _movements = [];

  List<CashMovement> get movements {
    final result = [..._movements];
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  List<CashMovement> get todayMovements {
    final now = DateTime.now();

    return movements.where((movement) {
      final date = movement.createdAt;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  double get todayInputs => todayMovements
      .where((movement) => movement.type == CashMovementType.input)
      .fold(0.0, (total, movement) => total + movement.amount);

  double get todayOutputs => todayMovements
      .where((movement) => movement.type == CashMovementType.output)
      .fold(0.0, (total, movement) => total + movement.amount);

  double get todayBalance => todayInputs - todayOutputs;

  double totalByTypeForPeriod({
    required CashMovementType type,
    required DateTime start,
    required DateTime end,
  }) {
    return movementsForPeriod(start: start, end: end)
        .where((movement) => movement.type == type)
        .fold(0.0, (total, movement) => total + movement.amount);
  }

  List<CashMovement> movementsForPeriod({
    required DateTime start,
    required DateTime end,
  }) {
    return movements.where((movement) {
      final date = movement.createdAt;
      return !date.isBefore(start) && date.isBefore(end);
    }).toList();
  }

  Map<CashMovementCategory, double> outputTotalsByCategoryForPeriod({
    required DateTime start,
    required DateTime end,
  }) {
    final result = <CashMovementCategory, double>{};

    for (final movement in movementsForPeriod(start: start, end: end)) {
      if (movement.type != CashMovementType.output) continue;
      result[movement.category] =
          (result[movement.category] ?? 0) + movement.amount;
    }

    return result;
  }

  void addMovement({
    required CashMovementType type,
    required CashMovementCategory category,
    required double amount,
    required PaymentMethod paymentMethod,
    required String reason,
    String description = '',
    String? referenceId,
    String? personName,
    DateTime? createdAt,
  }) {
    final cleanAmount = amount.abs();

    if (cleanAmount <= 0) return;

    final movement = CashMovement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      category: category,
      amount: cleanAmount,
      paymentMethod: paymentMethod,
      reason: reason.trim(),
      description: description.trim(),
      createdAt: createdAt ?? DateTime.now(),
      referenceId: referenceId,
      personName: personName,
    );

    _movements.insert(0, movement);
    _saveData();
    _safeNotifySoon();
  }

  void deleteMovement(String movementId) {
    _movements.removeWhere((movement) => movement.id == movementId);
    _saveData();
    _safeNotifySoon();
  }

  Future<void> reloadFromStorage() async {
    await _loadData();
    notifyListeners();
  }

  void _safeNotifySoon() {
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);

    _movements.clear();

    if (raw == null || raw.trim().isEmpty) {
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      _movements.addAll(
        decoded.whereType<Map<String, dynamic>>().map(CashMovement.fromMap),
      );
    } catch (_) {
      // Mantém vazio se algum dado salvo antigo vier quebrado.
    }

    notifyListeners();
  }

  Future<void> _saveAllAndNotify() async {
    await _saveData();
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      storageKey,
      jsonEncode(_movements.map((movement) => movement.toMap()).toList()),
    );
  }
}
