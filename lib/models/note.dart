import 'dart:math';

/// A single note / todo point.
class Note {
  const Note({
    required this.id,
    required this.text,
    this.isDone = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique id (timestamp-based + random suffix).
  final String id;

  /// The note content.
  final String text;

  /// Whether the note has been completed.
  final bool isDone;

  /// When the note was first created.
  final DateTime createdAt;

  /// Last time the note was modified.
  final DateTime updatedAt;

  Note copyWith({String? text, bool? isDone, DateTime? updatedAt}) => Note(
    id: id,
    text: text ?? this.text,
    isDone: isDone ?? this.isDone,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// Serialize to JSON for storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Deserialize from JSON, rejecting malformed records rather than silently
  /// accepting invalid data.
  factory Note.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final text = json['text'];
    final isDone = json['isDone'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];

    if (id is! String || id.trim().isEmpty || text is! String) {
      throw const FormatException('A note must have an id and text.');
    }
    if (isDone != null && isDone is! bool) {
      throw const FormatException('Note completion must be a boolean.');
    }
    if (createdAt is! String || updatedAt is! String) {
      throw const FormatException('A note must have timestamps.');
    }

    return Note(
      id: id,
      text: text,
      isDone: isDone as bool? ?? false,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  /// Create a brand-new note with auto-generated id.
  factory Note.create(String text) {
    final now = DateTime.now();
    return Note(
      id: '${now.microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}',
      text: text,
      createdAt: now,
      updatedAt: now,
    );
  }
}
