import 'package:dio/dio.dart';

import '../models/note_model.dart';

/// API client for synchronizing notes with the .NET backend.
///
/// This client handles all communication with the server's Batch Sync Endpoint.
/// It uses Dio for HTTP requests and implements proper error handling.
///
/// Base URL Configuration:
/// - Android Emulator: `http://10.0.2.2:5000` (maps to localhost)
/// - iOS Simulator/Physical Device: `http://localhost:5000`
/// - Production: Replace with actual server URL
class SyncClient {
  /// Dio instance for HTTP requests
  final Dio _dio;

  /// Base URL for the API server
  static const String _baseUrl = 'http://10.0.2.2:5000';

  /// Sync endpoint path
  static const String _syncEndpoint = '/api/sync';

  /// Creates a new SyncClient with configured Dio instance
  SyncClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          ) {
    // Add logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (log) => print('[SyncClient] $log'),
      ),
    );
  }

  /// Syncs a list of pending notes with the server.
  ///
  /// This method sends all notes where `isSynced == false` to the server's
  /// Batch Sync Endpoint. The server processes the changes and returns
  /// the updated notes list.
  ///
  /// [changes] - List of NoteModel objects that need to be synced.
  ///             These should have `isSynced == false`.
  ///
  /// Returns a list of NoteModel objects from the server response.
  /// These notes should be used to update the local Hive database.
  ///
  /// Throws [SyncException] if the sync operation fails.
  Future<List<NoteModel>> syncNotes(List<NoteModel> changes) async {
    if (changes.isEmpty) {
      return [];
    }

    try {
      // Convert notes to Sync DTO format expected by .NET backend
      final payload = changes.map((note) => note.toSyncDto()).toList();

      print('[SyncClient] Syncing ${changes.length} notes...');
      print('[SyncClient] Payload: $payload');

      final response = await _dio.post<List<dynamic>>(
        _syncEndpoint,
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        // Parse server response back to NoteModel objects
        final serverNotes = response.data!
            .map(
              (json) =>
                  NoteModel.fromServerResponse(json as Map<String, dynamic>),
            )
            .toList();

        print('[SyncClient] Received ${serverNotes.length} notes from server');
        return serverNotes;
      } else {
        throw SyncException(
          'Unexpected response status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('[SyncClient] DioException: ${e.message}');
      throw SyncException(
        _parseDioError(e),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      print('[SyncClient] Unexpected error: $e');
      throw SyncException('Sync failed: $e', originalError: e);
    }
  }

  /// Parses Dio errors into user-friendly messages.
  String _parseDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timed out while sending data.';
      case DioExceptionType.receiveTimeout:
        return 'Request timed out while receiving data.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Unknown error';
        return 'Server error ($statusCode): $message';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Could not connect to server. Please check your internet connection.';
      default:
        return e.message ?? 'An unknown network error occurred.';
    }
  }

  /// Updates the base URL for the API.
  ///
  /// Useful for switching between environments (dev/staging/production).
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Adds an authorization header for authenticated requests.
  ///
  /// [token] - JWT token received after login.
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Removes the authorization header.
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Disposes of the Dio instance.
  void dispose() {
    _dio.close();
  }
}

/// Exception thrown when sync operations fail.
///
/// Contains additional context about the failure including
/// HTTP status codes and the original error if available.
class SyncException implements Exception {
  /// Human-readable error message
  final String message;

  /// HTTP status code if available
  final int? statusCode;

  /// Original error that caused this exception
  final Object? originalError;

  SyncException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() {
    if (statusCode != null) {
      return 'SyncException [$statusCode]: $message';
    }
    return 'SyncException: $message';
  }
}
