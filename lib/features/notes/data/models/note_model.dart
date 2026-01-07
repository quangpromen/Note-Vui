import 'package:flutter/material.dart';

/// Represents a single note in the application.
///
/// Each note contains:
/// - A unique identifier
/// - A title and content
/// - Creation timestamp
/// - A pastel background color for visual distinction
class NoteModel {
  /// Unique identifier for the note
  final String id;

  /// Title of the note (displayed prominently on cards)
  final String title;

  /// Main content/body of the note
  final String content;

  /// When the note was created
  final DateTime createdAt;

  /// Pastel background color for the note card
  final Color backgroundColor;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.backgroundColor,
  });

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
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  /// Converts the note to a JSON-compatible Map for storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'backgroundColor': backgroundColor.toARGB32(),
    };
  }

  /// Creates a NoteModel from a JSON Map.
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      backgroundColor: Color(json['backgroundColor'] as int),
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
