import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/repositories/rfq_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class RfqEvent {}

final class RfqListRequested extends RfqEvent {}

/// Pull-to-refresh — reloads page 1 with whatever search query is
/// currently active, without emitting [RfqLoading] first (unlike
/// [RfqListRequested]/[RfqQueryChanged]), so the existing list stays
/// visible under the pull-to-refresh indicator instead of being replaced
/// by a full-page spinner.
final class RfqListRefreshRequested extends RfqEvent {}

final class RfqQueryChanged extends RfqEvent {
  RfqQueryChanged(this.query);
  final String query;
}

final class RfqNextPageRequested extends RfqEvent {}

final class RfqDetailRequested extends RfqEvent {
  RfqDetailRequested(this.id);
  final String id;
}

final class RfqSubmitRequested extends RfqEvent {
  RfqSubmitRequested(this.payload);
  final Map<String, dynamic> payload;
}

final class RfqQuoteAcceptRequested extends RfqEvent {
  RfqQuoteAcceptRequested({
    required this.quoteId,
    required this.rfqId,
  });

  final String quoteId;
  final String rfqId;
}

final class RfqPaymentCompletedLocally extends RfqEvent {
  RfqPaymentCompletedLocally(this.quoteId);
  final String quoteId;
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
  RfqListLoaded(
    this.rfqs, {
    this.query = '',
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<RfqEntity> rfqs;
  final String query;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  RfqListLoaded copyWith({
    List<RfqEntity>? rfqs,
    String? query,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return RfqListLoaded(
      rfqs ?? this.rfqs,
      query: query ?? this.query,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
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

// ── BLoC (factory) ───────────────────────────────────────────────────────────

class RfqBloc extends Bloc<RfqEvent, RfqState> {
  RfqBloc(this._repository) : super(RfqInitial()) {
    on<RfqListRequested>(_onList);
    on<RfqListRefreshRequested>(_onRefresh);
    on<RfqQueryChanged>(_onQueryChanged);
    on<RfqNextPageRequested>(_onNextPage);
    on<RfqDetailRequested>(_onDetail);
    on<RfqSubmitRequested>(_onSubmit);
    on<RfqQuoteAcceptRequested>(_onQuoteAcceptRequested);
    on<RfqPaymentCompletedLocally>(_onPaymentCompletedLocally);
    on<CartRfqSubmitRequested>(_onCartRfqSubmit);
  }

  final RfqRepository _repository;

  Future<void> _onList(RfqListRequested event, Emitter<RfqState> emit) async {
    emit(RfqLoading());
    final (rfqs, hasMore, failure) = await _repository.getRfqList(page: 1);
    if (failure != null) {
      AppHaptics.error();
      emit(RfqError(failure.message));
    } else {
      emit(RfqListLoaded(rfqs!, page: 1, hasMore: hasMore));
    }
  }

  Future<void> _onRefresh(
    RfqListRefreshRequested event,
    Emitter<RfqState> emit,
  ) async {
    final current = state;
    final query = current is RfqListLoaded ? current.query : '';
    final (rfqs, hasMore, failure) =
        await _repository.getRfqList(page: 1, search: query);
    if (failure != null) {
      AppHaptics.error();
      // Keep whatever was already on screen — only surface the error state
      // if there was nothing showing yet.
      if (current is! RfqListLoaded) emit(RfqError(failure.message));
      return;
    }
    emit(RfqListLoaded(rfqs!, query: query, page: 1, hasMore: hasMore));
  }

  Future<void> _onQueryChanged(
    RfqQueryChanged event,
    Emitter<RfqState> emit,
  ) async {
    emit(RfqLoading());
    final (rfqs, hasMore, failure) =
        await _repository.getRfqList(page: 1, search: event.query);
    if (failure != null) {
      AppHaptics.error();
      emit(RfqError(failure.message));
    } else {
      emit(RfqListLoaded(rfqs!, query: event.query, page: 1, hasMore: hasMore));
    }
  }

  Future<void> _onNextPage(
    RfqNextPageRequested event,
    Emitter<RfqState> emit,
  ) async {
    final current = state;
    if (current is! RfqListLoaded ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    final nextPage = current.page + 1;
    final (rfqs, hasMore, failure) = await _repository.getRfqList(
      page: nextPage,
      search: current.query,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(current.copyWith(isLoadingMore: false));
    } else {
      emit(
        current.copyWith(
          rfqs: [...current.rfqs, ...rfqs!],
          page: nextPage,
          hasMore: hasMore,
          isLoadingMore: false,
        ),
      );
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

  Future<void> _onQuoteAcceptRequested(
    RfqQuoteAcceptRequested event,
    Emitter<RfqState> emit,
  ) async {
    final currentState = state;
    if (currentState case RfqDetailLoaded(:final rfq)) {
      final (success, failure) = await _repository.acceptRfqQuote(
        quoteId: event.quoteId,
        rfqId: event.rfqId,
      );
      if (failure != null || !success) {
        AppHaptics.error();
        emit(RfqError(failure?.message ?? 'Failed to accept quote.'));
        return;
      }
      final quotes = rfq.quotes
          .map((q) => q.quoteId == event.quoteId
              ? q.copyWith(quoteStatus: 'Accepted')
              : q)
          .toList();
      emit(RfqDetailLoaded(
        rfq.copyWith(status: 'Quote Accepted', quotes: quotes),
      ));
    }
  }

  void _onPaymentCompletedLocally(
    RfqPaymentCompletedLocally event,
    Emitter<RfqState> emit,
  ) {
    final currentState = state;
    if (currentState case RfqDetailLoaded(:final rfq)) {
      final quotes = rfq.quotes
          .map((q) => q.quoteId == event.quoteId
              ? q.copyWith(quoteStatus: 'Order Converted')
              : q)
          .toList();
      emit(RfqDetailLoaded(
        rfq.copyWith(status: 'Order Created', quotes: quotes),
      ));
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
}
