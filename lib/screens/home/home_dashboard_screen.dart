import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/customers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_provider.dart';
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
    return Consumer3<InventoryProvider, SalesProvider, CustomersProvider>(
      builder: (context, inventory, sales, customers, _) {
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
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                LelecoActionCard(
                  icon: Icons.point_of_sale_rounded,
                  title: 'Nova venda',
                  subtitle: 'Abrir tela de caixa',
                  onTap: () => onNavigate(1),
                ),
                LelecoActionCard(
                  icon: Icons.add_box_rounded,
                  title: 'Repor estoque',
                  subtitle: 'Entrada rápida de produto',
                  onTap: () => onNavigate(2),
                ),
                LelecoActionCard(
                  icon: Icons.person_search_rounded,
                  title: 'Cobrar fiado',
                  subtitle: 'Consultar clientes devendo',
                  onTap: () => onNavigate(3),
                ),
                LelecoActionCard(
                  icon: Icons.note_alt_rounded,
                  title: 'Anotações',
                  subtitle: 'Recados e lembretes',
                  onTap: () => onNavigate(6),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}
