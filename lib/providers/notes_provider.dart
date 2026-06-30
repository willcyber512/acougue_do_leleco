import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/internal_note.dart';

class NotesProvider extends ChangeNotifier {
  NotesProvider() {
    _loadData();
  }

  static const String _notesStorageKey = 'leleco_internal_notes_v1';

  final List<InternalNote> _notes = [];

  bool _isLoading = true;
  String _searchTerm = '';

  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;

  List<InternalNote> get notes {
    final result = [..._notes];

    result.sort((a, b) {
      if (a.pinned != b.pinned) {
        return a.pinned ? -1 : 1;
      }

      if (a.done != b.done) {
        return a.done ? 1 : -1;
      }

      return b.updatedAt.compareTo(a.updatedAt);
    });

    return List.unmodifiable(result);
  }

  List<InternalNote> get filteredNotes {
    final term = _searchTerm.trim().toLowerCase();

    if (term.isEmpty) {
      return notes;
    }

    final result = _notes.where((note) {
      return note.title.toLowerCase().contains(term) ||
          note.content.toLowerCase().contains(term) ||
          note.priority.label.toLowerCase().contains(term);
    }).toList();

    result.sort((a, b) {
      if (a.pinned != b.pinned) {
        return a.pinned ? -1 : 1;
      }

      if (a.done != b.done) {
        return a.done ? 1 : -1;
      }

      return b.updatedAt.compareTo(a.updatedAt);
    });

    return List.unmodifiable(result);
  }

  int get totalNotes => _notes.length;

  int get pendingCount {
    return _notes.where((note) => !note.done).length;
  }

  int get doneCount {
    return _notes.where((note) => note.done).length;
  }

  int get pinnedCount {
    return _notes.where((note) => note.pinned).length;
  }

  void setSearchTerm(String value) {
    _searchTerm = value;
    notifyListeners();
  }

  void addNote({
    required String title,
    required String content,
    required NotePriority priority,
  }) {
    final now = DateTime.now();

    final note = InternalNote(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      content: content.trim(),
      priority: priority,
      pinned: false,
      done: false,
      createdAt: now,
      updatedAt: now,
    );

    _notes.insert(0, note);
    _saveAndNotify();
  }

  void updateNote(InternalNote note) {
    final index = _notes.indexWhere((item) => item.id == note.id);

    if (index == -1) return;

    _notes[index] = note.copyWith(updatedAt: DateTime.now());
    _saveAndNotify();
  }

  void togglePinned(String noteId) {
    final index = _notes.indexWhere((note) => note.id == noteId);

    if (index == -1) return;

    final note = _notes[index];

    _notes[index] = note.copyWith(
      pinned: !note.pinned,
      updatedAt: DateTime.now(),
    );

    _saveAndNotify();
  }

  void toggleDone(String noteId) {
    final index = _notes.indexWhere((note) => note.id == noteId);

    if (index == -1) return;

    final note = _notes[index];

    _notes[index] = note.copyWith(
      done: !note.done,
      updatedAt: DateTime.now(),
    );

    _saveAndNotify();
  }

  void deleteNote(String noteId) {
    _notes.removeWhere((note) => note.id == noteId);
    _saveAndNotify();
  }

  Future<void> reloadFromStorage() async {
    _isLoading = true;
    notifyListeners();

    _notes.clear();

    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_notesStorageKey);

      if (saved != null && saved.trim().isNotEmpty) {
        final decoded = jsonDecode(saved);

        if (decoded is List) {
          _notes
            ..clear()
            ..addAll(
              decoded.whereType<Map>().map(
                    (item) => InternalNote.fromMap(
                      Map<String, dynamic>.from(item),
                    ),
                  ),
            );
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      _notes.map((note) => note.toMap()).toList(),
    );

    await prefs.setString(_notesStorageKey, encoded);
  }

  void _saveAndNotify() {
    notifyListeners();
    _saveNotes();
  }
}
