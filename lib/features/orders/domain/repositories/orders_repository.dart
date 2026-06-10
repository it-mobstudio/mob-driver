import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';

abstract interface class OrdersRepository {
  Future<(List<OrderEntity>?, AppFailure?)> getOrders();
  Future<(OrderEntity?, AppFailure?)> getOrderDetail(String id);
}
