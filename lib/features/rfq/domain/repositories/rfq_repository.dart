import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';

abstract interface class RfqRepository {
  Future<(List<RfqEntity>?, bool hasMore, AppFailure?)> getRfqList({
    int page = 1,
    String? search,
  });
  Future<(RfqEntity?, AppFailure?)> getRfqDetail(String id);
  Future<(bool, AppFailure?)> submitRfq(Map<String, dynamic> payload);
  Future<(bool, AppFailure?)> acceptRfqQuote({
    required String quoteId,
    required String rfqId,
  });

  /// Creates a quote request from the items currently in the cart.
  Future<(String?, AppFailure?)> createCartQuoteRequest(
    Map<String, dynamic> payload,
  );
}
