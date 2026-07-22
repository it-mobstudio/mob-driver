import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/network/selected_city_query.dart';

abstract interface class HomeRemoteDatasource {
  Future<Map<String, dynamic>> getHomeData();
  Future<dynamic> getProductSections();
  Future<Map<String, dynamic>> getStoreOpenStatus();
}

class HomeRemoteDatasourceImpl implements HomeRemoteDatasource {
  HomeRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getHomeData() async {
    final response = await _dio.get<dynamic>(
      '/home/',
      queryParameters: await selectedCityQueryParameter(),
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  @override
  Future<dynamic> getProductSections() async {
    final response = await _dio.get<dynamic>(
      '/home/product-sections/',
      queryParameters: await selectedCityQueryParameter(),
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getStoreOpenStatus() async {
    final response = await _dio.get<dynamic>(
      '/home/store-open/',
      queryParameters: await selectedCityQueryParameter(),
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
