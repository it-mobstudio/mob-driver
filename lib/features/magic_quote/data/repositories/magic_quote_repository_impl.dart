import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/magic_quote/data/datasources/magic_quote_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/magic_quote/domain/repositories/magic_quote_repository.dart';
import 'package:m_o_b_demand_side/features/magic_quote/domain/utils/magic_quote_status.dart';

class MagicQuoteRepositoryImpl implements MagicQuoteRepository {
  MagicQuoteRepositoryImpl(this._datasource);

  final MagicQuoteRemoteDatasource _datasource;

  @override
  Future<(Map<String, dynamic>?, AppFailure?)> submitMagicQuote({
    required Map<String, dynamic> payload,
    required List<FFUploadedFile> images,
  }) async {
    try {
      final body = await _datasource.submitMagicQuote(
        payload: payload,
        images: images,
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

  @override
  Stream<Map<String, dynamic>> watchMagicQuoteStatus({
    required Map<String, dynamic> acceptedResponse,
    required String phoneNumber,
  }) {
    return _datasource.watchMagicQuoteStatus(
      acceptedResponse: acceptedResponse,
      phoneNumber: phoneNumber,
    );
  }

  @override
  Future<(List<Map<String, dynamic>>?, AppFailure?)>
      getMagicQuoteQuestions() async {
    try {
      final body = await _datasource.getMagicQuoteQuestions();
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      final questions = data['questions'];
      if (questions is List) {
        return (
          questions
              .whereType<Map>()
              .map((q) => Map<String, dynamic>.from(q))
              .toList(),
          null,
        );
      }
      return (const <Map<String, dynamic>>[], null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, AppFailure?)> saveMagicQuoteReview({
    required String quoteId,
    required Map<String, dynamic> questionnaireAnswers,
    required String additionalInstructions,
  }) async {
    try {
      final body = await _datasource.patchMagicQuote({
        'quote_id': quoteId,
        'action': 'save',
        'questionnaire_answers': questionnaireAnswers,
        'additional_instructions': additionalInstructions,
      });
      if (body['status'] == false) {
        final message = body['message']?.toString() ??
            'Failed to submit quote for review.';
        return (false, BusinessFailure(message));
      }
      return (true, null);
    } on DioException catch (e) {
      return (false, e.toAppFailure());
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(Map<String, dynamic>?, AppFailure?)> changeMagicQuoteItemQuantity({
    required String itemId,
    required bool increase,
  }) async {
    try {
      final body = await _datasource.patchMagicQuote({
        'id': itemId,
        'action': increase ? 'increase' : 'decrease',
      });
      if (body['status'] == false) {
        final message = body['message']?.toString() ??
            'Failed to update quantity.';
        return (null, BusinessFailure(message));
      }
      return (magicQuoteUpdatedPayloadOrNull(body), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(Map<String, dynamic>?, AppFailure?)> replaceMagicQuoteItem({
    required String itemId,
    required String mobSku,
  }) async {
    try {
      final body = await _datasource.patchMagicQuote({
        'id': itemId,
        'mob_sku': mobSku,
      });
      if (body['status'] == false) {
        final message = body['message']?.toString() ??
            'Failed to replace product.';
        return (null, BusinessFailure(message));
      }
      return (magicQuoteUpdatedPayloadOrNull(body), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(Map<String, dynamic>?, AppFailure?)> deleteMagicQuoteItem(
    String itemId,
  ) async {
    try {
      final body = await _datasource.deleteMagicQuoteItem({'id': itemId});
      if (body['status'] == false) {
        final message =
            body['message']?.toString() ?? 'Failed to remove item.';
        return (null, BusinessFailure(message));
      }
      return (magicQuoteUpdatedPayloadOrNull(body), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(Map<String, dynamic>?, Map<String, dynamic>?, AppFailure?)>
      addMagicQuoteItem({
    required String quoteId,
    required String mobSku,
  }) async {
    try {
      final body = await _datasource.addMagicQuoteItem({
        'quote_id': quoteId,
        'action': 'add',
        'mob_sku': mobSku,
      });
      if (body['status'] == false) {
        final message =
            body['message']?.toString() ?? 'Failed to add product.';
        return (null, null, BusinessFailure(message));
      }
      final payload = magicQuoteUpdatedPayloadOrNull(body);
      if (payload != null) return (payload, null, null);

      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : null;
      final nestedData = data?['data'] is Map
          ? Map<String, dynamic>.from(data!['data'] as Map)
          : null;
      final addedItem = nestedData?['item'] ?? data?['item'] ?? body['item'];
      return (
        null,
        addedItem is Map ? Map<String, dynamic>.from(addedItem) : null,
        null,
      );
    } on DioException catch (e) {
      return (null, null, e.toAppFailure());
    } catch (e) {
      return (null, null, UnknownFailure(e.toString()));
    }
  }
}
