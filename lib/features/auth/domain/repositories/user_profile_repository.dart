import '../../data/models/user_profile_models.dart';

/// Abstract repository cho chức năng lấy hồ sơ cá nhân.
///
/// Tuân theo Clean Architecture pattern đã dùng trong project:
/// - Domain layer chỉ chứa contract (abstract class)
/// - Data layer chứa implementation thực tế
abstract class UserProfileRepository {
  /// Lấy thông tin hồ sơ cá nhân từ API.
  ///
  /// Throw [Exception] các loại:
  /// - [UserProfileException]: lỗi từ server (404) hoặc lỗi mạng
  /// - [UserProfileUnauthorizedException]: lỗi 401 (chưa đăng nhập / token hết hạn)
  Future<UserProfileResponse> getUserProfile();
}
