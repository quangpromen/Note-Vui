/// Model đại diện cho response trả về từ API login/register/google-login.
///
/// JSON mẫu từ server:
/// ```json
/// {
///   "accessToken": "eyJhbGciOiJIUzI1NiIs...",
///   "refreshToken": "a1b2c3d4-e5f6-...",
///   "userId": "guid-string",
///   "email": "user@gmail.com",
///   "fullName": "Nguyen Van A",
///   "avatarUrl": "https://lh3.googleusercontent.com/..."
/// }
/// ```
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String fullName;

  /// Email — trả về từ google-login, nullable cho login thường.
  final String? email;

  /// Avatar URL — trả về từ google-login, nullable cho login thường.
  final String? avatarUrl;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.fullName,
    this.email,
    this.avatarUrl,
  });

  /// Tạo [AuthResponse] từ JSON map.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  /// Chuyển thành JSON map.
  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'userId': userId,
    'fullName': fullName,
    'email': email,
    'avatarUrl': avatarUrl,
  };

  @override
  String toString() =>
      'AuthResponse(userId: $userId, fullName: $fullName, email: $email)';
}
