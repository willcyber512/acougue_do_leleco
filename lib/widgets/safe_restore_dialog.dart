import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';
import '../providers/cash_closure_provider.dart';
import '../providers/customers_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/ramuza_barcode_log_provider.dart';
import '../providers/ramuza_settings_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/shortcuts_provider.dart';
import '../providers/suppliers_provider.dart';

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
  static const String _emergencyKey = 'leleco_emergency_before_restore_v1';

  final TextEditingController controller = TextEditingController();

  RestorePreview preview = const RestorePreview.empty();
  EmergencyBackupInfo emergencyInfo = const EmergencyBackupInfo.empty();

  bool isRestoring = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmergencyInfo();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emergencyKey);

    if (!mounted) return;

    setState(() {
      emergencyInfo = EmergencyBackupInfo.fromRaw(raw);
    });
  }

  void _updatePreview() {
    setState(() {
      preview = RestorePreview.fromText(controller.text);
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;

    if (text == null || text.trim().isEmpty) {
      _showMessage('Área de transferência vazia.', error: true);
      return;
    }

    controller.text = text;
    _updatePreview();
  }

  void _clearText() {
    controller.clear();

    setState(() {
      preview = const RestorePreview.empty();
    });
  }

  Future<void> _restoreFromText() async {
    final currentPreview = RestorePreview.fromText(controller.text);

    if (!currentPreview.canRestore) {
      _showMessage(
        currentPreview.generalError ?? 'Backup inválido.',
        error: true,
      );
      return;
    }

    final confirmed = await _confirmRestore(
      title: 'Confirmar restauração',
      message:
          'Antes de restaurar, o sistema vai salvar um backup de emergência do estado atual. Continuar?',
    );

    if (!confirmed) return;

    setState(() => isRestoring = true);

    try {
      await _saveEmergencyBackup();
      await _restoreDataMap(currentPreview.data);

      if (!mounted) return;

      await _reloadProviders(context);

      await _loadEmergencyInfo();

      _showMessage(
        'Backup restaurado. Um backup de emergência foi salvo.',
        success: true,
      );
    } catch (error) {
      _showMessage('Erro ao restaurar: $error', error: true);
    } finally {
      if (mounted) {
        setState(() => isRestoring = false);
      }
    }
  }

  Future<void> _recoverEmergencyBackup() async {
    if (!emergencyInfo.hasBackup) {
      _showMessage('Nenhum backup de emergência encontrado.', error: true);
      return;
    }

    final confirmed = await _confirmRestore(
      title: 'Recuperar backup de emergência',
      message:
          'Isso vai trazer de volta os dados salvos antes da última restauração. Continuar?',
    );

    if (!confirmed) return;

    setState(() => isRestoring = true);

    try {
      await _restoreDataMap(emergencyInfo.data);

      if (!mounted) return;

      await _reloadProviders(context);

      _showMessage(
        'Backup de emergência recuperado.',
        success: true,
      );
    } catch (error) {
      _showMessage('Erro ao recuperar emergência: $error', error: true);
    } finally {
      if (mounted) {
        setState(() => isRestoring = false);
      }
    }
  }

  Future<void> _saveEmergencyBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, String>{};

    for (final item in _backupKeys) {
      final value = prefs.getString(item.key);

      if (value != null) {
        data[item.key] = value;
      }
    }

    final payload = {
      'createdAt': DateTime.now().toIso8601String(),
      'type': 'emergency_before_restore',
      'data': data,
    };

    await prefs.setString(_emergencyKey, jsonEncode(payload));
  }

  Future<void> _restoreDataMap(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    for (final item in _backupKeys) {
      if (!data.containsKey(item.key)) continue;

      final value = data[item.key];

      if (value == null) continue;

      if (value is String) {
        await prefs.setString(item.key, value);
      } else {
        await prefs.setString(item.key, jsonEncode(value));
      }
    }
  }

  Future<void> _reloadProviders(BuildContext context) async {
    await context.read<InventoryProvider>().reloadFromStorage();
    await context.read<SalesProvider>().reloadFromStorage();
    await context.read<CustomersProvider>().reloadFromStorage();
    await context.read<NotesProvider>().reloadFromStorage();
    await context.read<CashClosureProvider>().reloadFromStorage();
    await context.read<ShortcutsProvider>().reloadFromStorage();
    await context.read<SuppliersProvider>().reloadFromStorage();
    await context.read<RamuzaSettingsProvider>().reloadFromStorage();
    await context.read<RamuzaBarcodeLogProvider>().reloadFromStorage();
  }

  Future<bool> _confirmRestore({
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
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restauração segura'),
      content: SizedBox(
        width: 900,
        height: 660,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WarningBox(
              text:
                  'Cole um backup exportado pelo sistema. Antes de restaurar, o app salva automaticamente um backup de emergência dos dados atuais.',
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 4,
              child: TextField(
                controller: controller,
                onChanged: (_) => _updatePreview(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'Backup em JSON',
                  alignLabelWithHint: true,
                  hintText: 'Cole aqui o backup exportado...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: isRestoring ? null : _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste_rounded),
                  label: const Text('Colar backup'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: isRestoring ? null : _clearText,
                  icon: const Icon(Icons.cleaning_services_rounded),
                  label: const Text('Limpar'),
                ),
                const Spacer(),
                _PreviewCounter(
                  label: 'Partes válidas',
                  value: preview.recognizedKeys.length.toString(),
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(width: 8),
                _PreviewCounter(
                  label: 'Desconhecidas',
                  value: preview.unknownKeys.length.toString(),
                  icon: Icons.help_rounded,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: _PreviewPanel(preview: preview),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 320,
                    child: _EmergencyCard(
                      info: emergencyInfo,
                      isBusy: isRestoring,
                      onRecover: _recoverEmergencyBackup,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isRestoring ? null : () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        FilledButton.icon(
          onPressed: isRestoring || !preview.canRestore ? null : _restoreFromText,
          icon: const Icon(Icons.restore_rounded),
          label: Text(isRestoring ? 'Restaurando...' : 'Restaurar backup'),
        ),
      ],
    );
  }

  void _showMessage(
    String message, {
    bool success = false,
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error
              ? AppColors.danger
              : success
                  ? AppColors.success
                  : null,
        ),
      );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurfaceAlt
            : AppColors.beige100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: AppColors.wine700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCounter extends StatelessWidget {
  const _PreviewCounter({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.preview});

  final RestorePreview preview;

  @override
  Widget build(BuildContext context) {
    if (preview.generalError != null) {
      return _EmptyPanel(text: preview.generalError!);
    }

    if (preview.recognizedKeys.isEmpty && preview.unknownKeys.isEmpty) {
      return const _EmptyPanel(
        text: 'Cole um backup para ver o que será restaurado.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: ListView(
          children: [
            const Text(
              'Partes que serão restauradas',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (preview.recognizedKeys.isEmpty)
              const Text('Nenhuma parte válida encontrada.')
            else
              ...preview.recognizedKeys.map(
                (item) => ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  title: Text(
                    item.label,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(item.key),
                ),
              ),
            if (preview.unknownKeys.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Partes desconhecidas ignoradas',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              ...preview.unknownKeys.take(8).map(
                    (key) => Text(
                      '• $key',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              if (preview.unknownKeys.length > 8)
                Text('... e mais ${preview.unknownKeys.length - 8}.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({
    required this.info,
    required this.isBusy,
    required this.onRecover,
  });

  final EmergencyBackupInfo info;
  final bool isBusy;
  final VoidCallback onRecover;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.emergency_share_rounded, color: AppColors.wine700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Backup de emergência',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                info.hasBackup
                    ? 'Criado em: ${_formatDateTime(info.createdAt!)}'
                    : 'Nenhum backup de emergência salvo ainda.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                info.hasBackup
                    ? '${info.keysCount} parte(s) recuperável(is).'
                    : 'Ele será criado automaticamente antes de uma restauração.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isBusy || !info.hasBackup ? null : onRecover,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('Recuperar emergência'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class RestorePreview {
  const RestorePreview({
    required this.data,
    required this.recognizedKeys,
    required this.unknownKeys,
    this.generalError,
  });

  const RestorePreview.empty()
      : data = const {},
        recognizedKeys = const [],
        unknownKeys = const [],
        generalError = null;

  final Map<String, dynamic> data;
  final List<_BackupKey> recognizedKeys;
  final List<String> unknownKeys;
  final String? generalError;

  bool get canRestore => generalError == null && recognizedKeys.isNotEmpty;

  factory RestorePreview.fromText(String text) {
    final raw = text.trim();

    if (raw.isEmpty) {
      return const RestorePreview.empty();
    }

    try {
      final decoded = jsonDecode(raw);

      final data = _extractDataMap(decoded);

      if (data == null) {
        return const RestorePreview(
          data: {},
          recognizedKeys: [],
          unknownKeys: [],
          generalError: 'JSON inválido. O backup precisa ser um objeto.',
        );
      }

      final recognized = _backupKeys.where((item) {
        return data.containsKey(item.key);
      }).toList();

      final knownKeys = _backupKeys.map((item) => item.key).toSet();

      final unknown = data.keys.where((key) {
        return !knownKeys.contains(key);
      }).toList();

      if (recognized.isEmpty) {
        return RestorePreview(
          data: data,
          recognizedKeys: const [],
          unknownKeys: unknown,
          generalError: 'Nenhuma parte válida do sistema foi encontrada.',
        );
      }

      return RestorePreview(
        data: data,
        recognizedKeys: recognized,
        unknownKeys: unknown,
      );
    } catch (_) {
      return const RestorePreview(
        data: {},
        recognizedKeys: [],
        unknownKeys: [],
        generalError: 'JSON inválido. Confira se copiou o backup inteiro.',
      );
    }
  }

  static Map<String, dynamic>? _extractDataMap(dynamic decoded) {
    if (decoded is! Map) return null;

    final data = decoded['data'];

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
}

class EmergencyBackupInfo {
  const EmergencyBackupInfo({
    required this.hasBackup,
    required this.data,
    required this.keysCount,
    this.createdAt,
  });

  const EmergencyBackupInfo.empty()
      : hasBackup = false,
        data = const {},
        keysCount = 0,
        createdAt = null;

  final bool hasBackup;
  final Map<String, dynamic> data;
  final int keysCount;
  final DateTime? createdAt;

  factory EmergencyBackupInfo.fromRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const EmergencyBackupInfo.empty();
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return const EmergencyBackupInfo.empty();
      }

      final rawData = decoded['data'];

      if (rawData is! Map) {
        return const EmergencyBackupInfo.empty();
      }

      final data = rawData.map((key, value) {
        return MapEntry(key.toString(), value);
      });

      final createdAt = DateTime.tryParse(decoded['createdAt']?.toString() ?? '');

      return EmergencyBackupInfo(
        hasBackup: data.isNotEmpty,
        data: data,
        keysCount: data.length,
        createdAt: createdAt,
      );
    } catch (_) {
      return const EmergencyBackupInfo.empty();
    }
  }
}

class _BackupKey {
  const _BackupKey({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}

const List<_BackupKey> _backupKeys = [
  _BackupKey(
    key: 'leleco_inventory_products_v1',
    label: 'Produtos / Estoque',
  ),
  _BackupKey(
    key: 'leleco_inventory_events_v1',
    label: 'Histórico do estoque',
  ),
  _BackupKey(
    key: 'leleco_inventory_losses_v1',
    label: 'Perdas do estoque',
  ),
  _BackupKey(
    key: 'leleco_sales_records_v1',
    label: 'Vendas',
  ),
  _BackupKey(
    key: 'leleco_customers_v1',
    label: 'Clientes / Fiado',
  ),
  _BackupKey(
    key: 'leleco_credit_entries_v1',
    label: 'Movimentos do fiado',
  ),
  _BackupKey(
    key: 'leleco_internal_notes_v1',
    label: 'Anotações internas',
  ),
  _BackupKey(
    key: 'leleco_supplier_purchases_v1',
    label: 'Compras de fornecedores',
  ),
  _BackupKey(
    key: 'leleco_suppliers_v1',
    label: 'Cadastro de fornecedores',
  ),
  _BackupKey(
    key: 'leleco_cash_closures_v1',
    label: 'Fechamentos de caixa',
  ),
  _BackupKey(
    key: 'leleco_dashboard_shortcuts_v1',
    label: 'Atalhos da tela Hoje',
  ),
  _BackupKey(
    key: 'leleco_ramuza_barcode_settings_v1',
    label: 'Configurações da Ramuza',
  ),
  _BackupKey(
    key: 'leleco_ramuza_barcode_events_v1',
    label: 'Histórico de leituras Ramuza',
  ),
];

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}
