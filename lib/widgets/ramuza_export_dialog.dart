import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/product_unit.dart';
import '../providers/inventory_provider.dart';
import '../services/ramuza_export_service.dart';

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
  final Set<String> selectedIds = {};

  String searchTerm = '';
  int validityDays = 5;
  bool includeHeader = true;
  bool removeAccents = true;
  bool showInstructions = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, _) {
        final products = _filterProducts(inventory.products, searchTerm);

        final selectedProducts = inventory.products.where((product) {
          return selectedIds.contains(product.id) && !product.isDeleted;
        }).toList();

        final csvText = RamuzaExportService.buildCsv(
          products: selectedProducts,
          validityDays: validityDays,
          includeHeader: includeHeader,
          removeAccents: removeAccents,
        );

        final txtText = RamuzaExportService.buildTxt(
          products: selectedProducts,
          validityDays: validityDays,
          includeHeader: includeHeader,
          removeAccents: removeAccents,
        );

        return AlertDialog(
          title: const Text('Integração Ramuza Atena II'),
          content: SizedBox(
            width: 1050,
            height: 680,
            child: Column(
              children: [
                _RamuzaHeader(selectedCount: selectedProducts.length),
                const SizedBox(height: 14),
                _OptionsBar(
                  validityDays: validityDays,
                  includeHeader: includeHeader,
                  removeAccents: removeAccents,
                  showInstructions: showInstructions,
                  onValidityChanged: (value) {
                    setState(() => validityDays = value);
                  },
                  onIncludeHeaderChanged: (value) {
                    setState(() => includeHeader = value);
                  },
                  onRemoveAccentsChanged: (value) {
                    setState(() => removeAccents = value);
                  },
                  onShowInstructionsChanged: (value) {
                    setState(() => showInstructions = value);
                  },
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _ProductSelectorPanel(
                          products: products,
                          selectedIds: selectedIds,
                          onSearchChanged: (value) {
                            setState(() => searchTerm = value);
                          },
                          onSelectVisible: () {
                            setState(() {
                              for (final product in products) {
                                selectedIds.add(product.id);
                              }
                            });
                          },
                          onClear: () {
                            setState(selectedIds.clear);
                          },
                          onToggle: (product, selected) {
                            setState(() {
                              if (selected) {
                                selectedIds.add(product.id);
                              } else {
                                selectedIds.remove(product.id);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 4,
                        child: showInstructions
                            ? _InstructionsPanel(
                                text: RamuzaExportService.buildInstructions(),
                              )
                            : _PreviewPanel(text: csvText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            OutlinedButton.icon(
              onPressed: selectedProducts.isEmpty
                  ? null
                  : () => _copyText(
                        context,
                        txtText,
                        'TXT copiado. Cole no Bloco de Notas e salve como .txt.',
                      ),
              icon: const Icon(Icons.description_rounded),
              label: const Text('Copiar TXT'),
            ),
            FilledButton.icon(
              onPressed: selectedProducts.isEmpty
                  ? null
                  : () => _copyText(
                        context,
                        csvText,
                        'CSV copiado. Cole no Excel ou Bloco de Notas e salve como .csv.',
                      ),
              icon: const Icon(Icons.table_chart_rounded),
              label: const Text('Copiar CSV'),
            ),
          ],
        );
      },
    );
  }
}

class _RamuzaHeader extends StatelessWidget {
  const _RamuzaHeader({required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.wine900,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.scale_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Exportação inicial de produtos/PLU para importar no software da Ramuza. Depois o software envia para a balança Atena II.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '$selectedCount produto(s)',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsBar extends StatelessWidget {
  const _OptionsBar({
    required this.validityDays,
    required this.includeHeader,
    required this.removeAccents,
    required this.showInstructions,
    required this.onValidityChanged,
    required this.onIncludeHeaderChanged,
    required this.onRemoveAccentsChanged,
    required this.onShowInstructionsChanged,
  });

  final int validityDays;
  final bool includeHeader;
  final bool removeAccents;
  final bool showInstructions;
  final ValueChanged<int> onValidityChanged;
  final ValueChanged<bool> onIncludeHeaderChanged;
  final ValueChanged<bool> onRemoveAccentsChanged;
  final ValueChanged<bool> onShowInstructionsChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<int>(
            value: validityDays,
            decoration: const InputDecoration(
              labelText: 'Validade padrão',
            ),
            items: const [1, 2, 3, 5, 7, 10, 15, 30].map((value) {
              return DropdownMenuItem(
                value: value,
                child: Text('$value dia(s)'),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              onValidityChanged(value);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CheckboxListTile(
            value: includeHeader,
            onChanged: (value) => onIncludeHeaderChanged(value ?? true),
            title: const Text('Incluir cabeçalho'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        Expanded(
          child: CheckboxListTile(
            value: removeAccents,
            onChanged: (value) => onRemoveAccentsChanged(value ?? true),
            title: const Text('Remover acentos'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        Expanded(
          child: SwitchListTile(
            value: showInstructions,
            onChanged: onShowInstructionsChanged,
            title: const Text('Instruções'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _ProductSelectorPanel extends StatelessWidget {
  const _ProductSelectorPanel({
    required this.products,
    required this.selectedIds,
    required this.onSearchChanged,
    required this.onSelectVisible,
    required this.onClear,
    required this.onToggle,
  });

  final List<Product> products;
  final Set<String> selectedIds;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSelectVisible;
  final VoidCallback onClear;
  final void Function(Product product, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Buscar produto, código ou categoria...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: onSelectVisible,
                  child: const Text('Selecionar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Limpar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: products.isEmpty
                  ? const Center(
                      child: Text('Nenhum produto encontrado.'),
                    )
                  : ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = products[index];

                        return _ProductTile(
                          product: product,
                          selected: selectedIds.contains(product.id),
                          onChanged: (selected) {
                            onToggle(product, selected);
                          },
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

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.selected,
    required this.onChanged,
  });

  final Product product;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: (value) => onChanged(value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.wine700,
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        'Código ${product.code} • ${product.category.label} • ${_formatMoney(product.salePrice)} / ${product.unit.label}',
      ),
      secondary: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: product.isLowStock ? AppColors.warning : AppColors.wine900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.inventory_2_rounded,
          color: AppColors.beige100,
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final preview = text.length > 5000
        ? '${text.substring(0, 5000)}\n...'
        : text;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility_rounded, color: AppColors.wine700),
                const SizedBox(width: 10),
                Text(
                  'Prévia do CSV',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSurfaceAlt
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    preview.isEmpty
                        ? 'Selecione produtos para gerar a prévia.'
                        : preview,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionsPanel extends StatelessWidget {
  const _InstructionsPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

List<Product> _filterProducts(List<Product> products, String searchTerm) {
  final term = searchTerm.trim().toLowerCase();

  final result = products.where((product) {
    if (product.isDeleted) return false;

    if (term.isEmpty) return true;

    return product.name.toLowerCase().contains(term) ||
        product.code.toLowerCase().contains(term) ||
        product.category.label.toLowerCase().contains(term);
  }).toList();

  result.sort((a, b) {
    if (a.favorite != b.favorite) {
      return a.favorite ? -1 : 1;
    }

    return a.name.compareTo(b.name);
  });

  return result;
}

Future<void> _copyText(
  BuildContext context,
  String text,
  String message,
) async {
  await Clipboard.setData(ClipboardData(text: text));

  if (!context.mounted) return;

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
