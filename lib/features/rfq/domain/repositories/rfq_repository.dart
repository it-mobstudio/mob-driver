import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';

abstract interface class RfqRepository {
  Future<(List<RfqEntity>?, AppFailure?)> getRfqList();
  Future<(RfqEntity?, AppFailure?)> getRfqDetail(String id);
  Future<(bool, AppFailure?)> submitRfq(Map<String, dynamic> payload);

  /// Creates a quote request from the items currently in the cart.
  Future<(String?, AppFailure?)> createCartQuoteRequest(
    Map<String, dynamic> payload,
  );
  Future<(Map<String, dynamic>?, AppFailure?)> submitMagicQuote({
    required Map<String, dynamic> payload,
    required List<FFUploadedFile> images,
  });

  /// Streams `magic_quote_status` updates following up on [acceptedResponse]
  /// (the response from [submitMagicQuote]) until the backend finishes
  /// processing.
  Stream<Map<String, dynamic>> watchMagicQuoteStatus({
    required Map<String, dynamic> acceptedResponse,
    required String phoneNumber,
  });
}
