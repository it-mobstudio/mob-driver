import 'package:dio/dio.dart';

abstract interface class CreditRemoteDatasource {
  Future<dynamic> getBusinessSegments();

  Future<Map<String, dynamic>> requestLineOfCredit(Map<String, dynamic> body);
}

class CreditRemoteDatasourceImpl implements CreditRemoteDatasource {
  CreditRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<dynamic> getBusinessSegments() async {
    final response = await _dio.get<dynamic>('/home/business_segment/');
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> requestLineOfCredit(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<dynamic>(
      '/request_line_of_credit/',
      data: body,
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
