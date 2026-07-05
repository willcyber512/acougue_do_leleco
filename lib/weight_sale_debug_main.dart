import 'package:flutter/material.dart';

import 'screens/sales/quick_weight_sale_screen.dart';

void main() {
  runApp(const WeightSaleDebugApp());
}

class WeightSaleDebugApp extends StatelessWidget {
  const WeightSaleDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Venda por Peso',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red,
      ),
      home: const QuickWeightSaleScreen(),
    );
  }
}
