import '/backend/api_requests/api_calls.dart';
import '/features/auth/models/auth_models.dart';

class AuthRepository {
  const AuthRepository();

  Future<SendOtpResult> sendOtp({
    required int emailOrPhone,
    bool isPhone = true,
  }) async {
    final response = await LoginOTPCall.call(
      emailOrPhone: emailOrPhone,
      isPhone: isPhone,
    );
    final body = response.jsonBody is Map
        ? Map<String, dynamic>.from(response.jsonBody as Map)
        : <String, dynamic>{};
    final success = body['status'] == true;
    final message = body['message']?.toString() ??
        (success ? 'OTP sent successfully.' : 'Failed to send OTP.');
    return SendOtpResult(
      success: success,
      message: message,
    );
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await CheckOTPCall.call(
      phone: phone,
      otp: otp,
    );
    final body = response.jsonBody is Map
        ? Map<String, dynamic>.from(response.jsonBody as Map)
        : <String, dynamic>{};
    final data = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : <String, dynamic>{};
    final success = body['status'] == true;
    final message = body['message']?.toString() ??
        (success ? 'OTP verified successfully.' : 'OTP verification failed.');
    return VerifyOtpResult(
      success: success,
      message: message,
      newAccount: data['newAccount'] == true,
      accessToken: _readFirstString(
        data,
        const ['access_token', 'accessToken', 'token', 'jwt'],
      ),
      refreshToken: _readFirstString(
        data,
        const ['refresh_token', 'refreshToken'],
      ),
    );
  }

  String? _readFirstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
