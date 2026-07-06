import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/orders/data/datasources/orders_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this._datasource);

  final OrdersRemoteDatasource _datasource;

  @override
  Future<(List<OrderEntity>?, bool, AppFailure?)> getOrders({
    int page = 1,
    String? search,
  }) async {
    try {
      final raw = await _datasource.getOrders(page: page, search: search);
      final list = _extractList(raw);
      final orders = list
          .whereType<Map>()
          .map((e) => OrderEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      return (orders, _hasMore(raw, orders.length, page), null);
    } on DioException catch (e) {
      return (null, false, e.toAppFailure());
    } catch (e) {
      return (null, false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(OrderEntity?, AppFailure?)> getOrderDetail(String id) async {
    try {
      final body = await _datasource.getOrderDetail(id);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      return (OrderEntity.fromMap(data), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AppFailure?> submitReview({
    required String suborderId,
    required int rating,
  }) async {
    try {
      final body = await _datasource.submitReview(
        suborderId: suborderId,
        rating: rating,
      );
      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'Failed to submit review.';
        return BusinessFailure(msg);
      }
      return null;
    } on DioException catch (e) {
      return e.toAppFailure();
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }

  static const _pageSize = 20;

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final body = Map<String, dynamic>.from(raw);
      final data = body['data'];
      if (data is List) return data;
      if (data is Map) {
        final results = (data)['results'];
        if (results is List) return results;
      }
      final results = body['results'];
      if (results is List) return results;
    }
    return const [];
  }

  Map<String, dynamic> _extractPagination(dynamic raw) {
    if (raw is Map) {
      final body = Map<String, dynamic>.from(raw);
      final data = body['data'];
      if (data is Map) {
        final pagination = Map<String, dynamic>.from(data)['pagination'];
        if (pagination is Map) return Map<String, dynamic>.from(pagination);
      }
      final pagination = body['pagination'];
      if (pagination is Map) return Map<String, dynamic>.from(pagination);
    }
    return const {};
  }

  bool _hasMore(dynamic raw, int loadedCount, int page) {
    final pagination = _extractPagination(raw);
    if (pagination.containsKey('is_next_page')) {
      return pagination['is_next_page'] == true;
    }
    final totalEntries =
        int.tryParse((pagination['total_entries'] ?? '').toString());
    if (totalEntries != null) {
      return page * _pageSize < totalEntries;
    }
    return loadedCount >= _pageSize;
  }
}
