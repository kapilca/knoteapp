# My Notes

A small, offline-first note-taking app built with Flutter. Type quick notes or
dictate them with your voice—everything is stored locally on the device.

## Features

- **Quick add** from the bottom composer, or **dictate** with speech-to-text.
- **Tap a note** to open a full-screen editor with debounced auto-save.
- **Check off** notes without deleting them.
- **Clear completed** notes explicitly from the overflow menu.
- **Search** note text and filter by all, active, or completed notes.
- **Swipe** notes to delete them with an undo action.
- **Reorder** notes with the accessible drag handle.
- **Copy** note text from the editor.
- **Light/dark theme** with the preference persisted locally.
- Notes persist locally through a serialized storage queue.
- Malformed records are skipped where possible and the previous payload is kept
  as a local recovery backup.

## Permissions

Speech recognition uses the microphone, so the Android manifest requests:

- `RECORD_AUDIO` (microphone)
- `INTERNET` (some devices use a network service for better accuracy)
- `WAKE_LOCK` (keep the screen on while dictating)

The plugin requests microphone permission at runtime the first time you dictate.
The app does not send note data to a backend. Speech recognition behavior can
still depend on the Android speech provider and network availability.

## Project layout

```
lib/
  main.dart                          # App entry + persisted theme
  controllers/notes_controller.dart  # Immutable state + queued persistence
  models/note.dart                    # Validated immutable note model
  services/
    note_storage.dart                 # Local storage + recovery backup
    speech_service.dart               # Speech-to-text lifecycle wrapper
  screens/
    notes_screen.dart                 # Search, filters, list + composer
    note_editor_screen.dart           # Debounced full-screen editor
  widgets/note_tile.dart              # Accessible note row
```

## Running

```bash
flutter pub get
flutter run
```

Tests:

```bash
flutter analyze
flutter test
```

## Release checklist

Before publishing, replace the placeholder Android application ID
`com.example.knoteapp`, configure a real release keystore instead of the debug
signing configuration, update the version/build number, verify launcher icons,
and test microphone behavior on physical Android devices. Only the Android
platform is currently included in this project.
