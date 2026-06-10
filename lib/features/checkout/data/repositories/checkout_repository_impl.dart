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
}
