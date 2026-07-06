import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/product.dart';
import '../models/ramuza_barcode_settings.dart';
import '../providers/inventory_provider.dart';
import '../providers/ramuza_barcode_log_provider.dart';
import '../providers/ramuza_settings_provider.dart';
import '../services/ramuza_export_service.dart';
import 'ramuza_barcode_config_dialog.dart';
import 'ramuza_barcode_history_dialog.dart';
import 'ramuza_export_dialog.dart';
import 'ramuza_hardware_test_dialog.dart';

Future<void> showbalançaIntegrationCenterDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const balançaIntegrationCenterDialog(),
  );
}

class balançaIntegrationCenterDialog extends StatelessWidget {
  const balançaIntegrationCenterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final settings = context.watch<RamuzaSettingsProvider>().settings;
    final log = context.watch<RamuzaBarcodeLogProvider>();

    final products = inventory.products.where((product) {
      return !product.isDeleted;
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    final validation = balançaExportService.validateProducts(products);
    final ready = products.isNotEmpty && !validation.hasErrors;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.wine900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.scale_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Central do leitor USB')),
        ],
      ),
      content: SizedBox(
        width: 1120,
        height: 720,
        child: ListView(
          children: [
            _HeroStatus(
              ready: ready,
              products: products,
              validation: validation,
              settings: settings,
              successReads: log.successCount,
              errorReads: log.errorCount,
            ),
            const SizedBox(height: 16),
            _ActionGrid(
              onExport: () => showbalançaExportDialog(context),
              onConfig: () => showbalançaBarcodeConfigDialog(context),
              onTest: () => showbalançaHardwareTestDialog(context),
              onHistory: () => showbalançaBarcodeHistoryDialog(context),
              onCopyChecklist: () => _copyChecklist(
                context,
                products: products,
                validation: validation,
                settings: settings,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _WorkflowPanel(
                    products: products,
                    validation: validation,
                    settings: settings,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: _ManualPanel(settings: settings)),
              ],
            ),
            const SizedBox(height: 16),
            _RiskPanel(validation: validation),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        FilledButton.icon(
          onPressed: () => showbalançaExportDialog(context),
          icon: const Icon(Icons.file_upload_rounded),
          label: const Text('Exportar produtos'),
        ),
      ],
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({
    required this.ready,
    required this.products,
    required this.validation,
    required this.settings,
    required this.successReads,
    required this.errorReads,
  });

  final bool ready;
  final List<Product> products;
  final balançaExportValidation validation;
  final RamuzaBarcodeSettings settings;
  final int successReads;
  final int errorReads;

  @override
  Widget build(BuildContext context) {
    final statusText = ready
        ? 'Integração preparada para teste real'
        : 'Corrija os avisos antes de entregar';

    final detailText = ready
        ? 'Produtos com PLU, exportação pronta e leitor configurado.'
        : 'Verifique produtos sem código, preço zerado ou código duplicado.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ready
            ? AppColors.success.withOpacity(0.12)
            : AppColors.warning.withOpacity(0.14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: ready
              ? AppColors.success.withOpacity(0.35)
              : AppColors.warning.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusText,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(detailText, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricPill(
                icon: Icons.inventory_2_rounded,
                label: 'Produtos',
                value: products.length.toString(),
              ),
              _MetricPill(
                icon: validation.hasErrors
                    ? Icons.error_rounded
                    : Icons.verified_rounded,
                label: 'Erros',
                value: validation.errors.length.toString(),
              ),
              _MetricPill(
                icon: Icons.warning_rounded,
                label: 'Avisos',
                value: validation.warnings.length.toString(),
              ),
              _MetricPill(
                icon: Icons.qr_code_2_rounded,
                label: 'Etiqueta',
                value:
                    '${settings.prefix}+${settings.productCodeDigits}+${settings.valueDigits}',
              ),
              _MetricPill(
                icon: Icons.done_rounded,
                label: 'Leituras ok',
                value: successReads.toString(),
              ),
              _MetricPill(
                icon: Icons.close_rounded,
                label: 'Falhas',
                value: errorReads.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.wine700),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.onExport,
    required this.onConfig,
    required this.onTest,
    required this.onHistory,
    required this.onCopyChecklist,
  });

  final VoidCallback onExport;
  final VoidCallback onConfig;
  final VoidCallback onTest;
  final VoidCallback onHistory;
  final VoidCallback onCopyChecklist;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionCard(
          icon: Icons.file_upload_rounded,
          title: 'Exportar arquivos',
          subtitle: 'Gera CSV/TXT para importar no software da balança.',
          onTap: onExport,
          primary: true,
        ),
        _ActionCard(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Configurar leitura',
          subtitle: 'Ajusta prefixo, PLU, peso/valor e checksum da etiqueta.',
          onTap: onConfig,
        ),
        _ActionCard(
          icon: Icons.science_rounded,
          title: 'Teste do leitor',
          subtitle: 'Simula etiqueta e testa o leitor USB antes da compra.',
          onTap: onTest,
        ),
        _ActionCard(
          icon: Icons.history_rounded,
          title: 'Histórico',
          subtitle:
              'Mostra leituras corretas, falhas e produtos não encontrados.',
          onTap: onHistory,
        ),
        _ActionCard(
          icon: Icons.checklist_rounded,
          title: 'Copiar checklist',
          subtitle: 'Copia o roteiro para testar no Windows com a dona.',
          onTap: onCopyChecklist,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final color = primary
        ? AppColors.wine900
        : Theme.of(context).colorScheme.surface;

    return SizedBox(
      width: 210,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.wine900.withOpacity(primary ? 0 : 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: primary ? Colors.white : AppColors.wine700),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: primary ? Colors.white : null,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primary ? Colors.white.withOpacity(0.84) : null,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkflowPanel extends StatelessWidget {
  const _WorkflowPanel({
    required this.products,
    required this.validation,
    required this.settings,
  });

  final List<Product> products;
  final balançaExportValidation validation;
  final RamuzaBarcodeSettings settings;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Fluxo de entrega para a dona',
      icon: Icons.route_rounded,
      children: [
        _StepLine(
          done: products.isNotEmpty,
          text:
              'Cadastrar produtos com código interno/PLU, nome, unidade e preço.',
        ),
        _StepLine(
          done: !validation.hasErrors,
          text: 'Exportar o pacote balança e salvar os arquivos no Windows.',
        ),
        const _StepLine(
          done: true,
          text: 'Importar no software da balança por Excel/CSV ou TXT.',
        ),
        const _StepLine(
          done: true,
          text: 'Enviar os PLUs para a balança pelo software oficial.',
        ),
        const _StepLine(
          done: true,
          text: 'Imprimir uma etiqueta real e ler no PDV do Açougue do Leleco.',
        ),
        _StepLine(
          done: settings.enabled,
          text:
              'Se o código sair diferente, ajustar o padrão em Configurar leitura.',
        ),
      ],
    );
  }
}

class _ManualPanel extends StatelessWidget {
  const _ManualPanel({required this.settings});

  final RamuzaBarcodeSettings settings;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Como a integração foi pensada',
      icon: Icons.menu_book_rounded,
      children: [
        const _InfoLine(
          title: 'Software oficial',
          text:
              'O app gera CSV/TXT. O software da balança importa e envia para a balança.',
        ),
        const _InfoLine(
          title: 'Leitor USB',
          text:
              'Funciona como teclado: lê a etiqueta, digita o código e aperta Enter.',
        ),
        _InfoLine(
          title: 'Padrão atual de etiqueta',
          text:
              'Prefixo ${settings.prefix}, PLU com ${settings.productCodeDigits} dígitos, valor com ${settings.valueDigits} dígitos, modo ${settings.valueMode.label}.',
        ),
        const _InfoLine(
          title: 'Sem chute de Wi-Fi',
          text:
              'Wi-Fi/Ethernet direto fica para depois de teste real, porque o manual não entrega o protocolo interno.',
        ),
      ],
    );
  }
}

class _RiskPanel extends StatelessWidget {
  const _RiskPanel({required this.validation});

  final balançaExportValidation validation;

  @override
  Widget build(BuildContext context) {
    final items = [
      ...validation.errors.map((item) => 'ERRO: $item'),
      ...validation.warnings.take(5).map((item) => 'AVISO: $item'),
    ];

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Text(
          'Checklist limpo: os produtos estão prontos para exportação.',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    return _Panel(
      title: 'Pontos para conferir antes de vender',
      icon: Icons.health_and_safety_rounded,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            item,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      }).toList(),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.wine700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.done, required this.text});

  final bool done;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: done ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

Future<void> _copyChecklist(
  BuildContext context, {
  required List<Product> products,
  required balançaExportValidation validation,
  required RamuzaBarcodeSettings settings,
}) async {
  final text =
      '''
CHECKLIST DE TESTE - AÇOUGUE DO LELECO + RAMUZA

1. Abrir o app do Açougue do Leleco no Windows.
2. Abrir Leitor USB.
3. Clicar em Exportar arquivos.
4. Salvar todos os arquivos.
5. Abrir o software da balança.
6. Fazer backup no software da balança antes de importar.
7. Importar primeiro: ramuza_plu_completo_com_cabecalho.csv.
8. Se não aceitar, testar: ramuza_plu_completo_sem_cabecalho.csv.
9. Se ainda não aceitar, testar: ramuza_plu_completo_tab.txt.
10. Enviar PLU/produtos para a balança pelo software da balança.
11. Imprimir uma etiqueta de teste.
12. Abrir Venda no app do Açougue.
13. Ler a etiqueta com leitor USB.
14. Conferir se o produto entrou no carrinho com peso/valor correto.
15. Se o PLU não bater, abrir Configurar leitura e ajustar prefixo/dígitos.

STATUS ATUAL
Produtos ativos: ${products.length}
Erros de exportação: ${validation.errors.length}
Avisos de exportação: ${validation.warnings.length}
Etiqueta: prefixo ${settings.prefix}, PLU ${settings.productCodeDigits}, valor ${settings.valueDigits}, modo ${settings.valueMode.label}

OBSERVAÇÃO
O leitor USB funciona como teclado. Ele deve digitar o código no campo de venda e enviar Enter.
'''
          .trim();

  await Clipboard.setData(ClipboardData(text: text));

  if (!context.mounted) return;

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(const SnackBar(content: Text('Checklist balança copiado.')));
}
