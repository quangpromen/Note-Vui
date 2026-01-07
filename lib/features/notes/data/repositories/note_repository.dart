import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_model.dart';

/// Repository for persisting notes to local storage.
///
/// Uses SharedPreferences to store notes as a JSON array.
/// This provides simple, reliable local storage that persists across app restarts.
class NoteRepository {
  static const String _storageKey = 'notes_data';

  /// Loads all notes from local storage.
  ///
  /// Returns an empty list if no notes are stored.
  Future<List<NoteModel>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((item) => NoteModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  /// Saves all notes to local storage.
  ///
  /// This overwrites any existing stored notes.
  Future<bool> saveNotes(List<NoteModel> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notes.map((note) => note.toJson()).toList();
    final jsonString = json.encode(jsonList);
    return prefs.setString(_storageKey, jsonString);
  }

  /// Clears all stored notes.
  Future<bool> clearNotes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_storageKey);
  }
}
