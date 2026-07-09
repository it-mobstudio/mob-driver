import 'package:dio/dio.dart';

abstract interface class ProductRemoteDatasource {
  Future<Map<String, dynamic>> browseProducts({
    required String categorySlug,
    String? subCategory,
    int page = 1,
    bool isProfessional = true,
    String? sortBy,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  });

  Future<dynamic> getFilters({
    required String category,
    String? subCategory,
  });

  Future<dynamic> getSearchFilters({
    required String query,
    Map<String, dynamic> extraParams = const <String, dynamic>{},
  });

  Future<Map<String, dynamic>> getProductDetail({
    required String slug,
    String? mobSku,
  });

  Future<dynamic> searchProducts({required String query, int page = 1});

  Future<Map<String, dynamic>> searchCatalog({
    required String query,
    int page = 1,
    bool isProfessional = true,
    String? sortBy,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  });

  Future<Map<String, dynamic>> notifyOutOfStock({
    required int productId,
    required String phoneNumber,
  });
}

class ProductRemoteDatasourceImpl implements ProductRemoteDatasource {
  ProductRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> browseProducts({
    required String categorySlug,
    String? subCategory,
    int page = 1,
    bool isProfessional = true,
    String? sortBy,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  }) async {
    final response = await _dio.get<dynamic>(
      '/home/$categorySlug/browse_products/',
      queryParameters: <String, dynamic>{
        ...queryParameters,
        'page': page,
        'is_professional': isProfessional,
        if (sortBy != null && sortBy.trim().isNotEmpty)
          'sort_by': sortBy.trim(),
        if (subCategory != null && subCategory.trim().isNotEmpty)
          'sub_category': subCategory.trim(),
      },
    );
    return _toMap(response.data);
  }

  @override
  Future<dynamic> getFilters({
    required String category,
    String? subCategory,
  }) async {
    final response = await _dio.get<dynamic>(
      '/home/get_filters/',
      queryParameters: <String, dynamic>{
        'category': category,
        if (subCategory != null && subCategory.trim().isNotEmpty)
          'sub_category': subCategory.trim(),
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

  @override
  Future<Map<String, dynamic>> searchCatalog({
    required String query,
    int page = 1,
    bool isProfessional = true,
    String? sortBy,
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  }) async {
    final response = await _dio.get<dynamic>(
      '/home/product_search/',
      queryParameters: <String, dynamic>{
        ...queryParameters,
        'search': query,
        'page': page,
        'is_professional': isProfessional,
        if (sortBy != null && sortBy.trim().isNotEmpty)
          'sort_by': sortBy.trim(),
      },
    );
    return _toMap(response.data);
  }

  @override
  Future<dynamic> getSearchFilters({
    required String query,
    Map<String, dynamic> extraParams = const <String, dynamic>{},
  }) async {
    final response = await _dio.get<dynamic>(
      '/home/get_filters/',
      queryParameters: <String, dynamic>{
        'search': query,
        ...extraParams,
      },
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> notifyOutOfStock({
    required int productId,
    required String phoneNumber,
  }) async {
    final response = await _dio.post<dynamic>(
      '/home/notify-out-of-stock/',
      data: {
        'product': productId,
        'phone_number': phoneNumber,
      },
    );
    return _toMap(response.data);
  }

  Map<String, dynamic> _toMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
