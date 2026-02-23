import 'dart:async';

import 'package:flutter/material.dart';

import 'token_storage.dart';

/// Singleton quản lý phiên đăng nhập toàn cục.
///
/// Khi token hết hạn (refresh thất bại), [SessionManager] sẽ:
/// 1. Xóa toàn bộ token khỏi secure storage
/// 2. Thông báo cho UI navigation callback để đẩy user ra Login
/// 3. Đảm bảo chỉ xử lý 1 lần (tránh hiển thị dialog trùng lặp)
///
/// Thiết lập trong `main.dart`:
/// ```dart
/// SessionManager().setNavigatorKey(navigatorKey);
/// SessionManager().onSessionExpired = () { ... navigate to Login ... };
/// ```
class SessionManager {
  // ─── Singleton ──────────────────────────────────────────────────────
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final TokenStorage _tokenStorage = TokenStorage();

  /// GlobalKey để truy cập NavigatorState từ bất kỳ đâu (service layer)
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Callback khi session hết hạn (được set trong main.dart)
  VoidCallback? onSessionExpired;

  /// Cờ tránh xử lý nhiều lần đồng thời
  bool _isHandlingExpiry = false;

  // ═══════════════════════════════════════════════════════════════════════
  // SETUP
  // ═══════════════════════════════════════════════════════════════════════

  /// Gắn GlobalKey cho NavigatorState để có thể navigate từ service layer.
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Lấy navigator key (cho MaterialApp).
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  // ═══════════════════════════════════════════════════════════════════════
  // XỬ LÝ SESSION HẾT HẠN
  // ═══════════════════════════════════════════════════════════════════════

  /// Xử lý khi session/token hết hạn hoàn toàn (refresh cũng thất bại).
  ///
  /// Được gọi bởi [AuthInterceptor] khi:
  /// - Refresh token thất bại
  /// - Không có refresh token
  ///
  /// Flow:
  /// 1. Xóa token
  /// 2. Gọi [onSessionExpired] callback (navigate + show dialog)
  Future<void> handleSessionExpired() async {
    // Tránh xử lý trùng lặp nếu nhiều request 401 cùng lúc
    if (_isHandlingExpiry) return;
    _isHandlingExpiry = true;

    try {
      // 1. Xóa toàn bộ token
      await _tokenStorage.clearAll();

      // 2. Thông báo UI
      onSessionExpired?.call();
    } finally {
      // Reset sau 2 giây để cho phép xử lý lại nếu cần
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingExpiry = false;
      });
    }
  }

  /// Kiểm tra xem session có đang bị xử lý hết hạn không.
  bool get isHandlingExpiry => _isHandlingExpiry;
}
