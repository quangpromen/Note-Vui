/// Request model cho API đổi mật khẩu.
///
/// **Endpoint**: `POST /api/auth/change-password`
/// **Authorization**: Bearer Token (bắt buộc đăng nhập)
///
/// Validation rules (server-side):
/// - [currentPassword]: bắt buộc → lỗi: "Mật khẩu hiện tại là bắt buộc."
/// - [newPassword]: bắt buộc, tối thiểu 6 ký tự → lỗi: "Mật khẩu mới là bắt buộc." / "Mật khẩu mới phải có ít nhất 6 ký tự."
/// - [confirmNewPassword]: bắt buộc, phải trùng [newPassword] → lỗi: "Xác nhận mật khẩu mới là bắt buộc." / "Mật khẩu mới và xác nhận mật khẩu không khớp."
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  /// Chuyển sang JSON format phù hợp với API Backend.
  Map<String, dynamic> toJson() => {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
    'confirmNewPassword': confirmNewPassword,
  };
}

/// Response model cho API đổi mật khẩu.
///
/// Thành công — 200:
/// ```json
/// { "success": true, "message": "Đổi mật khẩu thành công. Vui lòng đăng nhập lại với mật khẩu mới." }
/// ```
///
/// Lỗi logic — 400:
/// ```json
/// { "success": false, "message": "Mật khẩu hiện tại không chính xác." }
/// ```
class ChangePasswordResponse {
  final bool success;
  final String message;

  const ChangePasswordResponse({required this.success, required this.message});

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}
