import 'package:dio/dio.dart';
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
      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'Payment verification failed.';
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
