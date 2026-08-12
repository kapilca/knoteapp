import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

/// Storage abstraction used by [NotesController], allowing deterministic tests.
abstract interface class NotesStore {
  Future<List<Note>> loadNotes();

  Future<void> saveNotes(List<Note> notes);
}

/// Persists notes locally using SharedPreferences and JSON encoding.
class NoteStorage implements NotesStore {
  NoteStorage({this.preferences});

  static const String _key = 'notes.v1';
  static const String _backupKey = 'notes.v1.backup';

  final SharedPreferences? preferences;

  Future<SharedPreferences> get _prefs async =>
      preferences ?? SharedPreferences.getInstance();

  @override
  Future<List<Note>> loadNotes() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final parsed = _decode(raw);
    if (parsed != null) return parsed;

    // If the current payload is malformed, try the last known-good payload
    // before presenting an empty list to the user.
    final backup = prefs.getString(_backupKey);
    final recovered = backup == null ? null : _decode(backup);
    return recovered ?? [];
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    final prefs = await _prefs;
    final previous = prefs.getString(_key);
    if (previous != null && previous.isNotEmpty) {
      await prefs.setString(_backupKey, previous);
    }

    // Encode a snapshot supplied by the controller, not a mutable live list.
    final encoded = jsonEncode(notes.map((note) => note.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  List<Note>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;

      final notes = <Note>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          notes.add(Note.fromJson(Map<String, dynamic>.from(item)));
        } on FormatException {
          // Keep valid records even if one old/corrupt record is unusable.
        }
      }
      // An empty JSON array is valid. A non-empty payload with no valid
      // records is treated as corrupt so loadNotes() can try the backup.
      if (decoded.isNotEmpty && notes.isEmpty) return null;
      return notes;
    } on Object {
      return null;
    }
  }
}
