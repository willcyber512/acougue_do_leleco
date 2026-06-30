import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/dashboard_shortcut.dart';
import '../providers/shortcuts_provider.dart';

Future<void> showShortcutsConfigDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return const ShortcutsConfigDialog();
    },
  );
}

class ShortcutsConfigDialog extends StatelessWidget {
  const ShortcutsConfigDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShortcutsProvider>(
      builder: (context, provider, _) {
        return AlertDialog(
          title: const Text('Configurar atalhos da tela Hoje'),
          content: SizedBox(
            width: 760,
            height: 560,
            child: Column(
              children: [
                _InfoCard(activeCount: provider.activeCount),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: provider.shortcuts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final shortcut = provider.shortcuts[index];

                      return _ShortcutConfigTile(
                        shortcut: shortcut,
                        index: index,
                        isFirst: index == 0,
                        isLast: index == provider.shortcuts.length - 1,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: provider.resetDefaults,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Restaurar padrão'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.wine900,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Escolha quais atalhos aparecem na tela Hoje e organize a ordem usando as setas.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '$activeCount ativo(s)',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutConfigTile extends StatelessWidget {
  const _ShortcutConfigTile({
    required this.shortcut,
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  final DashboardShortcut shortcut;
  final int index;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ShortcutsProvider>();

    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: shortcut.enabled ? AppColors.wine900 : AppColors.brown900,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _shortcutIcon(shortcut.type),
            color: AppColors.beige100,
          ),
        ),
        title: Text(
          shortcut.type.label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(shortcut.type.subtitle),
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Subir',
              onPressed: isFirst ? null : () => provider.moveUp(shortcut.type),
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            IconButton(
              tooltip: 'Descer',
              onPressed:
                  isLast ? null : () => provider.moveDown(shortcut.type),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
            Switch(
              value: shortcut.enabled,
              onChanged: (_) => provider.toggleShortcut(shortcut.type),
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
