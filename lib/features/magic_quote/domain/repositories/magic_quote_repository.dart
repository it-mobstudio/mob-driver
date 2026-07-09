import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';

abstract interface class MagicQuoteRepository {
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

  /// Fetches the dynamic "submit for review" questionnaire shown before a
  /// Magic Quote is sent for manual review.
  Future<(List<Map<String, dynamic>>?, AppFailure?)> getMagicQuoteQuestions();

  /// Submits the review questionnaire answers (and free-text note) for
  /// [quoteId], moving the quote into manual review.
  Future<(bool, AppFailure?)> saveMagicQuoteReview({
    required String quoteId,
    required Map<String, dynamic> questionnaireAnswers,
    required String additionalInstructions,
  });

  /// Increases or decreases the quantity of quote item [itemId]. Returns the
  /// refreshed `{rfq_order, quote, items}` payload when the backend sends
  /// one back, or `null` if the caller should apply an optimistic local
  /// update instead.
  Future<(Map<String, dynamic>?, AppFailure?)> changeMagicQuoteItemQuantity({
    required String itemId,
    required bool increase,
  });

  /// Removes quote item [itemId]. Returns the refreshed payload, or `null`
  /// if the caller should remove the item from local state instead.
  Future<(Map<String, dynamic>?, AppFailure?)> deleteMagicQuoteItem(
    String itemId,
  );

  /// Adds [mobSku] as a new line item on quote [quoteId]. Returns the
  /// refreshed `{rfq_order, quote, items}` payload when present; otherwise
  /// [addedItem] carries just the single new line item for the caller to
  /// merge into local state.
  Future<
      (
        Map<String, dynamic>? payload,
        Map<String, dynamic>? addedItem,
        AppFailure? failure
      )> addMagicQuoteItem({
    required String quoteId,
    required String mobSku,
  });

  /// Swaps quote item [itemId] for [mobSku]. Returns the refreshed payload,
  /// or `null` if the caller should apply a local update instead.
  Future<(Map<String, dynamic>?, AppFailure?)> replaceMagicQuoteItem({
    required String itemId,
    required String mobSku,
  });
}
