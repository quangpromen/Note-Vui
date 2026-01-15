import 'package:hive_flutter/hive_flutter.dart';

import '../models/note_model.dart';

/// Repository for persisting notes using Hive database.
///
/// Hive provides:
/// - Fast read/write operations
/// - No size limitations
/// - Native Dart object storage
/// - Automatic persistence
///
/// This repository follows the Repository pattern, abstracting
/// the data layer from the rest of the application.
class NoteRepository {
  /// The name of the Hive box for storing notes
  static const String _boxName = 'notes';

  /// Cached reference to the notes box
  Box<NoteModel>? _box;

  /// Gets the notes box, opening it if necessary.
  /// This is an internal method to ensure the box is always available.
  Future<Box<NoteModel>> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<NoteModel>(_boxName);
    return _box!;
  }

  /// Initializes the Hive database.
  ///
  /// Must be called once before any other operations.
  /// Typically called in main.dart before runApp().
  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteModelAdapter());
  }

  /// Loads all notes from the database.
  ///
  /// Returns notes sorted by creation date (newest first).
  Future<List<NoteModel>> loadNotes() async {
    final box = await _getBox();
    final notes = box.values.toList();

    // Sort by creation date, newest first
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return notes;
  }

  /// Saves a new note to the database.
  ///
  /// Uses the note's ID as the key for efficient retrieval.
  Future<void> addNote(NoteModel note) async {
    final box = await _getBox();
    await box.put(note.id, note);
  }

  /// Updates an existing note in the database.
  ///
  /// Automatically sets the [updatedAt] field to the current timestamp
  /// before saving to track modification history.
  ///
  /// Throws [NoteNotFoundException] if the note doesn't exist.
  Future<void> updateNote(NoteModel note) async {
    final box = await _getBox();
    if (!box.containsKey(note.id)) {
      throw NoteNotFoundException(note.id);
    }

    // Automatically set updatedAt to current time before saving
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    await box.put(note.id, updatedNote);
  }

  /// Searches notes by query string.
  ///
  /// Returns notes where the [query] appears in:
  /// - Title
  /// - Content
  /// - Any tag in the tags list
  ///
  /// Search is case-insensitive for better user experience.
  /// Results are sorted by creation date (newest first).
  Future<List<NoteModel>> searchNotes(String query) async {
    final box = await _getBox();
    final allNotes = box.values.toList();

    // Empty query returns all notes
    if (query.trim().isEmpty) {
      allNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allNotes;
    }

    final lowerQuery = query.toLowerCase();

    // Filter notes where query matches title, content, or any tag
    final filteredNotes = allNotes.where((note) {
      // Check title
      if (note.title.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Check content
      if (note.content.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // Check tags - return true if any tag contains the query
      for (final tag in note.tags) {
        if (tag.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }

      return false;
    }).toList();

    // Sort by creation date, newest first
    filteredNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filteredNotes;
  }

  /// Deletes a note from the database.
  ///
  /// Returns true if the note was deleted, false if it didn't exist.
  Future<bool> deleteNote(String id) async {
    final box = await _getBox();
    if (!box.containsKey(id)) {
      return false;
    }
    await box.delete(id);
    return true;
  }

  /// Gets a single note by its ID.
  ///
  /// Returns null if the note doesn't exist.
  Future<NoteModel?> getNoteById(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  /// Checks if a note with the given ID exists.
  Future<bool> exists(String id) async {
    final box = await _getBox();
    return box.containsKey(id);
  }

  /// Returns the total number of notes stored.
  Future<int> count() async {
    final box = await _getBox();
    return box.length;
  }

  /// Clears all notes from the database.
  ///
  /// Use with caution - this action cannot be undone.
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }

  /// Closes the database connection.
  ///
  /// Call this when the app is disposed or no longer needs the database.
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }
}

/// Exception thrown when a note is not found in the database.
class NoteNotFoundException implements Exception {
  final String noteId;

  NoteNotFoundException(this.noteId);

  @override
  String toString() =>
      'NoteNotFoundException: Note with ID "$noteId" not found';
}
