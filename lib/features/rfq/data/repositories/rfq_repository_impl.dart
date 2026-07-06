import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/rfq/data/datasources/rfq_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/repositories/rfq_repository.dart';

class RfqRepositoryImpl implements RfqRepository {
  RfqRepositoryImpl(this._datasource);

  final RfqRemoteDatasource _datasource;

  static const _pageSize = 20;

  @override
  Future<(List<RfqEntity>?, bool, AppFailure?)> getRfqList({
    int page = 1,
    String? search,
  }) async {
    try {
      final raw = await _datasource.getRfqList(page: page, search: search);
      final list = _extractList(raw);
      final rfqs = list
          .whereType<Map>()
          .map((e) => RfqEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      return (rfqs, _hasMore(raw, rfqs.length, page), null);
    } on DioException catch (e) {
      return (null, false, e.toAppFailure());
    } catch (e) {
      return (null, false, UnknownFailure(e.toString()));
    }
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is! Map) return <dynamic>[];

    for (final key in ['data', 'results', 'rfqs', 'quotes']) {
      final value = raw[key];
      if (value is List) return value;
      if (value is Map) {
        final nested = _extractList(value);
        if (nested.isNotEmpty) return nested;
      }
    }

    return <dynamic>[];
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

  @override
  Future<(RfqEntity?, AppFailure?)> getRfqDetail(String id) async {
    try {
      final body = await _datasource.getRfqDetail(id);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      return (RfqEntity.fromMap(data), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, AppFailure?)> submitRfq(Map<String, dynamic> payload) async {
    try {
      final body = await _datasource.submitRfq(payload);
      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'RFQ submission failed.';
        return (false, BusinessFailure(msg));
      }
      return (true, null);
    } on DioException catch (e) {
      return (false, e.toAppFailure());
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(String?, AppFailure?)> createCartQuoteRequest(
    Map<String, dynamic> payload,
  ) async {
    try {
      final body = await _datasource.createCartQuoteRequest(payload);
      if (body['status'] == false) {
        final msg = body['message']?.toString() ??
            'Failed to create quote request.';
        return (null, BusinessFailure(msg));
      }
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      return (data['rfq_id']?.toString() ?? '', null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
