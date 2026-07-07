import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/credit/domain/entities/business_segment_entity.dart';
import 'package:m_o_b_demand_side/features/credit/domain/entities/credit_transaction_entity.dart';
import 'package:m_o_b_demand_side/features/credit/domain/repositories/credit_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class CreditEvent {}

final class CreditSegmentsRequested extends CreditEvent {}

final class CreditHistoryRequested extends CreditEvent {}

final class CreditApplyRequested extends CreditEvent {
  CreditApplyRequested({
    required this.businessName,
    required this.gst,
    required this.phoneNumber,
    required this.businessSegment,
  });

  final String businessName;
  final String gst;
  final String phoneNumber;
  final String businessSegment;
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class CreditState {}

final class CreditInitial extends CreditState {}

final class CreditSegmentsLoading extends CreditState {}

final class CreditSegmentsLoaded extends CreditState {
  CreditSegmentsLoaded(this.segments);
  final List<BusinessSegmentEntity> segments;
}

final class CreditSegmentsError extends CreditState {
  CreditSegmentsError(this.message);
  final String message;
}

final class CreditApplySubmitting extends CreditState {}

final class CreditApplySubmitted extends CreditState {}

final class CreditApplyError extends CreditState {
  CreditApplyError(this.message);
  final String message;
}

final class CreditHistoryLoading extends CreditState {}

final class CreditHistoryLoaded extends CreditState {
  CreditHistoryLoaded(this.transactions);
  final List<CreditTransactionEntity> transactions;
}

final class CreditHistoryError extends CreditState {
  CreditHistoryError(this.message);
  final String message;
}

// ── BLoC (factory) ───────────────────────────────────────────────────────────

class CreditBloc extends Bloc<CreditEvent, CreditState> {
  CreditBloc(this._repository) : super(CreditInitial()) {
    on<CreditSegmentsRequested>(_onSegments);
    on<CreditApplyRequested>(_onApply);
    on<CreditHistoryRequested>(_onHistory);
  }

  final CreditRepository _repository;

  Future<void> _onSegments(
    CreditSegmentsRequested event,
    Emitter<CreditState> emit,
  ) async {
    emit(CreditSegmentsLoading());
    final (segments, failure) = await _repository.getBusinessSegments();
    if (failure != null) {
      emit(CreditSegmentsError(failure.message));
    } else {
      emit(CreditSegmentsLoaded(segments!));
    }
  }

  Future<void> _onApply(
    CreditApplyRequested event,
    Emitter<CreditState> emit,
  ) async {
    emit(CreditApplySubmitting());
    final (success, failure) = await _repository.requestLineOfCredit(
      businessName: event.businessName,
      gst: event.gst,
      phoneNumber: event.phoneNumber,
      businessSegment: event.businessSegment,
    );
    if (failure != null || !success) {
      AppHaptics.error();
      emit(CreditApplyError(failure?.message ?? 'Failed to submit your request.'));
    } else {
      AppHaptics.success();
      emit(CreditApplySubmitted());
    }
  }

  Future<void> _onHistory(
    CreditHistoryRequested event,
    Emitter<CreditState> emit,
  ) async {
    emit(CreditHistoryLoading());
    final (transactions, failure) = await _repository.getCreditHistory();
    if (failure != null) {
      emit(CreditHistoryError(failure.message));
    } else {
      emit(CreditHistoryLoaded(transactions!));
    }
  }
}
