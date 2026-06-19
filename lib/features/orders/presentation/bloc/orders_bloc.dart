import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/domain/repositories/orders_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class OrdersEvent {}

final class OrdersLoadRequested extends OrdersEvent {}

final class OrderDetailRequested extends OrdersEvent {
  OrderDetailRequested(this.id);
  final String id;
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class OrdersState {}

final class OrdersInitial extends OrdersState {}

final class OrdersLoading extends OrdersState {}

final class OrdersLoaded extends OrdersState {
  OrdersLoaded(this.orders);
  final List<OrderEntity> orders;
}

final class OrderDetailLoaded extends OrdersState {
  OrderDetailLoaded(this.order);
  final OrderEntity order;
}

final class OrdersError extends OrdersState {
  OrdersError(this.message);
  final String message;
}

// ── BLoC (factory) ───────────────────────────────────────────────────────────

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc(this._repository) : super(OrdersInitial()) {
    on<OrdersLoadRequested>(_onLoad);
    on<OrderDetailRequested>(_onDetail);
  }

  final OrdersRepository _repository;

  Future<void> _onLoad(OrdersLoadRequested event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    final (orders, failure) = await _repository.getOrders();
    if (failure != null) {
      AppHaptics.error();
      emit(OrdersError(failure.message));
    } else {
      emit(OrdersLoaded(orders!));
    }
  }

  Future<void> _onDetail(OrderDetailRequested event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    final (order, failure) = await _repository.getOrderDetail(event.id);
    if (failure != null) {
      AppHaptics.error();
      emit(OrdersError(failure.message));
    } else {
      emit(OrderDetailLoaded(order!));
    }
  }
}
