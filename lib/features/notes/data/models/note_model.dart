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
/// - A unique identifier (local) and optional server ID
/// - A title and content
/// - Creation and update timestamps
/// - A pastel background color for visual distinction
/// - Tags for categorization (Smart Note feature)
/// - AI-generated summary (Smart Note feature)
/// - Sync flags for offline-first synchronization (Phase 3)
@HiveType(typeId: 0)
class NoteModel extends HiveObject {
  /// Unique identifier for the note (local ID, generated with UUID)
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

  // ============ Sync Fields (v3.0 - Offline-First) ============

  /// The ID from the server database (nullable until synced)
  /// This is the primary key on the .NET backend.
  /// Null means the note has never been synced to the server.
  @HiveField(8)
  final String? serverId;

  /// Whether this note has been synced with the server.
  /// Defaults to false. Set to true only when confirmed by server response.
  /// Notes with isSynced=false will be included in the next sync batch.
  @HiveField(9)
  final bool isSynced;

  /// Soft delete flag for offline-first deletion.
  /// When true, the note is marked for deletion but kept locally until synced.
  /// After successful sync, notes with isDeleted=true are physically removed.
  @HiveField(10)
  final bool isDeleted;

  // ============ Getters ============

  /// Getter to convert stored int back to Color
  Color get backgroundColor => Color(backgroundColorValue);

  /// Primary constructor used by Hive for deserialization
  /// Accepts backgroundColorValue directly as int
  /// All sync fields have default values for backward compatibility
  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.backgroundColorValue,
    this.updatedAt,
    List<String>? tags,
    this.aiSummary,
    this.serverId,
    bool? isSynced,
    bool? isDeleted,
  }) : tags = tags ?? const [],
       isSynced = isSynced ?? false,
       isDeleted = isDeleted ?? false;

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
    this.serverId,
    bool? isSynced,
    bool? isDeleted,
  }) : backgroundColorValue = backgroundColor.toARGB32(),
       tags = tags ?? const [],
       isSynced = isSynced ?? false,
       isDeleted = isDeleted ?? false;

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
    String? serverId,
    bool? isSynced,
    bool? isDeleted,
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
      serverId: serverId ?? this.serverId,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Converts the note to a JSON-compatible Map for local storage/debugging.
  /// Includes all fields including sync metadata.
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
      'serverId': serverId,
      'isSynced': isSynced,
      'isDeleted': isDeleted,
    };
  }

  /// Converts the note to a Sync DTO format expected by the .NET backend.
  /// Maps local fields to the server's NoteSyncDto structure.
  ///
  /// Server expects:
  /// - Id: Server ID (null for new notes)
  /// - ClientId: Local ID for mapping back
  /// - Title, Content: Note data
  /// - IsDeleted: Soft delete flag
  /// - UpdatedAt: Last modification time for conflict resolution
  Map<String, dynamic> toSyncDto() {
    return {
      'id': serverId, // Server ID (null if never synced)
      'clientId': id, // Local UUID for mapping
      'title': title,
      'content': content,
      'isDeleted': isDeleted,
      'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      // Include additional metadata the server might need
      'backgroundColor': backgroundColorValue,
      'tags': tags,
      'aiSummary': aiSummary,
    };
  }

  /// Creates a NoteModel from a JSON Map (local storage format).
  /// Useful for API responses or migration from other storage.
  /// Handles missing fields gracefully for backward compatibility.
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
      serverId: json['serverId'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  /// Creates a NoteModel from server response (Sync DTO format).
  /// Maps the server's response structure back to local model.
  ///
  /// Server returns:
  /// - Id: Server database ID
  /// - ClientId: The local ID we sent
  /// - Title, Content, IsDeleted, UpdatedAt, CreatedAt
  factory NoteModel.fromServerResponse(Map<String, dynamic> json) {
    return NoteModel(
      id: json['clientId'] as String? ?? json['id'] as String,
      serverId: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      backgroundColorValue: json['backgroundColor'] as int? ?? 0xFFFFFFFF,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      aiSummary: json['aiSummary'] as String?,
      isSynced: true, // Coming from server means it's synced
      isDeleted: json['isDeleted'] as bool? ?? false,
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
        other.aiSummary == aiSummary &&
        other.serverId == serverId &&
        other.isSynced == isSynced &&
        other.isDeleted == isDeleted;
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
    serverId,
    isSynced,
    isDeleted,
  );

  @override
  String toString() {
    return 'NoteModel(id: $id, serverId: $serverId, title: $title, isSynced: $isSynced, isDeleted: $isDeleted)';
  }
}
