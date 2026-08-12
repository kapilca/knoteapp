import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/notes_controller.dart';
import '../models/note.dart';
import '../services/speech_service.dart';
import '../widgets/note_tile.dart';
import 'note_editor_screen.dart';

/// The main screen: a list of notes with a quick-add / dictation composer at
/// the bottom.
class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onToggleTheme,
  });

  final NotesController controller;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _input = TextEditingController();
  final TextEditingController _search = TextEditingController();
  final SpeechService _speech = SpeechService.instance;
  String _query = '';
  _NoteFilter _filter = _NoteFilter.all;
  bool _searchOpen = false;

  /// Text present in the composer when dictation started; recognized words are
  /// appended after it.
  String _dictationBase = '';

  /// True while the [NoteEditorScreen] is on top. Used to keep this screen's
  /// speech listener from writing into the hidden composer while the editor
  /// owns dictation.
  bool _editorOpen = false;

  /// The currently shown "note deleted" notice, plus the data needed to undo.
  /// Shown at the top of the body so it never covers the composer input.
  ({int index, Note note})? _deletedNotice;

  /// Auto-hides the delete notice after a few seconds.
  Timer? _noticeTimer;

  @override
  void initState() {
    super.initState();
    _speech.listening.addListener(_onSpeechState);
    _speech.available.addListener(_onSpeechState);
    _speech.lastError.addListener(_onSpeechState);
    _speech.lastWords.addListener(_onWords);
  }

  @override
  void dispose() {
    _speech.listening.removeListener(_onSpeechState);
    _speech.available.removeListener(_onSpeechState);
    _speech.lastError.removeListener(_onSpeechState);
    _speech.lastWords.removeListener(_onWords);
    if (_speech.listening.value) _speech.stopListening();
    _noticeTimer?.cancel();
    _input.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSpeechState() {
    if (mounted) setState(() {});
  }

  void _onWords() {
    // While the editor is open it owns the mic; ignore updates here so we
    // don't clobber the composer hidden underneath.
    if (_editorOpen) return;
    final words = _speech.lastWords.value;
    final merged = _dictationBase.isEmpty
        ? words
        : (words.isEmpty ? _dictationBase : '$_dictationBase $words');
    _input.value = TextEditingValue(
      text: merged,
      selection: TextSelection.collapsed(offset: merged.length),
    );
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _query = '';
        _search.clear();
      }
    });
  }

  void _addNote() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    widget.controller.add(text);
    _input.clear();
  }

  Future<void> _toggleMic() async {
    if (_speech.listening.value) {
      await _speech.stopListening();
      if (mounted) setState(() {});
      return;
    }
    if (!_speech.available.value) {
      try {
        await _speech.init();
      } catch (_) {
        // Platform doesn't support speech recognition (e.g. tests / desktop).
      }
    }
    if (!_speech.available.value) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device.'),
          // Float *above* the composer so the input field stays tappable
          // while the message is visible.
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 84),
        ),
      );
      return;
    }
    _dictationBase = _input.text.trim();
    try {
      await _speech.startListening();
    } catch (_) {
      if (mounted) setState(() {});
      return;
    }
    if (mounted) setState(() {});
  }

  Future<void> _openEditor(Note note) async {
    // Capture the navigator before any await so we don't touch [context]
    // across an async gap.
    final navigator = Navigator.of(context);
    // Stop dictating into the composer while editing.
    if (_speech.listening.value) await _speech.stopListening();
    _editorOpen = true;
    await navigator.push(
      MaterialPageRoute(
        builder: (_) =>
            NoteEditorScreen(controller: widget.controller, noteId: note.id),
      ),
    );
    _editorOpen = false;
    if (mounted) setState(() {});
  }

  void _deleteNote(int index, Note note) {
    final controller = widget.controller;
    final originalIndex = controller.indexOf(note.id);
    controller.remove(note.id);
    if (!mounted) return;
    // Show a top banner (instead of a bottom SnackBar) so it never covers the
    // composer. Tapping the banner dismisses it; the Undo button restores it.
    setState(
      () => _deletedNotice = (
        index: originalIndex < 0 ? index : originalIndex,
        note: note,
      ),
    );
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 4), _dismissDeleteNotice);
  }

  void _dismissDeleteNotice() {
    _noticeTimer?.cancel();
    _noticeTimer = null;
    if (mounted) setState(() => _deletedNotice = null);
  }

  void _undoDelete() {
    final notice = _deletedNotice;
    if (notice == null) return;
    widget.controller.insertAt(notice.index, notice.note);
    _dismissDeleteNotice();
  }

  Future<void> _confirmClearCompleted(int count) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear completed?'),
        content: Text(
          'Remove $count completed ${count == 1 ? 'note' : 'notes'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) widget.controller.clearCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: _searchOpen
            ? TextField(
                controller: _search,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search notes',
                  border: InputBorder.none,
                ),
              )
            : const Text('My Notes'),
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search',
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            tooltip: widget.isDark ? 'Light mode' : 'Dark mode',
            icon: Icon(
              widget.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: widget.onToggleTheme,
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _confirmClearCompleted(controller.completedCount);
              } else if (value.startsWith('filter:')) {
                setState(() {
                  _filter = _NoteFilter.values.byName(value.substring(7));
                });
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String>(
                value: 'filter:all',
                child: Text('Show all notes'),
              ),
              const PopupMenuItem<String>(
                value: 'filter:active',
                child: Text('Show active notes'),
              ),
              const PopupMenuItem<String>(
                value: 'filter:completed',
                child: Text('Show completed notes'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'clear',
                enabled: controller.completedCount > 0,
                child: Text(
                  controller.completedCount > 0
                      ? 'Clear completed (${controller.completedCount})'
                      : 'Clear completed',
                ),
              ),
            ],
          ),
        ],
      ),
      // The composer is part of the body (not bottomNavigationBar) so the
      // Scaffold resizes it above the onscreen keyboard and the typed text
      // stays visible. resizeToAvoidBottomInset only shrinks the body.
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          Widget content;
          if (!controller.isLoaded) {
            content = const Center(child: CircularProgressIndicator());
          } else {
            final notes = controller.orderedNotes.where((note) {
              final matchesQuery =
                  _query.isEmpty ||
                  note.text.toLowerCase().contains(_query.toLowerCase());
              final matchesFilter = switch (_filter) {
                _NoteFilter.all => true,
                _NoteFilter.active => !note.isDone,
                _NoteFilter.completed => note.isDone,
              };
              return matchesQuery && matchesFilter;
            }).toList();
            content = notes.isEmpty
                ? _EmptyState(
                    message: _query.isNotEmpty || _filter != _NoteFilter.all
                        ? 'Try another search or filter.'
                        : null,
                  )
                : _NotesList(
                    notes: notes,
                    onToggle: controller.toggle,
                    onReorderItem: controller.move,
                    onTap: _openEditor,
                    onDelete: _deleteNote,
                    reorderable: _query.isEmpty && _filter == _NoteFilter.all,
                  );
          }
          return Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                reverseDuration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => SlideTransition(
                  position: animation.drive(
                    Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero),
                  ),
                  child: child,
                ),
                child: _deletedNotice == null
                    ? const SizedBox.shrink()
                    : _DeleteNotice(
                        key: const ValueKey('delete-notice'),
                        onDismiss: _dismissDeleteNotice,
                        onUndo: _undoDelete,
                      ),
              ),
              Expanded(child: content),
              _Composer(
                controller: _input,
                theme: theme,
                listening: _speech.listening.value,
                error: _speech.lastError.value,
                onSend: _addNote,
                onMic: _toggleMic,
                enabled: controller.isLoaded,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({
    required this.notes,
    required this.onToggle,
    required this.onReorderItem,
    required this.onTap,
    required this.onDelete,
    required this.reorderable,
  });

  final List<Note> notes;
  final void Function(String id) onToggle;
  final void Function(int oldIndex, int newIndex) onReorderItem;
  final void Function(Note note) onTap;
  final void Function(int index, Note note) onDelete;
  final bool reorderable;

  Widget _item(BuildContext context, int index) {
    final theme = Theme.of(context);
    final note = notes[index];
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(index, note),
      child: NoteTile(
        index: index,
        note: note,
        onToggle: () => onToggle(note.id),
        onTap: () => onTap(note),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!reorderable) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: notes.length,
        itemBuilder: _item,
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: notes.length,
      onReorderItem: onReorderItem,
      itemBuilder: _item,
    );
  }
}

enum _NoteFilter { all, active, completed }

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message == null ? 'No notes yet' : 'No matching notes',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'Type below to jot something down, or tap the mic to dictate.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom composer: text field + dictation mic + send.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.theme,
    required this.listening,
    required this.error,
    required this.onSend,
    required this.onMic,
    required this.enabled,
  });

  final TextEditingController controller;
  final ThemeData theme;
  final bool listening;
  final String? error;
  final VoidCallback onSend;
  final VoidCallback onMic;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                enabled: enabled,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: listening ? 'Listening…' : 'Add a note',
                  errorText: error,
                  prefixIcon: listening
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _MicButton(
              listening: listening,
              enabled: enabled,
              onPressed: onMic,
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              heroTag: 'add-note',
              elevation: 0,
              highlightElevation: 0,
              onPressed: enabled ? onSend : null,
              tooltip: 'Add note',
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.listening,
    required this.enabled,
    required this.onPressed,
  });

  final bool listening;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton(
      heroTag: 'dictate',
      elevation: 0,
      highlightElevation: 0,
      tooltip: listening ? 'Stop dictation' : 'Dictate',
      backgroundColor: listening
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surfaceContainerHigh,
      foregroundColor: listening
          ? theme.colorScheme.onErrorContainer
          : theme.colorScheme.primary,
      onPressed: enabled ? onPressed : null,
      child: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
    );
  }
}

/// Top banner shown after a note is deleted. Tapping anywhere on it dismisses
/// it (the user has seen it); the Undo button restores the deleted note.
class _DeleteNotice extends StatelessWidget {
  const _DeleteNotice({
    super.key,
    required this.onDismiss,
    required this.onUndo,
  });

  final VoidCallback onDismiss;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.inverseSurface,
      child: InkWell(
        onTap: onDismiss,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 20,
                color: theme.colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Note deleted',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onInverseSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: onUndo,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.inversePrimary,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Undo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
