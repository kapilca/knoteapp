import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:knoteapp/models/note.dart';
import 'package:knoteapp/services/note_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'falls back to the previous payload when all current records are bad',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final backup = Note(
        id: 'backup',
        text: 'Recover me',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      await prefs.setString('notes.v1', '[{"not":"a note"}]');
      await prefs.setString('notes.v1.backup', jsonEncode([backup.toJson()]));

      final notes = await NoteStorage(preferences: prefs).loadNotes();

      expect(notes.single.text, 'Recover me');
    },
  );

  test('keeps valid records when one record is malformed', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notes.v1',
      jsonEncode([
        {
          'id': 'valid',
          'text': 'Keep me',
          'isDone': false,
          'createdAt': DateTime.utc(2026).toIso8601String(),
          'updatedAt': DateTime.utc(2026).toIso8601String(),
        },
        {'id': 'invalid'},
      ]),
    );

    final notes = await NoteStorage(preferences: prefs).loadNotes();

    expect(notes.map((note) => note.text), ['Keep me']);
  });
}
