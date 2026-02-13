import 'dart:async';

import 'package:dio/dio.dart';

import '../core/auth/token_storage.dart';
import 'api_config.dart';

/// Dio Interceptor tự động xử lý xác thực cho mọi request.
///
/// Hai nhiệm vụ chính:
///
/// 1. **onRequest** — Nếu có accessToken trong máy, tự động gắn
///    `Authorization: Bearer <token>` vào header.
///    Bỏ qua cho các endpoint công khai (login, register, refresh).
///
/// 2. **onError (401)** — Khi nhận 401 Unauthorized:
///    - Gọi `/auth/refresh-token` để lấy cặp token mới.
///    - Lưu token mới vào secure storage.
///    - Retry request gốc với token mới.
///    - Nếu refresh thất bại → xóa token, buộc đăng nhập lại.
///
/// Sử dụng:
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(AuthInterceptor(dio: dio));
/// ```
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage = TokenStorage();

  /// Cờ chống gọi refresh nhiều lần đồng thời
  bool _isRefreshing = false;

  /// Hàng đợi các request chờ refresh xong
  final List<_QueuedRequest> _queue = [];

  /// Các endpoint KHÔNG cần gắn Bearer token
  static const List<String> _publicPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh-token',
  ];

  AuthInterceptor({required Dio dio}) : _dio = dio;

  // ═══════════════════════════════════════════════════════════════════════
  // REQUEST — Tự động gắn Bearer Token
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Luôn thêm header ngrok để bỏ qua cảnh báo
    options.headers['ngrok-skip-browser-warning'] = 'true';

    // Bỏ qua token cho endpoint công khai
    final isPublic = _publicPaths.any((path) => options.path.contains(path));

    if (!isPublic) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ERROR — Xử lý 401 bằng refresh-token
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Chỉ xử lý 401 Unauthorized
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Không retry chính endpoint refresh-token (tránh vòng lặp vô hạn)
    if (err.requestOptions.path.contains('/auth/refresh-token')) {
      await _forceLogout();
      return handler.next(err);
    }

    // Nếu đang refresh → xếp request vào hàng đợi
    if (_isRefreshing) {
      final completer = Completer<Response>();
      _queue.add(
        _QueuedRequest(
          requestOptions: err.requestOptions,
          completer: completer,
        ),
      );
      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    // ─── Bắt đầu refresh ────────────────────────────────────────────
    _isRefreshing = true;

    try {
      final newTokens = await _callRefreshToken();

      if (newTokens != null) {
        // Lưu token mới
        await _tokenStorage.saveAccessToken(newTokens['accessToken']!);
        await _tokenStorage.saveRefreshToken(newTokens['refreshToken']!);

        // Retry request gốc với token mới
        final retryResponse = await _retry(
          err.requestOptions,
          newTokens['accessToken']!,
        );

        // Giải quyết tất cả request đang chờ
        for (final queued in _queue) {
          try {
            final res = await _retry(
              queued.requestOptions,
              newTokens['accessToken']!,
            );
            queued.completer.complete(res);
          } catch (e) {
            queued.completer.completeError(e);
          }
        }
        _queue.clear();
        _isRefreshing = false;

        return handler.resolve(retryResponse);
      } else {
        // Refresh thất bại → đăng xuất
        await _forceLogout();
        _rejectQueue(err);
        _isRefreshing = false;
        return handler.next(err);
      }
    } catch (e) {
      await _forceLogout();
      _rejectQueue(err);
      _isRefreshing = false;
      return handler.next(err);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Gọi API refresh-token bằng Dio riêng (tránh interceptor loop).
  Future<Map<String, String>?> _callRefreshToken() async {
    try {
      final currentAccess = await _tokenStorage.getAccessToken();
      final currentRefresh = await _tokenStorage.getRefreshToken();

      if (currentRefresh == null || currentRefresh.isEmpty) return null;

      // Dùng Dio mới, KHÔNG qua interceptor
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
        return {
          'accessToken': response.data!['accessToken'] as String,
          'refreshToken': response.data!['refreshToken'] as String,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Retry request gốc với token mới.
  Future<Response> _retry(RequestOptions opts, String newToken) {
    opts.headers['Authorization'] = 'Bearer $newToken';
    opts.headers['ngrok-skip-browser-warning'] = 'true';
    return _dio.fetch(opts);
  }

  /// Xóa tất cả token → buộc đăng nhập lại.
  Future<void> _forceLogout() async {
    await _tokenStorage.clearAll();
  }

  /// Reject tất cả request trong hàng đợi.
  void _rejectQueue(DioException error) {
    for (final q in _queue) {
      q.completer.completeError(error);
    }
    _queue.clear();
  }
}

/// Request đang chờ token refresh xong.
class _QueuedRequest {
  final RequestOptions requestOptions;
  final Completer<Response> completer;
  _QueuedRequest({required this.requestOptions, required this.completer});
}
