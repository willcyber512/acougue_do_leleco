import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/theme_provider.dart';
import 'cash_closure_dialog.dart';
import 'inventory_categories_dialog.dart';
import 'leleco_logo.dart';
import 'operation_mode_button.dart';
import 'ramuza_barcode_config_dialog.dart';
import 'ramuza_barcode_history_dialog.dart';
import 'system_diagnostics_dialog.dart';
import 'ramuza_export_dialog.dart';
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
            width: 300,
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
          if (title == 'Ajustes') ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                showSystemDiagnosticsDialog(context);
              },
              icon: const Icon(Icons.health_and_safety_rounded),
              label: const Text('Diag.', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
          if (title == 'Venda') ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                showRamuzaBarcodeConfigDialog(context);
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Etiqueta'),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () {
                showRamuzaBarcodeHistoryDialog(context);
              },
              tooltip: 'Histórico de leituras Ramuza',
              icon: const Icon(Icons.manage_search_rounded),
            ),
            const SizedBox(width: 8),
            const OperationModeButton(),
          ],
          if (title == 'Estoque') ...[
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () {
                showRamuzaExportDialog(context);
              },
              icon: const Icon(Icons.scale_rounded),
              label: const Text('Ramuza'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                showInventoryCategoriesDialog(context);
              },
              icon: const Icon(Icons.category_rounded),
              label: const Text('Cat.', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
          if (title == 'Caixa') ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                showCashClosuresHistoryDialog(context);
              },
              icon: const Icon(Icons.history_rounded),
              label: const Text('Hist.', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () {
                showCashClosureDialog(context);
              },
              icon: const Icon(Icons.lock_clock_rounded),
              label: const Text('Fechar', maxLines: 1, overflow: TextOverflow.ellipsis),
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
