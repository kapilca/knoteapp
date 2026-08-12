import 'package:flutter_test/flutter_test.dart';

import 'package:knoteapp/controllers/notes_controller.dart';
import 'package:knoteapp/models/note.dart';
import 'package:knoteapp/services/note_storage.dart';

class _MemoryStore implements NotesStore {
  _MemoryStore({required this.initial});

  final List<Note> initial;
  final List<List<Note>> saves = [];

  @override
  Future<List<Note>> loadNotes() async {
    return List<Note>.from(initial);
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    saves.add(List<Note>.from(notes));
  }
}

void main() {
  test('loads notes and serializes saves in order', () async {
    final store = _MemoryStore(initial: const []);
    final controller = NotesController(storage: store);
    await controller.ready;

    controller.add('First');
    controller.add('Second');
    await controller.flush();

    expect(controller.orderedNotes.map((note) => note.text), [
      'Second',
      'First',
    ]);
    expect(store.saves, hasLength(2));
    expect(store.saves.last.map((note) => note.text), ['Second', 'First']);
    controller.dispose();
  });

  test('completed notes are retained until clearCompleted is called', () async {
    final controller = NotesController(
      storage: _MemoryStore(initial: const []),
    );
    await controller.ready;

    controller.add('Keep me');
    final id = controller.orderedNotes.single.id;
    controller.toggle(id);

    expect(controller.completedCount, 1);
    expect(controller.findById(id), isNotNull);

    controller.clearCompleted();
    expect(controller.orderedNotes, isEmpty);
    controller.dispose();
  });
}
