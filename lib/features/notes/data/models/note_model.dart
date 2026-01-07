import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'note_model.g.dart';

/// Represents a single note in the application.
///
/// This model is annotated for Hive database storage, allowing efficient
/// persistence without size limitations.
///
/// Each note contains:
/// - A unique identifier
/// - A title and content
/// - Creation timestamp
/// - A pastel background color for visual distinction
@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  /// Unique identifier for the note
  @HiveField(0)
  final String id;

  /// Title of the note (displayed prominently on cards)
  @HiveField(1)
  final String title;

  /// Main content/body of the note
  @HiveField(2)
  final String content;

  /// When the note was created
  @HiveField(3)
  final DateTime createdAt;

  /// Background color stored as ARGB integer for Hive compatibility
  @HiveField(4)
  final int backgroundColorValue;

  /// Getter to convert stored int back to Color
  Color get backgroundColor => Color(backgroundColorValue);

  /// Primary constructor used by Hive for deserialization
  /// Accepts backgroundColorValue directly as int
  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.backgroundColorValue,
  });

  /// Named constructor for creating notes with Color object
  /// Converts Color to int for storage
  NoteModel.withColor({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required Color backgroundColor,
  }) : backgroundColorValue = backgroundColor.toARGB32();

  /// Creates a copy of this note with optional parameter overrides.
  /// Useful for updating notes immutably.
  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    Color? backgroundColor,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      backgroundColorValue: backgroundColor?.toARGB32() ?? backgroundColorValue,
    );
  }

  /// Converts the note to a JSON-compatible Map.
  /// Kept for backwards compatibility and potential API use.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'backgroundColor': backgroundColorValue,
    };
  }

  /// Creates a NoteModel from a JSON Map.
  /// Useful for API responses or migration from other storage.
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      backgroundColorValue: json['backgroundColor'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, createdAt: $createdAt)';
  }
}
