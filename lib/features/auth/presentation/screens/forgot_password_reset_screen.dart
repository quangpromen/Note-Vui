import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../notes/domain/note_service.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/forgot_password_widgets.dart';
import 'login_screen.dart';

class ForgotPasswordResetScreen extends StatefulWidget {
  const ForgotPasswordResetScreen({super.key, required this.noteService});

  final NoteService noteService;

  @override
  State<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends State<ForgotPasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(ForgotPasswordController controller) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final isOk = await controller.resetPassword(
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;

    if (!isOk) {
      showForgotPasswordSnackBar(
        context,
        message: controller.errorMessage ?? 'Không thể đặt lại mật khẩu.',
        isError: true,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Thành công',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Đặt lại mật khẩu thành công.',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đăng nhập',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(noteService: widget.noteService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ForgotPasswordController>(
      builder: (context, controller, _) {
        return Stack(
          children: [
            ForgotPasswordScaffold(
              title: 'Đặt mật khẩu mới',
              subtitle: 'Mật khẩu mới phải có ít nhất 6 ký tự.',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ForgotPasswordTextField(
                      controller: _newPasswordController,
                      hint: 'Mật khẩu mới',
                      icon: CupertinoIcons.lock,
                      obscureText: _obscureNewPassword,
                      validator: controller.validatePassword,
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
                    ForgotPasswordTextField(
                      controller: _confirmPasswordController,
                      hint: 'Xác nhận mật khẩu mới',
                      icon: CupertinoIcons.lock_shield,
                      obscureText: _obscureConfirmPassword,
                      validator: (value) => controller.validateConfirmPassword(
                        _newPasswordController.text,
                        value,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
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
                    const SizedBox(height: 20),
                    ForgotPasswordPrimaryButton(
                      label: 'Hoàn tất',
                      isLoading: controller.isLoading,
                      onTap: () => _handleSubmit(controller),
                    ),
                  ],
                ),
              ),
            ),
            ForgotPasswordLoadingOverlay(isVisible: controller.isLoading),
          ],
        );
      },
    );
  }
}
