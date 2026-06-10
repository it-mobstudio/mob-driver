import 'package:dio/dio.dart';

abstract interface class ProductRemoteDatasource {
  Future<Map<String, dynamic>> browseProducts({
    required String categoryName,
    int page = 1,
    bool isProfessional = true,
  });

  Future<dynamic> getFilters({
    required String search,
    bool isProfessional = true,
  });

  Future<Map<String, dynamic>> getProductDetail({
    required String slug,
    String? mobSku,
  });

  Future<dynamic> searchProducts({required String query, int page = 1});
}

class ProductRemoteDatasourceImpl implements ProductRemoteDatasource {
  ProductRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> browseProducts({
    required String categoryName,
    int page = 1,
    bool isProfessional = true,
  }) async {
    final response = await _dio.get<dynamic>(
      '/home/$categoryName/browse_products/',
      queryParameters: {'page': page, 'is_professional': isProfessional},
    );
    return _toMap(response.data);
  }

  @override
  Future<dynamic> getFilters({
    required String search,
    bool isProfessional = true,
  }) async {
    final response = await _dio.get<dynamic>(
      '/home/get_filters/',
      queryParameters: {
        'search': search,
        'quick_ecommerce': true,
        'is_professional': isProfessional,
      },
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getProductDetail({
    required String slug,
    String? mobSku,
  }) async {
    final response = await _dio.get<dynamic>(
      '/home/$slug/get_product_details/',
      queryParameters:
          (mobSku != null && mobSku.isNotEmpty) ? {'mob_sku': mobSku} : null,
    );
    return _toMap(response.data);
  }

  @override
  Future<dynamic> searchProducts({required String query, int page = 1}) async {
    final response = await _dio.get<dynamic>(
      '/home/product_search/',
      queryParameters: {'search': query, 'page': page},
    );
    return response.data;
  }

  Map<String, dynamic> _toMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
