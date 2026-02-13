import 'package:flutter/foundation.dart';

import '../models/auth_response.dart';
import '../services/auth_service.dart';

/// Quản lý trạng thái xác thực cho toàn bộ ứng dụng.
///
/// Sử dụng với [ChangeNotifierProvider] trong `main.dart`:
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => AuthProvider()..checkAuthStatus(),
///   child: MaterialApp(...),
/// )
/// ```
///
/// Trong UI, lấy provider bằng:
/// ```dart
/// final auth = Provider.of<AuthProvider>(context, listen: false);
/// await auth.login(email, password);
/// ```
///
/// Trạng thái:
/// - [isLoading]    → đang gọi API (hiện loading spinner)
/// - [isLoggedIn]   → đã đăng nhập (có token)
/// - [errorMessage] → lỗi cuối cùng (hiện SnackBar)
/// - [currentUser]  → thông tin user sau login/register
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // ─── State ──────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  AuthResponse? _currentUser;

  // ─── Getters ────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  AuthResponse? get currentUser => _currentUser;
  String get userName => _currentUser?.fullName ?? 'Người dùng';

  // ═══════════════════════════════════════════════════════════════════════
  // KIỂM TRA TRẠNG THÁI BAN ĐẦU
  // ═══════════════════════════════════════════════════════════════════════

  /// Gọi khi app khởi động để kiểm tra đã login chưa.
  /// Nếu có token trong máy → [isLoggedIn] = true.
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authService.isLoggedIn();
    } catch (_) {
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOGIN
  // ═══════════════════════════════════════════════════════════════════════

  /// Đăng nhập với email + password.
  ///
  /// Trả về `true` nếu thành công, `false` nếu thất bại.
  /// Nếu thất bại, [errorMessage] sẽ chứa lý do (tiếng Việt).
  ///
  /// ```dart
  /// // Trong UI:
  /// final auth = Provider.of<AuthProvider>(context, listen: false);
  /// final ok = await auth.login('test@gmail.com', '123456');
  /// if (!ok) {
  ///   ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(content: Text(auth.errorMessage ?? 'Lỗi')),
  ///   );
  /// }
  /// ```
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _currentUser = response;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi không xác định.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REGISTER
  // ═══════════════════════════════════════════════════════════════════════

  /// Đăng ký tài khoản mới.
  ///
  /// Trả về `true` nếu thành công (auto-login), `false` nếu thất bại.
  Future<bool> register(String email, String password, String fullName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(email, password, fullName);
      _currentUser = response;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi không xác định.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════════════════════

  /// Đăng xuất — xóa token, reset state.
  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Xóa thông báo lỗi (khi user đóng SnackBar hoặc chuyển màn hình).
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
