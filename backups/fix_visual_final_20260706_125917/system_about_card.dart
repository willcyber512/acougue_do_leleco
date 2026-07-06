import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import 'leleco_logo.dart';

class SystemAboutCard extends StatelessWidget {
  const SystemAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LelecoLogo(size: 96),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Versão ${AppConstants.appVersion}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sistema interno para gestão do açougue, com controle de vendas, estoque, caixa, fiado, perdas, alertas, relatórios e backup local.',
                  ),
                  const SizedBox(height: 16),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ModuleChip(label: 'PDV'),
                      _ModuleChip(label: 'Estoque'),
                      _ModuleChip(label: 'Fiado'),
                      _ModuleChip(label: 'Caixa'),
                      _ModuleChip(label: 'Relatórios'),
                      _ModuleChip(label: 'Alertas'),
                      _ModuleChip(label: 'Anotações'),
                      _ModuleChip(label: 'Backup'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: () => _openAboutDialog(context),
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('Info'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.wine900.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

Future<void> _openAboutDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Informações do aplicativo'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LelecoLogo(size: 110),
              const SizedBox(height: 14),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Versão ${AppConstants.appVersion}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              const Text(
                'Aplicativo criado para uso interno do Açougue do Leleco. O sistema ajuda no controle de vendas, estoque, caixa, fiado, relatórios, fornecedores, backup e leitura de etiquetas por leitor USB.'
                ''
                '',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              const _InfoLine(label: 'Uso', value: 'Interno'),
              const _InfoLine(label: 'Dados', value: 'Dados locais do sistema'),
              const _InfoLine(
                label: 'Backup',
                value: 'Backup e restauração local',
              ),
              const _InfoLine(
                label: 'Plataforma',
                value: 'Windows e Linux',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
