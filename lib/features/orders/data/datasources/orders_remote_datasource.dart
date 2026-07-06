import 'package:dio/dio.dart';

abstract interface class OrdersRemoteDatasource {
  Future<dynamic> getOrders();
  Future<Map<String, dynamic>> getOrderDetail(String id);
  Future<Map<String, dynamic>> submitReview({
    required String suborderId,
    required int rating,
  });
}

class OrdersRemoteDatasourceImpl implements OrdersRemoteDatasource {
  OrdersRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<dynamic> getOrders() async {
    final response = await _dio.get<dynamic>(
      '/orders/customer-orders/get_orders/',
      queryParameters: const {'page': 1},
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getOrderDetail(String id) async {
    final response = await _dio.get<dynamic>(
      '/orders/customer-orders/$id/get_suborder_details/',
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<Map<String, dynamic>> submitReview({
    required String suborderId,
    required int rating,
  }) async {
    final response = await _dio.post<dynamic>(
      '/orders/customer-orders/add_review/',
      data: FormData.fromMap({
        'suborder_id': suborderId,
        'rating': rating.toString(),
      }),
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
