import 'package:dio/dio.dart';

abstract interface class AuthRemoteDatasource {
  Future<Map<String, dynamic>> sendOtp({
    required String emailOrPhone,
    required bool isPhone,
  });

  Future<Map<String, dynamic>> verifyOtp({
    required String emailOrPhone,
    required String otp,
  });

  Future<Map<String, dynamic>> registerUser({
    required String name,
    String? phone,
    String? email,
    String? gstin,
    String? businessName,
    String? referralCode,
    String? fcmToken,
  });

  Future<Map<String, dynamic>> checkReferralCode({required String code});

  Future<Map<String, dynamic>> updateFcmToken({
    required String emailOrPhone,
    required String fcmToken,
  });
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  AuthRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> sendOtp({
    required String emailOrPhone,
    required bool isPhone,
  }) async {
    final response = await _dio.post<dynamic>(
      '/driver/auth/send-otp/',
      data: {'phone': emailOrPhone},
    );
    return _body(response.data);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String emailOrPhone,
    required String otp,
  }) async {
    final response = await _dio.post<dynamic>(
      '/driver/auth/verify-otp/',
      data: {'phone': emailOrPhone, 'otp': otp},
    );
    return _body(response.data);
  }

  @override
  Future<Map<String, dynamic>> registerUser({
    required String name,
    String? phone,
    String? email,
    String? gstin,
    String? businessName,
    String? referralCode,
    String? fcmToken,
  }) async {
    final formData = FormData.fromMap({
      'full_name': name,
      if (phone != null && phone.isNotEmpty) 'email_or_phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (gstin != null && gstin.isNotEmpty) 'gstin': gstin,
      if (businessName != null && businessName.isNotEmpty)
        'business_name': businessName,
      if (referralCode != null && referralCode.isNotEmpty)
        'referral_code': referralCode,
      if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
    });
    final response = await _dio.post<dynamic>(
      '/accounts/mob_user/auth/update_user/',
      data: formData,
    );
    return _body(response.data);
  }

  @override
  Future<Map<String, dynamic>> checkReferralCode({required String code}) async {
    final response = await _dio.get<dynamic>(
      '/accounts/referral-code-checker/',
      queryParameters: {'referral_code': code},
    );
    return _body(response.data);
  }

  @override
  Future<Map<String, dynamic>> updateFcmToken({
    required String emailOrPhone,
    required String fcmToken,
  }) async {
    // Driver backend does not expose an FCM-token endpoint yet.
    return {'status': true};
  }

  Map<String, dynamic> _body(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
