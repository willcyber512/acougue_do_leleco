import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/cash_closure_provider.dart';
import '../../providers/customers_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/local_backup_service.dart';
import '../../widgets/system_about_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController exportController = TextEditingController();
  final TextEditingController importController = TextEditingController();

  bool isBusy = false;

  @override
  void dispose() {
    exportController.dispose();
    importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backupDate = LocalBackupService.readBackupDate(importController.text);

    return ListView(
      children: [
        _HeaderCard(),
        const SizedBox(height: 18),
        const SystemAboutCard(),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ExportBackupCard(
                controller: exportController,
                isBusy: isBusy,
                onGenerate: _generateBackup,
                onCopy: _copyExportedBackup,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _ImportBackupCard(
                controller: importController,
                isBusy: isBusy,
                backupDate: backupDate,
                onPaste: _pasteBackup,
                onRestore: _restoreBackup,
                onChanged: () => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _generateBackup() async {
    setState(() => isBusy = true);

    try {
      final backup = await LocalBackupService.exportBackup();

      exportController.text = backup;

      await Clipboard.setData(
        ClipboardData(text: backup),
      );

      _showMessage('Backup gerado e copiado.');
    } catch (_) {
      _showMessage('Não foi possível gerar o backup.');
    } finally {
      if (mounted) {
        setState(() => isBusy = false);
      }
    }
  }

  Future<void> _copyExportedBackup() async {
    final text = exportController.text.trim();

    if (text.isEmpty) {
      _showMessage('Gere um backup primeiro.');
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: text),
    );

    _showMessage('Backup copiado.');
  }

  Future<void> _pasteBackup() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboard?.text ?? '';

    if (text.trim().isEmpty) {
      _showMessage('Área de transferência vazia.');
      return;
    }

    importController.text = text;
    setState(() {});
    _showMessage('Backup colado.');
  }

  Future<void> _restoreBackup() async {
    final backupText = importController.text.trim();

    if (backupText.isEmpty) {
      _showMessage('Cole um backup primeiro.');
      return;
    }

    final confirmed = await _confirmRestore();

    if (!confirmed) return;

    setState(() => isBusy = true);

    try {
      await LocalBackupService.importBackup(backupText);

      if (!mounted) return;

      await context.read<InventoryProvider>().reloadFromStorage();
      await context.read<SalesProvider>().reloadFromStorage();
      await context.read<CustomersProvider>().reloadFromStorage();
      await context.read<NotesProvider>().reloadFromStorage();
      await context.read<CashClosureProvider>().reloadFromStorage();

      _showMessage('Backup restaurado com sucesso.');
    } catch (_) {
      _showMessage('Backup inválido ou corrompido.');
    } finally {
      if (mounted) {
        setState(() => isBusy = false);
      }
    }
  }

  Future<bool> _confirmRestore() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restaurar backup?'),
          content: const Text(
            'Os dados atuais serão substituídos pelos dados do backup colado. '
            'Antes de restaurar, gere um backup dos dados atuais.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }
}

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
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
                Icons.backup_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup e restauração local',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Use esta tela para salvar uma cópia dos dados antes de cadastrar produtos reais.',
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

class _ExportBackupCard extends StatelessWidget {
  const _ExportBackupCard({
    required this.controller,
    required this.isBusy,
    required this.onGenerate,
    required this.onCopy,
  });

  final TextEditingController controller;
  final bool isBusy;
  final VoidCallback onGenerate;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 560,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              icon: Icons.upload_file_rounded,
              title: 'Gerar backup',
            ),
            const SizedBox(height: 10),
            const Text(
              'Gera um texto com todos os dados salvos: estoque, vendas, caixa, fiado, perdas e histórico.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: isBusy ? null : onGenerate,
                  icon: const Icon(Icons.backup_rounded),
                  label: const Text('Gerar e copiar'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onCopy,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copiar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'O backup gerado vai aparecer aqui...',
                  filled: true,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportBackupCard extends StatelessWidget {
  const _ImportBackupCard({
    required this.controller,
    required this.isBusy,
    required this.backupDate,
    required this.onPaste,
    required this.onRestore,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isBusy;
  final DateTime? backupDate;
  final VoidCallback onPaste;
  final VoidCallback onRestore;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 560,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              icon: Icons.download_rounded,
              title: 'Restaurar backup',
            ),
            const SizedBox(height: 10),
            Text(
              backupDate == null
                  ? 'Cole aqui um backup antigo para restaurar.'
                  : 'Backup detectado de ${_formatDateTime(backupDate!)}.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onPaste,
                  icon: const Icon(Icons.paste_rounded),
                  label: const Text('Colar'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: isBusy ? null : onRestore,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Restaurar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                expands: true,
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  hintText: 'Cole o backup aqui...',
                  filled: true,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.wine700),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
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
