import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

/// Persists the list of notes locally using SharedPreferences (JSON encoded).
///
/// This keeps notes across app restarts without needing a backend or a
/// heavier database. For thousands of notes you'd switch to Hive/SQLite,
/// but SharedPreferences is perfectly fine for personal note-taking.
class NoteStorage {
  NoteStorage._();

  static const String _key = 'notes.v1';

  static Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt data — start fresh rather than crashing.
      return [];
    }
  }

  static Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(notes.map((n) => n.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
