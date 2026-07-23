import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../models/sale_cart_item.dart';
import '../../providers/customers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/ramuza_settings_provider.dart';
import '../../providers/ramuza_barcode_log_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/ramuza_barcode_parser.dart';
import '../../widgets/sale_receipt_dialog.dart';
import '../../widgets/quick_product_from_barcode_dialog.dart';
import '../../models/ramuza_barcode_event.dart';
import '../../services/cash_sale_sync.dart';
import '../../widgets/easy_help_card.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;

        if (compact) {
          return SingleChildScrollView(
            child: Column(
              children: const [
                EasyHelpCard(
                  title: 'Venda fácil',
                  subtitle: 'Passe o produto, confira o carrinho e finalize.',
                  icon: Icons.point_of_sale_rounded,
                  steps: [
                    EasyHelpStep(
                      title: 'Passe no leitor',
                      description: 'Leia o código ou digite o produto.',
                      icon: Icons.qr_code_scanner_rounded,
                    ),
                    EasyHelpStep(
                      title: 'Confira o carrinho',
                      description: 'Veja quantidade, peso e total.',
                      icon: Icons.shopping_cart_checkout_rounded,
                    ),
                    EasyHelpStep(
                      title: 'Escolha pagamento',
                      description: 'Dinheiro, Pix, cartão ou fiado.',
                      icon: Icons.payments_rounded,
                    ),
                    EasyHelpStep(
                      title: 'Finalize',
                      description: 'Baixa estoque e registra no caixa.',
                      icon: Icons.check_circle_rounded,
                    ),
                  ],
                  footer:
                      'Fiado não entra no caixa na hora. Ele fica na aba Fiado e só entra no caixa quando o cliente pagar.',
                ),
                SizedBox(height: 14),
                SizedBox(height: 560, child: _ProductsPanel()),
                SizedBox(height: 14),
                SizedBox(height: 520, child: _CartPanel()),
              ],
            ),
          );
        }

        return const Column(
          children: [
            EasyHelpCard(
              title: 'Venda fácil',
              subtitle: 'Passe o produto, confira o carrinho e finalize.',
              icon: Icons.point_of_sale_rounded,
              steps: [
                EasyHelpStep(
                  title: 'Passe no leitor',
                  description: 'Leia o código ou digite o produto.',
                  icon: Icons.qr_code_scanner_rounded,
                ),
                EasyHelpStep(
                  title: 'Confira o carrinho',
                  description: 'Veja quantidade, peso e total.',
                  icon: Icons.shopping_cart_checkout_rounded,
                ),
                EasyHelpStep(
                  title: 'Escolha pagamento',
                  description: 'Dinheiro, Pix, cartão ou fiado.',
                  icon: Icons.payments_rounded,
                ),
                EasyHelpStep(
                  title: 'Finalize',
                  description: 'Baixa estoque e registra no caixa.',
                  icon: Icons.check_circle_rounded,
                ),
              ],
              footer:
                  'Fiado não entra no caixa na hora. Ele fica na aba Fiado e só entra no caixa quando o cliente pagar.',
            ),
            SizedBox(height: 14),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 7, child: _ProductsPanel()),
                  SizedBox(width: 18),
                  Expanded(flex: 4, child: _CartPanel()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductsPanel extends StatelessWidget {
  const _ProductsPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer2<InventoryProvider, SalesProvider>(
      builder: (context, inventory, sales, _) {
        final ramuzaSettings = context.watch<RamuzaSettingsProvider>().settings;

        final parsedBarcode = RamuzaBarcodeParser.tryParse(
          sales.searchTerm,
          ramuzaSettings,
        );

        final products = parsedBarcode == null
            ? _filterProducts(inventory.products, sales.searchTerm)
            : _filterProductsForRamuzaCode(
                inventory.products,
                parsedBarcode.productCode,
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BarcodeSearchField(
              value: sales.searchTerm,
              onChanged: sales.setSearchTerm,
              onSubmitted: (value) {
                _handleSalesInput(context, value);
              },
            ),
            const SizedBox(height: 12),
            Text(
              parsedBarcode == null
                  ? 'Enter adiciona 1 unidade/kg. Para peso exato, use o botão "Qtd".'
                  : 'Etiqueta balança detectada: PLU ${parsedBarcode.productCode}. Aperte Enter para adicionar.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: products.isEmpty
                  ? _EmptyProducts(
                      message: parsedBarcode == null
                          ? 'Nenhum produto encontrado.'
                          : 'Etiqueta detectada, mas o PLU ${parsedBarcode.productCode} não está disponível no estoque.',
                    )
                  : GridView.builder(
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 270,
                            mainAxisExtent: 230,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                      itemBuilder: (context, index) {
                        return _ProductSaleCard(product: products[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _BarcodeSearchField extends StatefulWidget {
  const _BarcodeSearchField({
    required this.value,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<_BarcodeSearchField> createState() => _BarcodeSearchFieldState();
}

class _BarcodeSearchFieldState extends State<_BarcodeSearchField> {
  late final TextEditingController controller;
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: widget.value);
    focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant _BarcodeSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != controller.text) {
      controller.text = widget.value;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!focusNode.hasFocus) {
        focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: TextField(
          autofocus: true,
          focusNode: focusNode,
          controller: controller,
          onTap: focusNode.requestFocus,
          onChanged: widget.onChanged,
          onSubmitted: (value) {
            widget.onSubmitted(value);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              focusNode.requestFocus();
            });
          },
          decoration: InputDecoration(
            hintText: 'Passe o leitor aqui ou digite o produto...',
            prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
            suffixIcon: const Icon(Icons.keyboard_return_rounded),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductSaleCard extends StatelessWidget {
  const _ProductSaleCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final sales = context.read<SalesProvider>();
    final isLow = product.isLowStock;

    void addOne() {
      sales.addProduct(product);
      _showMessage(
        context,
        '${product.name} adicionado com 1 ${product.unit.label}.',
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: addOne,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.wine900,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        product.favorite
                            ? Icons.star_rounded
                            : Icons.shopping_bag_rounded,
                        color: AppColors.beige100,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        product.code,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatQuantity(product.stockQuantity, product.unit)} em estoque',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isLow ? AppColors.warning : null,
                    fontWeight: isLow ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatMoney(product.salePrice),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 21,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.beige100
                        : AppColors.wine700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: OutlinedButton(
                          onPressed: () =>
                              _openQuantityDialog(context, product),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Qtd',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: FilledButton(
                          onPressed: addOne,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            '+1',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, sales, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Carrinho',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${sales.items.length} item(ns)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: sales.items.isEmpty
                      ? const _EmptyCart()
                      : ListView.separated(
                          itemCount: sales.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _CartItemTile(item: sales.items[index]);
                          },
                        ),
                ),
                const SizedBox(height: 12),
                _PaymentSelector(
                  selected: sales.paymentMethod,
                  onChanged: sales.setPaymentMethod,
                ),
                const SizedBox(height: 12),
                _TotalBox(
                  subtotal: sales.subtotal,
                  discount: sales.discountAmount,
                  total: sales.total,
                  onDiscountTap: sales.hasItems
                      ? () => _openDiscountDialog(context)
                      : null,
                  onClearDiscount: sales.hasDiscount
                      ? sales.clearDiscount
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: sales.hasItems ? sales.clearCart : null,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text(
                          'Limpar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: sales.hasItems
                            ? () async {
                                final inventory = context
                                    .read<InventoryProvider>();
                                final customersProvider = context
                                    .read<CustomersProvider>();

                                Customer? selectedCustomer;

                                if (sales.paymentMethod ==
                                    PaymentMethod.fiado) {
                                  selectedCustomer =
                                      await _selectCustomerForFiado(context);

                                  if (selectedCustomer == null) {
                                    return;
                                  }
                                }

                                final validationError = inventory
                                    .validateSaleItems(sales.items);

                                if (validationError != null) {
                                  _showMessage(context, validationError);
                                  return;
                                }

                                final sale = sales.createSaleRecord(
                                  customerId: selectedCustomer?.id,
                                  customerName: selectedCustomer?.name,
                                );

                                if (sale == null) {
                                  _showMessage(
                                    context,
                                    'Adicione produtos ao carrinho.',
                                  );
                                  return;
                                }

                                final stockOk = inventory.deductSaleRecord(
                                  sale,
                                );

                                if (!stockOk) {
                                  _showMessage(
                                    context,
                                    'Não foi possível baixar o estoque.',
                                  );
                                  return;
                                }

                                sales.completeSale(sale);

                                syncSaleCashMovement(context, sale);

                                if (sale.paymentMethod == PaymentMethod.fiado &&
                                    selectedCustomer != null) {
                                  customersProvider.registerPurchase(
                                    sale,
                                    selectedCustomer,
                                  );
                                }

                                _showMessage(
                                  context,
                                  'Venda #${sale.shortId} finalizada.',
                                );

                                if (!context.mounted) return;

                                await showSaleReceiptDialog(context, sale);
                              }
                            : null,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text(
                          'Finalizar venda',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final SaleCartItem item;

  @override
  Widget build(BuildContext context) {
    final sales = context.read<SalesProvider>();
    final product = item.product;
    final quantity = item.quantity;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.beige100.withOpacity(0.06)
              : AppColors.wine900.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.wine900,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.shopping_basket_rounded,
                  color: AppColors.beige100,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _openCartQuantityDialog(context, item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatMoney(product.salePrice)} x ${_formatNumber(quantity)} ${product.unit.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatMoney(item.subtotal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Remover',
                visualDensity: VisualDensity.compact,
                onPressed: () => sales.removeItem(product.id),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 46,
                height: 40,
                child: OutlinedButton(
                  onPressed: () => sales.decreaseQuantity(product.id),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.remove_rounded, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _openCartQuantityDialog(context, item),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.beige100.withOpacity(0.08)
                          : AppColors.wine700.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _formatNumber(quantity),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 46,
                height: 40,
                child: FilledButton(
                  onPressed: () => sales.increaseQuantity(product.id),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.add_rounded, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentSelector extends StatelessWidget {
  const _PaymentSelector({required this.selected, required this.onChanged});

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PaymentMethod>(
      value: selected,
      decoration: InputDecoration(
        labelText: 'Forma de pagamento',
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
      items: PaymentMethod.values.map((method) {
        return DropdownMenuItem(value: method, child: Text(method.label));
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
    );
  }
}

class _TotalBox extends StatelessWidget {
  const _TotalBox({
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.onDiscountTap,
    required this.onClearDiscount,
  });

  final double subtotal;
  final double discount;
  final double total;
  final VoidCallback? onDiscountTap;
  final VoidCallback? onClearDiscount;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = discount > 0.004;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.wine900,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDiscount) ...[
            _TotalLine(label: 'Subtotal', value: _formatMoney(subtotal)),
            const SizedBox(height: 4),
            _TotalLine(label: 'Desconto', value: '- ${_formatMoney(discount)}'),
            const SizedBox(height: 8),
          ],
          const Text(
            'Total da venda',
            style: TextStyle(
              color: AppColors.beige100,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatMoney(total),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.beige100,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onDiscountTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.beige100,
                  side: const BorderSide(color: AppColors.beige100),
                ),
                icon: const Icon(Icons.percent_rounded),
                label: Text(hasDiscount ? 'Alterar desconto' : 'Dar desconto'),
              ),
              if (hasDiscount)
                TextButton.icon(
                  onPressed: onClearDiscount,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.beige100,
                  ),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Remover'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.beige100,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.beige100,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Adicione produtos para iniciar a venda.'));
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

Future<void> _openDiscountDialog(BuildContext context) async {
  final sales = context.read<SalesProvider>();
  final subtotal = sales.subtotal;

  if (subtotal <= 0) {
    _showMessage(context, 'Adicione produtos antes de dar desconto.');
    return;
  }

  final controller = TextEditingController(
    text: sales.discountAmount > 0
        ? sales.discountAmount.toStringAsFixed(2).replaceAll('.', ',')
        : '',
  );

  final discount = await showDialog<double>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Desconto na venda')),
            IconButton(
              tooltip: 'Fechar',
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Subtotal: ${_formatMoney(subtotal)}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Desconto em R\$',
                  hintText: 'Ex: 5,00',
                  prefixText: 'R\$ ',
                ),
                onSubmitted: (_) {
                  Navigator.of(
                    dialogContext,
                  ).pop(_parseMoneyInput(controller.text));
                },
              ),
              const SizedBox(height: 8),
              Text(
                'O desconto não pode ser maior que o subtotal.',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(0),
            child: const Text('Remover desconto'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(_parseMoneyInput(controller.text));
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Aplicar'),
          ),
        ],
      );
    },
  );

  if (discount == null) return;

  sales.setDiscountAmount(discount);

  _showMessage(
    context,
    sales.hasDiscount
        ? 'Desconto aplicado: ${_formatMoney(sales.discountAmount)}.'
        : 'Desconto removido.',
  );
}

double _parseMoneyInput(String value) {
  final normalized = value
      .trim()
      .replaceAll('R\$', '')
      .replaceAll(' ', '')
      .replaceAll('.', '')
      .replaceAll(',', '.');

  return double.tryParse(normalized) ?? 0;
}

Future<void> _handleSalesInput(BuildContext context, String value) async {
  final inventory = context.read<InventoryProvider>();
  final sales = context.read<SalesProvider>();
  final ramuzaSettings = context.read<RamuzaSettingsProvider>().settings;

  final parsed = RamuzaBarcodeParser.tryParse(value, ramuzaSettings);

  if (parsed != null) {
    var product = _findByRamuzaCode(inventory.products, parsed.productCode);

    if (product == null) {
      _showMessage(
        context,
        'Etiqueta lida. PLU ${parsed.productCode} ainda não está cadastrado.',
      );

      product = await showQuickProductFromBarcodeDialog(
        context: context,
        productCode: parsed.productCode,
        rawBarcode: parsed.digits,
        suggestedQuantity: parsed.quantity,
      );

      if (product == null) {
        _logRamuzaBarcodeRead(
          context: context,
          parsed: parsed,
          product: null,
          status: RamuzaBarcodeStatus.canceledQuickRegister,
          message:
              'PLU ${parsed.productCode} não cadastrado. Cadastro rápido cancelado.',
          screen: 'PDV',
        );

        sales.setSearchTerm('');
        return;
      }
    }

    if (product.isDeleted) {
      _logRamuzaBarcodeRead(
        context: context,
        parsed: parsed,
        product: product,
        status: RamuzaBarcodeStatus.productDeleted,
        message: 'Produto está na lixeira.',
        screen: 'PDV',
      );

      _showMessage(
        context,
        'Etiqueta lida. Produto ${product.name} está na lixeira.',
      );

      sales.setSearchTerm('');
      return;
    }

    final quantity = parsed.quantityForProduct(product);

    if (quantity == null || quantity <= 0) {
      _logRamuzaBarcodeRead(
        context: context,
        parsed: parsed,
        product: product,
        status: RamuzaBarcodeStatus.invalidQuantity,
        message: 'Não foi possível calcular a quantidade/valor.',
        screen: 'PDV',
      );

      _showMessage(
        context,
        'Etiqueta lida, mas não deu para calcular quantidade/valor.',
      );

      sales.setSearchTerm('');
      return;
    }

    if (product.stockQuantity <= 0) {
      _logRamuzaBarcodeRead(
        context: context,
        parsed: parsed,
        product: product,
        status: RamuzaBarcodeStatus.stockEmpty,
        message: 'Estoque zerado.',
        screen: 'PDV',
        quantity: quantity,
      );

      _showMessage(
        context,
        'Etiqueta lida: ${product.name}, mas o estoque está zerado.',
      );

      sales.setSearchTerm('');
      return;
    }

    final error = _validateQuantity(product, quantity);

    if (error != null) {
      _logRamuzaBarcodeRead(
        context: context,
        parsed: parsed,
        product: product,
        status: RamuzaBarcodeStatus.invalidQuantity,
        message: error,
        screen: 'PDV',
        quantity: quantity,
      );

      _showMessage(context, 'Etiqueta lida: ${product.name}. $error');

      sales.setSearchTerm('');
      return;
    }

    sales.addProduct(product, quantity: quantity);
    sales.setSearchTerm('');

    _logRamuzaBarcodeRead(
      context: context,
      parsed: parsed,
      product: product,
      status: RamuzaBarcodeStatus.success,
      message: 'Produto adicionado ao carrinho.',
      screen: 'PDV',
      quantity: quantity,
    );

    _showMessage(
      context,
      'Etiqueta OK: ${product.name} • ${_formatNumber(quantity)} ${product.unit.label}.',
    );

    return;
  }

  final product = _findByCodeOrName(inventory.products, value);

  if (product == null) {
    _showMessage(context, 'Produto não encontrado.');
    return;
  }

  sales.addProduct(product);
  sales.setSearchTerm('');

  _showMessage(
    context,
    '${product.name} adicionado com 1 ${product.unit.label}.',
  );
}

void _logRamuzaBarcodeRead({
  required BuildContext context,
  required RamuzaParsedBarcode parsed,
  required Product? product,
  required RamuzaBarcodeStatus status,
  required String message,
  required String screen,
  double? quantity,
}) {
  final now = DateTime.now();

  context.read<RamuzaBarcodeLogProvider>().addEvent(
    RamuzaBarcodeEvent(
      id: now.microsecondsSinceEpoch.toString(),
      rawBarcode: parsed.raw,
      digits: parsed.digits,
      productCode: parsed.productCode,
      productName: product?.name,
      quantity: quantity,
      totalPrice: parsed.totalPrice,
      status: status,
      message: message,
      screen: screen,
      createdAt: now,
    ),
  );
}

Product? _findByRamuzaCode(List<Product> products, String code) {
  final normalizedCode = _normalizeNumericCode(code);

  for (final product in products) {
    final productCode = _normalizeNumericCode(product.code);

    if (productCode == normalizedCode) {
      return product;
    }
  }

  return null;
}

String _normalizeNumericCode(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  final parsed = int.tryParse(digits);

  if (parsed == null) return digits;

  return parsed.toString();
}

Future<void> _openQuantityDialog(BuildContext context, Product product) async {
  final sales = context.read<SalesProvider>();
  final quantityController = TextEditingController(
    text: product.unit == ProductUnit.kg ? '1,000' : '1',
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Adicionar ${product.name}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Estoque disponível: ${_formatQuantity(product.stockQuantity, product.unit)}',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantidade (${product.unit.label})',
                  hintText: product.unit == ProductUnit.kg
                      ? 'Ex: 1,250'
                      : 'Ex: 2',
                  suffixText: product.unit.label,
                ),
                onSubmitted: (_) {
                  _confirmAddQuantity(
                    context: context,
                    dialogContext: dialogContext,
                    product: product,
                    sales: sales,
                    text: quantityController.text,
                  );
                },
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
            onPressed: () {
              _confirmAddQuantity(
                context: context,
                dialogContext: dialogContext,
                product: product,
                sales: sales,
                text: quantityController.text,
              );
            },
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('Adicionar'),
          ),
        ],
      );
    },
  );
}

void _confirmAddQuantity({
  required BuildContext context,
  required BuildContext dialogContext,
  required Product product,
  required SalesProvider sales,
  required String text,
}) {
  final quantity = _parseDouble(text);

  final error = _validateQuantity(product, quantity);

  if (error != null) {
    _showMessage(context, error);
    return;
  }

  sales.addProduct(product, quantity: quantity);

  Navigator.of(dialogContext).pop();

  _showMessage(
    context,
    '${product.name} adicionado: ${_formatNumber(quantity)} ${product.unit.label}.',
  );
}

Future<void> _openCartQuantityDialog(
  BuildContext context,
  SaleCartItem item,
) async {
  final sales = context.read<SalesProvider>();
  final product = item.product;

  final quantityController = TextEditingController(
    text: product.unit == ProductUnit.kg
        ? item.quantity.toStringAsFixed(3).replaceAll('.', ',')
        : item.quantity.toStringAsFixed(0),
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Alterar quantidade'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.name, style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                'Estoque disponível: ${_formatQuantity(product.stockQuantity, product.unit)}',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nova quantidade (${product.unit.label})',
                  hintText: product.unit == ProductUnit.kg
                      ? 'Ex: 0,750'
                      : 'Ex: 3',
                  suffixText: product.unit.label,
                ),
                onSubmitted: (_) {
                  _confirmUpdateCartQuantity(
                    context: context,
                    dialogContext: dialogContext,
                    product: product,
                    sales: sales,
                    text: quantityController.text,
                  );
                },
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
            onPressed: () {
              _confirmUpdateCartQuantity(
                context: context,
                dialogContext: dialogContext,
                product: product,
                sales: sales,
                text: quantityController.text,
              );
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text(
              'Salvar',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    },
  );
}

void _confirmUpdateCartQuantity({
  required BuildContext context,
  required BuildContext dialogContext,
  required Product product,
  required SalesProvider sales,
  required String text,
}) {
  final quantity = _parseDouble(text);

  final error = _validateQuantity(product, quantity);

  if (error != null) {
    _showMessage(context, error);
    return;
  }

  sales.updateQuantity(product.id, quantity);

  Navigator.of(dialogContext).pop();

  _showMessage(
    context,
    'Quantidade de ${product.name}: ${_formatNumber(quantity)} ${product.unit.label}.',
  );
}

String? _validateQuantity(Product product, double quantity) {
  if (quantity <= 0) {
    return 'Informe uma quantidade maior que zero.';
  }

  if (quantity > product.stockQuantity) {
    return 'Quantidade maior que o estoque disponível.';
  }

  if (product.unit != ProductUnit.kg && quantity % 1 != 0) {
    return 'Para unidade ou pacote, use número inteiro.';
  }

  return null;
}

Future<Customer?> _openQuickCustomerForFiadoDialog(BuildContext context) async {
  final provider = context.read<CustomersProvider>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();

  return showDialog<Customer>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Novo cliente fiado'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nome do cliente',
                  hintText: 'Ex: João Silva',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: 'Opcional',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  hintText: 'Opcional',
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
            icon: const Icon(Icons.person_add_alt_rounded),
            onPressed: () {
              final name = nameController.text.trim();

              if (name.isEmpty) {
                _showMessage(context, 'Informe o nome do cliente.');
                return;
              }

              final customer = provider.addCustomer(
                name: name,
                phone: phoneController.text.trim(),
                notes: notesController.text.trim(),
              );

              Navigator.of(dialogContext).pop(customer);
            },
            label: const Text('Criar e usar'),
          ),
        ],
      );
    },
  );
}

Future<Customer?> _selectCustomerForFiado(BuildContext context) async {
  return showDialog<Customer>(
    context: context,
    builder: (dialogContext) {
      return Consumer<CustomersProvider>(
        builder: (context, provider, _) {
          final customers = provider.customers;

          return AlertDialog(
            title: const Text('Selecionar cliente para fiado'),
            content: SizedBox(
              width: 640,
              height: 430,
              child: customers.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum cliente cadastrado. Cadastre um cliente na tela Fiado primeiro.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: customers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        final balance = provider.balanceForCustomer(
                          customer.id,
                        );

                        return Card(
                          child: ListTile(
                            onTap: () {
                              Navigator.of(dialogContext).pop(customer);
                            },
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.wine900,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.beige100,
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            subtitle: Text(
                              customer.phone == null || customer.phone!.isEmpty
                                  ? 'Sem telefone'
                                  : customer.phone!,
                            ),
                            trailing: Text(
                              _formatMoney(balance),
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final customer = await _openQuickCustomerForFiadoDialog(
                    context,
                  );

                  if (customer == null) return;
                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop(customer);
                },
                icon: const Icon(Icons.person_add_alt_rounded),
                label: const Text('Novo cliente'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      );
    },
  );
}

List<Product> _filterProducts(List<Product> products, String searchTerm) {
  final term = searchTerm.trim().toLowerCase();

  final availableProducts = products.where((product) {
    return !product.isDeleted && product.stockQuantity > 0;
  }).toList();

  if (term.isEmpty) {
    return availableProducts;
  }

  return availableProducts.where((product) {
    return product.name.toLowerCase().contains(term) ||
        product.code.toLowerCase().contains(term) ||
        product.category.label.toLowerCase().contains(term);
  }).toList();
}

List<Product> _filterProductsForRamuzaCode(
  List<Product> products,
  String code,
) {
  final normalizedCode = _normalizeNumericCode(code);

  return products.where((product) {
    if (product.isDeleted || product.stockQuantity <= 0) return false;

    return _normalizeNumericCode(product.code) == normalizedCode;
  }).toList();
}

Product? _findByCodeOrName(List<Product> products, String value) {
  final term = value.trim().toLowerCase();

  if (term.isEmpty) return null;

  try {
    return products.firstWhere((product) {
      return !product.isDeleted &&
          product.stockQuantity > 0 &&
          (product.code.toLowerCase() == term ||
              product.name.toLowerCase() == term);
    });
  } catch (_) {
    return null;
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

double _parseDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}
