import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure wrapper around FlutterSecureStorage for authentication tokens.
///
/// Provides a clean API for managing JWT tokens with:
/// - Save: Store access token securely
/// - Read: Retrieve stored token
/// - Delete: Remove token on logout
/// - Has Token: Check if user is authenticated
///
/// Uses platform-native secure storage:
/// - iOS: Keychain
/// - Android: Keystore + EncryptedSharedPreferences
class TokenStorage {
  /// Singleton instance
  static final TokenStorage _instance = TokenStorage._internal();

  /// Factory constructor returns singleton
  factory TokenStorage() => _instance;

  TokenStorage._internal();

  /// Key for storing access token
  static const String _accessTokenKey = 'access_token';

  /// Key for storing refresh token (future use)
  static const String _refreshTokenKey = 'refresh_token';

  /// Flutter Secure Storage instance with Android options
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Saves the access token securely.
  ///
  /// [token] - The JWT access token to store.
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Reads the stored access token.
  ///
  /// Returns null if no token is stored.
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Deletes the stored access token.
  ///
  /// Called during logout to clear authentication state.
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  /// Checks if an access token exists.
  ///
  /// Returns true if user has a stored token (logged in).
  /// Returns false if no token (guest mode).
  Future<bool> hasAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Saves the refresh token securely (for future token refresh).
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Reads the stored refresh token.
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Deletes the stored refresh token.
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Clears all stored tokens.
  ///
  /// Used for complete logout or when switching accounts.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
