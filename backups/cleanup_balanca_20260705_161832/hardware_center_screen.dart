import 'package:flutter/material.dart';

import '../sales/quick_weight_sale_screen.dart';
import 'scale_integration_screen.dart';

class HardwareCenterScreen extends StatelessWidget {
  const HardwareCenterScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Central de Hardware'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Leitor USB e etiquetas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Área para vender lendo a etiqueta gerada pela balança, como um SmartPOS do açougue.',
          ),
          const SizedBox(height: 16),
          _HardwareCard(
            icon: Icons.scale,
            title: 'Etiqueta da balança / leitor USB',
            subtitle: 'Testar leitura de código, simular etiqueta e validar se o sistema entende o código lido.',
            buttonText: 'Testar leitura',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ScaleIntegrationScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _HardwareCard(
            icon: Icons.point_of_sale,
            title: 'Venda por peso manual',
            subtitle: 'Permite vender digitando o peso visto na balança ou lendo a etiqueta com o leitor USB.',
            buttonText: 'Abrir venda',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuickWeightSaleScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const _InfoCard(),
        ],
      ),
    );
  }
}

class _HardwareCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const _HardwareCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.open_in_new),
                        label: Text(buttonText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fluxo seguro tipo SmartPOS',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'A balança gera a etiqueta. O leitor USB lê o código. O sistema identifica o produto, calcula/confere a venda e o funcionário confirma. Não é obrigatório controlar a balança por cabo ou rede.',
            ),
          ],
        ),
      ),
    );
  }
}
