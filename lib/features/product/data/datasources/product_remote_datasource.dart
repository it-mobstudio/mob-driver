import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/network/selected_city_query.dart';

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
    Map<String, String> variantSelections = const <String, String>{},
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
    final cityQuery = await selectedCityQueryParameter();
    final response = await _dio.get<dynamic>(
      '/home/$categorySlug/browse_products/',
      queryParameters: <String, dynamic>{
        ...queryParameters,
        ...cityQuery,
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
    final cityQuery = await selectedCityQueryParameter();
    final response = await _dio.get<dynamic>(
      '/home/get_filters/',
      queryParameters: <String, dynamic>{
        ...cityQuery,
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
    Map<String, String> variantSelections = const <String, String>{},
  }) async {
    final selectedEntries = variantSelections.entries
        .where((entry) => entry.key.trim().isNotEmpty && entry.value.isNotEmpty)
        .toList();
    final cityQuery = await selectedCityQueryParameter();
    final city = cityQuery['city']?.toString().trim() ?? '';
    final response = await _dio.get<dynamic>(
      '/home/$slug/get_product_details/',
      queryParameters: <String, dynamic>{
        if (city.isNotEmpty) 'cities': city,
        if (selectedEntries.isNotEmpty)
          'variant_type': selectedEntries.map((entry) => entry.key).join(','),
        for (final entry in selectedEntries) entry.key: entry.value,
        if (mobSku != null && mobSku.isNotEmpty) 'mob_sku': mobSku,
      },
    );
    return _toMap(response.data);
  }

  @override
  Future<dynamic> searchProducts({required String query, int page = 1}) async {
    final cityQuery = await selectedCityQueryParameter();
    final response = await _dio.get<dynamic>(
      '/home/product_search/',
      queryParameters: {
        ...cityQuery,
        'search': query,
        'page': page,
      },
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
    final cityQuery = await selectedCityQueryParameter();
    final response = await _dio.get<dynamic>(
      '/home/product_search/',
      queryParameters: <String, dynamic>{
        ...queryParameters,
        ...cityQuery,
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
    final cityQuery = await selectedCityQueryParameter();
    final response = await _dio.get<dynamic>(
      '/home/get_filters/',
      queryParameters: <String, dynamic>{
        ...extraParams,
        ...cityQuery,
        'search': query,
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
