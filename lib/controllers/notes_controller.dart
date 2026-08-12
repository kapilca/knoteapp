import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/note_storage.dart';

/// Owns the in-memory list of notes and persists every change.
class NotesController extends ChangeNotifier {
  NotesController({NotesStore? storage}) : _storage = storage ?? NoteStorage() {
    _loadFuture = _load();
  }

  final NotesStore _storage;
  final List<Note> _notes = [];
  late final Future<void> _loadFuture;
  Future<void> _saveChain = Future<void>.value();
  bool _loaded = false;
  bool _disposed = false;
  String? _storageError;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Completes when the initial storage read finishes.
  Future<void> get ready => _loadFuture;

  /// True once the initial load from storage has completed.
  bool get isLoaded => _loaded;

  /// A human-readable storage error, if the last load or save failed.
  String? get storageError => _storageError;

  /// Notes in their user-defined display order.
  List<Note> get orderedNotes => List<Note>.unmodifiable(_notes);

  int get completedCount => _notes.where((note) => note.isDone).length;

  Future<void> _load() async {
    try {
      final loaded = await _storage.loadNotes();
      if (_disposed) return;
      _notes
        ..clear()
        ..addAll(loaded);
    } on Object catch (error) {
      if (_disposed) return;
      _storageError = 'Could not load notes: $error';
    }

    if (_disposed) return;
    _loaded = true;
    notifyListeners();
  }

  bool get _canMutate => _loaded && !_disposed;

  void add(String text) {
    if (!_canMutate) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _notes.insert(0, Note.create(trimmed));
    _changed();
  }

  /// Update a note. Set [persist] to false while debouncing editor input.
  void update(String id, String text, {bool persist = true}) {
    if (!_canMutate) return;
    final trimmed = text.trim();
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1 || trimmed.isEmpty) return;

    final note = _notes[index];
    if (note.text == trimmed) return;
    _notes[index] = note.copyWith(text: trimmed, updatedAt: DateTime.now());
    _changed(persist: persist);
  }

  void toggle(String id) {
    if (!_canMutate) return;
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) return;

    final note = _notes[index];
    _notes[index] = note.copyWith(
      isDone: !note.isDone,
      updatedAt: DateTime.now(),
    );
    _changed();
  }

  void remove(String id) {
    if (!_canMutate) return;
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) return;
    _notes.removeAt(index);
    _changed();
  }

  /// Find the current full-list position of a note, useful for undo after a
  /// filtered list has been displayed.
  int indexOf(String id) => _notes.indexWhere((note) => note.id == id);

  /// Re-insert [note] at [index]. Used to undo a remove.
  void insertAt(int index, Note note) {
    if (!_canMutate || _notes.any((item) => item.id == note.id)) return;
    _notes.insert(index.clamp(0, _notes.length), note);
    _changed();
  }

  void move(int oldIndex, int newIndex) {
    if (!_canMutate || oldIndex < 0 || oldIndex >= _notes.length) return;
    if (oldIndex == newIndex) return;
    final note = _notes.removeAt(oldIndex);
    _notes.insert(newIndex.clamp(0, _notes.length), note);
    _changed();
  }

  void clearCompleted() {
    if (!_canMutate) return;
    final before = _notes.length;
    _notes.removeWhere((note) => note.isDone);
    if (_notes.length != before) _changed();
  }

  Note? findById(String id) {
    final index = _notes.indexWhere((note) => note.id == id);
    return index == -1 ? null : _notes[index];
  }

  /// Explicitly queue the current state for persistence. Useful after a
  /// debounced editor update or before leaving the app.
  Future<void> save() {
    if (!_loaded || _disposed) return Future<void>.value();
    return _enqueueSave();
  }

  /// Wait for all queued writes to finish.
  Future<void> flush() => _saveChain;

  void _changed({bool persist = true}) {
    if (_disposed) return;
    notifyListeners();
    if (persist) unawaited(_enqueueSave());
  }

  Future<void> _enqueueSave() {
    final snapshot = List<Note>.unmodifiable(_notes);
    _saveChain = _saveChain.then<void>(
      (_) => _saveSnapshot(snapshot),
      onError: (error, stack) => _saveSnapshot(snapshot),
    );
    return _saveChain;
  }

  Future<void> _saveSnapshot(List<Note> snapshot) async {
    try {
      await _storage.saveNotes(snapshot);
      if (!_disposed) {
        _storageError = null;
        notifyListeners();
      }
    } on Object catch (error) {
      if (!_disposed) {
        _storageError = 'Could not save notes: $error';
        notifyListeners();
      }
    }
  }
}
