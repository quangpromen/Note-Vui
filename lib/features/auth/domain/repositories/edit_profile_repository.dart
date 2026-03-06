import '../../data/models/user_profile_models.dart';
import '../../data/models/edit_profile_models.dart';

abstract class EditProfileRepository {
  /// Cập nhật thông tin cá nhân.
  ///
  /// Đầu vào: [EditProfileRequest] chứa fullName và avatarUrl.
  /// Đầu ra: [UserProfileResponse] chứa thông tin mới nhất sau khi cập nhật.
  /// Throws: Exception nếu lỗi mạng, validation, hoặc unauthorized (401).
  Future<UserProfileResponse> editProfile(EditProfileRequest request);
}
