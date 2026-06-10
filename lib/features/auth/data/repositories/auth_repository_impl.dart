import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final AuthRemoteDatasource _datasource;

  @override
  Future<(bool, AppFailure?)> sendOtp({
    required String emailOrPhone,
    required bool isPhone,
  }) async {
    try {
      final body = await _datasource.sendOtp(
        emailOrPhone: emailOrPhone,
        isPhone: isPhone,
      );
      final status = body['status'];
      if (status == false) {
        final msg = body['message']?.toString() ?? 'Failed to send OTP.';
        return (false, BusinessFailure(msg));
      }
      return (true, null);
    } on DioException catch (e) {
      return (false, e.toAppFailure());
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(AuthVerifyResult?, AppFailure?)> verifyOtp({
    required String emailOrPhone,
    required String otp,
  }) async {
    try {
      final body = await _datasource.verifyOtp(
        emailOrPhone: emailOrPhone,
        otp: otp,
      );

      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'OTP verification failed.';
        return (null, BusinessFailure(msg));
      }

      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;

      final accessToken = _readToken(data, const [
        'access',
        'access_token',
        'accessToken',
        'token',
        'jwt',
      ]);
      final refreshToken = _readToken(data, const [
        'refresh',
        'refresh_token',
        'refreshToken',
      ]);

      if (accessToken == null || accessToken.isEmpty) {
        return (null, const BusinessFailure('Invalid OTP response from server.'));
      }

      final userDetailsRaw = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : <String, dynamic>{};

      final result = AuthVerifyResult(
        accessToken: accessToken,
        refreshToken: refreshToken,
        isNewAccount: data['newAccount'] == true,
        userDetails: userDetailsRaw,
      );

      // Persist session via AuthSession (source of truth for tokens)
      await AuthSession.instance.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userDetails: userDetailsRaw.isNotEmpty ? userDetailsRaw : null,
      );

      return (result, null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, AppFailure?)> registerUser({
    required String name,
    String? phone,
    String? email,
    String? gstin,
    String? businessName,
  }) async {
    try {
      final body = await _datasource.registerUser(
        name: name,
        phone: phone,
        email: email,
        gstin: gstin,
        businessName: businessName,
      );
      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'Registration failed.';
        return (false, BusinessFailure(msg));
      }
      return (true, null);
    } on DioException catch (e) {
      return (false, e.toAppFailure());
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  String? _readToken(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
