import 'package:flutter_test/flutter_test.dart';

import 'package:knoteapp/models/note.dart';

void main() {
  final created = DateTime.utc(2026, 1, 2, 3, 4, 5);
  final updated = DateTime.utc(2026, 1, 2, 3, 5, 5);

  test('round-trips a note through JSON', () {
    final note = Note(
      id: 'note-1',
      text: 'Write tests',
      isDone: true,
      createdAt: created,
      updatedAt: updated,
    );

    final restored = Note.fromJson({
      'id': note.id,
      'text': note.text,
      'isDone': note.isDone,
      'createdAt': created.toIso8601String(),
      'updatedAt': updated.toIso8601String(),
    });

    expect(restored.toJson(), {
      'id': 'note-1',
      'text': 'Write tests',
      'isDone': true,
      'createdAt': created.toIso8601String(),
      'updatedAt': updated.toIso8601String(),
    });
  });

  test('copyWith returns a new immutable note', () {
    final note = Note(
      id: 'note-1',
      text: 'Draft',
      createdAt: created,
      updatedAt: created,
    );
    final edited = note.copyWith(text: 'Published', updatedAt: updated);

    expect(note.text, 'Draft');
    expect(edited.text, 'Published');
    expect(edited.createdAt, created);
    expect(edited.updatedAt, updated);
  });

  test('rejects malformed note JSON', () {
    expect(
      () => Note.fromJson({'id': 'missing-timestamps', 'text': 'bad'}),
      throwsFormatException,
    );
  });
}
