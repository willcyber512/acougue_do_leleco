import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/theme_provider.dart';
import 'leleco_logo.dart';

class LelecoTopBar extends StatelessWidget {
  const LelecoTopBar({super.key, required this.title, this.onNavigate});

  final String title;
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFFBF6F0),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.beige100.withOpacity(0.08)
                : AppColors.wine900.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          LelecoLogo(size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.beige100 : AppColors.wine900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _TopActionButton(
            tooltip: 'Venda',
            icon: Icons.point_of_sale_rounded,
            onPressed: () => onNavigate?.call(1),
          ),
          const SizedBox(width: 8),
          _TopActionButton(
            tooltip: 'Leitor USB',
            icon: Icons.qr_code_scanner_rounded,
            onPressed: () => onNavigate?.call(8),
          ),
          const SizedBox(width: 8),
          _TopActionButton(
            tooltip: 'Ajustes',
            icon: Icons.settings_rounded,
            onPressed: () => onNavigate?.call(9),
          ),
          const SizedBox(width: 8),
          _TopActionButton(
            tooltip: isDark ? 'Modo claro' : 'Modo escuro',
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: isDark
            ? AppColors.beige100.withOpacity(0.10)
            : AppColors.wine700.withOpacity(0.10),
        foregroundColor: isDark ? AppColors.beige100 : AppColors.wine700,
      ),
    );
  }
}
