import 'package:dio/dio.dart';

abstract interface class ProfileRemoteDatasource {
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getReferralSummary();
  Future<Map<String, dynamic>> getWalletHistory();
  Future<Map<String, dynamic>> getMobstar();
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  ProfileRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.post<dynamic>(
      '/accounts/mob_user/auth/update_user/',
      data: FormData.fromMap(data),
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<Map<String, dynamic>> getReferralSummary() async {
    final response =
        await _dio.get<dynamic>('/accounts/mob_user_account/referral_summary/');
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<Map<String, dynamic>> getWalletHistory() async {
    final response = await _dio.get<dynamic>(
      '/accounts/mob_user_account/get_wallet_history/',
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<Map<String, dynamic>> getMobstar() async {
    final response = await _dio.get<dynamic>(
      '/accounts/mob_user_account/get_loyalty_history/',
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
