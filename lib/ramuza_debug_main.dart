import 'package:flutter/material.dart';

import 'screens/settings/scale_integration_screen.dart';

void main() {
  runApp(const RamuzaDebugApp());
}

class RamuzaDebugApp extends StatelessWidget {
  const RamuzaDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Teste Ramuza',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red,
      ),
      home: const ScaleIntegrationScreen(),
    );
  }
}
