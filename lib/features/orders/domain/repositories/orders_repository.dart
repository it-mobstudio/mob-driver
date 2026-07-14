import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';

abstract interface class OrdersRepository {
  Future<(List<OrderEntity>?, bool hasMore, AppFailure?)> getOrders({
    int page = 1,
    String? search,
  });
  Future<(OrderEntity?, AppFailure?)> getOrderDetail(String id);
  Future<(Map<String, dynamic>?, AppFailure?)> trackOrder(String suborderId);
  Future<AppFailure?> submitReview({
    required String suborderId,
    required int rating,
  });
}
