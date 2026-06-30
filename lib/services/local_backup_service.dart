import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalBackupService {
  LocalBackupService._();

  static const String backupAppName = 'acougue_do_leleco';
  static const int backupVersion = 1;

  static const List<String> storageKeys = [
    'leleco_inventory_products_v1',
    'leleco_inventory_events_v1',
    'leleco_inventory_losses_v1',
    'leleco_sales_records_v1',
    'leleco_customers_v1',
    'leleco_credit_entries_v1',
    'leleco_internal_notes_v1',
    'leleco_cash_closures_v1',
    'leleco_dashboard_shortcuts_v1',
    'leleco_ramuza_barcode_settings_v1',
  ];

  static Future<String> exportBackup() async {
    final prefs = await SharedPreferences.getInstance();

    final storage = <String, dynamic>{};

    for (final key in storageKeys) {
      storage[key] = prefs.getString(key) ?? '[]';
    }

    final backup = {
      'app': backupAppName,
      'version': backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'storage': storage,
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  static Future<void> importBackup(String backupText) async {
    final decoded = jsonDecode(backupText);

    if (decoded is! Map) {
      throw Exception('Backup inválido.');
    }

    final app = decoded['app']?.toString();

    if (app != backupAppName) {
      throw Exception('Esse arquivo não parece ser um backup do sistema.');
    }

    final storage = decoded['storage'];

    if (storage is! Map) {
      throw Exception('Backup sem dados para restaurar.');
    }

    final prefs = await SharedPreferences.getInstance();

    for (final key in storageKeys) {
      final value = storage[key];

      if (value == null) {
        continue;
      }

      if (value is String) {
        await prefs.setString(key, value);
      } else {
        await prefs.setString(key, jsonEncode(value));
      }
    }
  }

  static DateTime? readBackupDate(String backupText) {
    try {
      final decoded = jsonDecode(backupText);

      if (decoded is! Map) return null;

      return DateTime.tryParse(decoded['createdAt']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }
}
