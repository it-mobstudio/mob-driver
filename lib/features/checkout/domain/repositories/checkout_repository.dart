import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/entities/checkout_entity.dart';

abstract interface class CheckoutRepository {
  Future<(CheckoutSummaryEntity?, AppFailure?)> getCheckoutSummary();
  Future<AppFailure?> updateAddressToOrder(Map<String, dynamic> payload);
  Future<(PlacedOrderEntity?, AppFailure?)> placeOrder(Map<String, dynamic> payload);
  Future<(RazorpayOrderEntity?, AppFailure?)> createRazorpayOrder(int cartId);
  Future<(PlacedOrderEntity?, AppFailure?)> verifyRazorpayPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  });
  Future<(PlacedOrderEntity?, AppFailure?)> getSuborderDetails({
    required String platformOrderId,
    required String merchantPaymentRefId,
    required String paymentId,
    required String transactionId,
  });
  Future<(RupifiOrderEntity?, AppFailure?)> createRupifiOrder(String cartId);
}
