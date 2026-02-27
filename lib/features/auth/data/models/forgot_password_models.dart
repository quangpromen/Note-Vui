class ForgotPasswordSendOtpRequest {
  final String email;

  const ForgotPasswordSendOtpRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class ForgotPasswordSendOtpResponse {
  final bool success;
  final String message;

  const ForgotPasswordSendOtpResponse({
    required this.success,
    required this.message,
  });

  factory ForgotPasswordSendOtpResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordSendOtpResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}

class ForgotPasswordVerifyOtpRequest {
  final String email;
  final String otp;

  const ForgotPasswordVerifyOtpRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() => {'email': email, 'otp': otp};
}

class ForgotPasswordVerifyOtpResponse {
  final bool success;
  final String message;
  final String resetToken;

  const ForgotPasswordVerifyOtpResponse({
    required this.success,
    required this.message,
    required this.resetToken,
  });

  factory ForgotPasswordVerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordVerifyOtpResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      resetToken: json['resetToken']?.toString() ?? '',
    );
  }
}

class ForgotPasswordResetRequest {
  final String resetToken;
  final String newPassword;

  const ForgotPasswordResetRequest({
    required this.resetToken,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'resetToken': resetToken,
    'newPassword': newPassword,
  };
}

class ForgotPasswordResetResponse {
  final bool success;
  final String message;

  const ForgotPasswordResetResponse({
    required this.success,
    required this.message,
  });

  factory ForgotPasswordResetResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResetResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}
