import 'package:dio/dio.dart';

import '../../../../core/auth/token_storage.dart';
import '../../../../services/api_config.dart';
import '../models/note_model.dart';

/// API client for synchronizing notes with the .NET backend.
///
/// This client handles all communication with the server's Batch Sync Endpoint.
/// It uses Dio for HTTP requests and implements proper error handling.
///
/// Authentication:
/// - Uses an interceptor to automatically attach the Bearer token
/// - Token is read from secure storage before each request
///
/// Base URL Configuration:
/// - Uses [ApiConfig.baseUrl] which is loaded from .env
class SyncClient {
  /// Dio instance for HTTP requests
  final Dio _dio;

  /// Token storage for reading auth token
  final TokenStorage _tokenStorage = TokenStorage();

  /// Sync endpoint path (appended to ApiConfig.baseUrl)
  /// User Request: POST /api/Sync
  /// If baseUrl ends with /api, this should be /Sync
  static const String _syncEndpoint = '/Sync';

  /// Creates a new SyncClient with configured Dio instance
  SyncClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              headers: ApiConfig.defaultHeaders,
            ),
          ) {
    // Add auth interceptor to attach Bearer token automatically
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Read token from secure storage
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    // Add logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (log) => print('[SyncClient] $log'),
      ),
    );
  }

  /// Syncs local changes with server and retrieves updates.
  ///
  /// [changes] - List of local notes that have been created/updated/deleted.
  /// [lastSyncTime] - Timestamp of the last successful sync (null for first sync).
  ///
  /// Returns a [SyncResponse] containing updates from the server and new server time.
  Future<SyncResponse> syncNotes(
    List<NoteModel> changes, {
    DateTime? lastSyncTime,
  }) async {
    try {
      // Construct the sync payload
      final payload = {
        'lastSyncTime': lastSyncTime?.toIso8601String(),
        'changes': changes.map((note) => note.toSyncDto()).toList(),
      };

      print('[SyncClient] Syncing ${changes.length} changes...');
      print('[SyncClient] Payload: $payload'); // Uncomment for debugging

      final response = await _dio.post<dynamic>(_syncEndpoint, data: payload);

      if (response.statusCode == 200 && response.data != null) {
        print('[SyncClient] Response data type: ${response.data.runtimeType}');
        // print('[SyncClient] Response data: ${response.data}'); // Debugging

        final Map<String, dynamic> responseData;
        if (response.data is Map) {
          responseData = Map<String, dynamic>.from(response.data as Map);
        } else if (response.data is String) {
          print(
            '[SyncClient] Response is String (likely error HTML or double-encoded JSON)',
          );
          throw SyncException('Server returned String instead of JSON object');
        } else {
          print(
            '[SyncClient] Unexpected response type: ${response.data.runtimeType}',
          );
          throw SyncException(
            'Unexpected response type: ${response.data.runtimeType}',
          );
        }

        final syncResponse = SyncResponse.fromJson(responseData);
        print(
          '[SyncClient] Sync successful. Received ${syncResponse.upserts.length} updates. Server time: ${syncResponse.serverTime}',
        );
        return syncResponse;
      } else {
        throw SyncException(
          'Unexpected response status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('[SyncClient] DioException: ${e.message}');
      if (e.response != null) {
        print('[SyncClient] Response Status: ${e.response?.statusCode}');
        print('[SyncClient] Response Data: ${e.response?.data}');
      }
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

/// Response returned by the Sync API
class SyncResponse {
  /// List of notes strictly from server that need to be upserted locally
  final List<NoteModel> upserts;

  /// Server's current time, to be stored as lastSyncTime for next request
  final DateTime serverTime;

  /// Optional stats if needed
  final Map<String, dynamic>? stats;

  SyncResponse({required this.upserts, required this.serverTime, this.stats});

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    try {
      return SyncResponse(
        upserts:
            (json['upserts'] as List?)?.map((e) {
              if (e is! Map) {
                print('[SyncResponse] Unexpected element in upserts: $e');
                throw Exception('Upsert element is not a Map');
              }
              return NoteModel.fromServerResponse(Map<String, dynamic>.from(e));
            }).toList() ??
            [],
        serverTime: DateTime.parse(json['serverTime'] as String),
        stats: json['stats'] as Map<String, dynamic>?,
      );
    } catch (e, stack) {
      print(
        '[SyncResponse] Error parsing SyncResponse: $e\nStack: $stack\nJSON: $json',
      );
      rethrow;
    }
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
