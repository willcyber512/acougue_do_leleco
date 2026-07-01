import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../models/supplier_purchase.dart';
import '../../providers/suppliers_provider.dart';

enum _SupplierPeriod {
  today,
  sevenDays,
  thirtyDays,
  all,
}

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String searchTerm = '';
  bool showOnlyOpen = false;
  _SupplierPeriod selectedPeriod = _SupplierPeriod.thirtyDays;

  @override
  Widget build(BuildContext context) {
    return Consumer<SuppliersProvider>(
      builder: (context, provider, _) {
        final periodPurchases = _filterByPeriod(
          provider.purchases,
          selectedPeriod,
        );

        final filteredPurchases = periodPurchases.where((purchase) {
          final term = searchTerm.trim().toLowerCase();

          final matchesSearch = term.isEmpty ||
              purchase.supplierName.toLowerCase().contains(term) ||
              purchase.itemName.toLowerCase().contains(term) ||
              purchase.category.label.toLowerCase().contains(term) ||
              (purchase.documentNumber ?? '').toLowerCase().contains(term);

          final matchesOpen = !showOnlyOpen || !purchase.paid;

          return matchesSearch && matchesOpen;
        }).toList();

        final totalPurchased = periodPurchases.fold<double>(
          0,
          (total, purchase) => total + purchase.totalCost,
        );

        final openAmount = periodPurchases
            .where((purchase) => !purchase.paid)
            .fold<double>(
              0,
              (total, purchase) => total + purchase.totalCost,
            );

        final suppliersCount = periodPurchases
            .map((purchase) => purchase.supplierName.trim().toLowerCase())
            .where((name) => name.isNotEmpty)
            .toSet()
            .length;

        final supplierTotals = _supplierTotals(periodPurchases);
        final categoryTotals = _categoryTotals(periodPurchases);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SupplierHeader(
              periodLabel: _periodLabel(selectedPeriod),
              totalPurchased: totalPurchased,
              openAmount: openAmount,
              suppliersCount: suppliersCount,
              purchasesCount: periodPurchases.length,
              onAdd: () => _openPurchaseDialog(context),
            ),
            const SizedBox(height: 14),
            _PeriodSelector(
              selected: selectedPeriod,
              onChanged: (period) {
                setState(() => selectedPeriod = period);
              },
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 980;

                  if (compact) {
                    return ListView(
                      children: [
                        _SummaryPanel(
                          supplierTotals: supplierTotals,
                          categoryTotals: categoryTotals,
                        ),
                        const SizedBox(height: 14),
                        _PurchasesList(
                          purchases: filteredPurchases,
                          onEdit: (purchase) {
                            _openPurchaseDialog(context, purchase: purchase);
                          },
                          onDelete: (purchase) {
                            _deletePurchase(context, purchase);
                          },
                          onTogglePaid: (purchase) {
                            _togglePaid(context, purchase);
                          },
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 360,
                        child: _SummaryPanel(
                          supplierTotals: supplierTotals,
                          categoryTotals: categoryTotals,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _PurchasesList(
                          purchases: filteredPurchases,
                          onEdit: (purchase) {
                            _openPurchaseDialog(context, purchase: purchase);
                          },
                          onDelete: (purchase) {
                            _deletePurchase(context, purchase);
                          },
                          onTogglePaid: (purchase) {
                            _togglePaid(context, purchase);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _togglePaid(BuildContext context, SupplierPurchase purchase) {
    final provider = context.read<SuppliersProvider>();

    provider.updatePurchase(
      purchase.copyWith(
        paid: !purchase.paid,
        updatedAt: DateTime.now(),
      ),
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            purchase.paid
                ? 'Compra marcada como em aberto.'
                : 'Compra marcada como paga.',
          ),
        ),
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
    required this.periodLabel,
    required this.totalPurchased,
    required this.openAmount,
    required this.suppliersCount,
    required this.purchasesCount,
    required this.onAdd,
  });

  final String periodLabel;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fornecedores e compras',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Período: $periodLabel',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
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
                  label: 'Comprado no período',
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

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final _SupplierPeriod selected;
  final ValueChanged<_SupplierPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (_SupplierPeriod.today, 'Hoje', Icons.today_rounded),
      (_SupplierPeriod.sevenDays, '7 dias', Icons.date_range_rounded),
      (_SupplierPeriod.thirtyDays, '30 dias', Icons.calendar_month_rounded),
      (_SupplierPeriod.all, 'Tudo', Icons.all_inclusive_rounded),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.filter_alt_rounded, color: AppColors.wine700),
            const SizedBox(width: 10),
            const Text(
              'Período',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: items.map((item) {
                    final active = selected == item.$1;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: active,
                        selectedColor: AppColors.wine900,
                        avatar: Icon(
                          item.$3,
                          size: 18,
                          color: active ? AppColors.beige100 : AppColors.wine700,
                        ),
                        label: Text(item.$2),
                        labelStyle: TextStyle(
                          color: active ? AppColors.beige100 : null,
                          fontWeight: FontWeight.w900,
                        ),
                        onSelected: (_) => onChanged(item.$1),
                      ),
                    );
                  }).toList(),
                ),
              ),
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
              hintText: 'Pesquisar fornecedor, carne, categoria ou documento...',
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

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.supplierTotals,
    required this.categoryTotals,
  });

  final List<_SupplierTotal> supplierTotals;
  final List<_CategoryPurchaseTotal> categoryTotals;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MiniSummaryCard(
          title: 'Resumo por fornecedor',
          emptyText: 'Nenhum fornecedor no período.',
          children: supplierTotals.take(8).map((item) {
            return _SummaryLine(
              title: item.supplierName,
              subtitle: '${item.count} compra(s)',
              value: _formatMoney(item.total),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _MiniSummaryCard(
          title: 'Resumo por categoria',
          emptyText: 'Nenhuma categoria no período.',
          children: categoryTotals.take(8).map((item) {
            return _SummaryLine(
              title: item.category,
              subtitle: '${_formatNumber(item.quantity)} comprado',
              value: _formatMoney(item.total),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  const _MiniSummaryCard({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (children.isEmpty)
              Text(
                emptyText,
                style: const TextStyle(fontWeight: FontWeight.w700),
              )
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PurchasesList extends StatelessWidget {
  const _PurchasesList({
    required this.purchases,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePaid,
  });

  final List<SupplierPurchase> purchases;
  final ValueChanged<SupplierPurchase> onEdit;
  final ValueChanged<SupplierPurchase> onDelete;
  final ValueChanged<SupplierPurchase> onTogglePaid;

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) {
      return const _EmptySuppliers();
    }

    return ListView.separated(
      itemCount: purchases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _PurchaseCard(
          purchase: purchases[index],
          onEdit: () => onEdit(purchases[index]),
          onDelete: () => onDelete(purchases[index]),
          onTogglePaid: () => onTogglePaid(purchases[index]),
        );
      },
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.purchase,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePaid,
  });

  final SupplierPurchase purchase;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePaid;

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
                    if ((purchase.documentNumber ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Doc.: ${purchase.documentNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                tooltip: purchase.paid ? 'Marcar em aberto' : 'Marcar pago',
                onPressed: onTogglePaid,
                icon: Icon(
                  purchase.paid
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
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
        'Nenhuma compra de fornecedor encontrada.',
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

List<SupplierPurchase> _filterByPeriod(
  List<SupplierPurchase> purchases,
  _SupplierPeriod period,
) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  final filtered = purchases.where((purchase) {
    final date = purchase.purchaseDate;

    switch (period) {
      case _SupplierPeriod.today:
        return _sameDay(date, now);

      case _SupplierPeriod.sevenDays:
        return !date.isBefore(todayStart.subtract(const Duration(days: 6)));

      case _SupplierPeriod.thirtyDays:
        return !date.isBefore(todayStart.subtract(const Duration(days: 29)));

      case _SupplierPeriod.all:
        return true;
    }
  }).toList();

  filtered.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

  return filtered;
}

List<_SupplierTotal> _supplierTotals(List<SupplierPurchase> purchases) {
  final map = <String, _SupplierTotal>{};

  for (final purchase in purchases) {
    final key = purchase.supplierName.trim().isEmpty
        ? 'Sem fornecedor'
        : purchase.supplierName.trim();

    final existing = map[key];

    if (existing == null) {
      map[key] = _SupplierTotal(
        supplierName: key,
        count: 1,
        total: purchase.totalCost,
      );
    } else {
      map[key] = existing.copyWith(
        count: existing.count + 1,
        total: existing.total + purchase.totalCost,
      );
    }
  }

  final result = map.values.toList();
  result.sort((a, b) => b.total.compareTo(a.total));

  return result;
}

List<_CategoryPurchaseTotal> _categoryTotals(
  List<SupplierPurchase> purchases,
) {
  final map = <String, _CategoryPurchaseTotal>{};

  for (final purchase in purchases) {
    final key = purchase.category.label;
    final existing = map[key];

    if (existing == null) {
      map[key] = _CategoryPurchaseTotal(
        category: key,
        quantity: purchase.quantity,
        total: purchase.totalCost,
      );
    } else {
      map[key] = existing.copyWith(
        quantity: existing.quantity + purchase.quantity,
        total: existing.total + purchase.totalCost,
      );
    }
  }

  final result = map.values.toList();
  result.sort((a, b) => b.total.compareTo(a.total));

  return result;
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _periodLabel(_SupplierPeriod period) {
  switch (period) {
    case _SupplierPeriod.today:
      return 'Hoje';
    case _SupplierPeriod.sevenDays:
      return 'Últimos 7 dias';
    case _SupplierPeriod.thirtyDays:
      return 'Últimos 30 dias';
    case _SupplierPeriod.all:
      return 'Todo o histórico';
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

class _SupplierTotal {
  const _SupplierTotal({
    required this.supplierName,
    required this.count,
    required this.total,
  });

  final String supplierName;
  final int count;
  final double total;

  _SupplierTotal copyWith({
    int? count,
    double? total,
  }) {
    return _SupplierTotal(
      supplierName: supplierName,
      count: count ?? this.count,
      total: total ?? this.total,
    );
  }
}

class _CategoryPurchaseTotal {
  const _CategoryPurchaseTotal({
    required this.category,
    required this.quantity,
    required this.total,
  });

  final String category;
  final double quantity;
  final double total;

  _CategoryPurchaseTotal copyWith({
    double? quantity,
    double? total,
  }) {
    return _CategoryPurchaseTotal(
      category: category,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }
}
