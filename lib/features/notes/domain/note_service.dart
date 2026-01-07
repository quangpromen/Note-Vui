import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/models/note_model.dart';
import '../data/repositories/note_repository.dart';

/// Service class for managing notes state and business logic.
///
/// Uses ChangeNotifier to notify listeners (UI) when notes change.
/// Handles all CRUD operations and coordinates with the repository.
class NoteService extends ChangeNotifier {
  final NoteRepository _repository;
  List<NoteModel> _notes = [];
  bool _isLoading = true;

  NoteService({NoteRepository? repository})
    : _repository = repository ?? NoteRepository();

  /// Gets the current list of notes (read-only).
  List<NoteModel> get notes => List.unmodifiable(_notes);

  /// Whether the service is currently loading notes.
  bool get isLoading => _isLoading;

  /// Initializes the service by loading notes from storage.
  ///
  /// Call this once when the app starts.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _notes = await _repository.loadNotes();

    // Sort by creation date, newest first
    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _isLoading = false;
    notifyListeners();
  }

  /// Adds a new note and saves to storage.
  ///
  /// Automatically generates an ID and assigns a random pastel color.
  Future<void> addNote({required String title, required String content}) async {
    final note = NoteModel(
      id: _generateId(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      backgroundColor: _getRandomPastelColor(),
    );

    _notes.insert(0, note); // Add at the beginning (newest first)
    notifyListeners();

    await _repository.saveNotes(_notes);
  }

  /// Updates an existing note and saves to storage.
  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
  }) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) return;

    _notes[index] = _notes[index].copyWith(title: title, content: content);
    notifyListeners();

    await _repository.saveNotes(_notes);
  }

  /// Deletes a note and saves to storage.
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();

    await _repository.saveNotes(_notes);
  }

  /// Gets a note by its ID.
  NoteModel? getNoteById(String id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Generates a unique ID for a new note.
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Returns a random pastel color from the predefined palette.
  Color _getRandomPastelColor() {
    final random = Random();
    return AppColors.pastelColors[random.nextInt(
      AppColors.pastelColors.length,
    )];
  }
}
