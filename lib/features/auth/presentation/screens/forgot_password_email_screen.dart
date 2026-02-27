import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../notes/domain/note_service.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/forgot_password_widgets.dart';
import 'forgot_password_otp_screen.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key, required this.noteService});

  final NoteService noteService;

  @override
  State<ForgotPasswordEmailScreen> createState() =>
      _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp(ForgotPasswordController controller) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final isOk = await controller.sendOtp(_emailController.text);
    if (!mounted) return;

    if (!isOk) {
      showForgotPasswordSnackBar(
        context,
        message: controller.errorMessage ?? 'Không thể gửi OTP.',
        isError: true,
      );
      return;
    }

    showForgotPasswordSnackBar(
      context,
      message: controller.successMessage ?? 'Đã gửi OTP.',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: controller,
          child: ForgotPasswordOtpScreen(noteService: widget.noteService),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordController(),
      child: Consumer<ForgotPasswordController>(
        builder: (context, controller, _) {
          return Stack(
            children: [
              ForgotPasswordScaffold(
                title: 'Quên mật khẩu',
                subtitle: 'Nhập email để nhận mã khôi phục.',
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ForgotPasswordTextField(
                        controller: _emailController,
                        hint: 'Email',
                        icon: CupertinoIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: controller.validateEmail,
                        onFieldSubmitted: (_) => _handleSendOtp(controller),
                      ),
                      const SizedBox(height: 20),
                      ForgotPasswordPrimaryButton(
                        label: 'Gửi Mã Khôi Phục',
                        isLoading: controller.isLoading,
                        onTap: () => _handleSendOtp(controller),
                      ),
                    ],
                  ),
                ),
              ),
              ForgotPasswordLoadingOverlay(isVisible: controller.isLoading),
            ],
          );
        },
      ),
    );
  }
}
