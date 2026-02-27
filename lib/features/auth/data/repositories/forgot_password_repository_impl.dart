import 'package:dio/dio.dart';

import '../../../../services/api_config.dart';
import '../../../../services/auth_service.dart';
import '../../domain/repositories/forgot_password_repository.dart';
import '../models/forgot_password_models.dart';

class ForgotPasswordException implements Exception {
  final String message;

  const ForgotPasswordException(this.message);

  @override
  String toString() => 'ForgotPasswordException: $message';
}

class ForgotPasswordRepositoryImpl implements ForgotPasswordRepository {
  ForgotPasswordRepositoryImpl({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Dio get _dio => _authService.dio;

  @override
  Future<ForgotPasswordSendOtpResponse> sendOtp(
    ForgotPasswordSendOtpRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.forgotPasswordSendOtpEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return ForgotPasswordSendOtpResponse.fromJson(response.data!);
      }
      throw const ForgotPasswordException('Phan hoi may chu khong hop le.');
    } on DioException catch (e) {
      throw ForgotPasswordException(_parseError(e));
    }
  }

  @override
  Future<ForgotPasswordVerifyOtpResponse> verifyOtp(
    ForgotPasswordVerifyOtpRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.forgotPasswordVerifyOtpEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return ForgotPasswordVerifyOtpResponse.fromJson(response.data!);
      }
      throw const ForgotPasswordException('Phan hoi may chu khong hop le.');
    } on DioException catch (e) {
      throw ForgotPasswordException(_parseError(e));
    }
  }

  @override
  Future<ForgotPasswordResetResponse> resetPassword(
    ForgotPasswordResetRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.forgotPasswordResetEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        return ForgotPasswordResetResponse.fromJson(response.data!);
      }
      throw const ForgotPasswordException('Phan hoi may chu khong hop le.');
    } on DioException catch (e) {
      throw ForgotPasswordException(_parseError(e));
    }
  }

  String _parseError(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;
    final message = data is Map ? data['message']?.toString() : null;

    if (message != null && message.isNotEmpty) {
      return message;
    }

    if (code == 400) return 'Du lieu khong hop le.';
    if (code == 401) return 'Yeu cau khong hop le hoac het han.';
    if (code == 429) return 'Ban da thao tac qua nhanh. Vui long thu lai sau.';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Ket noi qua cham. Vui long thu lai.';
      case DioExceptionType.connectionError:
        return 'Khong the ket noi den may chu.';
      default:
        return 'Da xay ra loi. Vui long thu lai.';
    }
  }
}
