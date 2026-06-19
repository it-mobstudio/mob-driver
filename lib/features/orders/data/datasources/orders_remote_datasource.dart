import 'package:dio/dio.dart';

abstract interface class OrdersRemoteDatasource {
  Future<dynamic> getOrders();
  Future<Map<String, dynamic>> getOrderDetail(String id);
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
}
