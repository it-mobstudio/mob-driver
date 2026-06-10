import 'package:dio/dio.dart';

abstract interface class ProfileRemoteDatasource {
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data);
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  ProfileRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get<dynamic>('/accounts/mob_user/profile/');
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

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
}
