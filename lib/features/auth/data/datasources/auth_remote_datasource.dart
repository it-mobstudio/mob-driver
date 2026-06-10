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
      '/accounts/mob_user/auth/send_otp/',
      data: {'email_or_phone': emailOrPhone, 'isPhone': isPhone},
    );
    return _body(response.data);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String emailOrPhone,
    required String otp,
  }) async {
    final response = await _dio.post<dynamic>(
      '/accounts/mob_user/auth/check_otp/',
      data: {'email_or_phone': emailOrPhone, 'otp': otp},
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
  }) async {
    final formData = FormData.fromMap({
      'full_name': name,
      if (phone != null && phone.isNotEmpty) 'email_or_phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (gstin != null && gstin.isNotEmpty) 'gstin': gstin,
      if (businessName != null && businessName.isNotEmpty) 'business_name': businessName,
    });
    final response = await _dio.post<dynamic>(
      '/accounts/mob_user/auth/update_user/',
      data: formData,
    );
    return _body(response.data);
  }

  Map<String, dynamic> _body(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
