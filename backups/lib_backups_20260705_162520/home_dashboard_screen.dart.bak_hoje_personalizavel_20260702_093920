import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/dashboard_shortcut.dart';
import '../../providers/customers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/shortcuts_provider.dart';
import '../../widgets/leleco_action_card.dart';
import '../../widgets/leleco_metric_card.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onNavigate,
  });

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Consumer4<InventoryProvider, SalesProvider, CustomersProvider,
        ShortcutsProvider>(
      builder: (context, inventory, sales, customers, shortcuts, _) {
        final activeShortcuts = shortcuts.activeShortcuts;

        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: LelecoMetricCard(
                    icon: Icons.payments_rounded,
                    title: 'Faturamento hoje',
                    value: _formatMoney(sales.todayRevenue),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LelecoMetricCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Vendas hoje',
                    value: sales.todaySalesCount.toString(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LelecoMetricCard(
                    icon: Icons.money_off_rounded,
                    title: 'Fiado aberto',
                    value: _formatMoney(customers.totalOpenCredit),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LelecoMetricCard(
                    icon: Icons.warning_rounded,
                    title: 'Estoque baixo',
                    value: inventory.lowStockCount.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (activeShortcuts.isEmpty)
              const _NoShortcutsCard()
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: activeShortcuts.map((shortcut) {
                  return LelecoActionCard(
                    icon: _shortcutIcon(shortcut.type),
                    title: shortcut.type.label,
                    subtitle: shortcut.type.subtitle,
                    onTap: () => onNavigate(shortcut.type.moduleIndex),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }
}

class _NoShortcutsCard extends StatelessWidget {
  const _NoShortcutsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.wine900,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Nenhum atalho ativo. Use o botão Atalhos no topo para escolher quais aparecem aqui.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _shortcutIcon(DashboardShortcutType type) {
  switch (type) {
    case DashboardShortcutType.sale:
      return Icons.point_of_sale_rounded;
    case DashboardShortcutType.inventory:
      return Icons.add_box_rounded;
    case DashboardShortcutType.credit:
      return Icons.person_search_rounded;
    case DashboardShortcutType.notes:
      return Icons.note_alt_rounded;
    case DashboardShortcutType.cash:
      return Icons.payments_rounded;
    case DashboardShortcutType.reports:
      return Icons.bar_chart_rounded;
    case DashboardShortcutType.alerts:
      return Icons.notifications_rounded;
  }
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}
