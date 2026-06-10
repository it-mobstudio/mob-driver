import 'package:dio/dio.dart';

abstract interface class HomeRemoteDatasource {
  Future<Map<String, dynamic>> getHomeData();
  Future<dynamic> getProductSections();
}

class HomeRemoteDatasourceImpl implements HomeRemoteDatasource {
  HomeRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getHomeData() async {
    final response = await _dio.get<dynamic>('/home/');
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<dynamic> getProductSections() async {
    final response = await _dio.get<dynamic>('/home/product-sections/');
    return response.data;
  }
}
