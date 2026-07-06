import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/inventory_provider.dart';
import '../sales/quick_weight_sale_screen.dart';
import 'usb_scanner_test_screen.dart';

class HardwareCenterScreen extends StatelessWidget {
  const HardwareCenterScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final inventory = context.watch<InventoryProvider>();
    final products = inventory.products;
    final diagnostics = _UsbProductsDiagnostics.fromProducts(products);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Leitor USB e etiquetas'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: colorScheme.onPrimary,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leitor USB e etiquetas da balança',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'A balança gera a etiqueta, o leitor USB envia o código e o sistema registra a venda.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _MainActionCard(
            icon: Icons.point_of_sale_rounded,
            title: 'Venda por etiqueta',
            subtitle:
                'Tela principal para passar o leitor USB, adicionar itens na venda e finalizar com baixa no estoque.',
            buttonText: 'Abrir venda por etiqueta',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuickWeightSaleScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _MainActionCard(
            icon: Icons.usb_rounded,
            title: 'Teste do leitor USB',
            subtitle:
                'Use quando o leitor chegar para confirmar se ele está enviando os números da etiqueta para o sistema.',
            buttonText: 'Testar leitor',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const UsbScannerTestScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _DiagnosticsCard(diagnostics: diagnostics),
          const SizedBox(height: 16),
          const _FlowCard(),
          const SizedBox(height: 16),
          const _TipsCard(),
        ],
      ),
    );
  }
}

class _MainActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const _MainActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(icon, color: colorScheme.onSecondaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(buttonText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({
    required this.diagnostics,
  });

  final _UsbProductsDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allOk = diagnostics.issues.isEmpty && diagnostics.readyCount > 0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      allOk ? Colors.green.withOpacity(0.14) : colorScheme.errorContainer,
                  child: Icon(
                    allOk ? Icons.check_rounded : Icons.warning_amber_rounded,
                    color: allOk ? Colors.green.shade800 : colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Diagnóstico dos produtos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Confere se os produtos estão prontos para serem lidos pelas etiquetas da balança.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricChip(
                  label: 'Produtos',
                  value: '${diagnostics.totalProducts}',
                  icon: Icons.inventory_2_rounded,
                ),
                _MetricChip(
                  label: 'Prontos',
                  value: '${diagnostics.readyCount}',
                  icon: Icons.verified_rounded,
                ),
                _MetricChip(
                  label: 'Sem código',
                  value: '${diagnostics.withoutCode.length}',
                  icon: Icons.qr_code_2_rounded,
                ),
                _MetricChip(
                  label: 'Código duplicado',
                  value: '${diagnostics.duplicateProducts.length}',
                  icon: Icons.copy_rounded,
                ),
                _MetricChip(
                  label: 'Preço zerado',
                  value: '${diagnostics.zeroPrice.length}',
                  icon: Icons.price_change_rounded,
                ),
                _MetricChip(
                  label: 'Sem estoque',
                  value: '${diagnostics.zeroStock.length}',
                  icon: Icons.remove_shopping_cart_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (diagnostics.totalProducts == 0)
              const _StatusBox(
                icon: Icons.info_outline_rounded,
                text:
                    'Nenhum produto cadastrado ainda. Cadastre os produtos no estoque usando o mesmo código/PLU da balança.',
              )
            else if (allOk)
              const _StatusBox(
                icon: Icons.check_circle_outline_rounded,
                text:
                    'Tudo certo. Os produtos têm código/PLU, preço e estoque para funcionar com o leitor USB.',
              )
            else ...[
              for (final issue in diagnostics.issues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StatusBox(
                    icon: issue.icon,
                    text: issue.message,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard();

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Cadastrar o produto na balança com PLU e preço por kg.',
      'Cadastrar o mesmo produto no sistema com o mesmo código.',
      'A balança imprime a etiqueta.',
      'O leitor USB lê o código e joga no sistema.',
      'O funcionário confere e finaliza a venda.',
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fluxo correto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      child: Text('${i + 1}'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(steps[i])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Quando o leitor USB chegar, ele deve funcionar como teclado. É só clicar no campo de código e passar a etiqueta. Para testar agora, use o botão "Gerar etiqueta teste".',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsbProductsDiagnostics {
  const _UsbProductsDiagnostics({
    required this.totalProducts,
    required this.readyCount,
    required this.withoutCode,
    required this.zeroPrice,
    required this.zeroStock,
    required this.duplicateProducts,
    required this.issues,
  });

  final int totalProducts;
  final int readyCount;
  final List<Product> withoutCode;
  final List<Product> zeroPrice;
  final List<Product> zeroStock;
  final List<Product> duplicateProducts;
  final List<_DiagnosticIssue> issues;

  factory _UsbProductsDiagnostics.fromProducts(List<Product> products) {
    final withoutCode = <Product>[];
    final zeroPrice = <Product>[];
    final zeroStock = <Product>[];
    final duplicateProducts = <Product>[];
    final codeMap = <String, List<Product>>{};

    for (final product in products) {
      final normalizedCode = _normalizeProductCode(product.code);

      if (normalizedCode.isEmpty) {
        withoutCode.add(product);
      } else {
        codeMap.putIfAbsent(normalizedCode, () => []).add(product);
      }

      if (product.salePrice <= 0) {
        zeroPrice.add(product);
      }

      if (product.stockQuantity <= 0) {
        zeroStock.add(product);
      }
    }

    for (final entry in codeMap.entries) {
      if (entry.value.length > 1) {
        duplicateProducts.addAll(entry.value);
      }
    }

    final issues = <_DiagnosticIssue>[];

    if (withoutCode.isNotEmpty) {
      issues.add(
        _DiagnosticIssue(
          icon: Icons.qr_code_2_rounded,
          message:
              '${withoutCode.length} produto(s) estão sem código/PLU. Eles não serão encontrados pela etiqueta da balança.',
        ),
      );
    }

    if (duplicateProducts.isNotEmpty) {
      issues.add(
        _DiagnosticIssue(
          icon: Icons.copy_rounded,
          message:
              '${duplicateProducts.length} produto(s) estão com código/PLU duplicado. Cada produto precisa ter um código único.',
        ),
      );
    }

    if (zeroPrice.isNotEmpty) {
      issues.add(
        _DiagnosticIssue(
          icon: Icons.price_change_rounded,
          message:
              '${zeroPrice.length} produto(s) estão com preço de venda zerado. A venda por etiqueta precisa do preço correto.',
        ),
      );
    }

    if (zeroStock.isNotEmpty) {
      issues.add(
        _DiagnosticIssue(
          icon: Icons.inventory_2_rounded,
          message:
              '${zeroStock.length} produto(s) estão sem estoque. Eles podem ser lidos, mas não vão finalizar venda até repor.',
        ),
      );
    }

    final readyCount = products.where((product) {
      final normalizedCode = _normalizeProductCode(product.code);
      final duplicated = normalizedCode.isNotEmpty &&
          (codeMap[normalizedCode]?.length ?? 0) > 1;

      return normalizedCode.isNotEmpty &&
          !duplicated &&
          product.salePrice > 0 &&
          product.stockQuantity > 0;
    }).length;

    return _UsbProductsDiagnostics(
      totalProducts: products.length,
      readyCount: readyCount,
      withoutCode: withoutCode,
      zeroPrice: zeroPrice,
      zeroStock: zeroStock,
      duplicateProducts: duplicateProducts,
      issues: issues,
    );
  }

  static String _normalizeProductCode(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return '';

    if (digits.length > 6) {
      return digits.substring(digits.length - 6);
    }

    return digits.padLeft(6, '0');
  }
}

class _DiagnosticIssue {
  const _DiagnosticIssue({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;
}
