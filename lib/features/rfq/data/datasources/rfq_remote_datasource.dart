import 'package:dio/dio.dart';

abstract interface class RfqRemoteDatasource {
  Future<dynamic> getRfqList();
  Future<Map<String, dynamic>> getRfqDetail(String id);
  Future<Map<String, dynamic>> submitRfq(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> createCartQuoteRequest(
    Map<String, dynamic> payload,
  );
}

class RfqRemoteDatasourceImpl implements RfqRemoteDatasource {
  RfqRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<dynamic> getRfqList() async {
    final response = await _dio.get<dynamic>(
      '/rfq/get_rfqs/',
      queryParameters: {'page': 1},
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getRfqDetail(String id) async {
    final response = await _dio.get<dynamic>('/rfq/$id/get_rfq_details/');
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<Map<String, dynamic>> submitRfq(Map<String, dynamic> payload) async {
    final response = await _dio.post<dynamic>('/rfq/submit/', data: payload);
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<Map<String, dynamic>> createCartQuoteRequest(
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<dynamic>(
      '/orders/rfq_quotecreate_offline/',
      data: payload,
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
