import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/rfq/data/datasources/rfq_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/repositories/rfq_repository.dart';

class RfqRepositoryImpl implements RfqRepository {
  RfqRepositoryImpl(this._datasource);

  final RfqRemoteDatasource _datasource;

  @override
  Future<(List<RfqEntity>?, AppFailure?)> getRfqList() async {
    try {
      final raw = await _datasource.getRfqList();
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map) {
        final data = raw['data'];
        list = data is List ? data : <dynamic>[];
      } else {
        list = <dynamic>[];
      }
      final rfqs = list
          .whereType<Map>()
          .map((e) => RfqEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      return (rfqs, null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
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
  Future<(Map<String, dynamic>?, AppFailure?)> submitMagicQuote({
    required Map<String, dynamic> payload,
    required FFUploadedFile image,
  }) async {
    try {
      final body = await _datasource.submitMagicQuote(
        payload: payload,
        image: image,
      );
      if (body['status'] == false) {
        final message =
            body['message']?.toString() ?? 'Magic Quote submission failed.';
        return (null, BusinessFailure(message));
      }
      return (body, null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
