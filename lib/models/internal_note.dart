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

class InternalNote {
  const InternalNote({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.pinned,
    required this.done,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final NotePriority priority;
  final bool pinned;
  final bool done;
  final DateTime createdAt;
  final DateTime updatedAt;

  InternalNote copyWith({
    String? id,
    String? title,
    String? content,
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
