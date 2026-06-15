import 'package:dio/dio.dart';

abstract interface class CartRemoteDatasource {
  Future<Map<String, dynamic>> getCart({bool outOfStock = false});
  Future<Map<String, dynamic>> addToCart({
    required String vendorProductId,
    required int quantity,
  });
  Future<Map<String, dynamic>> removeFromCart({
    required String cartItemId,
    String? vendorProductId,
  });
  Future<Map<String, dynamic>> updateCartRedeem(Map<String, dynamic> payload);
}

class CartRemoteDatasourceImpl implements CartRemoteDatasource {
  CartRemoteDatasourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getCart({bool outOfStock = false}) async {
    final response = await _dio.get<dynamic>(
      '/orders/cart/get_cart/',
      queryParameters: {
        'userDetails': true,
        if (outOfStock) 'out_of_stock': true,
      },
    );
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> addToCart({
    required String vendorProductId,
    required int quantity,
  }) async {
    final response = await _dio.post<dynamic>(
      '/orders/cart/add_to_cart/',
      data: {
        'items': [
          {'product': vendorProductId, 'quantity': quantity},
        ],
      },
    );
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> removeFromCart({
    required String cartItemId,
    String? vendorProductId,
  }) async {
    final response = await _dio.post<dynamic>(
      '/orders/cart/remove_cart_item/',
      data: {
        'cart_item_id': int.tryParse(cartItemId) ?? cartItemId,
        'quantity': 0,
      },
    );
    return _extractData(response.data);
  }

  @override
  Future<Map<String, dynamic>> updateCartRedeem(Map<String, dynamic> payload) async {
    final response = await _dio.put<dynamic>(
      '/orders/cart/update_cart/',
      data: payload,
      queryParameters: {'userDetails': true},
    );
    return _extractData(response.data);
  }

  Map<String, dynamic> _extractData(dynamic raw) {
    if (raw is Map) {
      final body = Map<String, dynamic>.from(raw);
      if (body['data'] is Map) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
      return body;
    }
    return {};
  }
}
