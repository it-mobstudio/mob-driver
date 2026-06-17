import 'package:m_o_b_demand_side/core/errors/app_failure.dart';

class AuthVerifyResult {
  const AuthVerifyResult({
    required this.accessToken,
    required this.refreshToken,
    required this.isNewAccount,
    required this.userDetails,
  });

  final String accessToken;
  final String? refreshToken;
  final bool isNewAccount;
  final Map<String, dynamic> userDetails;
}

abstract interface class AuthRepository {
  Future<(bool, AppFailure?)> sendOtp({
    required String emailOrPhone,
    required bool isPhone,
  });

  Future<(AuthVerifyResult?, AppFailure?)> verifyOtp({
    required String emailOrPhone,
    required String otp,
  });

  Future<(bool, AppFailure?)> registerUser({
    required String name,
    String? phone,
    String? email,
    String? gstin,
    String? businessName,
    String? referralCode,
  });

  Future<(bool, String, AppFailure?)> checkReferralCode({
    required String code,
  });
}
