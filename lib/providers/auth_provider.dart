import 'package:flutter/foundation.dart';

import '../models/auth_response.dart';
import '../services/auth_service.dart';
import '../services/google_sign_in_service.dart';

/// Kết quả trả về từ [AuthProvider.googleLogin].
///
/// UI sẽ dùng enum này để quyết định hành vi:
/// - [success]       → Navigate sang HomeScreen
/// - [notRegistered] → Hiển thị dialog/snackbar hướng dẫn đăng ký
/// - [cancelled]     → Không làm gì (user tự huỷ)
/// - [error]         → Hiển thị thông báo lỗi chung
enum GoogleLoginResult { success, notRegistered, cancelled, error }

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
  final GoogleSignInService _googleSignInService = GoogleSignInService();

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
  // GOOGLE LOGIN
  // ═══════════════════════════════════════════════════════════════════════

  /// Đăng nhập bằng Google.
  ///
  /// Luồng đầy đủ:
  /// 1. GoogleSignIn SDK → lấy `idToken`
  /// 2. Gửi `idToken` lên Backend `/auth/google-login`
  /// 3. Xử lý kết quả:
  ///    - 200 OK → lưu token, set state → [GoogleLoginResult.success]
  ///    - 401    → tài khoản chưa đăng ký → [GoogleLoginResult.notRegistered]
  ///    - User huỷ popup → [GoogleLoginResult.cancelled]
  ///    - Lỗi khác → [GoogleLoginResult.error]
  ///
  /// ```dart
  /// // Trong UI:
  /// final result = await authProvider.googleLogin();
  /// switch (result) {
  ///   case GoogleLoginResult.success:
  ///     Navigator.pushReplacement(...HomeScreen...);
  ///     break;
  ///   case GoogleLoginResult.notRegistered:
  ///     showDialog(...'Vui lòng đăng ký trước'...);
  ///     break;
  ///   case GoogleLoginResult.cancelled:
  ///     break; // Không làm gì
  ///   case GoogleLoginResult.error:
  ///     showSnackBar(authProvider.errorMessage);
  ///     break;
  /// }
  /// ```
  Future<GoogleLoginResult> googleLogin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // ── Bước 1: Lấy idToken từ Google ──────────────────────────────
      final idToken = await _googleSignInService.getIdToken();

      // User huỷ popup Google
      if (idToken == null) {
        _isLoading = false;
        notifyListeners();
        return GoogleLoginResult.cancelled;
      }

      // ── Bước 2: Gửi idToken lên Backend ───────────────────────────
      final response = await _authService.googleLogin(idToken);

      // ── Bước 3: Thành công → lưu state ─────────────────────────────
      _currentUser = response;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return GoogleLoginResult.success;
    } on GoogleNotRegisteredException catch (e) {
      // 401 — Tài khoản Google chưa đăng ký
      _errorMessage = e.message;
      _isLoading = false;

      // Sign out Google để lần sau user có thể chọn lại tài khoản
      await _googleSignInService.signOut();

      notifyListeners();
      return GoogleLoginResult.notRegistered;
    } on AuthException catch (e) {
      // Lỗi API khác (mạng, server...)
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return GoogleLoginResult.error;
    } catch (e, stackTrace) {
      // Lỗi không xác định (Google SDK, ...)
      // ignore: avoid_print
      print('╔══ GOOGLE LOGIN ERROR ══════════════════════════');
      // ignore: avoid_print
      print('║ Error type: ${e.runtimeType}');
      // ignore: avoid_print
      print('║ Error: $e');
      // ignore: avoid_print
      print('║ StackTrace: $stackTrace');
      // ignore: avoid_print
      print('╚════════════════════════════════════════════════');
      _errorMessage = 'Đã xảy ra lỗi khi đăng nhập bằng Google: $e';
      _isLoading = false;
      notifyListeners();
      return GoogleLoginResult.error;
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

  /// Đăng xuất — xóa token, reset state, sign out Google.
  Future<void> logout() async {
    await _authService.logout();
    await _googleSignInService.signOut();
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Cập nhật thông tin người dùng hiện tại (khi Edit Profile).
  void updateUser({String? fullName, String? avatarUrl}) {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      fullName: fullName,
      avatarUrl: avatarUrl,
    );
    notifyListeners();
  }

  /// Xóa thông báo lỗi (khi user đóng SnackBar hoặc chuyển màn hình).
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
