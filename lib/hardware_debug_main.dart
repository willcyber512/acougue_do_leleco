import 'package:flutter/material.dart';

import 'screens/settings/hardware_center_screen.dart';

void main() {
  runApp(const HardwareDebugApp());
}

class HardwareDebugApp extends StatelessWidget {
  const HardwareDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Central de Hardware',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red,
      ),
      home: const HardwareCenterScreen(),
    );
  }
}
