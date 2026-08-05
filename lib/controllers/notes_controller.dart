import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/note_storage.dart';

/// Owns the in-memory list of notes and persists every change to
/// [NoteStorage].
///
/// A [ChangeNotifier], so any [AnimatedBuilder]/[ListenableBuilder] wired to it
/// rebuilds automatically when notes are added, edited, toggled or deleted.
class NotesController extends ChangeNotifier {
  NotesController() {
    _load();
  }

  final List<Note> _notes = [];
  bool _loaded = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// True once the initial load from storage has completed.
  bool get isLoaded => _loaded;

  /// Notes in their user-defined display order. Drag-and-drop reorders this
  /// list; new notes are inserted at the top.
  List<Note> get orderedNotes => List<Note>.from(_notes);

  int get completedCount => _notes.where((n) => n.isDone).length;

  Future<void> _load() async {
    _notes
      ..clear()
      ..addAll(await NoteStorage.loadNotes());
    _loaded = true;
    notifyListeners();
  }

  void add(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _notes.insert(0, Note.create(trimmed)); // newest on top
    notifyListeners();
    _persist();
  }

  void update(String id, String text) {
    final trimmed = text.trim();
    final i = _notes.indexWhere((n) => n.id == id);
    if (i == -1) return;
    if (trimmed.isEmpty) return; // empty notes are removed elsewhere
    final n = _notes[i];
    if (n.text == trimmed) return;
    n.text = trimmed;
    n.updatedAt = DateTime.now();
    notifyListeners();
    _persist();
  }

  void toggle(String id) {
    final i = _notes.indexWhere((n) => n.id == id);
    if (i == -1) return;
    final n = _notes[i];
    n.isDone = !n.isDone;
    n.updatedAt = DateTime.now();
    notifyListeners();
    _persist();
    _maybeAutoClear();
  }

  /// Once every note has been struck out, clear the whole list automatically.
  void _maybeAutoClear() {
    if (_notes.isEmpty || !_notes.every((n) => n.isDone)) return;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_disposed) return;
      // Re-check: the user may have un-struck a note during the delay.
      if (_notes.isNotEmpty && _notes.every((n) => n.isDone)) {
        _notes.clear();
        notifyListeners();
        _persist();
      }
    });
  }

  void remove(String id) {
    final i = _notes.indexWhere((n) => n.id == id);
    if (i == -1) return;
    _notes.removeAt(i);
    notifyListeners();
    _persist();
  }

  /// Re-insert [note] at [index]. Used to undo a [remove] (e.g. after a
  /// swipe-to-delete was dismissed).
  void insertAt(int index, Note note) {
    _notes.insert(index.clamp(0, _notes.length), note);
    notifyListeners();
    _persist();
  }

  /// Move a note from [oldIndex] to [newIndex]. Wired to
  /// ReorderableListView's `onReorderItem`, which already accounts for the
  /// removed item, so [newIndex] is the final target — no manual adjustment.
  void move(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _notes.length) return;
    if (oldIndex == newIndex) return;
    final note = _notes.removeAt(oldIndex);
    _notes.insert(newIndex.clamp(0, _notes.length), note);
    notifyListeners();
    _persist();
  }

  void clearCompleted() {
    final before = _notes.length;
    _notes.removeWhere((n) => n.isDone);
    if (_notes.length != before) {
      notifyListeners();
      _persist();
    }
  }

  Note? findById(String id) {
    final i = _notes.indexWhere((n) => n.id == id);
    return i == -1 ? null : _notes[i];
  }

  void _persist() {
    // Fire-and-forget; storage failures are non-fatal for an in-memory UI.
    NoteStorage.saveNotes(_notes);
  }
}
