import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Authentication service for managing user login, registration, and session state.
///
/// This service acts as the central authority for authentication:
/// - Login: Authenticate with email/password, store token
/// - Register: Create new account, automatically login
/// - Logout: Clear token, reset state
/// - isLoggedIn: Check if user is authenticated (vs Guest)
///
/// Guest Mode:
/// - Users without tokens can still use the app offline
/// - Sync and AI features are disabled for guests
/// - When guest logs in, their local notes are synced to their account
class AuthService {
  /// Singleton instance
  static final AuthService _instance = AuthService._internal();

  /// Factory constructor returns singleton
  factory AuthService() => _instance;

  AuthService._internal();

  /// Token storage for secure persistence
  final TokenStorage _tokenStorage = TokenStorage();

  /// Dio client for API calls
  late final Dio _dio;

  /// API base URL - same as SyncClient
  static const String _baseUrl = 'http://10.0.2.2:5000';

  /// Callback to trigger sync after login
  Future<void> Function()? _onLoginSuccess;

  /// Initialize the auth service
  void initialize({Future<void> Function()? onLoginSuccess}) {
    _onLoginSuccess = onLoginSuccess;
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Sets the sync callback for login success
  void setOnLoginSuccess(Future<void> Function()? callback) {
    _onLoginSuccess = callback;
  }

  /// Authenticates user with email and password.
  ///
  /// On success:
  /// 1. Saves the JWT token securely
  /// 2. Triggers note sync to merge guest data
  ///
  /// Throws [AuthException] on failure.
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data!['token'] as String?;
        if (token == null || token.isEmpty) {
          throw AuthException('No token received from server');
        }

        // Step 1: Save the token
        await _tokenStorage.saveAccessToken(token);

        // Step 2: Trigger sync to push guest notes to server
        if (_onLoginSuccess != null) {
          try {
            await _onLoginSuccess!();
          } catch (e) {
            print('[AuthService] Sync after login failed: $e');
            // Don't fail login if sync fails
          }
        }

        return AuthResult(
          success: true,
          message: 'Đăng nhập thành công!',
          token: token,
        );
      } else {
        throw AuthException('Unexpected response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw AuthException(_parseDioError(e));
    }
  }

  /// Registers a new user account.
  ///
  /// After successful registration, automatically logs in the user.
  ///
  /// Throws [AuthException] on failure.
  Future<AuthResult> register(String email, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Auto-login after successful registration
        return await login(email, password);
      } else {
        final message = response.data?['message'] ?? 'Registration failed';
        throw AuthException(message.toString());
      }
    } on DioException catch (e) {
      throw AuthException(_parseDioError(e));
    }
  }

  /// Logs out the current user.
  ///
  /// Clears all stored tokens and resets auth state.
  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }

  /// Checks if user is authenticated (has valid token).
  ///
  /// Returns:
  /// - true: User is logged in with token
  /// - false: User is in Guest Mode
  ///
  /// This is the key method for feature gating (Sync, AI).
  Future<bool> isLoggedIn() async {
    return await _tokenStorage.hasAccessToken();
  }

  /// Gets the current access token if available.
  Future<String?> getToken() async {
    return await _tokenStorage.getAccessToken();
  }

  /// Parses Dio errors into user-friendly Vietnamese messages.
  String _parseDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối quá chậm. Vui lòng thử lại.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'];
        if (statusCode == 400) {
          return message ?? 'Email hoặc mật khẩu không đúng.';
        } else if (statusCode == 401) {
          return 'Sai email hoặc mật khẩu.';
        } else if (statusCode == 409) {
          return 'Email đã được sử dụng.';
        }
        return message ?? 'Lỗi máy chủ ($statusCode).';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến máy chủ.';
      default:
        return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
  }
}

/// Result of an authentication operation.
class AuthResult {
  final bool success;
  final String message;
  final String? token;

  AuthResult({required this.success, required this.message, this.token});
}

/// Exception thrown for authentication errors.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
