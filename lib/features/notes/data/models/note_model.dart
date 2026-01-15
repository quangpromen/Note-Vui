import 'package:flutter/foundation.dart';
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
/// - Creation and update timestamps
/// - A pastel background color for visual distinction
/// - Tags for categorization (Smart Note feature)
/// - AI-generated summary (Smart Note feature)
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

  // ============ Smart Note Fields (v2.0) ============

  /// When the note was last updated (nullable for backward compatibility)
  /// This field is automatically set by the repository when updating a note.
  @HiveField(5)
  final DateTime? updatedAt;

  /// List of tags for categorization (Smart Note feature)
  /// Defaults to empty list for backward compatibility with existing data.
  /// Used for filtering and organizing notes.
  @HiveField(6)
  final List<String> tags;

  /// AI-generated summary of the note content (nullable)
  /// Populated by AI service when user requests a summary.
  @HiveField(7)
  final String? aiSummary;

  // ============ Getters ============

  /// Getter to convert stored int back to Color
  Color get backgroundColor => Color(backgroundColorValue);

  /// Primary constructor used by Hive for deserialization
  /// Accepts backgroundColorValue directly as int
  /// New fields (updatedAt, tags, aiSummary) are optional for backward compatibility
  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.backgroundColorValue,
    this.updatedAt,
    List<String>? tags,
    this.aiSummary,
  }) : tags = tags ?? const [];

  /// Named constructor for creating notes with Color object
  /// Converts Color to int for storage
  NoteModel.withColor({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required Color backgroundColor,
    this.updatedAt,
    List<String>? tags,
    this.aiSummary,
  }) : backgroundColorValue = backgroundColor.toARGB32(),
       tags = tags ?? const [];

  /// Creates a copy of this note with optional parameter overrides.
  /// Useful for updating notes immutably.
  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    Color? backgroundColor,
    DateTime? updatedAt,
    List<String>? tags,
    String? aiSummary,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      backgroundColorValue: backgroundColor?.toARGB32() ?? backgroundColorValue,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      aiSummary: aiSummary ?? this.aiSummary,
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
      'updatedAt': updatedAt?.toIso8601String(),
      'tags': tags,
      'aiSummary': aiSummary,
    };
  }

  /// Creates a NoteModel from a JSON Map.
  /// Useful for API responses or migration from other storage.
  /// Handles missing new fields gracefully for backward compatibility.
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      backgroundColorValue: json['backgroundColor'] as int,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      aiSummary: json['aiSummary'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoteModel &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.backgroundColorValue == backgroundColorValue &&
        other.updatedAt == updatedAt &&
        listEquals(other.tags, tags) &&
        other.aiSummary == aiSummary;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    createdAt,
    backgroundColorValue,
    updatedAt,
    Object.hashAll(tags),
    aiSummary,
  );

  @override
  String toString() {
    return 'NoteModel(id: $id, title: $title, createdAt: $createdAt, updatedAt: $updatedAt, tags: $tags)';
  }
}
