import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../services/auth_service.dart';
import '../datasources/sync_client.dart';
import '../models/note_model.dart';

/// Repository for persisting notes using Hive database with offline-first sync.
///
/// This repository implements the Offline-First pattern:
/// - All changes are immediately saved to Hive (Single Source of Truth)
/// - Changes are marked with `isSynced = false`
/// - Background sync is triggered after each change
/// - Server responses update local data and mark as synced
/// - Soft deletes are used until server confirms deletion
///
/// Hive provides:
/// - Fast read/write operations
/// - No size limitations
/// - Native Dart object storage
/// - Automatic persistence
class NoteRepository {
  /// The name of the Hive box for storing notes
  static const String _boxName = 'notes';

  /// Cached reference to the notes box
  Box<NoteModel>? _box;

  /// UUID generator for local IDs
  final Uuid _uuid = const Uuid();

  /// API client for syncing with server
  final SyncClient _syncClient;

  /// Connectivity checker
  final Connectivity _connectivity;

  /// Flag to prevent concurrent sync operations
  bool _isSyncing = false;

  /// Creates a new NoteRepository with optional injected dependencies.
  ///
  /// [syncClient] - Custom SyncClient for testing
  /// [connectivity] - Custom Connectivity for testing
  NoteRepository({SyncClient? syncClient, Connectivity? connectivity})
    : _syncClient = syncClient ?? SyncClient(),
      _connectivity = connectivity ?? Connectivity();

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

  /// Loads all non-deleted notes from the database.
  ///
  /// Returns notes sorted by creation date (newest first).
  /// Filters out soft-deleted notes (isDeleted == true).
  Future<List<NoteModel>> loadNotes() async {
    final box = await _getBox();

    // Filter out deleted notes - they shouldn't be visible to UI
    final notes = box.values.where((note) => !note.isDeleted).toList();

    // Sort by creation date, newest first
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return notes;
  }

  /// Saves a new note to the database.
  ///
  /// - Generates a UUID if the note ID is empty
  /// - Sets `isSynced = false` to mark for sync
  /// - Sets `updatedAt` to current timestamp
  /// - Saves to Hive immediately
  /// - Triggers background sync (fire-and-forget)
  Future<void> addNote(NoteModel note) async {
    final box = await _getBox();

    // Generate local ID if not provided
    final noteId = note.id.isEmpty ? _uuid.v4() : note.id;
    final now = DateTime.now();

    // Create note with sync metadata
    final noteToSave = note.copyWith(
      id: noteId,
      isSynced: false, // Mark as pending sync
      updatedAt: now,
    );

    await box.put(noteId, noteToSave);

    // Trigger background sync (fire-and-forget)
    syncPendingNotes();
  }

  /// Updates an existing note in the database.
  ///
  /// - Sets `isSynced = false` to mark for sync
  /// - Sets `updatedAt` to current timestamp
  /// - Saves to Hive immediately
  /// - Triggers background sync (fire-and-forget)
  ///
  /// Throws [NoteNotFoundException] if the note doesn't exist.
  Future<void> updateNote(NoteModel note) async {
    final box = await _getBox();
    if (!box.containsKey(note.id)) {
      throw NoteNotFoundException(note.id);
    }

    final now = DateTime.now();

    // Update with sync metadata
    final updatedNote = note.copyWith(
      isSynced: false, // Mark as pending sync
      updatedAt: now,
    );

    await box.put(note.id, updatedNote);

    // Trigger background sync (fire-and-forget)
    syncPendingNotes();
  }

  /// Soft-deletes a note (marks for deletion but keeps in database).
  ///
  /// Instead of physically deleting:
  /// - Sets `isDeleted = true`
  /// - Sets `isSynced = false` to sync the deletion
  /// - Sets `updatedAt` to current timestamp
  /// - Saves to Hive
  /// - Triggers background sync
  ///
  /// The note will be physically deleted after successful server sync.
  /// Returns true if the note was marked for deletion, false if not found.
  Future<bool> deleteNote(String id) async {
    final box = await _getBox();
    final existingNote = box.get(id);

    if (existingNote == null) {
      return false;
    }

    final now = DateTime.now();

    // Soft delete - mark as deleted, pending sync
    final deletedNote = existingNote.copyWith(
      isDeleted: true,
      isSynced: false,
      updatedAt: now,
    );

    await box.put(id, deletedNote);

    // Trigger background sync (fire-and-forget)
    syncPendingNotes();

    return true;
  }

  /// Searches notes by query string.
  ///
  /// Returns non-deleted notes where the [query] appears in:
  /// - Title
  /// - Content
  /// - Any tag in the tags list
  ///
  /// Search is case-insensitive for better user experience.
  /// Results are sorted by creation date (newest first).
  Future<List<NoteModel>> searchNotes(String query) async {
    final box = await _getBox();

    // Filter out deleted notes first
    final allNotes = box.values.where((note) => !note.isDeleted).toList();

    // Empty query returns all non-deleted notes
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

  /// Gets a single non-deleted note by its ID.
  ///
  /// Returns null if the note doesn't exist or is deleted.
  Future<NoteModel?> getNoteById(String id) async {
    final box = await _getBox();
    final note = box.get(id);

    // Don't return deleted notes
    if (note != null && note.isDeleted) {
      return null;
    }

    return note;
  }

  /// Checks if a non-deleted note with the given ID exists.
  Future<bool> exists(String id) async {
    final box = await _getBox();
    final note = box.get(id);
    return note != null && !note.isDeleted;
  }

  /// Returns the total number of non-deleted notes stored.
  Future<int> count() async {
    final box = await _getBox();
    return box.values.where((note) => !note.isDeleted).length;
  }

  /// Returns the number of notes pending sync.
  Future<int> pendingCount() async {
    final box = await _getBox();
    return box.values.where((note) => !note.isSynced).length;
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
    _syncClient.dispose();
  }

  // ============ Sync Logic ============

  /// Syncs all pending notes with the server.
  ///
  /// This method is called automatically after add/update/delete operations.
  /// It's "fire-and-forget" - exceptions are caught and logged.
  ///
  /// **CRITICAL for Guest Mode:**
  /// - If user is NOT logged in (Guest), returns immediately without API call.
  /// - This allows Guests to save notes to Hive without network errors.
  ///
  /// Sync Flow:
  /// 1. Check if user is logged in - return if Guest
  /// 2. Check network connectivity - return if offline
  /// 3. Gather all notes where `isSynced == false`
  /// 4. Send to server via SyncClient
  /// 5. Process server response:
  ///    - If note has `isDeleted == true`: physically delete from Hive
  ///    - Otherwise: update/insert into Hive with `isSynced = true`
  ///
  /// Made public for AuthService to call after login (Guest -> User merge).
  Future<void> syncPendingNotes() async {
    // **CRITICAL:** Check if user is logged in - Guests cannot sync
    final isUser = await AuthService().isLoggedIn();
    if (!isUser) {
      print('[NoteRepository] Guest mode - sync skipped');
      return; // Stop immediately. Do not call API.
    }

    // Prevent concurrent sync operations
    if (_isSyncing) {
      print('[NoteRepository] Sync already in progress, skipping...');
      return;
    }

    _isSyncing = true;

    try {
      // Step 1: Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('[NoteRepository] Offline - sync deferred');
        return;
      }

      final box = await _getBox();

      // Step 2: Gather all pending notes (isSynced == false)
      final pendingNotes = box.values.where((note) => !note.isSynced).toList();

      if (pendingNotes.isEmpty) {
        print('[NoteRepository] No pending notes to sync');
        return;
      }

      print('[NoteRepository] Syncing ${pendingNotes.length} pending notes...');

      // Step 3: Send to server
      final serverNotes = await _syncClient.syncNotes(pendingNotes);

      // Step 4: Process server response
      for (final serverNote in serverNotes) {
        if (serverNote.isDeleted) {
          // Physically delete notes confirmed as deleted by server
          print('[NoteRepository] Deleting confirmed: ${serverNote.id}');
          await box.delete(serverNote.id);
        } else {
          // Update local note with server data and mark as synced
          print(
            '[NoteRepository] Synced: ${serverNote.id} -> ${serverNote.serverId}',
          );
          final syncedNote = serverNote.copyWith(isSynced: true);
          await box.put(serverNote.id, syncedNote);
        }
      }

      print('[NoteRepository] Sync completed successfully');
    } on SyncException catch (e) {
      // Log sync errors but don't throw - data stays local for retry
      print('[NoteRepository] Sync failed: $e');
      print(
        '[NoteRepository] Data preserved locally - will retry on next change',
      );
    } catch (e) {
      // Catch any unexpected errors
      print('[NoteRepository] Unexpected sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Manually triggers a sync operation.
  ///
  /// Useful for pull-to-refresh or manual sync button.
  /// Returns true if sync was successful, false otherwise.
  Future<bool> manualSync() async {
    try {
      // Check connectivity first
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('[NoteRepository] Cannot sync - device is offline');
        return false;
      }

      await syncPendingNotes();
      return true;
    } catch (e) {
      print('[NoteRepository] Manual sync failed: $e');
      return false;
    }
  }

  /// Checks if the device is currently online.
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
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
