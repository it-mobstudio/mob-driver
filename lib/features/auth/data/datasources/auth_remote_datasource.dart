import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/utils/json_readers.dart';

abstract interface class AuthRemoteDatasource {
  /// `POST driver/auth/otp/request` — texts a 6-digit OTP to a driver the
  /// company has already registered. There is no self sign-up.
  Future<Map<String, dynamic>> requestOtp({required String phoneNumber});

  /// `POST driver/auth/otp/verify` — returns the access/refresh token pair.
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
  });

  /// `POST driver/auth/logout` — revokes the refresh token.
  Future<void> logout({required String refreshToken});
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  AuthRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> requestOtp({required String phoneNumber}) async =>
      asMap((await _dio.post<dynamic>(
        '/driver/auth/otp/request',
        data: {'phone_number': phoneNumber},
      ))
          .data);

  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async =>
      asMap((await _dio.post<dynamic>(
        '/driver/auth/otp/verify',
        data: {'phone_number': phoneNumber, 'otp': otp},
      ))
          .data);

  @override
  Future<void> logout({required String refreshToken}) async {
    await _dio.post<dynamic>(
      '/driver/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }
}
