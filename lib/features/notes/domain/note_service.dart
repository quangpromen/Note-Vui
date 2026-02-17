import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

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

  /// Listenable for database changes
  ValueListenable<Box<NoteModel>>? _boxListenable;

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
      // Load initial notes
      _notes = await _repository.loadNotes();
      _errorMessage = null;

      // Listen for database changes (reactive updates from sync/other sources)
      _boxListenable = await _repository.getListenable();
      _boxListenable?.addListener(_onDatabaseChanged);
    } catch (e) {
      _errorMessage = 'Không thể tải ghi chú: $e';
      _notes = [];
    } finally {
      _setLoading(false);
    }
  }

  /// Callback when Hive database changes.
  /// Reloads notes list to keep UI in sync with background operations.
  void _onDatabaseChanged() async {
    try {
      final newNotes = await _repository.loadNotes();

      // Basic check to see if we need to update UI
      // Ideally, check for equality, but reloading is cheap enough here
      _notes = newNotes;
      notifyListeners();
    } catch (e) {
      print('Error refreshing notes from DB: $e');
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

      _errorMessage = null;
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
      final noteToCheck = _notes.firstWhere(
        (n) => n.id == id,
        orElse: () => NoteModel(
          id: '',
          title: '',
          content: '',
          createdAt: DateTime.now(),
          backgroundColorValue: 0,
        ),
      );
      if (noteToCheck.id.isEmpty) {
        if (!_notes.any((n) => n.id == id)) {
          _errorMessage = 'Không tìm thấy ghi chú';
          notifyListeners();
          return false;
        }
      }

      final currentNote = _notes.firstWhere((n) => n.id == id);
      final updatedNote = currentNote.copyWith(title: title, content: content);

      await _repository.updateNote(updatedNote);

      _errorMessage = null;
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

      _errorMessage = null;
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

  /// Generates a unique ID (UUID v4) compatible with server GUID.
  String _generateUniqueId() {
    return const Uuid().v4();
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
    _boxListenable?.removeListener(_onDatabaseChanged);
    _repository.close();
    super.dispose();
  }
}
