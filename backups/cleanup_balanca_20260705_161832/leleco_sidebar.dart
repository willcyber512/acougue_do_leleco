import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'leleco_logo.dart';

class LelecoSidebar extends StatelessWidget {
  const LelecoSidebar({
    super.key,
    required this.selectedIndex,
    this.onItemSelected,
    this.onSelect,
    this.labels,
    this.icons,
  });

  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;
  final ValueChanged<int>? onSelect;
  final List<String>? labels;
  final List<IconData>? icons;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 850;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final itemLabels = labels ?? _defaultLabels;
    final itemIcons = icons ?? _defaultIcons;
    final selectHandler = onItemSelected ?? onSelect;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: compact ? 78 : 245,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSidebar : AppColors.lightSidebar,
        border: Border(
          right: BorderSide(
            color: isDark
                ? AppColors.beige100.withOpacity(0.08)
                : AppColors.wine900.withOpacity(0.06),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Container(
              padding: EdgeInsets.all(compact ? 4 : 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.beige100.withOpacity(0.04)
                    : AppColors.wine900.withOpacity(0.03),
                borderRadius: BorderRadius.circular(28),
              ),
              child: LelecoLogo(size: compact ? 54 : 92),
            ),
            if (!compact) ...[
              const SizedBox(height: 12),
              Text(
                'Açougue do\nLeleco',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                  color: isDark ? AppColors.beige100 : null,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 20,
                  vertical: 8,
                ),
                itemCount: itemLabels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final label = itemLabels[index];
                  final icon = index < itemIcons.length
                      ? itemIcons[index]
                      : Icons.circle_rounded;

                  return _SidebarItemTile(
                    compact: compact,
                    selected: selectedIndex == index,
                    icon: icon,
                    label: label,
                    onTap: () => selectHandler?.call(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItemTile extends StatelessWidget {
  const _SidebarItemTile({
    required this.compact,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool compact;
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final foreground = selected
        ? AppColors.beige100
        : isDark
        ? AppColors.beige100.withOpacity(0.72)
        : AppColors.wine700;

    final background = selected
        ? AppColors.wine700
        : isDark
        ? AppColors.beige100.withOpacity(0.00)
        : Colors.transparent;

    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: selected
                  ? Border.all(color: AppColors.beige100.withOpacity(0.08))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(icon, color: foreground, size: 23),
                if (!compact) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const List<String> _defaultLabels = [
  'Hoje',
  'Venda',
  'Estoque',
  'Fiado',
  'Caixa',
  'Relatórios',
  'Fornecedores',
  'Alertas',
  'Hardware',
  'Ajustes',
];

const List<IconData> _defaultIcons = [
  Icons.dashboard_rounded,
  Icons.point_of_sale_rounded,
  Icons.inventory_2_rounded,
  Icons.group_rounded,
  Icons.payments_rounded,
  Icons.bar_chart_rounded,
  Icons.local_shipping_rounded,
  Icons.notifications_rounded,
  Icons.devices_other_rounded,
  Icons.settings_rounded,
];
