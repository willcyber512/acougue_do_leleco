import 'package:flutter/material.dart';

import '../../widgets/leleco_action_card.dart';
import '../../widgets/leleco_metric_card.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        Row(
          children: [
            Expanded(
              child: LelecoMetricCard(
                icon: Icons.payments_rounded,
                title: 'Faturamento hoje',
                value: 'R\$ 1.250,00',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: LelecoMetricCard(
                icon: Icons.people_alt_rounded,
                title: 'Fiado aberto',
                value: 'R\$ 350,00',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: LelecoMetricCard(
                icon: Icons.receipt_long_rounded,
                title: 'Vendas realizadas',
                value: '24',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: LelecoMetricCard(
                icon: Icons.warning_rounded,
                title: 'Alertas',
                value: '5',
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            LelecoActionCard(
              icon: Icons.point_of_sale_rounded,
              title: 'Nova venda',
              subtitle: 'Abrir tela de caixa',
            ),
            LelecoActionCard(
              icon: Icons.add_box_rounded,
              title: 'Repor estoque',
              subtitle: 'Entrada rápida de produto',
            ),
            LelecoActionCard(
              icon: Icons.person_search_rounded,
              title: 'Cobrar fiado',
              subtitle: 'Consultar clientes devendo',
            ),
            LelecoActionCard(
              icon: Icons.note_alt_rounded,
              title: 'Anotações',
              subtitle: 'Recados e lembretes',
            ),
          ],
        ),
      ],
    );
  }
}
