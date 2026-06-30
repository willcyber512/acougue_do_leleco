import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_shortcut.dart';

class ShortcutsProvider extends ChangeNotifier {
  ShortcutsProvider() {
    _shortcuts.addAll(DashboardShortcutDefaults.items());
    _loadData();
  }

  static const String storageKey = 'leleco_dashboard_shortcuts_v1';

  final List<DashboardShortcut> _shortcuts = [];

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  List<DashboardShortcut> get shortcuts {
    return List.unmodifiable(_shortcuts);
  }

  List<DashboardShortcut> get activeShortcuts {
    return List.unmodifiable(
      _shortcuts.where((shortcut) => shortcut.enabled),
    );
  }

  int get activeCount {
    return _shortcuts.where((shortcut) => shortcut.enabled).length;
  }

  void toggleShortcut(DashboardShortcutType type) {
    final index = _shortcuts.indexWhere((shortcut) => shortcut.type == type);

    if (index == -1) return;

    final current = _shortcuts[index];

    _shortcuts[index] = current.copyWith(enabled: !current.enabled);

    _saveAndNotify();
  }

  void moveUp(DashboardShortcutType type) {
    final index = _shortcuts.indexWhere((shortcut) => shortcut.type == type);

    if (index <= 0) return;

    final item = _shortcuts.removeAt(index);
    _shortcuts.insert(index - 1, item);

    _saveAndNotify();
  }

  void moveDown(DashboardShortcutType type) {
    final index = _shortcuts.indexWhere((shortcut) => shortcut.type == type);

    if (index == -1 || index >= _shortcuts.length - 1) return;

    final item = _shortcuts.removeAt(index);
    _shortcuts.insert(index + 1, item);

    _saveAndNotify();
  }

  void resetDefaults() {
    _shortcuts
      ..clear()
      ..addAll(DashboardShortcutDefaults.items());

    _saveAndNotify();
  }

  Future<void> reloadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    _shortcuts
      ..clear()
      ..addAll(DashboardShortcutDefaults.items());

    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);

      if (saved != null && saved.trim().isNotEmpty) {
        final decoded = jsonDecode(saved);

        if (decoded is List) {
          final loaded = decoded.whereType<Map>().map((item) {
            return DashboardShortcut.fromMap(
              Map<String, dynamic>.from(item),
            );
          }).toList();

          _shortcuts
            ..clear()
            ..addAll(_normalizeShortcuts(loaded));
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<DashboardShortcut> _normalizeShortcuts(
    List<DashboardShortcut> loaded,
  ) {
    final result = <DashboardShortcut>[];
    final usedTypes = <DashboardShortcutType>{};

    for (final shortcut in loaded) {
      if (usedTypes.contains(shortcut.type)) continue;

      result.add(shortcut);
      usedTypes.add(shortcut.type);
    }

    for (final shortcut in DashboardShortcutDefaults.items()) {
      if (usedTypes.contains(shortcut.type)) continue;

      result.add(shortcut);
      usedTypes.add(shortcut.type);
    }

    return result;
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _shortcuts.map((shortcut) => shortcut.toMap()).toList(),
    );

    await prefs.setString(storageKey, encoded);
  }

  void _saveAndNotify() {
    notifyListeners();
    _saveData();
  }
}
