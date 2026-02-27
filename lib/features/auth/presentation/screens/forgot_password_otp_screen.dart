import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../notes/domain/note_service.dart';
import '../controllers/forgot_password_controller.dart';
import '../widgets/forgot_password_widgets.dart';
import 'forgot_password_reset_screen.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  const ForgotPasswordOtpScreen({super.key, required this.noteService});

  final NoteService noteService;

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _collectOtp() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _handleOtpInput(int index, String value) {
    if (value.length > 1) {
      _otpControllers[index].text = value.substring(value.length - 1);
      _otpControllers[index].selection = TextSelection.fromPosition(
        const TextPosition(offset: 1),
      );
    }

    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleVerify(ForgotPasswordController controller) async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final isOk = await controller.verifyOtp(_collectOtp());
    if (!mounted) return;

    if (!isOk) {
      showForgotPasswordSnackBar(
        context,
        message: controller.errorMessage ?? 'OTP không hợp lệ.',
        isError: true,
      );
      return;
    }

    showForgotPasswordSnackBar(
      context,
      message: controller.successMessage ?? 'Xác nhận OTP thành công.',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: controller,
          child: ForgotPasswordResetScreen(noteService: widget.noteService),
        ),
      ),
    );
  }

  Future<void> _handleResend(ForgotPasswordController controller) async {
    final isOk = await controller.resendOtp();
    if (!mounted) return;

    if (!isOk) {
      showForgotPasswordSnackBar(
        context,
        message:
            controller.errorMessage ??
            'Bạn chưa thể gửi lại OTP. Vui lòng thử lại sau.',
        isError: true,
      );
      return;
    }

    for (final controller in _otpControllers) {
      controller.clear();
    }

    showForgotPasswordSnackBar(
      context,
      message: controller.successMessage ?? 'Đã gửi lại OTP.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ForgotPasswordController>(
      builder: (context, controller, _) {
        return Stack(
          children: [
            ForgotPasswordScaffold(
              title: 'Xác thực OTP',
              subtitle: 'Mã OTP đã được gửi đến email ${controller.email}',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (index) => SizedBox(
                          width: 44,
                          child: TextFormField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (value) => _handleOtpInput(index, value),
                            validator: (_) {
                              if (_collectOtp().length != 6) {
                                return '';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (controller.validateOtp(_collectOtp()) != null &&
                        _collectOtp().isNotEmpty)
                      Text(
                        'OTP phải đủ 6 chữ số',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFFFD93D),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ForgotPasswordPrimaryButton(
                      label: 'Xác Nhận',
                      isLoading: controller.isLoading,
                      onTap: () => _handleVerify(controller),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: controller.canResendOtp
                          ? () => _handleResend(controller)
                          : null,
                      child: Text(
                        controller.canResendOtp
                            ? 'Gửi lại OTP'
                            : 'Gửi lại sau ${controller.resendCountdown}s',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
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
