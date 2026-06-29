import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'leleco_logo.dart';

class LelecoSidebar extends StatelessWidget {
  const LelecoSidebar({
    super.key,
    required this.labels,
    required this.icons,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> labels;
  final List<IconData> icons;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 245,
      color: isDark ? AppColors.darkSidebar : AppColors.lightSidebar,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        children: [
          const LelecoLogo(),
          const SizedBox(height: 14),
          Text(
            'Açougue do\nLeleco',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: labels.length,
              itemBuilder: (context, index) {
                return _SidebarItem(
                  label: labels[index],
                  icon: icons[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.beige100
        : AppColors.brown900;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.wine900 : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.beige100 : AppColors.wine700,
                size: selected ? 25 : 23,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: selected ? AppColors.beige100 : defaultColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
