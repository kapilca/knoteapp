# knoteapp

A small, offline-first note-taking app built with Flutter. Type quick notes or
dictate them with your voice — everything is stored locally on the device.

## Features

- **Quick add** from the bottom composer, or **dictate** with speech-to-text
  (tap the mic; recognized words stream straight into the field).
- **Tap a note** to open a full-screen editor that auto-saves as you type.
- **Check off** notes to mark them done, **swipe** or use the trash button to
  delete, and **Clear completed** from the overflow menu.
- **Light/dark theme** toggle.
- Notes persist across app restarts via `shared_preferences` (no account or
  backend required).

## Permissions

Speech recognition uses the microphone, so the Android manifest requests:

- `RECORD_AUDIO` (microphone)
- `INTERNET` (some devices use a network service for better accuracy)
- `WAKE_LOCK` (keep the screen on while dictating)

The plugin requests the microphone permission at runtime the first time you
dictate.

## Project layout

```
lib/
  main.dart                       # App entry + theme
  controllers/notes_controller.dart  # In-memory list + persistence
  models/note.dart                # Note data model
  services/
    note_storage.dart             # SharedPreferences persistence
    speech_service.dart           # speech_to_text wrapper
  screens/
    notes_screen.dart             # Home list + composer
    note_editor_screen.dart       # Full-screen editor
  widgets/note_tile.dart          # A single note row
```

## Running

```bash
flutter pub get
flutter run
```

Tests:

```bash
flutter test
```
