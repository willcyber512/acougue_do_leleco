import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/theme_provider.dart';

class LelecoTopBar extends StatelessWidget {
  const LelecoTopBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const Spacer(),
          SizedBox(
            width: 390,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar produto, cliente ou código...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: themeProvider.toggleTheme,
            tooltip: 'Alternar tema',
            icon: const Icon(Icons.dark_mode_rounded),
          ),
        ],
      ),
    );
  }
}
