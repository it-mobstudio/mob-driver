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

      // The backend sometimes wraps the auth payload in an envelope
      // ({status, message, data: {access, refresh, newAccount, data: {...}}})
      // and sometimes returns it flat ({access, refresh, newAccount, data: {...}}).
      // Resolve whichever level actually holds the tokens.
      final payload = _resolveAuthPayload(body);

      final accessToken = _readToken(payload, _tokenKeys);
      final refreshToken = _readToken(payload, const [
        'refresh',
        'refresh_token',
        'refreshToken',
      ]);

      if (accessToken == null || accessToken.isEmpty) {
        return (null, const BusinessFailure('Invalid OTP response from server.'));
      }

      final userDetailsRaw = payload['data'] is Map
          ? Map<String, dynamic>.from(payload['data'] as Map)
          : <String, dynamic>{};
      final userDetails = userDetailsRaw.isNotEmpty
          ? userDetailsRaw
          : <String, dynamic>{'phone': emailOrPhone};

      final result = AuthVerifyResult(
        accessToken: accessToken,
        refreshToken: refreshToken,
        isNewAccount: payload['newAccount'] == true,
        userDetails: userDetails,
      );

      // Persist session via AuthSession (source of truth for tokens)
      await AuthSession.instance.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userDetails: userDetails,
        needsRegistration: result.isNewAccount,
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
    String? referralCode,
  }) async {
    try {
      final body = await _datasource.registerUser(
        name: name,
        phone: phone,
        email: email,
        gstin: gstin,
        businessName: businessName,
        referralCode: referralCode,
      );
      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'Registration failed.';
        return (false, BusinessFailure(msg));
      }
      final payload = _resolveUpdateUserPayload(body);
      final accessToken = _readToken(payload, _tokenKeys);
      final refreshToken = _readToken(payload, const [
        'refresh',
        'refresh_token',
        'refreshToken',
      ]);
      final tokenMap = payload['token'] is Map
          ? Map<String, dynamic>.from(payload['token'] as Map)
          : <String, dynamic>{};
      final tokenAccess = _readToken(tokenMap, _tokenKeys);
      final tokenRefresh = _readToken(tokenMap, const [
        'refresh',
        'refresh_token',
        'refreshToken',
      ]);
      final userDetails = payload['user'] is Map
          ? Map<String, dynamic>.from(payload['user'] as Map)
          : payload['data'] is Map
              ? Map<String, dynamic>.from(payload['data'] as Map)
              : <String, dynamic>{};

      final nextAccessToken = accessToken ?? tokenAccess;
      if (nextAccessToken != null && nextAccessToken.isNotEmpty) {
        await AuthSession.instance.saveSession(
          accessToken: nextAccessToken,
          refreshToken: refreshToken ?? tokenRefresh,
          userDetails: userDetails.isNotEmpty ? userDetails : null,
          needsRegistration: false,
        );
      } else {
        if (userDetails.isNotEmpty) {
          await AuthSession.instance.saveUserDetails(userDetails);
        }
        await AuthSession.instance.setNeedsRegistration(false);
      }
      return (true, null);
    } on DioException catch (e) {
      return (false, e.toAppFailure());
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, String, AppFailure?)> checkReferralCode({
    required String code,
  }) async {
    try {
      final body = await _datasource.checkReferralCode(code: code);
      final hasExistsFlag = body.containsKey('exists');
      final isValid = body['status'] == true &&
          (!hasExistsFlag || body['exists'] == true);
      final message = body['message']?.toString() ??
          (isValid ? 'Valid referral code' : 'Invalid referral code');
      return (isValid, message, null);
    } on DioException catch (e) {
      return (false, '', e.toAppFailure());
    } catch (e) {
      return (false, '', UnknownFailure(e.toString()));
    }
  }

  static const _tokenKeys = [
    'access',
    'access_token',
    'accessToken',
    'token',
    'jwt',
  ];

  Map<String, dynamic> _resolveAuthPayload(Map<String, dynamic> body) {
    if (body.containsKey('newAccount') || _readToken(body, _tokenKeys) != null) {
      return body;
    }
    if (body['data'] is Map) {
      final nested = Map<String, dynamic>.from(body['data'] as Map);
      if (nested.containsKey('newAccount') || _readToken(nested, _tokenKeys) != null) {
        return nested;
      }
    }
    return body;
  }

  Map<String, dynamic> _resolveUpdateUserPayload(Map<String, dynamic> body) {
    if (body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return body;
  }

  String? _readToken(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}
