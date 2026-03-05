import 'package:flutter/foundation.dart';

import '../../../../core/auth/token_storage.dart';
import '../../data/models/change_password_models.dart';
import '../../data/repositories/change_password_repository_impl.dart';
import '../../domain/repositories/change_password_repository.dart';

/// Kết quả đổi mật khẩu — phân biệt thành công, lỗi thường, lỗi 401.
///
/// Giúp UI xử lý riêng từng trường hợp:
/// - [success]: show dialog thành công → navigate về Login
/// - [error]: show SnackBar lỗi
/// - [unauthorized]: tự động navigate về Login (token hết hạn)
enum ChangePasswordResult { success, error, unauthorized }

/// Controller quản lý trạng thái đổi mật khẩu.
///
/// Tuân theo pattern [ForgotPasswordController]:
/// - Validate client-side trước khi gọi API
/// - Quản lý loading/error/success state
/// - Xóa token sau khi đổi mật khẩu thành công
///
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => ChangePasswordController(),
///   child: ChangePasswordScreen(...),
/// )
/// ```
class ChangePasswordController extends ChangeNotifier {
  ChangePasswordController({ChangePasswordRepository? repository})
    : _repository = repository ?? ChangePasswordRepositoryImpl();

  final ChangePasswordRepository _repository;
  final TokenStorage _tokenStorage = TokenStorage();

  // ─── State ──────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // ─── Getters ────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // ═══════════════════════════════════════════════════════════════════════
  // VALIDATION — Client-side
  // ═══════════════════════════════════════════════════════════════════════

  /// Validate mật khẩu hiện tại — không được để trống.
  String? validateCurrentPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại.';
    }
    return null;
  }

  /// Validate mật khẩu mới — không để trống, tối thiểu 6 ký tự.
  String? validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu mới.';
    }
    if (value.length < 6) {
      return 'Mật khẩu mới phải có ít nhất 6 ký tự.';
    }
    return null;
  }

  /// Validate xác nhận mật khẩu — không để trống, phải khớp với mật khẩu mới.
  String? validateConfirmNewPassword(
    String? newPassword,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.trim().isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới.';
    }
    if (confirmPassword.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    if (newPassword != confirmPassword) {
      return 'Mật khẩu mới và xác nhận không khớp.';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ĐỔI MẬT KHẨU
  // ═══════════════════════════════════════════════════════════════════════

  /// Gọi API đổi mật khẩu.
  ///
  /// Trả về [ChangePasswordResult]:
  /// - [success]: đổi thành công, token đã bị xóa → UI navigate về Login
  /// - [error]: lỗi validation hoặc logic → UI show SnackBar
  /// - [unauthorized]: token hết hạn → UI navigate về Login ngay lập tức
  Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    // ── Client-side validation ──────────────────────────────────────
    final currentError = validateCurrentPassword(currentPassword);
    if (currentError != null) {
      _setError(currentError);
      return ChangePasswordResult.error;
    }

    final newError = validateNewPassword(newPassword);
    if (newError != null) {
      _setError(newError);
      return ChangePasswordResult.error;
    }

    final confirmError = validateConfirmNewPassword(
      newPassword,
      confirmNewPassword,
    );
    if (confirmError != null) {
      _setError(confirmError);
      return ChangePasswordResult.error;
    }

    // ── Mật khẩu mới phải khác mật khẩu hiện tại ────────────────────
    if (currentPassword == newPassword) {
      _setError('Mật khẩu mới phải khác mật khẩu hiện tại.');
      return ChangePasswordResult.error;
    }

    // ── Gọi API ─────────────────────────────────────────────────────
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _repository.changePassword(
        ChangePasswordRequest(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmNewPassword: confirmNewPassword,
        ),
      );

      _successMessage = response.message.isNotEmpty
          ? response.message
          : 'Đổi mật khẩu thành công. Vui lòng đăng nhập lại với mật khẩu mới.';

      // ── Xóa tất cả token sau khi đổi mật khẩu thành công ─────
      // Server đã revoke refresh token → session trên mọi thiết bị bị vô hiệu
      await _tokenStorage.clearAll();

      return ChangePasswordResult.success;
    } on ChangePasswordUnauthorizedException {
      // ── Token hết hạn → xóa token, UI sẽ navigate về Login ──────
      await _tokenStorage.clearAll();
      _setError('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      return ChangePasswordResult.unauthorized;
    } on ChangePasswordException catch (e) {
      _setError(e.message);
      return ChangePasswordResult.error;
    } catch (_) {
      _setError('Đã xảy ra lỗi. Vui lòng thử lại.');
      return ChangePasswordResult.error;
    } finally {
      _setLoading(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Xóa thông báo lỗi hiện tại.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Xóa thông báo thành công hiện tại.
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
