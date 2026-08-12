import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';

/// A single row representing a [Note]. Swipe the row left to delete it (with
/// an undo option); tap the trailing button to toggle a line-through; tap the
/// row to edit; drag the leading handle to reorder. Rows alternate background
/// shades by [index].
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.index,
    required this.onToggle,
    required this.onTap,
  });

  final Note note;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = note.isDone ? theme.colorScheme.outline : null;
    // Zebra striping: alternate between two surface shades by row parity.
    final base = index.isOdd
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerLow;

    return Card(
      elevation: 0,
      color: note.isDone ? base.withValues(alpha: 0.55) : base,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.only(
          left: 8,
          right: 8,
          top: 4,
          bottom: 4,
        ),
        leading: Semantics(
          button: true,
          label: 'Reorder note ${index + 1}',
          child: ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.drag_indicator,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ),
        title: Text(
          note.text,
          style: TextStyle(
            decoration: note.isDone ? TextDecoration.lineThrough : null,
            color: muted,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatTime(note),
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        trailing: IconButton(
          tooltip: note.isDone ? 'Remove strikethrough' : 'Strike through',
          icon: Icon(
            note.isDone ? Icons.check_circle : Icons.format_strikethrough,
            color: note.isDone
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  String _formatTime(Note note) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final created = DateTime(
      note.createdAt.year,
      note.createdAt.month,
      note.createdAt.day,
    );
    final dayDiff = today.difference(created).inDays;
    final clock = DateFormat.jm().format(note.createdAt);
    if (dayDiff == 0) return 'Today, $clock';
    if (dayDiff == 1) return 'Yesterday, $clock';
    return '${DateFormat.yMMMd().format(note.createdAt)}, $clock';
  }
}
