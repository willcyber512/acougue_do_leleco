import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/internal_note.dart';
import '../models/inventory_loss.dart';
import '../models/payment_method.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/product_unit.dart';
import '../models/sale.dart';
import '../providers/customers_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/sales_provider.dart';

Future<void> showUniversalSearchDialog({
  required BuildContext context,
  required ValueChanged<int> onNavigate,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return UniversalSearchDialog(onNavigate: onNavigate);
    },
  );
}

class UniversalSearchDialog extends StatefulWidget {
  const UniversalSearchDialog({
    super.key,
    required this.onNavigate,
  });

  final ValueChanged<int> onNavigate;

  @override
  State<UniversalSearchDialog> createState() => _UniversalSearchDialogState();
}

class _UniversalSearchDialogState extends State<UniversalSearchDialog> {
  final TextEditingController controller = TextEditingController();

  String searchTerm = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pesquisa universal'),
      content: SizedBox(
        width: 820,
        height: 560,
        child: Column(
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              onChanged: (value) {
                setState(() => searchTerm = value);
              },
              decoration: InputDecoration(
                hintText: 'Buscar produto, cliente, venda ou anotação...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer4<InventoryProvider, CustomersProvider,
                  SalesProvider, NotesProvider>(
                builder: (context, inventory, customers, sales, notes, _) {
                  final results = _buildResults(
                    inventory: inventory,
                    customers: customers,
                    sales: sales,
                    notes: notes,
                    searchTerm: searchTerm,
                  );

                  if (searchTerm.trim().isEmpty) {
                    return const _SearchEmptyState(
                      text:
                          'Digite algo para buscar em produtos, clientes, vendas e anotações.',
                    );
                  }

                  if (results.isEmpty) {
                    return const _SearchEmptyState(
                      text: 'Nenhum resultado encontrado.',
                    );
                  }

                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final result = results[index];

                      return _SearchResultTile(
                        result: result,
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onNavigate(result.moduleIndex);
                        },
                      );
                    },
                  );
                },
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
      ],
    );
  }
}

class _SearchResult {
  const _SearchResult({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.moduleIndex,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final int moduleIndex;
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.onTap,
  });

  final _SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: result.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(result.icon, color: AppColors.beige100),
        ),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(result.subtitle),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            result.badge,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

List<_SearchResult> _buildResults({
  required InventoryProvider inventory,
  required CustomersProvider customers,
  required SalesProvider sales,
  required NotesProvider notes,
  required String searchTerm,
}) {
  final term = searchTerm.trim().toLowerCase();

  if (term.isEmpty) return [];

  final results = <_SearchResult>[];

  for (final product in inventory.products) {
    if (_matches(term, [
      product.name,
      product.code,
      product.category.label,
      product.unit.label,
    ])) {
      results.add(
        _SearchResult(
          title: product.name,
          subtitle:
              'Código ${product.code} • ${product.category.label} • Estoque ${_formatQuantity(product.stockQuantity, product.unit)}',
          badge: 'Estoque',
          icon: Icons.inventory_2_rounded,
          color: product.isLowStock ? AppColors.warning : AppColors.wine900,
          moduleIndex: 2,
        ),
      );
    }
  }

  for (final customer in customers.customers) {
    final balance = customers.balanceForCustomer(customer.id);

    if (_matches(term, [
      customer.name,
      customer.phone,
      customer.notes,
      _formatMoney(balance),
    ])) {
      results.add(
        _SearchResult(
          title: customer.name,
          subtitle:
              '${customer.phone == null || customer.phone!.isEmpty ? 'Sem telefone' : customer.phone} • Saldo ${_formatMoney(balance)}',
          badge: 'Fiado',
          icon: Icons.person_rounded,
          color: balance > 0 ? AppColors.warning : AppColors.wine900,
          moduleIndex: 3,
        ),
      );
    }
  }

  for (final sale in sales.sales) {
    if (_matches(term, [
      sale.id,
      sale.shortId,
      sale.customerName,
      sale.paymentMethod.label,
      _formatMoney(sale.total),
    ])) {
      results.add(
        _SearchResult(
          title: 'Venda #${sale.shortId}',
          subtitle:
              '${_formatDateTime(sale.createdAt)} • ${sale.paymentMethod.label}${sale.customerName == null ? '' : ' • ${sale.customerName}'}',
          badge: sale.isCanceled ? 'Cancelada' : 'Caixa',
          icon: sale.isCanceled
              ? Icons.cancel_rounded
              : Icons.receipt_long_rounded,
          color: sale.isCanceled ? AppColors.danger : AppColors.wine900,
          moduleIndex: 4,
        ),
      );
    }
  }

  for (final note in notes.notes) {
    if (_matches(term, [
      note.title,
      note.content,
      note.priority.label,
      note.done ? 'concluida' : 'pendente',
      note.done ? 'concluída' : 'pendente',
    ])) {
      results.add(
        _SearchResult(
          title: note.title,
          subtitle:
              '${note.priority.label} • ${note.done ? 'Concluída' : 'Pendente'} • ${note.content.isEmpty ? 'Sem descrição' : note.content}',
          badge: 'Anotação',
          icon: note.done ? Icons.check_rounded : Icons.note_alt_rounded,
          color: note.done ? AppColors.success : AppColors.wine900,
          moduleIndex: 6,
        ),
      );
    }
  }

  for (final loss in inventory.losses) {
    if (_matches(term, [
      loss.productName,
      loss.productCode,
      loss.reason,
      loss.type.label,
      _formatMoney(loss.estimatedValue),
    ])) {
      results.add(
        _SearchResult(
          title: loss.productName,
          subtitle:
              '${loss.type.label} • ${_formatNumber(loss.quantity)} ${loss.unitLabel} • ${loss.reason}',
          badge: 'Perda',
          icon: Icons.remove_circle_outline_rounded,
          color: AppColors.warning,
          moduleIndex: 7,
        ),
      );
    }
  }

  return results.take(40).toList();
}

bool _matches(String term, List<String?> values) {
  return values.any((value) {
    final text = value?.trim().toLowerCase();

    if (text == null || text.isEmpty) return false;

    return text.contains(term);
  });
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}

String _formatQuantity(double value, ProductUnit unit) {
  if (unit == ProductUnit.kg) {
    return '${value.toStringAsFixed(3).replaceAll('.', ',')} ${unit.label}';
  }

  return '${value.toStringAsFixed(0)} ${unit.label}';
}

String _formatNumber(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(3).replaceAll('.', ',');
}

String _formatDateTime(DateTime value) {
  final day = _two(value.day);
  final month = _two(value.month);
  final hour = _two(value.hour);
  final minute = _two(value.minute);

  return '$day/$month $hour:$minute';
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}
