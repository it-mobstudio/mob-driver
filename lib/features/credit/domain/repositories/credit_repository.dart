import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/credit/domain/entities/business_segment_entity.dart';
import 'package:m_o_b_demand_side/features/credit/domain/entities/credit_transaction_entity.dart';

abstract interface class CreditRepository {
  Future<(List<BusinessSegmentEntity>?, AppFailure?)> getBusinessSegments();

  Future<(bool, AppFailure?)> requestLineOfCredit({
    required String businessName,
    required String gst,
    required String phoneNumber,
    required String businessSegment,
  });

  Future<(List<CreditTransactionEntity>?, AppFailure?)> getCreditHistory();
}
