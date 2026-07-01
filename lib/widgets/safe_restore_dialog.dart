import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/cash_closure_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/ramuza_barcode_log_provider.dart';
import '../providers/ramuza_settings_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/shortcuts_provider.dart';

Future<void> showSafeRestoreDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const SafeRestoreDialog(),
  );
}

class SafeRestoreDialog extends StatefulWidget {
  const SafeRestoreDialog({super.key});

  @override
  State<SafeRestoreDialog> createState() => _SafeRestoreDialogState();
}

class _SafeRestoreDialogState extends State<SafeRestoreDialog> {
  final controller = TextEditingController();

  RestorePreview preview = RestorePreview.empty();

  bool acceptedRisk = false;
  bool isRestoring = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      acceptedRisk = false;
      preview = RestorePreview.fromText(controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canRestore = preview.isValid && acceptedRisk && !isRestoring;

    return AlertDialog(
      title: const Text('Restaurar backup com segurança'),
      content: SizedBox(
        width: 980,
        height: 680,
        child: Row(
          children: [
            Expanded(
              child: _PastePanel(
                controller: controller,
                onChanged: _validate,
                onPaste: _pasteFromClipboard,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _PreviewPanel(
                preview: preview,
                acceptedRisk: acceptedRisk,
                onAcceptedChanged: preview.isValid
                    ? (value) {
                        setState(() => acceptedRisk = value);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isRestoring ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: canRestore ? _restoreBackup : null,
          icon: const Icon(Icons.restore_rounded),
          label: Text(isRestoring ? 'Restaurando...' : 'Restaurar agora'),
        ),
      ],
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text ?? '';

    controller.text = text;
    _validate();
  }

  Future<void> _restoreBackup() async {
    if (!preview.isValid) return;

    setState(() => isRestoring = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await _saveEmergencyBackup(prefs);
      await _writeBackupData(prefs, preview.data);

      if (!mounted) return;

      await _reloadProviders(context);

      if (!mounted) return;

      setState(() => isRestoring = false);

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Backup restaurado com segurança.'),
          ),
        );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() => isRestoring = false);

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Erro ao restaurar: $error'),
          ),
        );
    }
  }
}

class _PastePanel extends StatelessWidget {
  const _PastePanel({
    required this.controller,
    required this.onChanged,
    required this.onPaste,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.wine900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.content_paste_rounded,
                    color: AppColors.beige100,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cole aqui o backup completo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'JSON do backup',
                  hintText: '{ "app": "Açougue do Leleco", ... }',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPaste,
                icon: const Icon(Icons.paste_rounded),
                label: const Text('Colar da área de transferência'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.preview,
    required this.acceptedRisk,
    required this.onAcceptedChanged,
  });

  final RestorePreview preview;
  final bool acceptedRisk;
  final ValueChanged<bool>? onAcceptedChanged;

  @override
  Widget build(BuildContext context) {
    final color = preview.isValid ? AppColors.success : AppColors.warning;

    return Card(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  preview.isValid
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: AppColors.beige100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  preview.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            preview.message,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (preview.isValid) ...[
            _InfoLine(label: 'App', value: preview.appName),
            _InfoLine(label: 'Versão do backup', value: preview.version),
            _InfoLine(label: 'Tipo', value: preview.type),
            _InfoLine(label: 'Criado em', value: preview.createdAt),
            const SizedBox(height: 12),
            Text(
              'Dados que serão restaurados',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            ...preview.data.keys.map((key) {
              return _KeyTile(
                keyName: key,
                label: _keyLabel(key),
              );
            }),
            if (preview.ignoredKeys.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Chaves ignoradas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              ...preview.ignoredKeys.map((key) {
                return Text(
                  '• $key',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                );
              }),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'A restauração vai substituir os dados locais atuais pelas informações do backup. Antes disso, o sistema salva um backup de emergência automático.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            CheckboxListTile(
              value: acceptedRisk,
              onChanged: onAcceptedChanged == null
                  ? null
                  : (value) => onAcceptedChanged!(value ?? false),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Entendo que os dados locais serão substituídos.',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyTile extends StatelessWidget {
  const _KeyTile({
    required this.keyName,
    required this.label,
  });

  final String keyName;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle_rounded),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(keyName),
    );
  }
}

class RestorePreview {
  const RestorePreview({
    required this.isValid,
    required this.title,
    required this.message,
    required this.appName,
    required this.version,
    required this.type,
    required this.createdAt,
    required this.data,
    required this.ignoredKeys,
  });

  final bool isValid;
  final String title;
  final String message;
  final String appName;
  final String version;
  final String type;
  final String createdAt;
  final Map<String, dynamic> data;
  final List<String> ignoredKeys;

  factory RestorePreview.empty() {
    return const RestorePreview(
      isValid: false,
      title: 'Aguardando backup',
      message: 'Cole o JSON do backup completo para validar.',
      appName: '-',
      version: '-',
      type: '-',
      createdAt: '-',
      data: {},
      ignoredKeys: [],
    );
  }

  factory RestorePreview.fromText(String text) {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return RestorePreview.empty();
    }

    try {
      final decoded = jsonDecode(trimmed);

      if (decoded is! Map) {
        return _invalid('JSON inválido', 'O backup precisa ser um objeto JSON.');
      }

      final map = Map<String, dynamic>.from(decoded);

      final appName = map['app']?.toString() ?? 'Desconhecido';
      final version = map['version']?.toString() ?? 'Desconhecida';
      final type = map['type']?.toString() ?? 'backup';
      final createdAt = map['createdAt']?.toString() ?? 'Desconhecido';

      final rawData = _extractDataMap(map);

      if (rawData.isEmpty) {
        return _invalid(
          'Backup sem dados',
          'Não encontrei dados restauráveis dentro do JSON.',
        );
      }

      final data = <String, dynamic>{};
      final ignored = <String>[];

      for (final entry in rawData.entries) {
        if (_allowedKeys.contains(entry.key)) {
          data[entry.key] = entry.value;
        } else {
          ignored.add(entry.key);
        }
      }

      if (data.isEmpty) {
        return _invalid(
          'Nenhuma chave compatível',
          'O JSON existe, mas não tem dados compatíveis com este sistema.',
        );
      }

      return RestorePreview(
        isValid: true,
        title: 'Backup válido',
        message:
            '${data.length} grupo(s) de dados podem ser restaurados. Confira antes de continuar.',
        appName: appName,
        version: version,
        type: type,
        createdAt: createdAt,
        data: data,
        ignoredKeys: ignored,
      );
    } catch (error) {
      return _invalid(
        'Erro ao ler JSON',
        'Não foi possível interpretar o texto colado. Detalhe: $error',
      );
    }
  }

  static RestorePreview _invalid(String title, String message) {
    return RestorePreview(
      isValid: false,
      title: title,
      message: message,
      appName: '-',
      version: '-',
      type: '-',
      createdAt: '-',
      data: const {},
      ignoredKeys: const [],
    );
  }

  static Map<String, dynamic> _extractDataMap(Map<String, dynamic> map) {
    final data = map['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    final directData = <String, dynamic>{};

    for (final key in _allowedKeys) {
      if (map.containsKey(key)) {
        directData[key] = map[key];
      }
    }

    return directData;
  }
}

Future<void> _saveEmergencyBackup(SharedPreferences prefs) async {
  final currentData = <String, dynamic>{};

  for (final key in _allowedKeys) {
    if (prefs.containsKey(key)) {
      currentData[key] = prefs.get(key);
    }
  }

  final emergency = {
    'app': AppConstants.appName,
    'version': AppConstants.appVersion,
    'type': 'emergency_before_restore',
    'createdAt': DateTime.now().toIso8601String(),
    'data': currentData,
  };

  await prefs.setString(
    _emergencyBackupKey,
    const JsonEncoder.withIndent('  ').convert(emergency),
  );
}

Future<void> _writeBackupData(
  SharedPreferences prefs,
  Map<String, dynamic> data,
) async {
  for (final entry in data.entries) {
    await _writePreference(prefs, entry.key, entry.value);
  }
}

Future<void> _writePreference(
  SharedPreferences prefs,
  String key,
  dynamic value,
) async {
  if (value == null) {
    await prefs.remove(key);
    return;
  }

  if (value is String) {
    await prefs.setString(key, value);
    return;
  }

  if (value is bool) {
    await prefs.setBool(key, value);
    return;
  }

  if (value is int) {
    await prefs.setInt(key, value);
    return;
  }

  if (value is double) {
    await prefs.setDouble(key, value);
    return;
  }

  if (value is List && value.every((item) => item is String)) {
    await prefs.setStringList(key, value.cast<String>());
    return;
  }

  await prefs.setString(key, jsonEncode(value));
}

Future<void> _reloadProviders(BuildContext context) async {
  await context.read<InventoryProvider>().reloadFromStorage();
  await context.read<SalesProvider>().reloadFromStorage();
  await context.read<CustomersProvider>().reloadFromStorage();
  await context.read<NotesProvider>().reloadFromStorage();
  await context.read<CashClosureProvider>().reloadFromStorage();
  await context.read<ShortcutsProvider>().reloadFromStorage();
  await context.read<RamuzaSettingsProvider>().reloadFromStorage();
  await context.read<RamuzaBarcodeLogProvider>().reloadFromStorage();
}

const String _emergencyBackupKey = 'leleco_emergency_before_restore_v1';

const List<String> _allowedKeys = [
  'leleco_inventory_products_v1',
  'leleco_inventory_events_v1',
  'leleco_inventory_losses_v1',
  'leleco_sales_records_v1',
  'leleco_customers_v1',
  'leleco_credit_entries_v1',
  'leleco_internal_notes_v1',
  'leleco_cash_closures_v1',
  'leleco_dashboard_shortcuts_v1',
  'leleco_ramuza_barcode_settings_v1',
  'leleco_ramuza_barcode_events_v1',
];

String _keyLabel(String key) {
  const labels = {
    'leleco_inventory_products_v1': 'Produtos e estoque',
    'leleco_inventory_events_v1': 'Histórico do estoque',
    'leleco_inventory_losses_v1': 'Perdas',
    'leleco_sales_records_v1': 'Vendas',
    'leleco_customers_v1': 'Clientes',
    'leleco_credit_entries_v1': 'Fiado',
    'leleco_internal_notes_v1': 'Anotações internas',
    'leleco_cash_closures_v1': 'Fechamentos de caixa',
    'leleco_dashboard_shortcuts_v1': 'Atalhos',
    'leleco_ramuza_barcode_settings_v1': 'Configuração Ramuza',
    'leleco_ramuza_barcode_events_v1': 'Histórico Ramuza',
  };

  return labels[key] ?? key;
}
