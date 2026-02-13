import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cấu hình API tập trung cho toàn bộ ứng dụng NoteVui.
///
/// Thay đổi [baseUrl] trong file `.env` khi chuyển đổi môi trường:
/// - Ngrok (dev):  'https://xxxx.ngrok-free.app/api'
/// - Local:        'http://10.0.2.2:5100/api'
/// - Production:   'https://api.notevui.com/api'
class ApiConfig {
  ApiConfig._(); // Không cho khởi tạo

  /// ─── BASE URL ────────────────────────────────────────────────────────
  /// Đọc giá trị từ file .env. Nếu không có thì dùng default.
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://api.notevui.com/api';

  /// ─── ENDPOINTS ───────────────────────────────────────────────────────
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh-token';

  /// ─── TIMEOUTS ────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// ─── HEADERS ─────────────────────────────────────────────────────────
  /// Header bắt buộc để bỏ qua trang cảnh báo của ngrok.
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };
}
