import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../models/supplier_purchase.dart';
import '../../providers/suppliers_provider.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String searchTerm = '';
  bool showOnlyOpen = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<SuppliersProvider>(
      builder: (context, provider, _) {
        final purchases = provider.purchases.where((purchase) {
          final term = searchTerm.trim().toLowerCase();

          final matchesSearch = term.isEmpty ||
              purchase.supplierName.toLowerCase().contains(term) ||
              purchase.itemName.toLowerCase().contains(term) ||
              purchase.category.label.toLowerCase().contains(term);

          final matchesOpen = !showOnlyOpen || !purchase.paid;

          return matchesSearch && matchesOpen;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SupplierHeader(
              totalPurchased: provider.totalPurchased,
              openAmount: provider.openAmount,
              suppliersCount: provider.suppliersCount,
              purchasesCount: provider.purchases.length,
              onAdd: () => _openPurchaseDialog(context),
            ),
            const SizedBox(height: 14),
            _SupplierToolbar(
              searchTerm: searchTerm,
              showOnlyOpen: showOnlyOpen,
              onSearchChanged: (value) {
                setState(() => searchTerm = value);
              },
              onOpenChanged: (value) {
                setState(() => showOnlyOpen = value);
              },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: purchases.isEmpty
                  ? const _EmptySuppliers()
                  : ListView.separated(
                      itemCount: purchases.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _PurchaseCard(
                          purchase: purchases[index],
                          onEdit: () => _openPurchaseDialog(
                            context,
                            purchase: purchases[index],
                          ),
                          onDelete: () => _deletePurchase(
                            context,
                            purchases[index],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePurchase(
    BuildContext context,
    SupplierPurchase purchase,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir compra?'),
          content: Text(
            'Deseja excluir a compra "${purchase.itemName}" de ${purchase.supplierName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    context.read<SuppliersProvider>().deletePurchase(purchase.id);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Compra removida.')),
      );
  }
}

class _SupplierHeader extends StatelessWidget {
  const _SupplierHeader({
    required this.totalPurchased,
    required this.openAmount,
    required this.suppliersCount,
    required this.purchasesCount,
    required this.onAdd,
  });

  final double totalPurchased;
  final double openAmount;
  final int suppliersCount;
  final int purchasesCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.wine900,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: AppColors.beige100,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Controle de fornecedores e compras',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nova compra'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SupplierMetric(
                  icon: Icons.payments_rounded,
                  label: 'Comprado total',
                  value: _formatMoney(totalPurchased),
                ),
                _SupplierMetric(
                  icon: Icons.pending_actions_rounded,
                  label: 'Em aberto',
                  value: _formatMoney(openAmount),
                ),
                _SupplierMetric(
                  icon: Icons.store_rounded,
                  label: 'Fornecedores',
                  value: suppliersCount.toString(),
                ),
                _SupplierMetric(
                  icon: Icons.receipt_long_rounded,
                  label: 'Compras',
                  value: purchasesCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierMetric extends StatelessWidget {
  const _SupplierMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: 210,
      height: 112,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceAlt : AppColors.beige100,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.wine700),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierToolbar extends StatelessWidget {
  const _SupplierToolbar({
    required this.searchTerm,
    required this.showOnlyOpen,
    required this.onSearchChanged,
    required this.onOpenChanged,
  });

  final String searchTerm;
  final bool showOnlyOpen;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onOpenChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Pesquisar fornecedor, carne ou categoria...',
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilterChip(
          selected: showOnlyOpen,
          label: const Text('Somente em aberto'),
          avatar: const Icon(Icons.pending_actions_rounded),
          onSelected: onOpenChanged,
        ),
      ],
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.purchase,
    required this.onEdit,
    required this.onDelete,
  });

  final SupplierPurchase purchase;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = purchase.paid ? AppColors.success : AppColors.warning;
    final statusText = purchase.paid ? 'Pago' : 'Em aberto';

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.wine900,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.beige100,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${purchase.supplierName} • ${purchase.category.label} • ${_formatDate(purchase.purchaseDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatNumber(purchase.quantity)} ${purchase.unit.label} x ${_formatMoney(purchase.unitCost)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 110,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: Text(
                  _formatMoney(purchase.totalCost),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.wine700,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                tooltip: 'Excluir',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySuppliers extends StatelessWidget {
  const _EmptySuppliers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Nenhuma compra de fornecedor registrada ainda.',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

Future<void> _openPurchaseDialog(
  BuildContext context, {
  SupplierPurchase? purchase,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _PurchaseDialog(purchase: purchase),
  );
}

class _PurchaseDialog extends StatefulWidget {
  const _PurchaseDialog({this.purchase});

  final SupplierPurchase? purchase;

  @override
  State<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<_PurchaseDialog> {
  late final TextEditingController supplierController;
  late final TextEditingController itemController;
  late final TextEditingController quantityController;
  late final TextEditingController unitCostController;
  late final TextEditingController documentController;
  late final TextEditingController notesController;

  late ProductCategory category;
  late ProductUnit unit;
  late DateTime purchaseDate;
  late bool paid;

  @override
  void initState() {
    super.initState();

    final purchase = widget.purchase;

    supplierController = TextEditingController(text: purchase?.supplierName ?? '');
    itemController = TextEditingController(text: purchase?.itemName ?? '');
    quantityController = TextEditingController(
      text: purchase == null ? '' : _formatNumber(purchase.quantity),
    );
    unitCostController = TextEditingController(
      text: purchase == null ? '' : _moneyInput(purchase.unitCost),
    );
    documentController = TextEditingController(text: purchase?.documentNumber ?? '');
    notesController = TextEditingController(text: purchase?.notes ?? '');

    category = purchase?.category ?? ProductCategory.bovina;
    unit = purchase?.unit ?? ProductUnit.kg;
    purchaseDate = purchase?.purchaseDate ?? DateTime.now();
    paid = purchase?.paid ?? true;
  }

  @override
  void dispose() {
    supplierController.dispose();
    itemController.dispose();
    quantityController.dispose();
    unitCostController.dispose();
    documentController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantity = _parseNumber(quantityController.text);
    final unitCost = _parseMoney(unitCostController.text);
    final total = quantity * unitCost;

    return AlertDialog(
      title: Text(widget.purchase == null ? 'Nova compra' : 'Editar compra'),
      content: SizedBox(
        width: 760,
        height: 620,
        child: ListView(
          children: [
            TextField(
              controller: supplierController,
              decoration: const InputDecoration(
                labelText: 'Fornecedor',
                hintText: 'Ex: Frigorífico São Luís',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: itemController,
              decoration: const InputDecoration(
                labelText: 'O que comprou',
                hintText: 'Ex: Picanha, alcatra, frango, carvão...',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ProductCategory>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: ProductCategory.values.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => category = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<ProductUnit>(
                    value: unit,
                    decoration: const InputDecoration(labelText: 'Unidade'),
                    items: ProductUnit.values.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => unit = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantidade (${unit.label})',
                      hintText: 'Ex: 25',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: unitCostController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custo por unidade',
                      prefixText: 'R\$ ',
                      hintText: 'Ex: 32,50',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.payments_rounded),
                title: const Text(
                  'Total da compra',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${_formatNumber(quantity)} ${unit.label} x ${_formatMoney(unitCost)}',
                ),
                trailing: Text(
                  _formatMoney(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.today_rounded),
                    label: Text('Data: ${_formatDate(purchaseDate)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    value: paid,
                    onChanged: (value) {
                      setState(() => paid = value);
                    },
                    title: const Text(
                      'Pago',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: documentController,
              decoration: const InputDecoration(
                labelText: 'Nota / documento / referência',
                hintText: 'Opcional',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Ex: compra para repor estoque do fim de semana.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() => purchaseDate = selected);
  }

  void _save() {
    final supplier = supplierController.text.trim();
    final item = itemController.text.trim();
    final quantity = _parseNumber(quantityController.text);
    final unitCost = _parseMoney(unitCostController.text);

    if (supplier.isEmpty || item.isEmpty || quantity <= 0 || unitCost < 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Preencha fornecedor, item, quantidade e custo.'),
          ),
        );
      return;
    }

    final now = DateTime.now();
    final provider = context.read<SuppliersProvider>();

    final old = widget.purchase;

    final purchase = SupplierPurchase(
      id: old?.id ?? const Uuid().v4(),
      supplierName: supplier,
      itemName: item,
      category: category,
      unit: unit,
      quantity: quantity,
      unitCost: unitCost,
      purchaseDate: purchaseDate,
      paid: paid,
      notes: notesController.text.trim(),
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
      documentNumber: documentController.text.trim().isEmpty
          ? null
          : documentController.text.trim(),
    );

    if (old == null) {
      provider.addPurchase(purchase);
    } else {
      provider.updatePurchase(purchase);
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Compra salva.')),
      );
  }
}

double _parseMoney(String value) {
  return _parseNumber(value.replaceAll('R\$', '').trim());
}

double _parseNumber(String value) {
  final text = value
      .trim()
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .replaceAll(RegExp(r'[^0-9\.\-]'), '');

  return double.tryParse(text) ?? 0;
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');

  return 'R\$ $fixed';
}

String _moneyInput(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

String _formatNumber(double value) {
  if (value % 1 == 0) return value.toStringAsFixed(0);

  return value.toStringAsFixed(3).replaceAll('.', ',');
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();

  return '$day/$month/$year';
}
