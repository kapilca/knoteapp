import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../controllers/notes_controller.dart';
import '../services/speech_service.dart';

/// Full-screen editor for a single note. Edits auto-save to the controller,
/// and the note is deleted if it's left empty.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.controller,
    required this.noteId,
  });

  final NotesController controller;
  final String noteId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _text;
  final SpeechService _speech = SpeechService.instance;
  String _dictationBase = '';

  @override
  void initState() {
    super.initState();
    final note = widget.controller.findById(widget.noteId);
    _text = TextEditingController(text: note?.text ?? '');
    _text.addListener(_onTextChanged);
    _speech.listening.addListener(_onState);
    _speech.lastWords.addListener(_onWords);
  }

  @override
  void dispose() {
    _text.removeListener(_onTextChanged);
    _speech.listening.removeListener(_onState);
    _speech.lastWords.removeListener(_onWords);
    if (_speech.listening.value) _speech.stopListening();
    final trimmed = _text.text.trim();
    _text.dispose();
    // A note that's been emptied has no value — remove it.
    if (trimmed.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.remove(widget.noteId);
      });
    }
    super.dispose();
  }

  void _onState() {
    if (mounted) setState(() {});
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _onWords() {
    final words = _speech.lastWords.value;
    final merged = _dictationBase.isEmpty
        ? words
        : (words.isEmpty ? _dictationBase : '$_dictationBase $words');
    _text.value = TextEditingValue(
      text: merged,
      selection: TextSelection.collapsed(offset: merged.length),
    );
    widget.controller.update(widget.noteId, merged);
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
        // Platform without speech support.
      }
    }
    if (!_speech.available.value) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _dictationBase = _text.text.trim();
    await _speech.startListening();
    if (mounted) setState(() {});
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      widget.controller.remove(widget.noteId);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listening = _speech.listening.value;
    final title = _text.text.trim();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title.isEmpty ? 'Edit note' : title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: title.isEmpty ? null : const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_outlined),
            onPressed: _copy,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: AnimatedBuilder(
          animation: widget.controller,
              builder: (context, _) {
                final n = widget.controller.findById(widget.noteId);
                if (n == null) {
                  return const Center(child: Text('This note no longer exists.'));
                }
                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _text,
                          autofocus: true,
                          maxLines: null,
                          expands: true,
                          textCapitalization: TextCapitalization.sentences,
                          textAlignVertical: TextAlignVertical.top,
                          style: theme.textTheme.bodyLarge,
                          decoration: const InputDecoration(
                            hintText: 'Type your note…',
                            border: InputBorder.none,
                          ),
                          onChanged: (value) =>
                              widget.controller.update(widget.noteId, value),
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          Divider(height: 1, color: theme.dividerColor),
                          SwitchListTile(
                            secondary: Icon(
                              n.isDone
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(
                              n.isDone ? 'Completed' : 'Mark as completed',
                            ),
                            value: n.isDone,
                            onChanged: (_) =>
                                widget.controller.toggle(widget.noteId),
                          ),
                          ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.access_time,
                              color: theme.colorScheme.outline,
                            ),
                            title: Text(
                              'Created ${DateFormat.yMMMd().add_jm().format(n.createdAt)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'editor-dictate',
        onPressed: _toggleMic,
        backgroundColor: listening
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        foregroundColor: listening
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.onPrimaryContainer,
        icon: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
        label: Text(listening ? 'Stop' : 'Dictate'),
      ),
    );
  }
}
