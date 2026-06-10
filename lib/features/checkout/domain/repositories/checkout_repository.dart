import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/entities/checkout_entity.dart';

abstract interface class CheckoutRepository {
  Future<(CheckoutSummaryEntity?, AppFailure?)> getCheckoutSummary();
  Future<(PlacedOrderEntity?, AppFailure?)> placeOrder(Map<String, dynamic> payload);
}
