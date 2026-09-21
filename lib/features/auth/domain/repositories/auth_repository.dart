import 'package:m_o_b_demand_side/core/errors/app_failure.dart';

class OtpRequestResult {
  const OtpRequestResult({required this.message, this.debugOtp});
  final String message;

  /// Only set when the backend runs with `DRIVER_OTP_DEBUG_RESPONSE` (a
  /// non-production switch that echoes the OTP so login is testable without
  /// an SMS gateway). Never present against a production backend.
  final String? debugOtp;
}

class AuthVerifyResult {
  const AuthVerifyResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userDetails,
  });

  final String accessToken;
  final String? refreshToken;
  final Map<String, dynamic> userDetails;
}

abstract interface class AuthRepository {
  Future<(OtpRequestResult?, AppFailure?)> sendOtp({
    required String phoneNumber,
  });

  /// On success the session (tokens + driver) is already persisted.
  Future<(AuthVerifyResult?, AppFailure?)> verifyOtp({
    required String phoneNumber,
    required String otp,
  });

  /// Revokes the refresh token server-side (best effort) and clears the
  /// local session.
  Future<void> signOut();

  /// Push-token registration. The backend has no device-token endpoint yet
  /// (trip alerts reach the app by polling), so this succeeds without
  /// sending anything — it exists so the FCM plumbing has somewhere to call
  /// once one is added.
  Future<(bool, AppFailure?)> updateFcmToken({
    required String emailOrPhone,
    required String fcmToken,
  });
}
