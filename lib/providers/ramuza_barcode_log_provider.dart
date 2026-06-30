import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ramuza_barcode_event.dart';

class RamuzaBarcodeLogProvider extends ChangeNotifier {
  RamuzaBarcodeLogProvider() {
    _loadData();
  }

  static const String storageKey = 'leleco_ramuza_barcode_events_v1';

  final List<RamuzaBarcodeEvent> _events = [];

  bool _isLoading = true;

  bool get isLoading => _isLoading;

  List<RamuzaBarcodeEvent> get events {
    final result = [..._events];

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return List.unmodifiable(result);
  }

  int get totalEvents => _events.length;

  int get successCount {
    return _events.where((event) {
      return event.status == RamuzaBarcodeStatus.success;
    }).length;
  }

  int get errorCount {
    return _events.where((event) {
      return event.status != RamuzaBarcodeStatus.success;
    }).length;
  }

  void addEvent(RamuzaBarcodeEvent event) {
    _events.insert(0, event);

    if (_events.length > 300) {
      _events.removeRange(300, _events.length);
    }

    _saveAndNotify();
  }

  void clearEvents() {
    _events.clear();
    _saveAndNotify();
  }

  Future<void> reloadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    _events.clear();

    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);

      if (saved != null && saved.trim().isNotEmpty) {
        final decoded = jsonDecode(saved);

        if (decoded is List) {
          _events
            ..clear()
            ..addAll(
              decoded.whereType<Map>().map((item) {
                return RamuzaBarcodeEvent.fromMap(
                  Map<String, dynamic>.from(item),
                );
              }),
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
      jsonEncode(_events.map((event) => event.toMap()).toList()),
    );
  }

  void _saveAndNotify() {
    notifyListeners();
    _saveData();
  }
}
