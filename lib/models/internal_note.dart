enum NotePriority {
  low,
  normal,
  high,
}

extension NotePriorityLabel on NotePriority {
  String get label {
    switch (this) {
      case NotePriority.low:
        return 'Baixa';
      case NotePriority.normal:
        return 'Normal';
      case NotePriority.high:
        return 'Alta';
    }
  }
}

NotePriority notePriorityFromName(String? value) {
  return NotePriority.values.firstWhere(
    (priority) => priority.name == value,
    orElse: () => NotePriority.normal,
  );
}

enum NoteKind {
  general,
  purchase,
  stock,
  cash,
  customer,
}

extension NoteKindLabel on NoteKind {
  String get label {
    switch (this) {
      case NoteKind.general:
        return 'Geral';
      case NoteKind.purchase:
        return 'Compra';
      case NoteKind.stock:
        return 'Estoque';
      case NoteKind.cash:
        return 'Caixa';
      case NoteKind.customer:
        return 'Cliente/fiado';
    }
  }
}

NoteKind noteKindFromName(String? value) {
  return NoteKind.values.firstWhere(
    (kind) => kind.name == value,
    orElse: () => NoteKind.general,
  );
}

class InternalNote {
  const InternalNote({
    required this.id,
    required this.title,
    required this.content,
    required this.kind,
    required this.priority,
    required this.pinned,
    required this.done,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final NoteKind kind;
  final NotePriority priority;
  final bool pinned;
  final bool done;
  final DateTime createdAt;
  final DateTime updatedAt;

  InternalNote copyWith({
    String? id,
    String? title,
    String? content,
    NoteKind? kind,
    NotePriority? priority,
    bool? pinned,
    bool? done,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InternalNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      kind: kind ?? this.kind,
      priority: priority ?? this.priority,
      pinned: pinned ?? this.pinned,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'kind': kind.name,
      'priority': priority.name,
      'pinned': pinned,
      'done': done,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InternalNote.fromMap(Map<String, dynamic> map) {
    return InternalNote(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      kind: noteKindFromName(map['kind']?.toString()),
      priority: notePriorityFromName(map['priority']?.toString()),
      pinned: _toBool(map['pinned']),
      done: _toBool(map['done']),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;

    return value?.toString().toLowerCase() == 'true';
  }

  static DateTime _toDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
