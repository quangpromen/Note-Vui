import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/models/note_model.dart';
import '../data/repositories/note_repository.dart';

/// Service class for managing notes state and business logic.
///
/// This service:
/// - Manages the in-memory list of notes
/// - Coordinates with [NoteRepository] for persistence
/// - Notifies listeners (UI) when notes change
/// - Provides a clean API for CRUD operations
///
/// Usage:
/// ```dart
/// final noteService = NoteService();
/// await noteService.initialize();
/// await noteService.addNote(title: 'My Note', content: 'Content');
/// ```
class NoteService extends ChangeNotifier {
  final NoteRepository _repository;

  /// Internal list of notes, kept in sync with database
  List<NoteModel> _notes = [];

  /// Loading state for async operations
  bool _isLoading = false;

  /// Error message if last operation failed
  String? _errorMessage;

  /// Creates a NoteService with optional custom repository.
  /// Useful for testing with mock repositories.
  NoteService({NoteRepository? repository})
    : _repository = repository ?? NoteRepository();

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Gets the current list of notes (read-only copy).
  List<NoteModel> get notes => List.unmodifiable(_notes);

  /// Whether the service is currently performing an async operation.
  bool get isLoading => _isLoading;

  /// Error message from the last failed operation, or null if successful.
  String? get errorMessage => _errorMessage;

  /// Whether there are any notes.
  bool get hasNotes => _notes.isNotEmpty;

  /// Total number of notes.
  int get noteCount => _notes.length;

  /// Access to repository for sync operations.
  /// Used by AuthService to trigger sync after login (Guest -> User merge).
  NoteRepository get repository => _repository;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initializes the service by loading notes from storage.
  ///
  /// Must be called once when the app starts, after [NoteRepository.initialize].
  Future<void> initialize() async {
    _setLoading(true);

    try {
      _notes = await _repository.loadNotes();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Không thể tải ghi chú: $e';
      _notes = [];
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  /// Adds a new note with the given title and content.
  ///
  /// Automatically generates a unique ID and assigns a random pastel color.
  /// Returns the created note, or null if creation failed.
  Future<NoteModel?> addNote({
    required String title,
    required String content,
  }) async {
    _setLoading(true);

    try {
      final note = NoteModel.withColor(
        id: _generateUniqueId(),
        title: title,
        content: content,
        createdAt: DateTime.now(),
        backgroundColor: _getRandomPastelColor(),
      );

      await _repository.addNote(note);

      // Add at the beginning (newest first)
      _notes.insert(0, note);
      _errorMessage = null;
      notifyListeners();

      return note;
    } catch (e) {
      _errorMessage = 'Không thể tạo ghi chú: $e';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Updates an existing note's title and/or content.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> updateNote({
    required String id,
    required String title,
    required String content,
  }) async {
    _setLoading(true);

    try {
      final index = _notes.indexWhere((note) => note.id == id);
      if (index == -1) {
        _errorMessage = 'Không tìm thấy ghi chú';
        notifyListeners();
        return false;
      }

      final updatedNote = _notes[index].copyWith(
        title: title,
        content: content,
      );

      await _repository.updateNote(updatedNote);

      _notes[index] = updatedNote;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật ghi chú: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes a note by its ID.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> deleteNote(String id) async {
    _setLoading(true);

    try {
      final deleted = await _repository.deleteNote(id);
      if (!deleted) {
        _errorMessage = 'Không tìm thấy ghi chú để xóa';
        notifyListeners();
        return false;
      }

      _notes.removeWhere((note) => note.id == id);
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa ghi chú: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================================
  // QUERY METHODS
  // ============================================================================

  /// Gets a note by its ID.
  ///
  /// Searches in-memory list first for performance.
  NoteModel? getNoteById(String id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Searches notes by title or content.
  ///
  /// Returns notes matching the query (case-insensitive).
  List<NoteModel> searchNotes(String query) {
    if (query.isEmpty) return _notes;

    final lowerQuery = query.toLowerCase();
    return _notes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  /// Sets loading state and notifies listeners.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Generates a unique ID based on timestamp and random suffix.
  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return '$timestamp$random';
  }

  /// Returns a random pastel color from the predefined palette.
  Color _getRandomPastelColor() {
    final random = Random();
    return AppColors.pastelColors[random.nextInt(
      AppColors.pastelColors.length,
    )];
  }

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  /// Disposes resources and closes database connection.
  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }
}
