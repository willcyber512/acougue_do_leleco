import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/leleco_sidebar.dart';
import '../../widgets/leleco_top_bar.dart';
import '../home/home_dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../cash/cash_screen.dart';
import '../sales/sales_screen.dart';

class DesktopShellScreen extends StatefulWidget {
  const DesktopShellScreen({super.key});

  @override
  State<DesktopShellScreen> createState() => _DesktopShellScreenState();
}

class _DesktopShellScreenState extends State<DesktopShellScreen> {
  int selectedIndex = 0;

  static const List<String> labels = [
    'Hoje',
    'Venda',
    'Estoque',
    'Fiado',
    'Caixa',
    'Relatórios',
    'Alertas',
    'Ajustes',
  ];

  static const List<IconData> icons = [
    Icons.dashboard_rounded,
    Icons.point_of_sale_rounded,
    Icons.inventory_2_rounded,
    Icons.people_alt_rounded,
    Icons.payments_rounded,
    Icons.bar_chart_rounded,
    Icons.notifications_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          LelecoSidebar(
            labels: labels,
            icons: icons,
            selectedIndex: selectedIndex,
            onSelect: (index) => setState(() => selectedIndex = index),
          ),
          Expanded(
            child: Container(
              color: isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              child: Column(
                children: [
                  LelecoTopBar(title: labels[selectedIndex]),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildPage(selectedIndex),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    if (index == 0) {
      return const HomeDashboardScreen();
    }

    if (index == 1) {
      return const SalesScreen();
    }

    if (index == 2) {
      return const InventoryScreen();
    }

    if (index == 4) {
      return const CashScreen();
    }

    return _ModulePage(title: labels[index], icon: icons[index]);
  }
}

class _ModulePage extends StatelessWidget {
  const _ModulePage({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 58, color: AppColors.wine700),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Este módulo será construído na próxima etapa do sistema.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
