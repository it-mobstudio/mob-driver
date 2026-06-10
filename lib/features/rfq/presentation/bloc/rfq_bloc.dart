import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/entities/rfq_entity.dart';
import 'package:m_o_b_demand_side/features/rfq/domain/repositories/rfq_repository.dart';

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

// ── BLoC (factory) ───────────────────────────────────────────────────────────

class RfqBloc extends Bloc<RfqEvent, RfqState> {
  RfqBloc(this._repository) : super(RfqInitial()) {
    on<RfqListRequested>(_onList);
    on<RfqDetailRequested>(_onDetail);
    on<RfqSubmitRequested>(_onSubmit);
  }

  final RfqRepository _repository;

  Future<void> _onList(RfqListRequested event, Emitter<RfqState> emit) async {
    emit(RfqLoading());
    final (rfqs, failure) = await _repository.getRfqList();
    if (failure != null) {
      emit(RfqError(failure.message));
    } else {
      emit(RfqListLoaded(rfqs!));
    }
  }

  Future<void> _onDetail(RfqDetailRequested event, Emitter<RfqState> emit) async {
    emit(RfqLoading());
    final (rfq, failure) = await _repository.getRfqDetail(event.id);
    if (failure != null) {
      emit(RfqError(failure.message));
    } else {
      emit(RfqDetailLoaded(rfq!));
    }
  }

  Future<void> _onSubmit(RfqSubmitRequested event, Emitter<RfqState> emit) async {
    emit(RfqLoading());
    final (success, failure) = await _repository.submitRfq(event.payload);
    if (failure != null) {
      emit(RfqError(failure.message));
    } else if (success) {
      emit(RfqSubmitted());
    } else {
      emit(RfqError('RFQ submission failed.'));
    }
  }
}
