import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/theme_provider.dart';
import 'cash_closure_dialog.dart';
import 'inventory_categories_dialog.dart';
import 'leleco_logo.dart';
import 'shortcuts_config_dialog.dart';
import 'universal_search_dialog.dart';

class LelecoTopBar extends StatelessWidget {
  const LelecoTopBar({
    super.key,
    required this.title,
    required this.onNavigate,
  });

  final String title;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const LelecoLogo(size: 46),
          const SizedBox(width: 14),
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
              readOnly: true,
              onTap: () {
                showUniversalSearchDialog(
                  context: context,
                  onNavigate: onNavigate,
                );
              },
              decoration: InputDecoration(
                hintText: 'Pesquisar produto, cliente ou código...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: const Icon(Icons.open_in_new_rounded),
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
          if (title == 'Hoje') ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                showShortcutsConfigDialog(context);
              },
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Atalhos'),
            ),
          ],
          if (title == 'Estoque') ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                showInventoryCategoriesDialog(context);
              },
              icon: const Icon(Icons.category_rounded),
              label: const Text('Categorias'),
            ),
          ],
          if (title == 'Caixa') ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                showCashClosuresHistoryDialog(context);
              },
              icon: const Icon(Icons.history_rounded),
              label: const Text('Fechamentos'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                showCashClosureDialog(context);
              },
              icon: const Icon(Icons.lock_clock_rounded),
              label: const Text('Fechar dia'),
            ),
          ],
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
