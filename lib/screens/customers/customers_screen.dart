import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/cash_movement.dart';
import '../../models/credit_entry.dart';
import '../../models/customer.dart';
import '../../models/payment_method.dart';
import '../../providers/cash_movement_provider.dart';
import '../../providers/customers_provider.dart';
import '../../widgets/leleco_metric_card.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/cash_sale_sync.dart';
import '../../widgets/easy_help_card.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomersProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final customers = provider.filteredCustomers;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 230,
                  child: LelecoMetricCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Clientes',
                    value: provider.totalCustomers.toString(),
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: LelecoMetricCard(
                    icon: Icons.money_off_rounded,
                    title: 'Fiado aberto',
                    value: _formatMoney(provider.totalOpenCredit),
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: LelecoMetricCard(
                    icon: Icons.warning_rounded,
                    title: 'Com dívida',
                    value: provider.customersWithDebt.toString(),
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: LelecoMetricCard(
                    icon: Icons.payments_rounded,
                    title: 'Recebido hoje',
                    value: _formatMoney(provider.paymentsReceivedToday),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const EasyHelpCard(
              title: 'Fiado fácil',
              subtitle: 'Controle quem deve, quem pagou e corrija lançamentos.',
              icon: Icons.people_alt_rounded,
              steps: [
                EasyHelpStep(
                  title: 'Cadastre cliente',
                  description: 'Nome e telefone já bastam.',
                  icon: Icons.person_add_alt_rounded,
                ),
                EasyHelpStep(
                  title: 'Venda no fiado',
                  description: 'Na venda, escolha Fiado e o cliente.',
                  icon: Icons.shopping_bag_rounded,
                ),
                EasyHelpStep(
                  title: 'Receba pagamento',
                  description: 'O valor entra no caixa automaticamente.',
                  icon: Icons.payments_rounded,
                ),
                EasyHelpStep(
                  title: 'Corrija erro',
                  description: 'Use Histórico para cancelar ou estornar.',
                  icon: Icons.undo_rounded,
                ),
              ],
              footer:
                  'Pagamento recebido no fiado aparece no Caixa. Compra fiada só aparece como dívida até ser paga.',
            ),
            const SizedBox(height: 16),
            _CustomersToolbar(provider: provider),
            const SizedBox(height: 16),
            Expanded(
              child: customers.isEmpty
                  ? const _EmptyCustomers()
                  : ListView.separated(
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _CustomerCard(
                          provider: provider,
                          customer: customers[index],
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomersToolbar extends StatelessWidget {
  const _CustomersToolbar({required this.provider});

  final CustomersProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: provider.setSearchTerm,
            decoration: InputDecoration(
              hintText: 'Buscar cliente por nome ou telefone...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        FilledButton.icon(
          onPressed: () => _openCustomerDialog(context),
          icon: const Icon(Icons.person_add_alt_rounded),
          label: const Text('Novo cliente'),
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.provider, required this.customer});

  final CustomersProvider provider;
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final balance = provider.balanceForCustomer(customer.id);
    final hasDebt = balance > 0.009;

    return Card(
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
                Icons.person_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (customer.phone == null || customer.phone!.isEmpty)
                        ? 'Sem telefone cadastrado'
                        : customer.phone!,
                  ),
                ],
              ),
            ),
            Container(
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hasDebt
                    ? AppColors.warning.withOpacity(0.16)
                    : AppColors.success.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                hasDebt ? _formatMoney(balance) : 'Sem dívida',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: hasDebt ? AppColors.warning : AppColors.success,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Receber pagamento do fiado',
              onPressed: hasDebt
                  ? () => _openPaymentDialog(context, customer)
                  : null,
              icon: const Icon(Icons.payments_rounded),
            ),
            IconButton(
              tooltip: 'Ver histórico do cliente',
              onPressed: () => _openCustomerHistoryDialog(context, customer),
              icon: const Icon(Icons.history_rounded),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: () => _openCustomerDialog(context, customer: customer),
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCustomers extends StatelessWidget {
  const _EmptyCustomers();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Nenhum cliente cadastrado.'));
  }
}

Future<void> _openCustomerDialog(
  BuildContext context, {
  Customer? customer,
}) async {
  final provider = context.read<CustomersProvider>();

  final nameController = TextEditingController(text: customer?.name ?? '');
  final phoneController = TextEditingController(text: customer?.phone ?? '');
  final notesController = TextEditingController(text: customer?.notes ?? '');

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(customer == null ? 'Novo cliente' : 'Editar cliente'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do cliente',
                  hintText: 'Ex: João Silva',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: 'Ex: (98) 99999-9999',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Ex: cliente antigo, paga sábado...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();

              if (name.isEmpty) {
                _showMessage(context, 'Informe o nome do cliente.');
                return;
              }

              if (customer == null) {
                provider.addCustomer(
                  name: name,
                  phone: phoneController.text,
                  notes: notesController.text,
                );
              } else {
                provider.updateCustomer(
                  customer.copyWith(
                    name: name,
                    phone: phoneController.text.trim(),
                    notes: notesController.text.trim(),
                  ),
                );
              }

              Navigator.of(dialogContext).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );
}

Future<void> _openPaymentDialog(BuildContext context, Customer customer) async {
  final provider = context.read<CustomersProvider>();
  final cashProvider = context.read<CashMovementProvider>();
  final balance = provider.balanceForCustomer(customer.id);

  final amountController = TextEditingController(
    text: balance.toStringAsFixed(2).replaceAll('.', ','),
  );
  final noteController = TextEditingController();

  var selectedPaymentMethod = PaymentMethod.dinheiro;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('Receber de ${customer.name}'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.wine900.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Saldo atual: ${_formatMoney(balance)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor recebido',
                      hintText: 'Ex: 50,00',
                      prefixText: 'R\$ ',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<PaymentMethod>(
                    value: selectedPaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Forma de pagamento',
                      helperText: 'Esse valor entra automaticamente no caixa',
                    ),
                    items: PaymentMethod.values
                        .where((method) => method != PaymentMethod.fiado)
                        .map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method.label),
                          );
                        })
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedPaymentMethod = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Observação',
                      hintText: 'Ex: pagou parte da dívida',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.payments_rounded),
                onPressed: () {
                  final amount = _parseDouble(amountController.text);

                  if (amount <= 0) {
                    _showMessage(context, 'Informe um valor válido.');
                    return;
                  }

                  final receivedAmount = amount > balance ? balance : amount;

                  if (receivedAmount <= 0) {
                    _showMessage(
                      context,
                      'Esse cliente não tem saldo em aberto.',
                    );
                    return;
                  }

                  final description = noteController.text.trim().isEmpty
                      ? 'Pagamento de fiado'
                      : noteController.text.trim();

                  final cashReferenceId =
                      'credit_payment:${customer.id}:${DateTime.now().microsecondsSinceEpoch}';

                  provider.registerPayment(
                    customerId: customer.id,
                    amount: receivedAmount,
                    paymentMethod: selectedPaymentMethod,
                    cashMovementReferenceId: cashReferenceId,
                    description: description,
                  );

                  cashProvider.addMovement(
                    type: CashMovementType.input,
                    category: CashMovementCategory.creditPayment,
                    amount: receivedAmount,
                    paymentMethod: selectedPaymentMethod,
                    reason: 'Pagamento fiado - ${customer.name}',
                    description: description,
                    referenceId: cashReferenceId,
                    personName: customer.name,
                    createdAt: DateTime.now(),
                  );

                  Navigator.of(dialogContext).pop();

                  _showMessage(
                    context,
                    'Pagamento recebido e lançado no caixa.',
                  );
                },
                label: const Text('Receber'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _openCustomerHistoryDialog(
  BuildContext context,
  Customer customer,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Consumer<CustomersProvider>(
        builder: (context, provider, _) {
          final entries = provider.entriesForCustomer(customer.id);
          final balance = provider.balanceForCustomer(customer.id);

          return AlertDialog(
            title: Text('Histórico de ${customer.name}'),
            content: SizedBox(
              width: 720,
              height: 460,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.wine900.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Saldo atual: ${_formatMoney(balance)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: entries.isEmpty
                        ? const Center(
                            child: Text('Nenhum movimento encontrado.'),
                          )
                        : ListView.separated(
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _CreditEntryCard(entry: entries[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _cancelFiadoSaleFromCustomerHistory(
  BuildContext context,
  CreditEntry entry,
) async {
  if (entry.type != CreditEntryType.purchase) return;

  if (entry.saleId == null || entry.saleId!.trim().isEmpty) {
    _showMessage(
      context,
      'Essa compra fiada é antiga e não tem vínculo com a venda original.',
    );
    return;
  }

  final customers = context.read<CustomersProvider>();
  final sales = context.read<SalesProvider>();
  final inventory = context.read<InventoryProvider>();

  final paymentsAfterThisPurchase = customers
      .entriesForCustomer(entry.customerId)
      .where(
        (item) =>
            item.type == CreditEntryType.payment &&
            item.createdAt.isAfter(entry.createdAt),
      )
      .fold<double>(0, (total, item) => total + item.amount);

  if (paymentsAfterThisPurchase > 0.009) {
    _showMessage(
      context,
      'Essa compra já tem pagamento depois dela. Cancele apenas fiados ainda sem pagamento.',
    );
    return;
  }

  final sale = sales.findSaleById(entry.saleId!);

  if (sale == null) {
    _showMessage(context, 'Venda original não encontrada.');
    return;
  }

  if (sale.isCanceled) {
    customers.deleteEntriesBySaleId(sale.id);
    _showMessage(context, 'Dívida removida do fiado.');
    return;
  }

  final reason = await _askCreditCancelReason(
    context,
    title: 'Cancelar venda fiada #${sale.shortId}',
    actionLabel: 'Cancelar venda',
  );

  if (reason == null) return;
  if (!context.mounted) return;

  final restored = inventory.restoreSaleRecordStock(sale);

  if (!restored) {
    _showMessage(context, 'Não foi possível devolver o estoque dessa venda.');
    return;
  }

  final canceled = sales.cancelSale(sale.id, reason);

  if (!canceled) {
    _showMessage(context, 'Não foi possível cancelar a venda fiada.');
    return;
  }

  customers.deleteEntriesBySaleId(sale.id);
  removeSaleCashMovement(context, sale);

  _showMessage(
    context,
    'Venda fiada cancelada, dívida removida e estoque devolvido.',
  );
}

Future<void> _cancelCreditPaymentFromCustomerHistory(
  BuildContext context,
  CreditEntry entry,
) async {
  if (entry.type != CreditEntryType.payment) return;

  final reason = await _askCreditCancelReason(
    context,
    title: 'Estornar pagamento de ${_formatMoney(entry.amount)}',
    actionLabel: 'Estornar pagamento',
  );

  if (reason == null) return;
  if (!context.mounted) return;

  final customers = context.read<CustomersProvider>();
  final cash = context.read<CashMovementProvider>();

  customers.deleteEntryById(entry.id);

  final cashReference = entry.cashMovementReferenceId?.trim();

  if (cashReference != null && cashReference.isNotEmpty) {
    cash.deleteMovementsByReferenceId(cashReference);

    _showMessage(context, 'Pagamento estornado e entrada removida do caixa.');
    return;
  }

  _showMessage(
    context,
    'Pagamento estornado no fiado. Confira o caixa manualmente se esse pagamento for antigo.',
  );
}

Future<String?> _askCreditCancelReason(
  BuildContext context, {
  required String title,
  required String actionLabel,
}) async {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            hintText: 'Ex: lançamento feito errado',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Voltar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.undo_rounded),
            onPressed: () {
              final reason = controller.text.trim();

              if (reason.isEmpty) {
                _showMessage(context, 'Informe o motivo.');
                return;
              }

              Navigator.of(dialogContext).pop(reason);
            },
            label: Text(actionLabel),
          ),
        ],
      );
    },
  );
}

class _CreditEntryCard extends StatelessWidget {
  const _CreditEntryCard({required this.entry, this.onCancelFiado});

  final CreditEntry entry;
  final VoidCallback? onCancelFiado;

  @override
  Widget build(BuildContext context) {
    final isPurchase = entry.type == CreditEntryType.purchase;
    final color = isPurchase ? AppColors.warning : AppColors.success;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPurchase ? AppColors.wine900 : AppColors.success,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isPurchase
                    ? Icons.shopping_cart_rounded
                    : Icons.payments_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.type.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(entry.description),
                  if (!isPurchase)
                    Text(
                      'Forma: ${entry.paymentMethod.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDateTime(entry.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                if (isPurchase)
                  TextButton.icon(
                    onPressed:
                        onCancelFiado ??
                        () =>
                            _cancelFiadoSaleFromCustomerHistory(context, entry),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancelar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (!isPurchase)
                  TextButton.icon(
                    onPressed: () =>
                        _cancelCreditPaymentFromCustomerHistory(context, entry),
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: const Text('Estornar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                Text(
                  '${isPurchase ? '+' : '-'} ${_formatMoney(entry.amount)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}

String _formatDateTime(DateTime value) {
  final day = _two(value.day);
  final month = _two(value.month);
  final year = value.year;
  final hour = _two(value.hour);
  final minute = _two(value.minute);

  return '$day/$month/$year $hour:$minute';
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}

double _parseDouble(String value) {
  final normalized = value
      .trim()
      .replaceAll(r'R$', '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .replaceAll(RegExp(r'[^0-9\\.\\-]'), '');
  return double.tryParse(normalized) ?? 0;
}
