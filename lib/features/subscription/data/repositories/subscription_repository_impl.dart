import 'package:dio/dio.dart';

import '../../../../services/api_config.dart';
import '../../../../services/auth_service.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../models/subscription_request_entity.dart';

class SubscriptionException implements Exception {
  final String message;
  const SubscriptionException(this.message);

  @override
  String toString() => 'SubscriptionException: $message';
}

class SubscriptionUnauthorizedException implements Exception {
  final String message;
  const SubscriptionUnauthorizedException([
    this.message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
  ]);

  @override
  String toString() => 'SubscriptionUnauthorizedException: $message';
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Dio get _dio => _authService.dio;

  @override
  Future<SubscriptionRequestEntity> createUpgradeRequest(
    int planType,
    String note,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.subscriptionRequestsEndpoint,
        data: {'planType': planType, 'note': note},
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data!['success'] == true &&
            response.data!['data'] != null) {
          return SubscriptionRequestEntity.fromJson(
            response.data!['data'] as Map<String, dynamic>,
          );
        }
      }
      throw const SubscriptionException('Phản hồi không hợp lệ từ máy chủ.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const SubscriptionUnauthorizedException();
      }
      throw SubscriptionException(_parseError(e));
    }
  }

  @override
  Future<List<SubscriptionRequestEntity>> getMyRequests() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiConfig.mySubscriptionRequestsEndpoint,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!
            .map(
              (e) =>
                  SubscriptionRequestEntity.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
      throw const SubscriptionException('Phản hồi không hợp lệ từ máy chủ.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const SubscriptionUnauthorizedException();
      }
      throw SubscriptionException(_parseError(e));
    }
  }

  @override
  Future<bool> cancelRequest(int id) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiConfig.subscriptionRequestsEndpoint}/$id/cancel',
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data!['success'] == true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const SubscriptionUnauthorizedException();
      }
      throw SubscriptionException(_parseError(e));
    }
  }

  String _parseError(DioException e) {
    if (e.response?.data is Map) {
      final Map<String, dynamic> data =
          e.response!.data as Map<String, dynamic>;
      final String? message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return message; // This allows capturing the "Bạn đã có yêu cầu xử lý..." from backend.
      }
    }

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
