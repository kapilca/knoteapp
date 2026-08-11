import 'dart:math';

/// A single note / todo point.
class Note {
  Note({
    required this.id,
    required this.text,
    this.isDone = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique id (timestamp-based + random suffix).
  final String id;

  /// The note content.
  String text;

  /// Whether the note has been struck out / completed.
  bool isDone;

  /// When the note was first created.
  final DateTime createdAt;

  /// Last time the note was modified.
  DateTime updatedAt;

  /// Serialize to JSON for storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Deserialize from JSON.
  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        text: json['text'] as String,
        isDone: json['isDone'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  /// Create a brand-new note with auto-generated id.
  factory Note.create(String text) {
    final now = DateTime.now();
    return Note(
      id: '${now.microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}',
      text: text,
      isDone: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}
