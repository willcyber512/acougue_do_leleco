import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/product.dart';
import '../models/product_unit.dart';
import '../providers/inventory_provider.dart';
import '../services/ramuza_export_service.dart';
import 'ramuza_barcode_config_dialog.dart';

Future<void> showRamuzaExportDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return const RamuzaExportDialog();
    },
  );
}

class RamuzaExportDialog extends StatefulWidget {
  const RamuzaExportDialog({super.key});

  @override
  State<RamuzaExportDialog> createState() => _RamuzaExportDialogState();
}

class _RamuzaExportDialogState extends State<RamuzaExportDialog> {
  RamuzaExportFormat selectedFormat = RamuzaExportFormat.pluCsvHeader;

  final Set<String> selectedIds = {};

  bool removeAccents = true;
  bool onlyFavorites = false;
  bool initializedSelection = false;

  int validityDays = 3;

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, _) {
        final activeProducts = inventory.products.where((product) {
          if (product.isDeleted) return false;
          if (onlyFavorites && !product.favorite) return false;

          return true;
        }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        if (!initializedSelection) {
          selectedIds.addAll(activeProducts.map((product) => product.id));
          initializedSelection = true;
        }

        final selectedProducts = activeProducts.where((product) {
          return selectedIds.contains(product.id);
        }).toList();

        final validation = RamuzaExportService.validateProducts(selectedProducts);

        final file = RamuzaExportService.buildFile(
          products: selectedProducts,
          format: selectedFormat,
          validityDays: validityDays,
          removeAccents: removeAccents,
        );

        return AlertDialog(
          title: const Text('Exportação Ramuza blindada'),
          content: SizedBox(
            width: 1100,
            height: 720,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 360,
                  child: _LeftPanel(
                    activeProducts: activeProducts,
                    selectedIds: selectedIds,
                    onlyFavorites: onlyFavorites,
                    removeAccents: removeAccents,
                    validityDays: validityDays,
                    onOnlyFavoritesChanged: (value) {
                      setState(() {
                        onlyFavorites = value;
                        selectedIds
                          ..clear()
                          ..addAll(
                            inventory.products
                                .where((product) {
                                  if (product.isDeleted) return false;
                                  if (value && !product.favorite) return false;
                                  return true;
                                })
                                .map((product) => product.id),
                          );
                      });
                    },
                    onRemoveAccentsChanged: (value) {
                      setState(() => removeAccents = value);
                    },
                    onValidityChanged: (value) {
                      setState(() => validityDays = value);
                    },
                    onToggleProduct: (product, selected) {
                      setState(() {
                        if (selected) {
                          selectedIds.add(product.id);
                        } else {
                          selectedIds.remove(product.id);
                        }
                      });
                    },
                    onSelectAll: () {
                      setState(() {
                        selectedIds
                          ..clear()
                          ..addAll(activeProducts.map((product) => product.id));
                      });
                    },
                    onClearAll: () {
                      setState(() => selectedIds.clear());
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RightPanel(
                    selectedFormat: selectedFormat,
                    selectedProducts: selectedProducts,
                    validation: validation,
                    file: file,
                    onFormatChanged: (format) {
                      setState(() => selectedFormat = format);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                showRamuzaBarcodeConfigDialog(context);
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Configurar leitura'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            OutlinedButton.icon(
              onPressed: selectedProducts.isEmpty
                  ? null
                  : () => _copyPackage(
                        context,
                        products: selectedProducts,
                        validityDays: validityDays,
                        removeAccents: removeAccents,
                      ),
              icon: const Icon(Icons.inventory_2_rounded),
              label: const Text('Copiar pacote completo'),
            ),
            FilledButton.icon(
              onPressed: selectedProducts.isEmpty
                  ? null
                  : () => _copyFile(context, file),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar formato atual'),
            ),
          ],
        );
      },
    );
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.activeProducts,
    required this.selectedIds,
    required this.onlyFavorites,
    required this.removeAccents,
    required this.validityDays,
    required this.onOnlyFavoritesChanged,
    required this.onRemoveAccentsChanged,
    required this.onValidityChanged,
    required this.onToggleProduct,
    required this.onSelectAll,
    required this.onClearAll,
  });

  final List<Product> activeProducts;
  final Set<String> selectedIds;
  final bool onlyFavorites;
  final bool removeAccents;
  final int validityDays;
  final ValueChanged<bool> onOnlyFavoritesChanged;
  final ValueChanged<bool> onRemoveAccentsChanged;
  final ValueChanged<int> onValidityChanged;
  final void Function(Product product, bool selected) onToggleProduct;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ExportSummary(
          total: activeProducts.length,
          selected: selectedIds.length,
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: onlyFavorites,
          onChanged: onOnlyFavoritesChanged,
          title: const Text('Somente favoritos'),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          value: removeAccents,
          onChanged: onRemoveAccentsChanged,
          title: const Text('Remover acentos'),
          contentPadding: EdgeInsets.zero,
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Validade padrão',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            DropdownButton<int>(
              value: validityDays,
              items: const [1, 2, 3, 5, 7, 10, 15, 30].map((days) {
                return DropdownMenuItem(
                  value: days,
                  child: Text('$days dia(s)'),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                onValidityChanged(value);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onSelectAll,
                child: const Text('Todos'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: onClearAll,
                child: const Text('Limpar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: activeProducts.isEmpty
              ? const Center(
                  child: Text('Nenhum produto ativo.'),
                )
              : ListView.separated(
                  itemCount: activeProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final product = activeProducts[index];

                    return CheckboxListTile(
                      value: selectedIds.contains(product.id),
                      onChanged: (value) {
                        onToggleProduct(product, value ?? false);
                      },
                      title: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${product.code} • ${_formatMoney(product.salePrice)} / ${product.unit.label}',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({
    required this.selectedFormat,
    required this.selectedProducts,
    required this.validation,
    required this.file,
    required this.onFormatChanged,
  });

  final RamuzaExportFormat selectedFormat;
  final List<Product> selectedProducts;
  final RamuzaExportValidation validation;
  final RamuzaExportFile file;
  final ValueChanged<RamuzaExportFormat> onFormatChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<RamuzaExportFormat>(
          value: selectedFormat,
          decoration: const InputDecoration(
            labelText: 'Formato para testar',
          ),
          items: RamuzaExportFormat.values.map((format) {
            return DropdownMenuItem(
              value: format,
              child: Text(format.label),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            onFormatChanged(value);
          },
        ),
        const SizedBox(height: 12),
        _FormatInfo(format: selectedFormat),
        const SizedBox(height: 12),
        _ValidationBox(validation: validation),
        const SizedBox(height: 12),
        Text(
          'Prévia: ${file.fileName}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: selectedProducts.isEmpty
                ? const Center(
                    child: Text('Selecione pelo menos um produto.'),
                  )
                : SingleChildScrollView(
                    child: SelectableText(
                      file.content,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ExportSummary extends StatelessWidget {
  const _ExportSummary({
    required this.total,
    required this.selected,
  });

  final int total;
  final int selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.wine900,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.scale_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$selected de $total produto(s) selecionado(s)',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatInfo extends StatelessWidget {
  const _FormatInfo({required this.format});

  final RamuzaExportFormat format;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Text(
          format.description,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ValidationBox extends StatelessWidget {
  const _ValidationBox({required this.validation});

  final RamuzaExportValidation validation;

  @override
  Widget build(BuildContext context) {
    if (!validation.hasErrors && !validation.hasWarnings) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Produtos prontos para exportação.',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    final items = [
      ...validation.errors.map((item) => 'ERRO: $item'),
      ...validation.warnings.map((item) => 'AVISO: $item'),
    ];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 130),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: validation.hasErrors
            ? AppColors.danger.withOpacity(0.12)
            : AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListView(
        shrinkWrap: true,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        }).toList(),
      ),
    );
  }
}

Future<void> _copyFile(BuildContext context, RamuzaExportFile file) async {
  await Clipboard.setData(ClipboardData(text: file.content));

  _showMessage(
    context,
    'Formato copiado: ${file.fileName}',
  );
}

Future<void> _copyPackage(
  BuildContext context, {
  required List<Product> products,
  required int validityDays,
  required bool removeAccents,
}) async {
  final content = RamuzaExportService.buildPackage(
    products: products,
    validityDays: validityDays,
    removeAccents: removeAccents,
  );

  await Clipboard.setData(ClipboardData(text: content));

  _showMessage(
    context,
    'Pacote completo copiado com todos os formatos.',
  );
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(message)),
    );
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}
