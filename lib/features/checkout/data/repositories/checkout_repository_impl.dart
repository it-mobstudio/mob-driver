import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/checkout/data/datasources/checkout_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/entities/checkout_entity.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/repositories/checkout_repository.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  CheckoutRepositoryImpl(this._datasource);

  final CheckoutRemoteDatasource _datasource;

  @override
  Future<(CheckoutSummaryEntity?, AppFailure?)> getCheckoutSummary() async {
    try {
      final body = await _datasource.getCheckoutSummary();
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      return (CheckoutSummaryEntity.fromMap(data), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppFailure?> updateAddressToOrder(Map<String, dynamic> payload) async {
    try {
      final body = await _datasource.updateAddressToOrder(payload);
      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'Failed to update address.';
        return BusinessFailure(msg);
      }
      return null;
    } on DioException catch (e) {
      return e.toAppFailure();
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }

  @override
  Future<(PlacedOrderEntity?, AppFailure?)> placeOrder(
      Map<String, dynamic> payload) async {
    try {
      final body = await _datasource.placeOrder(payload);
      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'Failed to place order.';
        return (null, BusinessFailure(msg));
      }
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      return (PlacedOrderEntity.fromMap(data), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(PlacedOrderEntity?, AppFailure?)> verifyRazorpayPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      final body = await _datasource.verifyRazorpayPayment(
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
      );
      debugPrint('🔵 RAZORPAY VERIFY RESPONSE: $body');
      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'Payment verification failed.';
        debugPrint('🔴 RAZORPAY VERIFY FAILED: $msg');
        return (null, BusinessFailure(msg));
      }
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      debugPrint('🟢 RAZORPAY VERIFY DATA: $data');
      final entity = PlacedOrderEntity.fromMap(data);
      debugPrint('🟢 RAZORPAY ORDER ID: ${entity.orderId}');
      return (entity, null);
    } on DioException catch (e) {
      debugPrint('🔴 RAZORPAY VERIFY DIO ERROR: ${e.response?.statusCode} ${e.response?.data}');
      return (null, e.toAppFailure());
    } catch (e) {
      debugPrint('🔴 RAZORPAY VERIFY EXCEPTION: $e');
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(PlacedOrderEntity?, AppFailure?)> getSuborderDetails({
    required String platformOrderId,
    String paymentGateway = '',
    String merchantPaymentRefId = '',
    String paymentId = '',
    String transactionId = '',
  }) async {
    try {
      debugPrint('🔵 SUBORDER DETAILS REQUEST: platformOrderId=$platformOrderId merchantPaymentRefId=$merchantPaymentRefId paymentId=$paymentId');
      final body = await _datasource.getSuborderDetails(
        platformOrderId: platformOrderId,
        paymentGateway: paymentGateway,
        merchantPaymentRefId: merchantPaymentRefId,
        paymentId: paymentId,
        transactionId: transactionId,
        // currency/paymentFor only make sense alongside an actual payment
        // gateway (Razorpay flow) — omitted for wallet/direct-order success.
        currency: paymentGateway.isNotEmpty ? 'INR' : '',
        paymentFor: paymentGateway.isNotEmpty ? 'CART' : '',
      );
      debugPrint('🔵 SUBORDER DETAILS RESPONSE: $body');
      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'Payment verification failed.';
        debugPrint('🔴 SUBORDER DETAILS FAILED: $msg');
        return (null, BusinessFailure(msg));
      }
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      debugPrint('🟢 SUBORDER DATA: $data');
      return (PlacedOrderEntity.fromMap(data), null);
    } on DioException catch (e) {
      debugPrint('🔴 SUBORDER DETAILS DIO ERROR: ${e.response?.statusCode} ${e.response?.data}');
      return (null, e.toAppFailure());
    } catch (e) {
      debugPrint('🔴 SUBORDER DETAILS EXCEPTION: $e');
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(RupifiOrderEntity?, AppFailure?)> createRupifiOrder(
    String cartId, {
    String? paymentOrigin,
  }) async {
    try {
      final body = await _datasource.createRupifiOrder(
        cartId,
        paymentOrigin: paymentOrigin,
      );
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      final response = data['response'] is Map
          ? Map<String, dynamic>.from(data['response'] as Map)
          : const <String, dynamic>{};
      final responseData = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : const <String, dynamic>{};
      final paymentUrl = _firstNonEmpty([
        body['payment_url'],
        data['payment_url'],
        data['paymentUrl'],
        response['payment_url'],
        response['paymentUrl'],
        responseData['payment_url'],
        responseData['paymentUrl'],
      ]);
      if (paymentUrl.isEmpty) {
        final msg = body['message']?.toString() ?? 'Failed to create mobCREDIT order.';
        return (null, BusinessFailure(msg));
      }
      return (RupifiOrderEntity(paymentUrl: paymentUrl), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  @override
  Future<(RazorpayOrderEntity?, AppFailure?)> createRazorpayOrder(int cartId) async {
    try {
      final body = await _datasource.createRazorpayOrder(cartId);
      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'Failed to create Razorpay order.';
        return (null, BusinessFailure(msg));
      }
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      return (RazorpayOrderEntity.fromMap(data), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
