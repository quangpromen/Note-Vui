import '../../data/models/change_password_models.dart';

/// Abstract repository cho chức năng đổi mật khẩu.
///
/// Tuân theo Clean Architecture pattern đã dùng trong project:
/// - Domain layer chỉ chứa contract (abstract class)
/// - Data layer chứa implementation thực tế
abstract class ChangePasswordRepository {
  /// Gọi API đổi mật khẩu.
  ///
  /// Throw [Exception] các loại:
  /// - [ChangePasswordException]: lỗi từ server (400) hoặc lỗi mạng
  /// - [ChangePasswordUnauthorizedException]: lỗi 401 (chưa đăng nhập / token hết hạn)
  Future<ChangePasswordResponse> changePassword(ChangePasswordRequest request);
}
