import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/forgot_password_models.dart';
import '../../data/repositories/forgot_password_repository_impl.dart';
import '../../domain/repositories/forgot_password_repository.dart';

class ForgotPasswordController extends ChangeNotifier {
  ForgotPasswordController({ForgotPasswordRepository? repository})
    : _repository = repository ?? ForgotPasswordRepositoryImpl();

  final ForgotPasswordRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String _email = '';
  String _resetToken = '';
  int _resendCountdown = 0;
  Timer? _resendTimer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get email => _email;
  String get resetToken => _resetToken;
  int get resendCountdown => _resendCountdown;
  bool get canResendOtp => _resendCountdown == 0 && !_isLoading;

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui long nhap email';

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Email khong dung dinh dang';
    }
    return null;
  }

  String? validateOtp(String? value) {
    final otp = value?.trim() ?? '';
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      return 'OTP phai du 6 chu so';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui long nhap mat khau moi';
    }
    if (value.length < 6) {
      return 'Mat khau phai co it nhat 6 ky tu';
    }
    return null;
  }

  String? validateConfirmPassword(String? password, String? confirmPassword) {
    final passwordError = validatePassword(confirmPassword);
    if (passwordError != null) return passwordError;
    if (password != confirmPassword) return 'Mat khau xac nhan khong khop';
    return null;
  }

  Future<bool> sendOtp(String email) async {
    final emailError = validateEmail(email);
    if (emailError != null) {
      _setError(emailError);
      return false;
    }

    _setLoading(true);
    _clearMessages();
    _email = email.trim();

    try {
      final response = await _repository.sendOtp(
        ForgotPasswordSendOtpRequest(email: _email),
      );
      _successMessage = response.message.isNotEmpty
          ? response.message
          : 'Ma OTP da duoc gui den email cua ban.';
      _startResendCountdown();
      return true;
    } on ForgotPasswordException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Da xay ra loi. Vui long thu lai.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendOtp() async {
    if (!canResendOtp || _email.isEmpty) return false;
    return sendOtp(_email);
  }

  Future<bool> verifyOtp(String otp) async {
    final otpError = validateOtp(otp);
    if (otpError != null) {
      _setError(otpError);
      return false;
    }

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _repository.verifyOtp(
        ForgotPasswordVerifyOtpRequest(email: _email, otp: otp.trim()),
      );
      if (response.resetToken.isEmpty) {
        _setError('Khong nhan duoc reset token tu may chu.');
        return false;
      }
      _resetToken = response.resetToken;
      _successMessage = response.message.isNotEmpty
          ? response.message
          : 'Xac thuc OTP thanh cong.';
      return true;
    } on ForgotPasswordException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Da xay ra loi. Vui long thu lai.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final passwordError = validatePassword(newPassword);
    if (passwordError != null) {
      _setError(passwordError);
      return false;
    }

    final confirmError = validateConfirmPassword(newPassword, confirmPassword);
    if (confirmError != null) {
      _setError(confirmError);
      return false;
    }

    if (_resetToken.isEmpty) {
      _setError('Thieu reset token. Vui long xac thuc OTP lai.');
      return false;
    }

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _repository.resetPassword(
        ForgotPasswordResetRequest(
          resetToken: _resetToken,
          newPassword: newPassword,
        ),
      );
      _successMessage = response.message.isNotEmpty
          ? response.message
          : 'Dat lai mat khau thanh cong.';
      return true;
    } on ForgotPasswordException catch (e) {
      _setError(e.message);
      return false;
    } catch (_) {
      _setError('Da xay ra loi. Vui long thu lai.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    _resendCountdown = 60;
    notifyListeners();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 1) {
        _resendCountdown = 0;
        timer.cancel();
      } else {
        _resendCountdown--;
      }
      notifyListeners();
    });
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

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
