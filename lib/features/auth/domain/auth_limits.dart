abstract final class AuthLimits {
  /// Digits in the sign-in OTP sent by SMS.
  static const otpLength = 4;

  /// Wait before the driver may ask for the sign-in OTP again.
  static const otpResendSeconds = 30;
}
