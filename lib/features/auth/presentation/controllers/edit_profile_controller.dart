import 'package:flutter/foundation.dart';

import '../../../../core/auth/token_storage.dart';
import '../../data/models/edit_profile_models.dart';
import '../../data/models/user_profile_models.dart';
import '../../data/repositories/edit_profile_repository_impl.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/repositories/edit_profile_repository.dart';

enum EditProfileStatus { initial, loading, success, error, unauthorized }

class EditProfileController extends ChangeNotifier {
  EditProfileController({EditProfileRepository? repository})
    : _repository = repository ?? EditProfileRepositoryImpl();

  final EditProfileRepository _repository;
  final TokenStorage _tokenStorage = TokenStorage();

  EditProfileStatus _status = EditProfileStatus.initial;
  String? _errorMessage;
  UserProfileResponse? _updatedProfile;

  EditProfileStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserProfileResponse? get updatedProfile => _updatedProfile;

  bool get isLoading => _status == EditProfileStatus.loading;
  bool get hasError => _status == EditProfileStatus.error;
  bool get isUnauthorized => _status == EditProfileStatus.unauthorized;
  bool get isSuccess => _status == EditProfileStatus.success;

  Future<void> editProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    _status = EditProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = EditProfileRequest(
        fullName: fullName.trim(),
        avatarUrl: avatarUrl?.trim(),
      );
      final response = await _repository.editProfile(request);

      _updatedProfile = response;
      _status = EditProfileStatus.success;
    } on UserProfileUnauthorizedException {
      await _tokenStorage.clearAll();
      _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      _status = EditProfileStatus.unauthorized;
    } on UserProfileException catch (e) {
      _errorMessage = e.message;
      _status = EditProfileStatus.error;
    } catch (_) {
      _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      _status = EditProfileStatus.error;
    }

    notifyListeners();
  }
}
