import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service quản lý Google Sign-In SDK.
///
/// Nhiệm vụ duy nhất: hiển thị popup Google → lấy `idToken`.
/// Token này sẽ được gửi lên backend qua [AuthService.googleLogin].
///
/// **Web Client ID** (Backend): dùng làm `serverClientId`
/// để Google trả về idToken phù hợp cho backend verify.
///
/// Singleton pattern — chỉ cần gọi `GoogleSignInService()`.
class GoogleSignInService {
  // ─── Singleton ──────────────────────────────────────────────────────
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  /// Web Client ID — đọc từ .env (không hardcode).
  static String get _serverClientId =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

  /// Google Sign-In instance — lazy-init để tránh trigger khi app khởi động.
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _signIn => _googleSignIn ??= GoogleSignIn(
    serverClientId: _serverClientId,
    scopes: ['email', 'profile'],
  );

  // ═══════════════════════════════════════════════════════════════════════
  // LẤY ID TOKEN
  // ═══════════════════════════════════════════════════════════════════════

  /// Hiển thị popup Google Sign-In và lấy `idToken`.
  ///
  /// Trả về:
  /// - `String idToken` nếu đăng nhập thành công
  /// - `null` nếu người dùng huỷ giữa chừng
  ///
  /// Throw [Exception] nếu có lỗi kỹ thuật (mạng, cấu hình...).
  Future<String?> getIdToken() async {
    try {
      // Bước 1: Hiển thị popup chọn tài khoản Google
      final GoogleSignInAccount? account = await _signIn.signIn();

      // Người dùng huỷ → trả null
      if (account == null) return null;

      // Bước 2: Lấy authentication data (idToken, accessToken)
      final GoogleSignInAuthentication auth = await account.authentication;

      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Không thể lấy idToken từ Google. '
          'Kiểm tra lại cấu hình SHA-1 và OAuth Client ID.',
        );
      }

      return idToken;
    } catch (e, stackTrace) {
      // Log lỗi chi tiết để debug
      // ignore: avoid_print
      print('╔══ GOOGLE SIGN-IN ERROR ══════════════════════');
      // ignore: avoid_print
      print('║ Error type: ${e.runtimeType}');
      // ignore: avoid_print
      print('║ Error: $e');
      // ignore: avoid_print
      print('║ StackTrace: $stackTrace');
      // ignore: avoid_print
      print('╚═════════════════════════════════════════════');

      // Nếu là lỗi do user cancel → không rethrow
      if (_isUserCancelError(e)) return null;

      // Lỗi kỹ thuật khác → rethrow
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SIGN OUT
  // ═══════════════════════════════════════════════════════════════════════

  /// Đăng xuất Google Sign-In (xóa session cũ).
  ///
  /// Gọi khi user logout app hoặc khi muốn cho chọn lại tài khoản Google.
  Future<void> signOut() async {
    try {
      await _signIn.signOut();
    } catch (_) {
      // Bỏ qua lỗi sign out — không quan trọng
    }
  }

  /// Ngắt kết nối hoàn toàn (revoke access) — hiếm khi dùng.
  Future<void> disconnect() async {
    try {
      await _signIn.disconnect();
    } catch (_) {
      // Bỏ qua
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Kiểm tra xem lỗi có phải do người dùng huỷ popup Google.
  bool _isUserCancelError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('sign_in_canceled') ||
        errorStr.contains('canceled') ||
        errorStr.contains('cancelled') ||
        errorStr.contains('user canceled') ||
        errorStr.contains('apiexception: 12501') ||
        errorStr.contains('popup_closed');
  }
}
