import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/core/utils/json_readers.dart';
import 'package:m_o_b_demand_side/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final AuthRemoteDatasource _datasource;

  @override
  Future<(OtpRequestResult?, AppFailure?)> sendOtp({
    required String phoneNumber,
  }) async {
    try {
      final body = await _datasource.requestOtp(phoneNumber: phoneNumber);
      return (
        OtpRequestResult(
          message: readString(body['message']) ?? 'OTP sent.',
          debugOtp: readString(body['otp']),
        ),
        null
      );
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(AuthVerifyResult?, AppFailure?)> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final body = await _datasource.verifyOtp(
        phoneNumber: phoneNumber,
        otp: otp,
      );

      final accessToken = readString(body['accessToken']);
      if (accessToken == null) {
        return (
          null,
          const BusinessFailure('Invalid response from the server.')
        );
      }
      final refreshToken = readString(body['refreshToken']);

      // Only what the session screens need to show before the profile has
      // loaded; the full profile is fetched from `driver/me`.
      final driver = asMap(body['driver']);
      final userDetails = <String, dynamic>{
        'id': readString(driver['id']),
        'full_name':
            readString(driver['full_name']) ?? readString(body['driverName']),
        'phone_number': readString(driver['phone_number']) ?? phoneNumber,
      };

      await AuthSession.instance.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userDetails: userDetails,
      );

      return (
        AuthVerifyResult(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userDetails: userDetails,
        ),
        null
      );
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<void> signOut() async {
    final refreshToken = AuthSession.instance.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        // Short leash: signing out on a bad connection must still sign out.
        await _datasource
            .logout(refreshToken: refreshToken)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Revocation is best effort; the local session is cleared regardless.
      }
    }
    await AuthSession.instance.signOut();
  }

  @override
  Future<(bool, AppFailure?)> updateFcmToken({
    required String emailOrPhone,
    required String fcmToken,
  }) async =>
      (true, null);
}
