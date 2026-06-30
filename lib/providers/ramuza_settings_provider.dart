import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ramuza_barcode_settings.dart';

class RamuzaSettingsProvider extends ChangeNotifier {
  RamuzaSettingsProvider() {
    _loadData();
  }

  static const String storageKey = 'leleco_ramuza_barcode_settings_v1';

  RamuzaBarcodeSettings _settings = RamuzaBarcodeSettings.defaults();

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  RamuzaBarcodeSettings get settings => _settings;

  void updateSettings(RamuzaBarcodeSettings settings) {
    _settings = settings;
    _saveAndNotify();
  }

  void resetDefaults() {
    _settings = RamuzaBarcodeSettings.defaults();
    _saveAndNotify();
  }

  Future<void> reloadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);

      if (saved != null && saved.trim().isNotEmpty) {
        final decoded = jsonDecode(saved);

        if (decoded is Map) {
          _settings = RamuzaBarcodeSettings.fromMap(
            Map<String, dynamic>.from(decoded),
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

    await prefs.setString(
      storageKey,
      jsonEncode(_settings.toMap()),
    );
  }

  void _saveAndNotify() {
    notifyListeners();
    _saveData();
  }
}
