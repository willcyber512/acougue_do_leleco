import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/product.dart';
import '../providers/customers_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/ramuza_barcode_log_provider.dart';
import '../providers/ramuza_settings_provider.dart';
import '../providers/sales_provider.dart';

Future<void> showSystemDiagnosticsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) {
      return const SystemDiagnosticsDialog();
    },
  );
}

class SystemDiagnosticsDialog extends StatelessWidget {
  const SystemDiagnosticsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final sales = context.watch<SalesProvider>();
    final customers = context.watch<CustomersProvider>();
    final ramuzaSettings = context.watch<RamuzaSettingsProvider>().settings;
    final ramuzaLog = context.watch<RamuzaBarcodeLogProvider>();

    final activeProducts = inventory.products.where((product) {
      return !product.isDeleted;
    }).toList();

    final lowStockProducts = activeProducts.where((product) {
      return product.isLowStock;
    }).toList();

    final emptyStockProducts = activeProducts.where((product) {
      return product.stockQuantity <= 0;
    }).toList();

    final noCodeProducts = activeProducts.where((product) {
      return product.code.trim().isEmpty;
    }).toList();

    final noPriceProducts = activeProducts.where((product) {
      return product.salePrice <= 0;
    }).toList();

    final duplicatedCodes = _duplicatedCodes(activeProducts);

    final issues = <_DiagnosticIssue>[
      if (activeProducts.isEmpty)
        const _DiagnosticIssue(
          level: _DiagnosticLevel.warning,
          title: 'Nenhum produto ativo',
          description: 'Cadastre produtos antes de usar vendas e leitor USB.',
        ),
      if (noCodeProducts.isNotEmpty)
        _DiagnosticIssue(
          level: _DiagnosticLevel.danger,
          title: 'Produtos sem código',
          description:
              '${noCodeProducts.length} produto(s) não têm código interno/PLU.',
        ),
      if (noPriceProducts.isNotEmpty)
        _DiagnosticIssue(
          level: _DiagnosticLevel.danger,
          title: 'Produtos com preço zerado',
          description:
              '${noPriceProducts.length} produto(s) estão com preço de venda zerado.',
        ),
      if (duplicatedCodes.isNotEmpty)
        _DiagnosticIssue(
          level: _DiagnosticLevel.danger,
          title: 'Códigos duplicados',
          description:
              '${duplicatedCodes.length} código(s) aparecem em mais de um produto.',
        ),
      if (lowStockProducts.isNotEmpty)
        _DiagnosticIssue(
          level: _DiagnosticLevel.warning,
          title: 'Estoque baixo',
          description:
              '${lowStockProducts.length} produto(s) estão no estoque mínimo ou abaixo.',
        ),
      if (!ramuzaSettings.enabled)
        const _DiagnosticIssue(
          level: _DiagnosticLevel.warning,
          title: 'Leitura de etiqueta desativada',
          description: 'A leitura de etiquetas está pronta para uso pelo leitor USB.',
        ),
      if (ramuzaLog.errorCount > ramuzaLog.successCount &&
          ramuzaLog.totalEvents > 0)
        _DiagnosticIssue(
          level: _DiagnosticLevel.warning,
          title: 'Muitas falhas de leitura',
          description:
              '${ramuzaLog.errorCount} falha(s) contra ${ramuzaLog.successCount} sucesso(s).',
        ),
    ];

    final criticalCount = issues.where((issue) {
      return issue.level == _DiagnosticLevel.danger;
    }).length;

    final warningCount = issues.where((issue) {
      return issue.level == _DiagnosticLevel.warning;
    }).length;

    final report = _buildReport(
      activeProducts: activeProducts,
      lowStockProducts: lowStockProducts,
      emptyStockProducts: emptyStockProducts,
      noCodeProducts: noCodeProducts,
      noPriceProducts: noPriceProducts,
      duplicatedCodes: duplicatedCodes,
      todaySalesCount: sales.todaySales.length,
      todayRevenue: sales.todayRevenue,
      totalOpenCredit: customers.totalOpenCredit,
      ramuzaEnabled: ramuzaSettings.enabled,
      ramuzaPrefix: ramuzaSettings.prefix,
      ramuzaExpectedLength: ramuzaSettings.expectedLength,
      ramuzaSuccess: ramuzaLog.successCount,
      ramuzaErrors: ramuzaLog.errorCount,
      issues: issues,
    );

    return AlertDialog(
      title: const Text('Central de Diagnóstico'),
      content: SizedBox(
        width: 1000,
        height: 680,
        child: Column(
          children: [
            _HealthHeader(
              criticalCount: criticalCount,
              warningCount: warningCount,
              issuesCount: issues.length,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _MetricsPanel(
                      activeProducts: activeProducts.length,
                      lowStockProducts: lowStockProducts.length,
                      emptyStockProducts: emptyStockProducts.length,
                      todaySalesCount: sales.todaySales.length,
                      todayRevenue: sales.todayRevenue,
                      totalOpenCredit: customers.totalOpenCredit,
                      ramuzaEnabled: ramuzaSettings.enabled,
                      ramuzaExpectedLength: ramuzaSettings.expectedLength,
                      ramuzaSuccess: ramuzaLog.successCount,
                      ramuzaErrors: ramuzaLog.errorCount,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _IssuesPanel(
                      issues: issues,
                      noCodeProducts: noCodeProducts,
                      noPriceProducts: noPriceProducts,
                      duplicatedCodes: duplicatedCodes,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: report));

            if (!context.mounted) return;

            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Relatório de diagnóstico copiado.'),
                ),
              );
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copiar relatório'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _HealthHeader extends StatelessWidget {
  const _HealthHeader({
    required this.criticalCount,
    required this.warningCount,
    required this.issuesCount,
  });

  final int criticalCount;
  final int warningCount;
  final int issuesCount;

  @override
  Widget build(BuildContext context) {
    final color = criticalCount > 0
        ? AppColors.danger
        : warningCount > 0
            ? AppColors.warning
            : AppColors.success;

    final title = criticalCount > 0
        ? 'Atenção: existem problemas críticos'
        : warningCount > 0
            ? 'Sistema funcionando, mas com avisos'
            : 'Sistema saudável';

    final subtitle = issuesCount == 0
        ? 'Nenhum problema encontrado nos dados principais.'
        : '$criticalCount crítico(s) e $warningCount aviso(s) encontrados.';

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                criticalCount > 0
                    ? Icons.error_rounded
                    : warningCount > 0
                        ? Icons.warning_rounded
                        : Icons.check_circle_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({
    required this.activeProducts,
    required this.lowStockProducts,
    required this.emptyStockProducts,
    required this.todaySalesCount,
    required this.todayRevenue,
    required this.totalOpenCredit,
    required this.ramuzaEnabled,
    required this.ramuzaExpectedLength,
    required this.ramuzaSuccess,
    required this.ramuzaErrors,
  });

  final int activeProducts;
  final int lowStockProducts;
  final int emptyStockProducts;
  final int todaySalesCount;
  final double todayRevenue;
  final double totalOpenCredit;
  final bool ramuzaEnabled;
  final int ramuzaExpectedLength;
  final int ramuzaSuccess;
  final int ramuzaErrors;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Resumo do sistema',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          _MetricTile(
            icon: Icons.inventory_2_rounded,
            label: 'Produtos ativos',
            value: activeProducts.toString(),
          ),
          _MetricTile(
            icon: Icons.warning_rounded,
            label: 'Produtos em estoque baixo',
            value: lowStockProducts.toString(),
          ),
          _MetricTile(
            icon: Icons.remove_shopping_cart_rounded,
            label: 'Produtos zerados',
            value: emptyStockProducts.toString(),
          ),
          _MetricTile(
            icon: Icons.point_of_sale_rounded,
            label: 'Vendas hoje',
            value: todaySalesCount.toString(),
          ),
          _MetricTile(
            icon: Icons.payments_rounded,
            label: 'Faturamento hoje',
            value: _formatMoney(todayRevenue),
          ),
          _MetricTile(
            icon: Icons.person_rounded,
            label: 'Fiado aberto',
            value: _formatMoney(totalOpenCredit),
          ),
          _MetricTile(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Leitor ativo',
            value: ramuzaEnabled ? 'Sim' : 'Não',
          ),
          _MetricTile(
            icon: Icons.straighten_rounded,
            label: 'Tamanho da etiqueta',
            value: '$ramuzaExpectedLength dígitos',
          ),
          _MetricTile(
            icon: Icons.check_circle_rounded,
            label: 'Leituras de etiqueta OK',
            value: ramuzaSuccess.toString(),
          ),
          _MetricTile(
            icon: Icons.error_rounded,
            label: 'Leituras de etiqueta com falha',
            value: ramuzaErrors.toString(),
          ),
        ],
      ),
    );
  }
}

class _IssuesPanel extends StatelessWidget {
  const _IssuesPanel({
    required this.issues,
    required this.noCodeProducts,
    required this.noPriceProducts,
    required this.duplicatedCodes,
  });

  final List<_DiagnosticIssue> issues;
  final List<Product> noCodeProducts;
  final List<Product> noPriceProducts;
  final Map<String, List<Product>> duplicatedCodes;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return const Card(
        child: Center(
          child: Text(
            'Nenhum problema encontrado.',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );
    }

    return Card(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Problemas e avisos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 12),
          ...issues.map((issue) {
            return _IssueTile(issue: issue);
          }),
          if (noCodeProducts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailsBox(
              title: 'Produtos sem código',
              lines: noCodeProducts.map((product) => product.name).toList(),
            ),
          ],
          if (noPriceProducts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailsBox(
              title: 'Produtos com preço zerado',
              lines: noPriceProducts.map((product) => product.name).toList(),
            ),
          ],
          if (duplicatedCodes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailsBox(
              title: 'Códigos duplicados',
              lines: duplicatedCodes.entries.map((entry) {
                final names = entry.value.map((product) => product.name).join(', ');
                return '${entry.key}: $names';
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final _DiagnosticIssue issue;

  @override
  Widget build(BuildContext context) {
    final color = issue.level == _DiagnosticLevel.danger
        ? AppColors.danger
        : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            issue.level == _DiagnosticLevel.danger
                ? Icons.error_rounded
                : Icons.warning_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  issue.description,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsBox extends StatelessWidget {
  const _DetailsBox({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      children: lines.map((line) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SelectableText(line),
          ),
        );
      }).toList(),
    );
  }
}

enum _DiagnosticLevel {
  warning,
  danger,
}

class _DiagnosticIssue {
  const _DiagnosticIssue({
    required this.level,
    required this.title,
    required this.description,
  });

  final _DiagnosticLevel level;
  final String title;
  final String description;
}

Map<String, List<Product>> _duplicatedCodes(List<Product> products) {
  final map = <String, List<Product>>{};

  for (final product in products) {
    final code = _normalizeCode(product.code);

    if (code.isEmpty) continue;

    map.putIfAbsent(code, () => []).add(product);
  }

  map.removeWhere((_, products) => products.length < 2);

  return map;
}

String _normalizeCode(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

  if (digits.isEmpty) return '';

  final parsed = int.tryParse(digits);

  return parsed?.toString() ?? digits;
}

String _buildReport({
  required List<Product> activeProducts,
  required List<Product> lowStockProducts,
  required List<Product> emptyStockProducts,
  required List<Product> noCodeProducts,
  required List<Product> noPriceProducts,
  required Map<String, List<Product>> duplicatedCodes,
  required int todaySalesCount,
  required double todayRevenue,
  required double totalOpenCredit,
  required bool ramuzaEnabled,
  required String ramuzaPrefix,
  required int ramuzaExpectedLength,
  required int ramuzaSuccess,
  required int ramuzaErrors,
  required List<_DiagnosticIssue> issues,
}) {
  final now = DateTime.now();

  final buffer = StringBuffer();

  buffer.writeln('DIAGNÓSTICO - ${AppConstants.appName}');
  buffer.writeln('Versão: ${AppConstants.appVersion}');
  buffer.writeln('Data: ${_formatDateTime(now)}');
  buffer.writeln('');
  buffer.writeln('RESUMO');
  buffer.writeln('Produtos ativos: ${activeProducts.length}');
  buffer.writeln('Produtos em estoque baixo: ${lowStockProducts.length}');
  buffer.writeln('Produtos zerados: ${emptyStockProducts.length}');
  buffer.writeln('Produtos sem código: ${noCodeProducts.length}');
  buffer.writeln('Produtos com preço zerado: ${noPriceProducts.length}');
  buffer.writeln('Códigos duplicados: ${duplicatedCodes.length}');
  buffer.writeln('Vendas hoje: $todaySalesCount');
  buffer.writeln('Faturamento hoje: ${_formatMoney(todayRevenue)}');
  buffer.writeln('Fiado aberto: ${_formatMoney(totalOpenCredit)}');
  buffer.writeln('');
  buffer.writeln('RAMUZA');
  buffer.writeln('Leitura ativa: ${ramuzaEnabled ? 'Sim' : 'Não'}');
  buffer.writeln('Prefixo: $ramuzaPrefix');
  buffer.writeln('Tamanho esperado: $ramuzaExpectedLength dígitos');
  buffer.writeln('Leituras OK: $ramuzaSuccess');
  buffer.writeln('Leituras com falha: $ramuzaErrors');
  buffer.writeln('');
  buffer.writeln('PROBLEMAS');

  if (issues.isEmpty) {
    buffer.writeln('Nenhum problema encontrado.');
  } else {
    for (final issue in issues) {
      buffer.writeln('- ${issue.title}: ${issue.description}');
    }
  }

  if (duplicatedCodes.isNotEmpty) {
    buffer.writeln('');
    buffer.writeln('CÓDIGOS DUPLICADOS');

    for (final entry in duplicatedCodes.entries) {
      final names = entry.value.map((product) => product.name).join(', ');
      buffer.writeln('${entry.key}: $names');
    }
  }

  return buffer.toString();
}

String _formatMoney(double value) {
  final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixed';
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}
