import 'package:dio/dio.dart';

import '../../../../services/api_config.dart';
import '../../../../services/auth_service.dart';
import '../../domain/repositories/edit_profile_repository.dart';
import '../models/edit_profile_models.dart';
import '../models/user_profile_models.dart';
import 'user_profile_repository_impl.dart';

class EditProfileRepositoryImpl implements EditProfileRepository {
  EditProfileRepositoryImpl({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Dio get _dio => _authService.dio;

  @override
  Future<UserProfileResponse> editProfile(EditProfileRequest request) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiConfig.userProfileEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dataMap = response.data!['data'];
        if (dataMap != null) {
          return UserProfileResponse.fromJson(dataMap as Map<String, dynamic>);
        }
      }
      throw const UserProfileException('Phản hồi không hợp lệ từ máy chủ.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map) {
          final message = data['message']?.toString();
          if (message != null && message.isNotEmpty) {
            throw UserProfileException(message);
          }
        }
        throw const UserProfileException(
          'Thông tin không hợp lệ. Vui lòng kiểm tra lại.',
        );
      }
      if (e.response?.statusCode == 401) {
        throw const UserProfileUnauthorizedException();
      }
      throw UserProfileException(_parseError(e));
    }
  }

  String _parseError(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        if (message.contains('not found')) {
          return 'Không tìm thấy thông tin người dùng.';
        }
        if (message.contains('not authenticated')) {
          return 'Bạn chưa đăng nhập.';
        }
        return message;
      }
    }

    if (code == 404) return 'Không tìm thấy thông tin người dùng.';

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
