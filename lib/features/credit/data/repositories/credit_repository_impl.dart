import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/credit/data/datasources/credit_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/credit/domain/entities/business_segment_entity.dart';
import 'package:m_o_b_demand_side/features/credit/domain/entities/credit_transaction_entity.dart';
import 'package:m_o_b_demand_side/features/credit/domain/repositories/credit_repository.dart';

class CreditRepositoryImpl implements CreditRepository {
  CreditRepositoryImpl(this._datasource);

  final CreditRemoteDatasource _datasource;

  @override
  Future<(List<BusinessSegmentEntity>?, AppFailure?)>
      getBusinessSegments() async {
    try {
      final raw = await _datasource.getBusinessSegments();
      final list = _extractList(raw);
      final segments = list
          .whereType<Map>()
          .map((e) =>
              BusinessSegmentEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      return (segments, null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, AppFailure?)> requestLineOfCredit({
    required String businessName,
    required String gst,
    required String phoneNumber,
    required String businessSegment,
  }) async {
    try {
      await _datasource.requestLineOfCredit({
        'business_name': businessName,
        'gst': gst,
        'phone_number': int.tryParse(phoneNumber) ?? phoneNumber,
        'business_segment': businessSegment,
      });
      return (true, null);
    } on DioException catch (e) {
      return (false, e.toAppFailure());
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<CreditTransactionEntity>?, AppFailure?)>
      getCreditHistory() async {
    try {
      final raw = await _datasource.getCreditHistory();
      final list = _extractList(raw);
      final transactions = list
          .whereType<Map>()
          .map((e) =>
              CreditTransactionEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      return (transactions, null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

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
}
