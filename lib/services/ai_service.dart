import 'package:dio/dio.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';
import '../core/auth/token_storage.dart';
import 'api_config.dart';

/// Exception chung cho các lỗi từ AI API
class AiException implements Exception {
  final String message;
  final int? statusCode;

  AiException(this.message, [this.statusCode]);

  @override
  String toString() => 'AiException: $message (StatusCode: $statusCode)';
}

/// Exception chuyên biệt khi tài khoản không phải VIP (403)
class AiPremiumRequiredException extends AiException {
  AiPremiumRequiredException(String message) : super(message, 403);
}

class AiService {
  late final Dio _dio;
  late final TokenStorage _tokenStorage;

  AiService({Dio? dio, TokenStorage? tokenStorage}) {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
            headers: ApiConfig.defaultHeaders,
          ),
        );
    _tokenStorage = tokenStorage ?? TokenStorage();
  }

  /// Gọi API POST /Ai/summarize
  Future<AiResponse> summarize(AiRequest request) async {
    try {
      // 1. Lấy token từ local storage
      final token = await _tokenStorage.getAccessToken();

      // 2. Đính kèm vào request header
      final options = Options(
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      // 3. Thực hiện HTTP POST call
      final response = await _dio.post(
        '/Ai/summarize',
        data: request.toJson(),
        options: options,
      );

      // 4. Parse JSON body (status code 200 OK)
      final aiResponse = AiResponse.fromJson(response.data);

      if (!aiResponse.isSuccess) {
        throw AiException(
          aiResponse.errorMessage ??
              'API trả về kết quả lỗi nhưng không có thông báo cụ thể.',
          200,
        );
      }

      return aiResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;

        String errorMessage = 'Lỗi không xác định.';
        if (data is Map<String, dynamic> && data['errorMessage'] != null) {
          errorMessage = data['errorMessage'];
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        }

        // Xử lý rõ ràng các mã lỗi (HTTP Status Codes)
        switch (statusCode) {
          case 400:
            throw AiException(
              'Dữ liệu không hợp lệ (400 Bad Request): $errorMessage',
              400,
            );
          case 401:
            throw AiException(
              'Phiên đăng nhập hết hạn hoặc Token không hợp lệ. (401 Unauthorized)',
              401,
            );
          case 403:
            throw AiPremiumRequiredException(
              errorMessage != 'Lỗi không xác định.'
                  ? errorMessage
                  : 'Tài khoản của bạn không phải VIP. Vui lòng nâng cấp Premium.',
            );
          case 500:
          case 503:
            throw AiException('$errorMessage', statusCode);
          default:
            throw AiException(
              'Lỗi HTTP $statusCode: $errorMessage',
              statusCode,
            );
        }
      } else {
        // Lỗi không có response (ví dụ timeout, mất mạng)
        throw AiException('Lỗi kết nối mạng: ${e.message}');
      }
    } catch (e) {
      if (e is AiException) rethrow; // Ném lại các lỗi tự định nghĩa
      throw AiException('Đã xảy ra lỗi không xác định: $e');
    }
  }

  /// Gọi API POST /Ai/translate
  Future<AiResponse> translate(AiRequest request) async {
    try {
      // 1. Lấy token từ local storage
      final token = await _tokenStorage.getAccessToken();

      // 2. Đính kèm vào request header
      final options = Options(
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      // 3. Thực hiện HTTP POST call
      final response = await _dio.post(
        '/Ai/translate',
        data: request.toJson(),
        options: options,
      );

      // 4. Parse JSON body (status code 200 OK)
      final aiResponse = AiResponse.fromJson(response.data);

      if (!aiResponse.isSuccess) {
        throw AiException(
          aiResponse.errorMessage ??
              'API trả về kết quả lỗi nhưng không có thông báo cụ thể.',
          200,
        );
      }

      return aiResponse;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;

        String errorMessage = 'Lỗi không xác định.';
        if (data is Map<String, dynamic> && data['errorMessage'] != null) {
          errorMessage = data['errorMessage'];
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        }

        // Xử lý rõ ràng các mã lỗi (HTTP Status Codes)
        switch (statusCode) {
          case 400:
            throw AiException(
              'Dữ liệu không hợp lệ (400 Bad Request): $errorMessage',
              400,
            );
          case 401:
            throw AiException(
              'Phiên đăng nhập hết hạn hoặc Token không hợp lệ. (401 Unauthorized)',
              401,
            );
          case 403:
            throw AiPremiumRequiredException(
              errorMessage != 'Lỗi không xác định.'
                  ? errorMessage
                  : 'AI features are exclusively available for VIP members. Please upgrade to Premium.',
            );
          case 500:
          case 503:
            throw AiException('$errorMessage', statusCode);
          default:
            throw AiException(
              'Lỗi HTTP $statusCode: $errorMessage',
              statusCode,
            );
        }
      } else {
        // Lỗi không có response (ví dụ timeout, mất mạng)
        throw AiException('Lỗi kết nối mạng: ${e.message}');
      }
    } catch (e) {
      if (e is AiException) rethrow; // Ném lại các lỗi tự định nghĩa
      throw AiException('Đã xảy ra lỗi không xác định: $e');
    }
  }
}
