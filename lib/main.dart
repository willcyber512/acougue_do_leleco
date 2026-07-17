import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/cash_closure_provider.dart';
import 'providers/cash_movement_provider.dart';
import 'providers/customers_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/ramuza_barcode_log_provider.dart';
import 'providers/ramuza_settings_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/shortcuts_provider.dart';
import 'providers/suppliers_provider.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => CustomersProvider()),
        ChangeNotifierProvider(create: (_) => SuppliersProvider()),
        ChangeNotifierProvider(create: (_) => CashClosureProvider()),
        ChangeNotifierProvider(create: (_) => CashMovementProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => ShortcutsProvider()),
        ChangeNotifierProvider(create: (_) => RamuzaSettingsProvider()),
        ChangeNotifierProvider(create: (_) => RamuzaBarcodeLogProvider()),
      ],
      child: const LelecoApp(),
    ),
  );
}
