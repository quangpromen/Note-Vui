import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../notes/domain/note_service.dart';
import '../controllers/change_password_controller.dart';
import '../widgets/forgot_password_widgets.dart';
import 'login_screen.dart';

/// Màn hình Đổi Mật Khẩu.
///
/// Flow:
/// 1. User nhập mật khẩu hiện tại, mật khẩu mới, xác nhận mật khẩu mới
/// 2. Validate client-side → gọi API
/// 3. Thành công → show dialog → clear token → navigate về Login
/// 4. Thất bại (400) → show SnackBar lỗi từ server
/// 5. Thất bại (401) → tự động navigate về Login
///
/// Sử dụng [ChangeNotifierProvider] để inject [ChangePasswordController].
/// Reuse widget từ [forgot_password_widgets.dart] để đảm bảo UI đồng bộ.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.noteService});

  final NoteService noteService;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // XỬ LÝ ĐỔI MẬT KHẨU
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _handleSubmit(ChangePasswordController controller) async {
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    // Validate form fields (hiển thị lỗi ngay dưới ô nhập)
    if (!_formKey.currentState!.validate()) return;

    final result = await controller.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmNewPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;

    switch (result) {
      // ── Thành công: show dialog → navigate về Login ──────────────
      case ChangePasswordResult.success:
        await _showSuccessDialog(controller.successMessage);
        if (!mounted) return;
        _navigateToLogin();
        break;

      // ── Lỗi validation/logic: show SnackBar ─────────────────────
      case ChangePasswordResult.error:
        showForgotPasswordSnackBar(
          context,
          message: controller.errorMessage ?? 'Không thể đổi mật khẩu.',
          isError: true,
        );
        break;

      // ── Token hết hạn (401): navigate về Login ngay ─────────────
      case ChangePasswordResult.unauthorized:
        showForgotPasswordSnackBar(
          context,
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          isError: true,
        );
        if (!mounted) return;
        _navigateToLogin();
        break;
    }
  }

  /// Hiển thị dialog thông báo đổi mật khẩu thành công.
  Future<void> _showSuccessDialog(String? message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              CupertinoIcons.check_mark_circled_solid,
              color: Color(0xFF4CAF50),
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Thành công',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          message ??
              'Đổi mật khẩu thành công. Vui lòng đăng nhập lại với mật khẩu mới.',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đăng nhập lại',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF008080),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate về LoginScreen, xóa toàn bộ navigation stack.
  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(noteService: widget.noteService),
      ),
      (route) => false,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChangePasswordController(),
      child: Consumer<ChangePasswordController>(
        builder: (context, controller, _) {
          return Stack(
            children: [
              ForgotPasswordScaffold(
                title: 'Đổi mật khẩu',
                subtitle: 'Nhập mật khẩu hiện tại và mật khẩu mới để thay đổi.',
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Mật khẩu hiện tại ────────────────────────
                      ForgotPasswordTextField(
                        controller: _currentPasswordController,
                        hint: 'Mật khẩu hiện tại',
                        icon: CupertinoIcons.lock,
                        obscureText: _obscureCurrentPassword,
                        textInputAction: TextInputAction.next,
                        validator: controller.validateCurrentPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword =
                                  !_obscureCurrentPassword;
                            });
                          },
                          icon: Icon(
                            _obscureCurrentPassword
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Mật khẩu mới ─────────────────────────────
                      ForgotPasswordTextField(
                        controller: _newPasswordController,
                        hint: 'Mật khẩu mới',
                        icon: CupertinoIcons.lock_rotation,
                        obscureText: _obscureNewPassword,
                        textInputAction: TextInputAction.next,
                        validator: controller.validateNewPassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                          icon: Icon(
                            _obscureNewPassword
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Xác nhận mật khẩu mới ────────────────────
                      ForgotPasswordTextField(
                        controller: _confirmPasswordController,
                        hint: 'Xác nhận mật khẩu mới',
                        icon: CupertinoIcons.lock_shield,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        validator: (value) =>
                            controller.validateConfirmNewPassword(
                              _newPasswordController.text,
                              value,
                            ),
                        onFieldSubmitted: (_) => _handleSubmit(controller),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? CupertinoIcons.eye
                                : CupertinoIcons.eye_slash,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Nút đổi mật khẩu ─────────────────────────
                      ForgotPasswordPrimaryButton(
                        label: 'Đổi mật khẩu',
                        isLoading: controller.isLoading,
                        onTap: () => _handleSubmit(controller),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Loading overlay ──────────────────────────────────────
              ForgotPasswordLoadingOverlay(isVisible: controller.isLoading),
            ],
          );
        },
      ),
    );
  }
}
