import 'package:dio/dio.dart';

import '../../../../services/api_config.dart';
import '../../../../services/auth_service.dart';
import '../../domain/repositories/change_password_repository.dart';
import '../models/change_password_models.dart';

// ═══════════════════════════════════════════════════════════════════════════
// EXCEPTIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Exception cho các lỗi đổi mật khẩu — chứa message tiếng Việt.
///
/// Bao gồm:
/// - Lỗi 400 (validation / logic error từ server)
/// - Lỗi mạng (timeout, không kết nối được)
/// - Lỗi không xác định
class ChangePasswordException implements Exception {
  final String message;

  const ChangePasswordException(this.message);

  @override
  String toString() => 'ChangePasswordException: $message';
}

/// Exception riêng cho lỗi 401 — user chưa đăng nhập hoặc token hết hạn.
///
/// UI sẽ bắt exception này để navigate về LoginScreen.
class ChangePasswordUnauthorizedException implements Exception {
  final String message;

  const ChangePasswordUnauthorizedException([
    this.message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
  ]);

  @override
  String toString() => 'ChangePasswordUnauthorizedException: $message';
}

// ═══════════════════════════════════════════════════════════════════════════
// REPOSITORY IMPLEMENTATION
// ═══════════════════════════════════════════════════════════════════════════

/// Implementation của [ChangePasswordRepository].
///
/// Gọi API `POST /auth/change-password` thông qua [AuthService.dio]
/// (đã có sẵn `Authorization: Bearer <token>` từ [AuthInterceptor]).
///
/// Xử lý các dạng response từ server:
/// - 200 OK → [ChangePasswordResponse] với success = true
/// - 400 Bad Request → throw [ChangePasswordException] với message từ server
/// - 401 Unauthorized → throw [ChangePasswordUnauthorizedException]
/// - Lỗi mạng → throw [ChangePasswordException] với message tiếng Việt
class ChangePasswordRepositoryImpl implements ChangePasswordRepository {
  ChangePasswordRepositoryImpl({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Dio get _dio => _authService.dio;

  @override
  Future<ChangePasswordResponse> changePassword(
    ChangePasswordRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.changePasswordEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return ChangePasswordResponse.fromJson(response.data!);
      }
      throw const ChangePasswordException('Phản hồi không hợp lệ từ máy chủ.');
    } on DioException catch (e) {
      // ── Xử lý lỗi 401 riêng — cần navigate về Login ──────────────
      if (e.response?.statusCode == 401) {
        throw const ChangePasswordUnauthorizedException();
      }
      throw ChangePasswordException(_parseError(e));
    }
  }

  /// Chuyển lỗi Dio → message tiếng Việt.
  ///
  /// Xử lý cả 2 format lỗi từ server:
  /// - `{ "errors": { "FieldName": ["error message"] } }` (ModelState)
  /// - `{ "success": false, "message": "..." }` (logic error)
  String _parseError(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      // ── Dạng 1: ModelState validation errors ──────────────────────
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final allMessages = <String>[];
        for (final entry in errors.entries) {
          final messages = entry.value;
          if (messages is List) {
            for (final msg in messages) {
              allMessages.add(msg.toString());
            }
          }
        }
        if (allMessages.isNotEmpty) return allMessages.first;
      }

      // ── Dạng 2: Logic error message ───────────────────────────────
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }

    // ── Xử lý theo HTTP status code ───────────────────────────────────
    if (code == 400) return 'Dữ liệu không hợp lệ.';

    // ── Xử lý theo loại lỗi Dio ──────────────────────────────────────
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
