class SendOtpResult {
  const SendOtpResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}

class VerifyOtpResult {
  const VerifyOtpResult({
    required this.success,
    required this.message,
    required this.newAccount,
    this.accessToken,
    this.refreshToken,
    this.userDetails,
  });

  final bool success;
  final String message;
  final bool newAccount;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? userDetails;
}
