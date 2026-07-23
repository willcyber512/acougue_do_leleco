import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/inventory_event.dart';
import '../../models/inventory_loss.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/product_unit.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/leleco_metric_card.dart';
import '../../widgets/product_detail_dialog.dart';
import '../../widgets/easy_help_card.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, _) {
        if (inventory.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = inventory.filteredProducts;

        return LayoutBuilder(
          builder: (context, constraints) {
            final metricWidth = constraints.maxWidth < 520
                ? constraints.maxWidth
                : constraints.maxWidth < 980
                ? (constraints.maxWidth - 16) / 2
                : 215.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: metricWidth,
                        child: LelecoMetricCard(
                          icon: Icons.inventory_2_rounded,
                          title: 'Produtos',
                          value: inventory.totalProducts.toString(),
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: LelecoMetricCard(
                          icon: Icons.warning_rounded,
                          title: 'Estoque baixo',
                          value: inventory.lowStockCount.toString(),
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: LelecoMetricCard(
                          icon: Icons.remove_circle_rounded,
                          title: 'Perdas',
                          value: inventory.lossesCount.toString(),
                          footer: _formatMoney(inventory.lossesEstimatedValue),
                        ),
                      ),
                      SizedBox(
                        width: metricWidth,
                        child: LelecoMetricCard(
                          icon: Icons.history_rounded,
                          title: 'Registros',
                          value: inventory.eventsCount.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const EasyHelpCard(
                    title: 'Estoque fácil',
                    subtitle:
                        'Use para cadastrar produtos, preços, códigos e estoque mínimo.',
                    icon: Icons.inventory_2_rounded,
                    steps: [
                      EasyHelpStep(
                        title: 'Cadastre o produto',
                        description:
                            'Clique em Novo produto e coloque nome, categoria e unidade.',
                        icon: Icons.add_box_rounded,
                      ),
                      EasyHelpStep(
                        title: 'Preencha o código',
                        description:
                            'Use o mesmo código/PLU da etiqueta quando tiver balança.',
                        icon: Icons.qr_code_rounded,
                      ),
                      EasyHelpStep(
                        title: 'Confira preço e estoque',
                        description:
                            'Coloque preço de venda, estoque atual e estoque mínimo.',
                        icon: Icons.price_check_rounded,
                      ),
                      EasyHelpStep(
                        title: 'Acompanhe avisos',
                        description:
                            'Produtos com estoque baixo aparecem em destaque.',
                        icon: Icons.warning_rounded,
                      ),
                    ],
                    footer:
                        'Dica: para vender por etiqueta, o produto precisa ter o mesmo código/PLU usado na balança.',
                  ),
                  const SizedBox(height: 16),
                  _InventoryToolbar(inventory: inventory),
                  if (inventory.lowStockCount > 0) ...[
                    const SizedBox(height: 16),
                    _LowStockWarning(count: inventory.lowStockCount),
                  ],
                  const SizedBox(height: 16),
                  if (products.isEmpty)
                    const SizedBox(height: 260, child: _EmptyInventory())
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _ProductListCard(product: products[index]);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InventoryToolbar extends StatelessWidget {
  const _InventoryToolbar({required this.inventory});

  final InventoryProvider inventory;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 360,
          child: TextField(
            onChanged: inventory.setSearchTerm,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, código ou categoria...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            value: inventory.selectedCategory?.name ?? 'all',
            decoration: InputDecoration(
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: 'all',
                child: Text('Todas categorias'),
              ),
              ...ProductCategory.values.map(
                (category) => DropdownMenuItem(
                  value: category.name,
                  child: Text(category.label),
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null || value == 'all') {
                inventory.setCategory(null);
                return;
              }

              final category = ProductCategory.values.firstWhere(
                (item) => item.name == value,
              );

              inventory.setCategory(category);
            },
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _openLossesDialog(context),
          icon: const Icon(Icons.remove_circle_outline_rounded),
          label: const Text('Perdas'),
        ),
        OutlinedButton.icon(
          onPressed: () => _openHistoryDialog(context),
          icon: const Icon(Icons.history_rounded),
          label: const Text('Histórico'),
        ),
        OutlinedButton.icon(
          onPressed: () => _openTrashDialog(context),
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text('Lixeira (${inventory.deletedProductsCount})'),
        ),
        FilledButton.icon(
          onPressed: () => _openProductDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Novo produto'),
        ),
      ],
    );
  }
}

class _LowStockWarning extends StatelessWidget {
  const _LowStockWarning({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count produto(s) precisam de atenção no estoque.',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductListCard extends StatelessWidget {
  const _ProductListCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final inventory = context.read<InventoryProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Icon(
                    product.favorite
                        ? Icons.star_rounded
                        : Icons.inventory_2_rounded,
                    color: AppColors.beige100,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => showProductDetailDialog(context, product),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Código ${product.code} • ${product.category.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _StockChip(product: product),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ProductInfoBox(
                  icon: Icons.sell_rounded,
                  label: 'Preço',
                  value: _formatMoney(product.salePrice),
                ),
                _ProductInfoBox(
                  icon: Icons.payments_rounded,
                  label: 'Custo',
                  value: _formatMoney(product.costPrice),
                ),
                _ProductInfoBox(
                  icon: Icons.inventory_rounded,
                  label: 'Estoque',
                  value: _formatQuantity(product.stockQuantity, product.unit),
                ),
                _ProductInfoBox(
                  icon: Icons.warning_amber_rounded,
                  label: 'Mínimo',
                  value: _formatQuantity(product.minStock, product.unit),
                ),
              ],
            ),
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Favoritar',
                    onPressed: () => inventory.toggleFavorite(product.id),
                    icon: Icon(
                      product.favorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Repor estoque',
                    onPressed: () => _openReplenishDialog(context, product),
                    icon: const Icon(Icons.add_box_rounded),
                  ),
                  IconButton(
                    tooltip: 'Registrar perda',
                    onPressed: () => _openLossDialog(context, product),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  IconButton(
                    tooltip: 'Ficha do produto',
                    onPressed: () => showProductDetailDialog(context, product),
                    icon: const Icon(Icons.badge_rounded),
                  ),
                  IconButton(
                    tooltip: 'Editar produto',
                    onPressed: () =>
                        _openProductDialog(context, product: product),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  IconButton(
                    tooltip: 'Mover para lixeira',
                    onPressed: () => _moveProductToTrash(context, product),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductInfoBox extends StatelessWidget {
  const _ProductInfoBox({
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

    return Container(
      width: 156,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.wine900.withOpacity(isDark ? 0.22 : 0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.wine700, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.beige100.withOpacity(0.72)
                        : AppColors.wine700,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final isLow = product.isLowStock;

    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.warning.withOpacity(0.16)
            : AppColors.success.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isLow ? 'Baixo' : 'Ok',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isLow ? AppColors.warning : AppColors.success,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Nenhum produto encontrado.',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

Future<void> _openProductDialog(
  BuildContext context, {
  Product? product,
}) async {
  final inventory = context.read<InventoryProvider>();

  final codeController = TextEditingController(text: product?.code ?? '');
  final nameController = TextEditingController(text: product?.name ?? '');
  final imagePathController = TextEditingController(
    text: product?.imagePath ?? '',
  );
  final salePriceController = TextEditingController(
    text: product == null ? '' : product.salePrice.toStringAsFixed(2),
  );
  final costPriceController = TextEditingController(
    text: product == null ? '' : product.costPrice.toStringAsFixed(2),
  );
  final stockController = TextEditingController(
    text: product == null ? '' : product.stockQuantity.toString(),
  );
  final minStockController = TextEditingController(
    text: product == null ? '' : product.minStock.toString(),
  );

  var category = product?.category ?? ProductCategory.bovina;
  var unit = product?.unit ?? ProductUnit.kg;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(product == null ? 'Novo produto' : 'Editar produto'),
            content: SizedBox(
              width: 640,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeController,
                            decoration: const InputDecoration(
                              labelText: 'Código interno',
                              hintText: 'Ex: 1001',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do produto',
                              hintText: 'Ex: Picanha',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: imagePathController,
                      decoration: const InputDecoration(
                        labelText: 'Foto do produto',
                        hintText:
                            'URL da imagem ou caminho do asset. Opcional.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ProductCategory>(
                            value: category,
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                            ),
                            items: ProductCategory.values.map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() => category = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<ProductUnit>(
                            value: unit,
                            decoration: const InputDecoration(
                              labelText: 'Unidade',
                            ),
                            items: ProductUnit.values.map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item.label),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() => unit = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: salePriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Preço de venda ao cliente',
                              hintText: 'Ex: 39,90',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: costPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Preço de custo do açougue',
                              hintText: 'Ex: 29,00',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Estoque atual',
                              hintText: 'Ex: 10',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: minStockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Estoque mínimo para aviso',
                              hintText: 'Ex: 5',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final code = codeController.text.trim();
                  final name = nameController.text.trim();

                  if (code.isEmpty || name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preencha código e nome do produto.'),
                      ),
                    );
                    return;
                  }

                  final now = DateTime.now();

                  final newProduct = Product(
                    id: product?.id ?? now.microsecondsSinceEpoch.toString(),
                    code: code,
                    name: name,
                    category: category,
                    unit: unit,
                    salePrice: _parseDouble(salePriceController.text),
                    costPrice: _parseDouble(costPriceController.text),
                    stockQuantity: _parseDouble(stockController.text),
                    minStock: _parseDouble(minStockController.text),
                    favorite: product?.favorite ?? false,
                    imagePath: imagePathController.text.trim().isEmpty
                        ? null
                        : imagePathController.text.trim(),
                    createdAt: product?.createdAt ?? now,
                    updatedAt: now,
                    deletedAt: product?.deletedAt,
                  );

                  if (product == null) {
                    inventory.addProduct(newProduct);
                  } else {
                    inventory.updateProduct(newProduct);
                  }

                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _openReplenishDialog(BuildContext context, Product product) async {
  final inventory = context.read<InventoryProvider>();
  final quantityController = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Repor ${product.name}'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantidade para adicionar (${product.unit.label})',
              hintText: 'Ex: 10',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final quantity = _parseDouble(quantityController.text);
              inventory.replenishProduct(product.id, quantity);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Repor'),
          ),
        ],
      );
    },
  );
}

Future<void> _openLossDialog(BuildContext context, Product product) async {
  final inventory = context.read<InventoryProvider>();
  final quantityController = TextEditingController();
  final reasonController = TextEditingController();

  var type = InventoryLossType.discarded;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Registrar perda: ${product.name}'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Estoque atual: ${_formatQuantity(product.stockQuantity, product.unit)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantidade perdida (${product.unit.label})',
                      hintText: 'Ex: 1,5',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<InventoryLossType>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Motivo da perda',
                    ),
                    items: InventoryLossType.values.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => type = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observação',
                      hintText: 'Ex: produto vencido no balcão',
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
                  final quantity = _parseDouble(quantityController.text);
                  final reason = reasonController.text.trim().isEmpty
                      ? type.label
                      : reasonController.text.trim();

                  final success = inventory.registerLoss(
                    productId: product.id,
                    quantity: quantity,
                    type: type,
                    reason: reason,
                  );

                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Não foi possível registrar a perda.'),
                      ),
                    );
                    return;
                  }

                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Registrar'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _moveProductToTrash(BuildContext context, Product product) {
  final inventory = context.read<InventoryProvider>();

  inventory.moveProductToTrash(product.id);

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text('${product.name} foi movido para a lixeira.'),
        action: SnackBarAction(
          label: 'DESFAZER',
          onPressed: () => inventory.restoreProduct(product.id),
        ),
      ),
    );
}

Future<void> _openLossesDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Consumer<InventoryProvider>(
        builder: (context, inventory, _) {
          final losses = inventory.losses;

          return AlertDialog(
            title: const Text('Controle de perdas'),
            content: SizedBox(
              width: 800,
              height: 460,
              child: losses.isEmpty
                  ? const Center(child: Text('Nenhuma perda registrada.'))
                  : ListView.separated(
                      itemCount: losses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _LossCard(loss: losses[index]);
                      },
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

class _LossCard extends StatelessWidget {
  const _LossCard({required this.loss});

  final InventoryLoss loss;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
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
                Icons.remove_circle_outline_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loss.productName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loss.type.label} • ${_formatNumber(loss.quantity)} ${loss.unitLabel} • ${loss.reason}',
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Código ${loss.productCode} • Valor estimado ${_formatMoney(loss.estimatedValue)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDateTime(loss.createdAt),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openHistoryDialog(
  BuildContext context, {
  Product? product,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Consumer<InventoryProvider>(
        builder: (context, inventory, _) {
          final events = product == null
              ? inventory.events
              : inventory.eventsForProduct(product.id);

          return AlertDialog(
            title: Text(
              product == null
                  ? 'Histórico do estoque'
                  : 'Histórico de ${product.name}',
            ),
            content: SizedBox(
              width: 760,
              height: 460,
              child: events.isEmpty
                  ? const Center(child: Text('Nenhum registro encontrado.'))
                  : ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _HistoryCard(event: events[index]);
                      },
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.event});

  final InventoryEvent event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
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
              child: Icon(_eventIcon(event.type), color: AppColors.beige100),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.type.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(event.description),
                  if (event.productCode != null &&
                      event.productName != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Código ${event.productCode} • ${event.productName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatDateTime(event.createdAt),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openTrashDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Consumer<InventoryProvider>(
        builder: (context, inventory, _) {
          final deletedProducts = inventory.deletedProducts;

          return AlertDialog(
            title: const Text('Lixeira de produtos'),
            content: SizedBox(
              width: 720,
              height: 430,
              child: deletedProducts.isEmpty
                  ? const Center(child: Text('A lixeira está vazia.'))
                  : ListView.separated(
                      itemCount: deletedProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final product = deletedProducts[index];

                        return Card(
                          child: Padding(
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
                                    Icons.delete_outline_rounded,
                                    color: AppColors.beige100,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Código ${product.code} • Excluído em ${_formatDateTime(product.deletedAt)}',
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Restaurar',
                                  onPressed: () {
                                    inventory.restoreProduct(product.id);
                                  },
                                  icon: const Icon(Icons.restore_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Excluir definitivamente',
                                  onPressed: () async {
                                    final confirmed = await _confirmAction(
                                      context,
                                      title: 'Excluir definitivamente?',
                                      message:
                                          'O produto "${product.name}" será removido para sempre.',
                                    );

                                    if (!confirmed) return;

                                    inventory.deleteProductForever(product.id);
                                  },
                                  icon: const Icon(
                                    Icons.delete_forever_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: deletedProducts.isEmpty
                    ? null
                    : () async {
                        final confirmed = await _confirmAction(
                          context,
                          title: 'Esvaziar lixeira?',
                          message:
                              'Todos os produtos da lixeira serão removidos definitivamente.',
                        );

                        if (!confirmed) return;

                        inventory.emptyTrash();
                      },
                child: const Text('Esvaziar lixeira'),
              ),
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

Future<bool> _confirmAction(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

IconData _eventIcon(InventoryEventType type) {
  switch (type) {
    case InventoryEventType.created:
      return Icons.add_circle_rounded;
    case InventoryEventType.updated:
      return Icons.edit_rounded;
    case InventoryEventType.favorited:
      return Icons.star_rounded;
    case InventoryEventType.unfavorited:
      return Icons.star_border_rounded;
    case InventoryEventType.replenished:
      return Icons.add_box_rounded;
    case InventoryEventType.saleDeducted:
      return Icons.point_of_sale_rounded;
    case InventoryEventType.saleRestored:
      return Icons.undo_rounded;
    case InventoryEventType.lossRegistered:
      return Icons.remove_circle_outline_rounded;
    case InventoryEventType.movedToTrash:
      return Icons.delete_outline_rounded;
    case InventoryEventType.restored:
      return Icons.restore_rounded;
    case InventoryEventType.deletedForever:
      return Icons.delete_forever_rounded;
    case InventoryEventType.emptiedTrash:
      return Icons.cleaning_services_rounded;
  }
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
  return value.toStringAsFixed(3).replaceAll('.', ',');
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';

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
  final normalized = value.trim().replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}
