import 'package:dio/dio.dart';

abstract interface class RfqRemoteDatasource {
  Future<dynamic> getRfqList({int page = 1, String? search});
  Future<Map<String, dynamic>> getRfqDetail(String id);
  Future<Map<String, dynamic>> submitRfq(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> acceptRfqQuote(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> createCartQuoteRequest(
    Map<String, dynamic> payload,
  );
}

class RfqRemoteDatasourceImpl implements RfqRemoteDatasource {
  RfqRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<dynamic> getRfqList({int page = 1, String? search}) async {
    final response = await _dio.get<dynamic>(
      '/rfq/get_rfqs/',
      queryParameters: {
        'page': page,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
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
  Future<Map<String, dynamic>> acceptRfqQuote(
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<dynamic>(
      '/rfq/accept_or_reject_quote/',
      data: payload,
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<Map<String, dynamic>> createCartQuoteRequest(
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<dynamic>(
      '/orders/cart/create_quote_request/',
      data: payload,
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
