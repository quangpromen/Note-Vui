import 'package:dio/dio.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';
import 'auth_service.dart';

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

/// Service gọi các API AI (summarize, translate, ideas...).
///
/// Sử dụng chung [Dio] instance từ [AuthService] để:
/// - Tự động gắn `Authorization: Bearer <token>` qua [AuthInterceptor]
/// - Tự động refresh token khi gặp 401
/// - Tự động force-logout khi refresh thất bại
///
/// → Không cần tự quản lý token trong mỗi hàm nữa.
class AiService {
  late final Dio _dio;

  AiService({Dio? dio}) {
    // Ưu tiên Dio được inject (testing), nếu không thì dùng shared Dio
    _dio = dio ?? AuthService().dio;
  }

  /// Gọi API POST /Ai/summarize
  Future<AiResponse> summarize(AiRequest request) async {
    return _callAiEndpoint('/Ai/summarize', request);
  }

  /// Gọi API POST /Ai/translate
  Future<AiResponse> translate(AiRequest request) async {
    return _callAiEndpoint('/Ai/translate', request);
  }

  /// Gọi API POST /Ai/ideas — Tạo ý tưởng bằng AI
  Future<AiResponse> generateIdeas(AiRequest request) async {
    return _callAiEndpoint('/Ai/ideas', request);
  }

  /// Gọi API POST /Ai/grammar — Sửa lỗi ngữ pháp & chính tả bằng AI
  Future<AiResponse> fixGrammar(AiRequest request) async {
    return _callAiEndpoint('/Ai/grammar', request);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE: Logic gọi API chung cho tất cả endpoint AI
  // ═══════════════════════════════════════════════════════════════════════

  /// Gọi chung cho tất cả AI endpoint.
  ///
  /// Token tự động được gắn bởi [AuthInterceptor] trong [AuthService.dio].
  /// Nếu 401 → interceptor tự refresh hoặc force-logout.
  Future<AiResponse> _callAiEndpoint(String path, AiRequest request) async {
    try {
      final response = await _dio.post(path, data: request.toJson());

      // Parse JSON body (status code 200 OK)
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
            throw AiException('Dữ liệu không hợp lệ: $errorMessage', 400);
          case 401:
            // Interceptor đã xử lý refresh + force-logout
            // Nếu vẫn rơi vào đây = refresh cũng thất bại
            throw AiException(
              'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
              401,
            );
          case 403:
            throw AiPremiumRequiredException(
              errorMessage != 'Lỗi không xác định.'
                  ? errorMessage
                  : 'Tính năng AI chỉ dành cho thành viên VIP. Vui lòng nâng cấp Premium.',
            );
          case 500:
          case 503:
            throw AiException(
              'Hệ thống AI đang bận, vui lòng thử lại sau.',
              statusCode,
            );
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
