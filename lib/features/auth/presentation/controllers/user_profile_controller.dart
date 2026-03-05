import 'package:flutter/foundation.dart';

import '../../../../core/auth/token_storage.dart';
import '../../data/models/user_profile_models.dart';
import '../../data/repositories/user_profile_repository_impl.dart';
import '../../domain/repositories/user_profile_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TRẠNG THÁI — 3 states: Loading, Success, Error
// ═══════════════════════════════════════════════════════════════════════════

/// Enum quản lý trạng thái hiển thị hồ sơ cá nhân.
///
/// - [initial]: chưa fetch (vừa khởi tạo controller)
/// - [loading]: đang gọi API
/// - [success]: có data, hiển thị bình thường
/// - [error]: lỗi mạng/server, hiển thị UI lỗi + nút Thử lại
/// - [unauthorized]: token hết hạn → navigate về Login
enum UserProfileStatus { initial, loading, success, error, unauthorized }

/// Controller quản lý trạng thái màn hình Hồ sơ cá nhân.
///
/// Tuân theo pattern [ChangePasswordController]:
/// - Quản lý loading/success/error state
/// - Fetch data lúc khởi tạo (gọi [fetchProfile] từ initState)
/// - Hỗ trợ pull-to-refresh (gọi lại [fetchProfile])
///
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => UserProfileController()..fetchProfile(),
///   child: UserProfileScreen(...),
/// )
/// ```
class UserProfileController extends ChangeNotifier {
  UserProfileController({UserProfileRepository? repository})
    : _repository = repository ?? UserProfileRepositoryImpl();

  final UserProfileRepository _repository;
  final TokenStorage _tokenStorage = TokenStorage();

  // ─── State ──────────────────────────────────────────────────────────
  UserProfileStatus _status = UserProfileStatus.initial;
  UserProfileResponse? _profile;
  String? _errorMessage;

  // ─── Getters ────────────────────────────────────────────────────────
  UserProfileStatus get status => _status;
  UserProfileResponse? get profile => _profile;
  String? get errorMessage => _errorMessage;

  /// Shortcut: đang loading hay không (bao gồm cả initial load)
  bool get isLoading =>
      _status == UserProfileStatus.loading ||
      _status == UserProfileStatus.initial;

  /// Shortcut: có data để hiển thị
  bool get hasData => _status == UserProfileStatus.success && _profile != null;

  /// Shortcut: có lỗi
  bool get hasError => _status == UserProfileStatus.error;

  /// Shortcut: token hết hạn
  bool get isUnauthorized => _status == UserProfileStatus.unauthorized;

  // ═══════════════════════════════════════════════════════════════════════
  // FETCH PROFILE — Gọi API lấy hồ sơ cá nhân
  // ═══════════════════════════════════════════════════════════════════════

  /// Gọi API `GET /user/profile` để lấy thông tin hồ sơ cá nhân.
  ///
  /// Được gọi khi:
  /// 1. Khởi tạo màn hình (initState → fetchProfile)
  /// 2. Pull-to-refresh (vuốt xuống)
  /// 3. Nhấn nút "Thử lại"
  ///
  /// Xử lý kết quả:
  /// - Thành công → [status] = success, [profile] chứa data
  /// - Lỗi 401 → xóa token, [status] = unauthorized → UI navigate về Login
  /// - Lỗi khác → [status] = error, [errorMessage] chứa message tiếng Việt
  Future<void> fetchProfile() async {
    _status = UserProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getUserProfile();
      _profile = response;
      _status = UserProfileStatus.success;
    } on UserProfileUnauthorizedException {
      // ── Token hết hạn → xóa token, UI sẽ navigate về Login ──────
      await _tokenStorage.clearAll();
      _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      _status = UserProfileStatus.unauthorized;
    } on UserProfileException catch (e) {
      _errorMessage = e.message;
      _status = UserProfileStatus.error;
    } catch (_) {
      _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      _status = UserProfileStatus.error;
    }

    notifyListeners();
  }

  /// Refresh profile — dùng cho RefreshIndicator (pull-to-refresh).
  ///
  /// Khác [fetchProfile] ở chỗ: KHÔNG set loading state
  /// để tránh mất UI hiện tại khi đang refresh ngầm.
  Future<void> refreshProfile() async {
    try {
      final response = await _repository.getUserProfile();
      _profile = response;
      _status = UserProfileStatus.success;
      _errorMessage = null;
    } on UserProfileUnauthorizedException {
      await _tokenStorage.clearAll();
      _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      _status = UserProfileStatus.unauthorized;
    } on UserProfileException catch (e) {
      // Khi refresh: nếu lỗi mà đã có data cũ → giữ data cũ,
      // chỉ cập nhật errorMessage
      _errorMessage = e.message;
      if (_profile == null) {
        _status = UserProfileStatus.error;
      }
    } catch (_) {
      _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      if (_profile == null) {
        _status = UserProfileStatus.error;
      }
    }

    notifyListeners();
  }
}
