import 'package:dio/dio.dart';

abstract interface class CheckoutRemoteDatasource {
  Future<Map<String, dynamic>> getCheckoutSummary();
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> payload);
}

class CheckoutRemoteDatasourceImpl implements CheckoutRemoteDatasource {
  CheckoutRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getCheckoutSummary() async {
    final response = await _dio.get<dynamic>('/checkout/');
    return _toMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> payload) async {
    final response = await _dio.post<dynamic>('/checkout/place-order/', data: payload);
    return _toMap(response.data);
  }

  Map<String, dynamic> _toMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
