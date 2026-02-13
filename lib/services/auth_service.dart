import 'package:dio/dio.dart';

import '../core/auth/token_storage.dart';
import '../models/auth_response.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';

/// Service gọi API xác thực cho NoteVui.
///
/// Cung cấp 3 hàm chính:
/// - [login]        → POST /auth/login
/// - [register]     → POST /auth/register
/// - [refreshToken] → POST /auth/refresh-token
///
/// Sử dụng [Dio] với [AuthInterceptor] để tự động:
/// - Gắn `Authorization: Bearer <token>` vào mọi request
/// - Gắn `ngrok-skip-browser-warning: true`
/// - Xử lý 401 bằng refresh-token
///
/// Singleton pattern — chỉ cần gọi `AuthService()`.
class AuthService {
  // ─── Singleton ──────────────────────────────────────────────────────
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Dio HTTP client
  late final Dio _dio;

  /// Secure token storage
  final TokenStorage _tokenStorage = TokenStorage();

  /// Đã khởi tạo chưa
  bool _initialized = false;

  /// Callback sau khi đăng nhập thành công (vd: trigger sync)
  Future<void> Function()? _onLoginSuccess;

  // ═══════════════════════════════════════════════════════════════════════
  // KHỞI TẠO
  // ═══════════════════════════════════════════════════════════════════════

  /// Khởi tạo Dio với base URL, interceptors.
  /// Gọi 1 lần duy nhất trong main().
  void initialize({Future<void> Function()? onLoginSuccess}) {
    if (_initialized) return;

    _onLoginSuccess = onLoginSuccess;

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: ApiConfig.defaultHeaders,
      ),
    );

    // Interceptor xác thực: gắn token + xử lý 401
    _dio.interceptors.add(AuthInterceptor(dio: _dio));

    _initialized = true;
  }

  /// Getter Dio instance cho module khác dùng chung (sync, notes, ai...).
  Dio get dio {
    _ensureInitialized();
    return _dio;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOGIN
  // ═══════════════════════════════════════════════════════════════════════

  /// Đăng nhập bằng email + password.
  ///
  /// **Endpoint**: `POST /auth/login`
  ///
  /// Thành công:
  /// 1. Parse JSON → [AuthResponse]
  /// 2. Lưu accessToken + refreshToken vào secure storage
  /// 3. Gọi [_onLoginSuccess] callback (sync notes)
  ///
  /// Thất bại: throw [AuthException] với message tiếng Việt.
  Future<AuthResponse> login(String email, String password) async {
    _ensureInitialized();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final auth = AuthResponse.fromJson(response.data!);

        // Lưu token an toàn
        await _tokenStorage.saveAccessToken(auth.accessToken);
        await _tokenStorage.saveRefreshToken(auth.refreshToken);

        // Callback (sync notes sau login)
        await _safeCallback();

        return auth;
      }

      throw AuthException('Phản hồi không hợp lệ từ máy chủ.');
    } on DioException catch (e) {
      throw AuthException(_parseError(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REGISTER
  // ═══════════════════════════════════════════════════════════════════════

  /// Đăng ký tài khoản mới.
  ///
  /// **Endpoint**: `POST /auth/register`
  ///
  /// Thành công: parse JSON → [AuthResponse], lưu token, trigger callback.
  /// Thất bại: throw [AuthException].
  Future<AuthResponse> register(
    String email,
    String password,
    String fullName,
  ) async {
    _ensureInitialized();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConfig.registerEndpoint,
        data: {'email': email, 'password': password, 'fullName': fullName},
      );

      if (response.statusCode == 200 && response.data != null) {
        final auth = AuthResponse.fromJson(response.data!);

        await _tokenStorage.saveAccessToken(auth.accessToken);
        await _tokenStorage.saveRefreshToken(auth.refreshToken);

        await _safeCallback();

        return auth;
      }

      throw AuthException('Phản hồi không hợp lệ từ máy chủ.');
    } on DioException catch (e) {
      throw AuthException(_parseError(e));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REFRESH TOKEN
  // ═══════════════════════════════════════════════════════════════════════

  /// Làm mới token khi accessToken hết hạn.
  ///
  /// **Endpoint**: `POST /auth/refresh-token`
  ///
  /// Thường được gọi tự động bởi [AuthInterceptor],
  /// nhưng cũng có thể gọi thủ công nếu cần.
  Future<bool> refreshToken() async {
    _ensureInitialized();

    try {
      final currentAccess = await _tokenStorage.getAccessToken();
      final currentRefresh = await _tokenStorage.getRefreshToken();

      if (currentRefresh == null || currentRefresh.isEmpty) return false;

      // Dùng Dio riêng để tránh interceptor loop
      final freshDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: ApiConfig.defaultHeaders,
        ),
      );

      final response = await freshDio.post<Map<String, dynamic>>(
        ApiConfig.refreshTokenEndpoint,
        data: {
          'accessToken': currentAccess ?? '',
          'refreshToken': currentRefresh,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        await _tokenStorage.saveAccessToken(
          response.data!['accessToken'] as String,
        );
        await _tokenStorage.saveRefreshToken(
          response.data!['refreshToken'] as String,
        );
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOGOUT & STATUS
  // ═══════════════════════════════════════════════════════════════════════

  /// Đăng xuất — xóa tất cả token.
  Future<void> logout() async {
    await _tokenStorage.clearAll();
  }

  /// Kiểm tra đã đăng nhập chưa (có token trong máy).
  Future<bool> isLoggedIn() async {
    return await _tokenStorage.hasAccessToken();
  }

  /// Lấy token hiện tại (hoặc null).
  Future<String?> getToken() async {
    return await _tokenStorage.getAccessToken();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'AuthService chưa được khởi tạo. Gọi initialize() trong main().',
      );
    }
  }

  /// Gọi callback an toàn (không crash nếu lỗi).
  Future<void> _safeCallback() async {
    if (_onLoginSuccess != null) {
      try {
        await _onLoginSuccess!();
      } catch (_) {
        // Không fail login nếu callback lỗi
      }
    }
  }

  /// Chuyển lỗi Dio → message tiếng Việt dễ hiểu.
  String _parseError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối quá chậm. Vui lòng thử lại.';

      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        final msg = data is Map ? data['message'] : null;

        if (code == 400) return msg?.toString() ?? 'Dữ liệu không hợp lệ.';
        if (code == 401) return 'Sai email hoặc mật khẩu.';
        if (code == 409) return 'Email đã được sử dụng.';
        return msg?.toString() ?? 'Lỗi máy chủ ($code).';

      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến máy chủ. Kiểm tra mạng.';

      default:
        return 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }
  }
}

/// Exception cho các lỗi xác thực – chứa message tiếng Việt.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
