import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/entities/checkout_entity.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/repositories/checkout_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class CheckoutEvent {}

final class CheckoutLoadRequested extends CheckoutEvent {}

final class CheckoutOrderPlaceRequested extends CheckoutEvent {
  CheckoutOrderPlaceRequested({required this.payload});
  final Map<String, dynamic> payload;
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class CheckoutState {}

final class CheckoutInitial extends CheckoutState {}

final class CheckoutLoading extends CheckoutState {}

final class CheckoutSummaryLoaded extends CheckoutState {
  CheckoutSummaryLoaded(this.summary);
  final CheckoutSummaryEntity summary;
}

final class CheckoutOrderPlaced extends CheckoutState {
  CheckoutOrderPlaced(this.order);
  final PlacedOrderEntity order;
}

final class CheckoutError extends CheckoutState {
  CheckoutError(this.message);
  final String message;
}

// ── BLoC (factory) ───────────────────────────────────────────────────────────

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc(this._repository) : super(CheckoutInitial()) {
    on<CheckoutLoadRequested>(_onLoad);
    on<CheckoutOrderPlaceRequested>(_onPlaceOrder);
  }

  final CheckoutRepository _repository;

  Future<void> _onLoad(CheckoutLoadRequested event, Emitter<CheckoutState> emit) async {
    emit(CheckoutLoading());
    final (summary, failure) = await _repository.getCheckoutSummary();
    if (failure != null) {
      emit(CheckoutError(failure.message));
    } else {
      emit(CheckoutSummaryLoaded(summary!));
    }
  }

  Future<void> _onPlaceOrder(
    CheckoutOrderPlaceRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    final (order, failure) = await _repository.placeOrder(event.payload);
    if (failure != null) {
      emit(CheckoutError(failure.message));
    } else {
      emit(CheckoutOrderPlaced(order!));
    }
  }
}
