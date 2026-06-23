import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/repositories/rfq_repository.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/utils/magic_quote_status.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class RfqEvent {}

final class RfqListRequested extends RfqEvent {}

final class RfqDetailRequested extends RfqEvent {
  RfqDetailRequested(this.id);
  final String id;
}

final class RfqSubmitRequested extends RfqEvent {
  RfqSubmitRequested(this.payload);
  final Map<String, dynamic> payload;
}

final class RfqQuoteAcceptedLocally extends RfqEvent {}

final class RfqPaymentCompletedLocally extends RfqEvent {}

final class MagicQuoteSubmitRequested extends RfqEvent {
  MagicQuoteSubmitRequested({
    required this.payload,
    required this.images,
  });

  final Map<String, dynamic> payload;
  final List<FFUploadedFile> images;
}

final class CartRfqSubmitRequested extends RfqEvent {
  CartRfqSubmitRequested(this.payload);
  final Map<String, dynamic> payload;
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class RfqState {}

final class RfqInitial extends RfqState {}

final class RfqLoading extends RfqState {}

final class RfqListLoaded extends RfqState {
  RfqListLoaded(this.rfqs);
  final List<RfqEntity> rfqs;
}

final class RfqDetailLoaded extends RfqState {
  RfqDetailLoaded(this.rfq);
  final RfqEntity rfq;
}

final class RfqSubmitted extends RfqState {}

final class RfqError extends RfqState {
  RfqError(this.message);
  final String message;
}

final class CartRfqSubmitting extends RfqState {}

final class CartRfqSubmitted extends RfqState {
  CartRfqSubmitted(this.rfqId);
  final String rfqId;
}

final class CartRfqError extends RfqState {
  CartRfqError(this.message);
  final String message;
}

final class MagicQuoteSubmitting extends RfqState {}

final class MagicQuoteProgress extends RfqState {
  MagicQuoteProgress({required this.status, required this.steps});
  final String status;
  final List<String> steps;
}

final class MagicQuoteSubmitted extends RfqState {
  MagicQuoteSubmitted(this.response);
  final Map<String, dynamic> response;
}

final class MagicQuoteError extends RfqState {
  MagicQuoteError(this.message);
  final String message;
}

// ── BLoC (factory) ───────────────────────────────────────────────────────────

class RfqBloc extends Bloc<RfqEvent, RfqState> {
  RfqBloc(this._repository) : super(RfqInitial()) {
    on<RfqListRequested>(_onList);
    on<RfqDetailRequested>(_onDetail);
    on<RfqSubmitRequested>(_onSubmit);
    on<RfqQuoteAcceptedLocally>(_onQuoteAcceptedLocally);
    on<RfqPaymentCompletedLocally>(_onPaymentCompletedLocally);
    on<MagicQuoteSubmitRequested>(_onMagicQuoteSubmit);
    on<CartRfqSubmitRequested>(_onCartRfqSubmit);
  }

  final RfqRepository _repository;

  Future<void> _onList(RfqListRequested event, Emitter<RfqState> emit) async {
    emit(RfqLoading());
    final (rfqs, failure) = await _repository.getRfqList();
    if (failure != null) {
      AppHaptics.error();
      emit(RfqError(failure.message));
    } else {
      emit(RfqListLoaded(rfqs!));
    }
  }

  Future<void> _onDetail(
      RfqDetailRequested event, Emitter<RfqState> emit) async {
    emit(RfqLoading());
    final (rfq, failure) = await _repository.getRfqDetail(event.id);
    if (failure != null) {
      AppHaptics.error();
      emit(RfqError(failure.message));
    } else {
      emit(RfqDetailLoaded(rfq!));
    }
  }

  Future<void> _onSubmit(
      RfqSubmitRequested event, Emitter<RfqState> emit) async {
    emit(RfqLoading());
    final (success, failure) = await _repository.submitRfq(event.payload);
    if (failure != null) {
      AppHaptics.error();
      emit(RfqError(failure.message));
    } else if (success) {
      emit(RfqSubmitted());
    } else {
      AppHaptics.error();
      emit(RfqError('RFQ submission failed.'));
    }
  }

  void _onQuoteAcceptedLocally(
    RfqQuoteAcceptedLocally event,
    Emitter<RfqState> emit,
  ) {
    final currentState = state;
    if (currentState case RfqDetailLoaded(:final rfq)) {
      emit(RfqDetailLoaded(rfq.copyWith(status: 'quote_accepted')));
    }
  }

  void _onPaymentCompletedLocally(
    RfqPaymentCompletedLocally event,
    Emitter<RfqState> emit,
  ) {
    final currentState = state;
    if (currentState case RfqDetailLoaded(:final rfq)) {
      emit(RfqDetailLoaded(rfq.copyWith(status: 'converted_to_order')));
    }
  }

  Future<void> _onCartRfqSubmit(
    CartRfqSubmitRequested event,
    Emitter<RfqState> emit,
  ) async {
    emit(CartRfqSubmitting());
    final (rfqId, failure) =
        await _repository.createCartQuoteRequest(event.payload);
    if (failure != null) {
      AppHaptics.error();
      emit(CartRfqError(failure.message));
    } else {
      emit(CartRfqSubmitted(rfqId ?? ''));
    }
  }

  Future<void> _onMagicQuoteSubmit(
    MagicQuoteSubmitRequested event,
    Emitter<RfqState> emit,
  ) async {
    emit(MagicQuoteSubmitting());
    final (response, failure) = await _repository.submitMagicQuote(
      payload: event.payload,
      images: event.images,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(MagicQuoteError(failure.message));
      return;
    }

    final accepted = response ?? const <String, dynamic>{};
    if (magicQuoteHasGeneratedItems(accepted)) {
      emit(MagicQuoteSubmitted(accepted));
      return;
    }

    final steps = <String>[];
    final initialStatus = magicQuoteStatusOf(accepted);
    if (initialStatus.isNotEmpty) steps.add(initialStatus);
    emit(MagicQuoteProgress(
      status: initialStatus.isEmpty ? 'Uploaded' : initialStatus,
      steps: List.of(steps),
    ));

    await emit.forEach<Map<String, dynamic>>(
      _repository.watchMagicQuoteStatus(
        acceptedResponse: accepted,
        phoneNumber: event.payload['phone']?.toString() ?? '',
      ),
      onData: (message) {
        final status = magicQuoteStatusOf(message);
        if (status.isNotEmpty && !steps.contains(status)) steps.add(status);
        if (magicQuoteIsProcessingOf(message) == false) {
          return MagicQuoteSubmitted(message);
        }
        return MagicQuoteProgress(
          status: status.isEmpty
              ? (steps.isEmpty ? 'Processing' : steps.last)
              : status,
          steps: List.of(steps),
        );
      },
      onError: (error, _) {
        AppHaptics.error();
        return MagicQuoteError(
          error is StateError
              ? error.message
              : 'Magic Quote updates failed.',
        );
      },
    );
  }
}
