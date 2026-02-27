import '../../data/models/forgot_password_models.dart';

abstract class ForgotPasswordRepository {
  Future<ForgotPasswordSendOtpResponse> sendOtp(
    ForgotPasswordSendOtpRequest request,
  );

  Future<ForgotPasswordVerifyOtpResponse> verifyOtp(
    ForgotPasswordVerifyOtpRequest request,
  );

  Future<ForgotPasswordResetResponse> resetPassword(
    ForgotPasswordResetRequest request,
  );
}
