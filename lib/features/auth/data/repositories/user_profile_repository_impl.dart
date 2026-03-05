import 'package:dio/dio.dart';

import '../../../../services/api_config.dart';
import '../../../../services/auth_service.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../models/user_profile_models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Exception cho các lỗi lấy hồ sơ cá nhân — chứa message tiếng Việt.
///
/// Bao gồm:
/// - Lỗi 404 (user not found)
/// - Lỗi mạng (timeout, không kết nối được)
/// - Lỗi không xác định
class UserProfileException implements Exception {
  final String message;

  const UserProfileException(this.message);

  @override
  String toString() => 'UserProfileException: $message';
}

/// Exception riêng cho lỗi 401 — user chưa đăng nhập hoặc token hết hạn.
///
/// UI sẽ bắt exception này để xóa token và navigate về LoginScreen.
class UserProfileUnauthorizedException implements Exception {
  final String message;

  const UserProfileUnauthorizedException([
    this.message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
  ]);

  @override
  String toString() => 'UserProfileUnauthorizedException: $message';
}

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORY IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════════

/// Implementation của [UserProfileRepository].
///
/// Gọi API `GET /user/profile` thông qua [AuthService.dio]
/// (đã có sẵn `Authorization: Bearer <token>` từ [AuthInterceptor]).
///
/// Xử lý các dạng response từ server:
/// - 200 OK → [UserProfileResponse] với data đầy đủ
/// - 401 Unauthorized → throw [UserProfileUnauthorizedException]
/// - 404 Not Found → throw [UserProfileException] với message "Không tìm thấy..."
/// - Lỗi mạng → throw [UserProfileException] với message tiếng Việt
class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Dio get _dio => _authService.dio;

  @override
  Future<UserProfileResponse> getUserProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConfig.userProfileEndpoint,
      );

      if (response.statusCode == 200 && response.data != null) {
        return UserProfileResponse.fromJson(response.data!);
      }
      throw const UserProfileException('Phản hồi không hợp lệ từ máy chủ.');
    } on DioException catch (e) {
      // ── Xử lý lỗi 401 riêng — cần navigate về Login ──────────────
      if (e.response?.statusCode == 401) {
        throw const UserProfileUnauthorizedException();
      }
      throw UserProfileException(_parseError(e));
    }
  }

  /// Chuyển lỗi Dio → message tiếng Việt.
  ///
  /// Xử lý cả format lỗi từ server:
  /// - `{ "message": "User not found" }` (404)
  /// - Lỗi mạng / timeout
  String _parseError(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      // ── Dạng: message string từ server ─────────────────────────────
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        // Dịch message phổ biến sang tiếng Việt
        if (message.contains('not found')) {
          return 'Không tìm thấy thông tin người dùng.';
        }
        if (message.contains('not authenticated')) {
          return 'Bạn chưa đăng nhập.';
        }
        return message;
      }
    }

    // ── Xử lý theo HTTP status code ─────────────────────────────────────
    if (code == 404) return 'Không tìm thấy thông tin người dùng.';

    // ── Xử lý theo loại lỗi Dio ────────────────────────────────────────
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối quá chậm. Vui lòng thử lại.';
      case DioExceptionType.connectionError:
        return 'Không có kết nối mạng. Vui lòng thử lại.';
      default:
        return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
  }
}
