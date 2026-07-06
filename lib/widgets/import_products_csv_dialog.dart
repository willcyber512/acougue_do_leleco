import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/inventory_provider.dart';
import '../services/product_csv_import_service.dart';

Future<void> showImportProductsCsvDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const ImportProductsCsvDialog(),
  );
}

class ImportProductsCsvDialog extends StatefulWidget {
  const ImportProductsCsvDialog({super.key});

  @override
  State<ImportProductsCsvDialog> createState() => _ImportProductsCsvDialogState();
}

class _ImportProductsCsvDialogState extends State<ImportProductsCsvDialog> {
  final controller = TextEditingController();

  CsvImportPreview preview = const CsvImportPreview(rows: []);
  bool imported = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final inventory = context.read<InventoryProvider>();

    setState(() {
      imported = false;
      preview = ProductCsvImportService.preview(
        rawCsv: controller.text,
        existingProducts: inventory.products,
      );
    });
  }

  void _pasteSample() {
    controller.text = ProductCsvImportService.sampleCsv();
    _updatePreview();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;

    if (text == null || text.trim().isEmpty) {
      _showMessage('Área de transferência vazia.');
      return;
    }

    controller.text = text;
    _updatePreview();
  }

  void _importValidRows() {
    final inventory = context.read<InventoryProvider>();
    final validRows = preview.validRows;

    for (final row in validRows) {
      final product = row.product;
      if (product == null) continue;

      inventory.addProduct(product);
    }

    setState(() {
      imported = true;
      preview = const CsvImportPreview(rows: []);
      controller.clear();
    });

    _showMessage('${validRows.length} produto(s) importado(s).');
  }

  @override
  Widget build(BuildContext context) {
    final validCount = preview.validRows.length;
    final invalidCount = preview.invalidRows.length;

    return AlertDialog(
      title: const Text('Importação avançada'),
      content: SizedBox(
        width: 920,
        height: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cole uma tabela CSV usando ponto e vírgula. O sistema confere antes de importar.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _HelpBox(),
            const SizedBox(height: 12),
            Expanded(
              flex: 4,
              child: TextField(
                controller: controller,
                onChanged: (_) => _updatePreview(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'CSV de produtos',
                  alignLabelWithHint: true,
                  hintText: ProductCsvImportService.sampleCsv(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _CounterChip(
                  label: 'Válidos',
                  value: validCount.toString(),
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(width: 8),
                _CounterChip(
                  label: 'Com erro',
                  value: invalidCount.toString(),
                  icon: Icons.error_rounded,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('Colar'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _pasteSample,
                  icon: const Icon(Icons.table_chart_rounded),
                  label: const Text('Exemplo'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: _PreviewPanel(preview: preview),
            ),
            if (imported) ...[
              const SizedBox(height: 8),
              const Text(
                'Importação concluída.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        FilledButton.icon(
          onPressed: preview.canImport ? _importValidRows : null,
          icon: const Icon(Icons.upload_file_rounded),
          label: Text('Importar $validCount produto(s)'),
        ),
      ],
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HelpBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceAlt
            : AppColors.beige100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Cabeçalho: codigo;nome;categoria;unidade;preco;estoque;minimo;custo\n'
        'Categorias aceitas: ${ProductCsvImportService.acceptedCategoriesText()}\n'
        'Unidades aceitas: ${ProductCsvImportService.acceptedUnitsText()}',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.preview});

  final CsvImportPreview preview;

  @override
  Widget build(BuildContext context) {
    if (preview.generalError != null) {
      return _EmptyPreview(text: preview.generalError!);
    }

    if (preview.rows.isEmpty) {
      return const _EmptyPreview(
        text: 'Cole um CSV ou clique em “Exemplo” para testar.',
      );
    }

    return ListView.separated(
      itemCount: preview.rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = preview.rows[index];

        return _ImportRowTile(row: row);
      },
    );
  }
}

class _ImportRowTile extends StatelessWidget {
  const _ImportRowTile({required this.row});

  final CsvImportRow row;

  @override
  Widget build(BuildContext context) {
    final valid = row.isValid;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: valid ? AppColors.success : AppColors.danger,
        ),
      ),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle_rounded : Icons.error_rounded,
            color: valid ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Linha ${row.lineNumber}: ${row.code} • ${row.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          if (valid)
            Text(
              '${row.categoryText} • ${row.unitText} • ${row.priceText}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            Expanded(
              child: Text(
                row.errors.join(' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
