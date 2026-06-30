import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/internal_note.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/leleco_metric_card.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final notes = provider.filteredNotes;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.note_alt_rounded,
                    title: 'Anotações',
                    value: provider.totalNotes.toString(),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.pending_actions_rounded,
                    title: 'Pendentes',
                    value: provider.pendingCount.toString(),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.push_pin_rounded,
                    title: 'Fixadas',
                    value: provider.pinnedCount.toString(),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: LelecoMetricCard(
                    icon: Icons.done_all_rounded,
                    title: 'Concluídas',
                    value: provider.doneCount.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _NotesToolbar(provider: provider),
            const SizedBox(height: 16),
            Expanded(
              child: notes.isEmpty
                  ? const _EmptyNotes()
                  : ListView.separated(
                      itemCount: notes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _NoteCard(note: notes[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _NotesToolbar extends StatelessWidget {
  const _NotesToolbar({required this.provider});

  final NotesProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: provider.setSearchTerm,
            decoration: InputDecoration(
              hintText: 'Buscar anotação por título, texto ou prioridade...',
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
          onPressed: () => _openNoteDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova anotação'),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final InternalNote note;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotesProvider>();
    final priorityColor = _priorityColor(note.priority);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: note.done ? AppColors.success : AppColors.wine900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                note.done ? Icons.check_rounded : Icons.note_alt_rounded,
                color: AppColors.beige100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (note.pinned) ...[
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 18,
                          color: AppColors.wine700,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          note.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    decoration: note.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.content.isEmpty ? 'Sem descrição.' : note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration:
                          note.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SmallChip(
                        text: note.priority.label,
                        color: priorityColor,
                      ),
                      _SmallChip(
                        text: note.done ? 'Concluída' : 'Pendente',
                        color: note.done ? AppColors.success : AppColors.warning,
                      ),
                      _SmallChip(
                        text: 'Atualizada ${_formatDateTime(note.updatedAt)}',
                        color: AppColors.wine700,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: note.done ? 'Marcar como pendente' : 'Concluir',
              onPressed: () => provider.toggleDone(note.id),
              icon: Icon(
                note.done
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
              ),
            ),
            IconButton(
              tooltip: note.pinned ? 'Desfixar' : 'Fixar',
              onPressed: () => provider.togglePinned(note.id),
              icon: Icon(
                note.pinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: () => _openNoteDialog(context, note: note),
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              tooltip: 'Excluir',
              onPressed: () => _deleteNote(context, note),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Nenhuma anotação encontrada.'),
    );
  }
}

Future<void> _openNoteDialog(
  BuildContext context, {
  InternalNote? note,
}) async {
  final provider = context.read<NotesProvider>();

  final titleController = TextEditingController(text: note?.title ?? '');
  final contentController = TextEditingController(text: note?.content ?? '');

  var priority = note?.priority ?? NotePriority.normal;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(note == null ? 'Nova anotação' : 'Editar anotação'),
            content: SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ex: Comprar embalagens',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Ex: lembrar de comprar sacolas e bandejas',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<NotePriority>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Prioridade',
                    ),
                    items: NotePriority.values.map((item) {
                      return DropdownMenuItem(
                        value: item,
                        child: Text(item.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => priority = value);
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
              FilledButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final content = contentController.text.trim();

                  if (title.isEmpty) {
                    _showMessage(context, 'Informe o título da anotação.');
                    return;
                  }

                  if (note == null) {
                    provider.addNote(
                      title: title,
                      content: content,
                      priority: priority,
                    );
                  } else {
                    provider.updateNote(
                      note.copyWith(
                        title: title,
                        content: content,
                        priority: priority,
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
    },
  );
}

Future<void> _deleteNote(BuildContext context, InternalNote note) async {
  final provider = context.read<NotesProvider>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Excluir anotação?'),
        content: Text('A anotação "${note.title}" será removida.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  provider.deleteNote(note.id);
}

Color _priorityColor(NotePriority priority) {
  switch (priority) {
    case NotePriority.low:
      return AppColors.success;
    case NotePriority.normal:
      return AppColors.wine700;
    case NotePriority.high:
      return AppColors.warning;
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(message)),
    );
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
