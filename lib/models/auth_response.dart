/// Model đại diện cho response trả về từ API login/register.
///
/// JSON mẫu từ server:
/// ```json
/// {
///   "accessToken": "eyJhbGciOiJIUzI1NiIs...",
///   "refreshToken": "a1b2c3d4-e5f6-...",
///   "userId": "guid-string",
///   "fullName": "Nguyen Van A"
/// }
/// ```
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String fullName;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.fullName,
  });

  /// Tạo [AuthResponse] từ JSON map.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
    );
  }

  /// Chuyển thành JSON map.
  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'userId': userId,
    'fullName': fullName,
  };

  @override
  String toString() => 'AuthResponse(userId: $userId, fullName: $fullName)';
}
