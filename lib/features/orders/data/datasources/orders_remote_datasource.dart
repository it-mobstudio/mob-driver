import 'package:dio/dio.dart';

abstract interface class OrdersRemoteDatasource {
  Future<dynamic> getOrders({int page = 1, String? search});
  Future<Map<String, dynamic>> getOrderDetail(String id);
  Future<Map<String, dynamic>> trackOrder(String suborderId);
  Future<Map<String, dynamic>> submitReview({
    required String suborderId,
    required int rating,
  });
}

class OrdersRemoteDatasourceImpl implements OrdersRemoteDatasource {
  OrdersRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<dynamic> getOrders({int page = 1, String? search}) async {
    final response = await _dio.get<dynamic>(
      '/orders/customer-orders/get_orders/',
      queryParameters: {
        'page': page,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
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
  Future<Map<String, dynamic>> trackOrder(String suborderId) async {
    final response = await _dio.get<dynamic>(
      '/orders/customer-orders/$suborderId/track_order/',
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
