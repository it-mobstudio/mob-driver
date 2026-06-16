import 'package:dio/dio.dart';

abstract interface class CheckoutRemoteDatasource {
  Future<Map<String, dynamic>> getCheckoutSummary();
  Future<Map<String, dynamic>> updateAddressToOrder(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> createRazorpayOrder(int cartId);
  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    String paymentFor,
  });
  Future<Map<String, dynamic>> getSuborderDetails({
    required String platformOrderId,
    required String merchantPaymentRefId,
    required String paymentId,
    required String transactionId,
    String currency,
    String paymentFor,
  });
  Future<Map<String, dynamic>> createRupifiOrder(String cartId);
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
  Future<Map<String, dynamic>> updateAddressToOrder(Map<String, dynamic> payload) async {
    final response = await _dio.patch<dynamic>(
      '/orders/cart/update_address_to_order/',
      data: payload,
    );
    return _toMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> payload) async {
    final response = await _dio.post<dynamic>('/checkout/place-order/', data: payload);
    return _toMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> createRazorpayOrder(int cartId) async {
    final response = await _dio.post<dynamic>(
      '/order/razorpay_order/',
      data: {'cart_id': cartId},
    );
    return _toMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    String paymentFor = 'CART',
  }) async {
    final response = await _dio.get<dynamic>(
      '/order/razorpay_order/',
      queryParameters: {
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': orderId,
        'razorpay_signature': signature,
        'payment_Gateway': 'RAZORPAY',
        'payment_for': paymentFor,
      },
    );
    return _toMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> getSuborderDetails({
    required String platformOrderId,
    required String merchantPaymentRefId,
    required String paymentId,
    required String transactionId,
    String currency = 'INR',
    String paymentFor = 'CART',
  }) async {
    final response = await _dio.get<dynamic>(
      '/orders/customer-orders/$platformOrderId/get_suborder_details/',
      queryParameters: {
        'payment_Gateway': 'RAZORPAY',
        'merchantPaymentRefId': merchantPaymentRefId,
        'paymentId': paymentId,
        'transactionId': transactionId,
        'currency': currency,
        'paymentFor': paymentFor,
        'userDetails': 'true',
      },
    );
    return _toMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> createRupifiOrder(String cartId) async {
    final response = await _dio.post<dynamic>(
      '/order/rupifi_order/',
      data: {'cart_id': cartId},
    );
    return _toMap(response.data);
  }

  Map<String, dynamic> _toMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}
