import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/domain/repositories/orders_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class OrdersEvent {}

final class OrdersLoadRequested extends OrdersEvent {}

/// Pull-to-refresh — reloads page 1 with whatever query/filter is currently
/// active, without blanking the list to a loading spinner first (unlike
/// [OrdersLoadRequested]/[OrdersQueryChanged]), so the existing list stays
/// visible under the pull-to-refresh indicator the whole time.
final class OrdersRefreshRequested extends OrdersEvent {}

final class OrdersQueryChanged extends OrdersEvent {
  OrdersQueryChanged(this.query);
  final String query;
}

final class OrdersNextPageRequested extends OrdersEvent {}

final class OrderDetailRequested extends OrdersEvent {
  OrderDetailRequested(this.id);
  final String id;
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class OrdersState {}

final class OrdersInitial extends OrdersState {}

final class OrdersLoading extends OrdersState {}

final class OrdersLoaded extends OrdersState {
  OrdersLoaded(
    this.orders, {
    this.query = '',
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<OrderEntity> orders;
  final String query;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  OrdersLoaded copyWith({
    List<OrderEntity>? orders,
    String? query,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return OrdersLoaded(
      orders ?? this.orders,
      query: query ?? this.query,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
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
    on<OrdersRefreshRequested>(_onRefresh);
    on<OrdersQueryChanged>(_onQueryChanged);
    on<OrdersNextPageRequested>(_onNextPage);
    on<OrderDetailRequested>(_onDetail);
  }

  final OrdersRepository _repository;

  Future<void> _onLoad(
      OrdersLoadRequested event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    final (orders, hasMore, failure) = await _repository.getOrders(page: 1);
    if (failure != null) {
      AppHaptics.error();
      emit(OrdersError(failure.message));
    } else {
      emit(OrdersLoaded(orders!, page: 1, hasMore: hasMore));
    }
  }

  Future<void> _onRefresh(
    OrdersRefreshRequested event,
    Emitter<OrdersState> emit,
  ) async {
    final current = state;
    final query = current is OrdersLoaded ? current.query : '';
    final (orders, hasMore, failure) =
        await _repository.getOrders(page: 1, search: query);
    if (failure != null) {
      AppHaptics.error();
      // Keep whatever was already on screen — only surface the error state
      // if there was nothing showing yet.
      if (current is! OrdersLoaded) emit(OrdersError(failure.message));
      return;
    }
    emit(OrdersLoaded(orders!, query: query, page: 1, hasMore: hasMore));
  }

  Future<void> _onQueryChanged(
    OrdersQueryChanged event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    final (orders, hasMore, failure) =
        await _repository.getOrders(page: 1, search: event.query);
    if (failure != null) {
      AppHaptics.error();
      emit(OrdersError(failure.message));
    } else {
      emit(
        OrdersLoaded(orders!, query: event.query, page: 1, hasMore: hasMore),
      );
    }
  }

  Future<void> _onNextPage(
    OrdersNextPageRequested event,
    Emitter<OrdersState> emit,
  ) async {
    final current = state;
    if (current is! OrdersLoaded || !current.hasMore || current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    final nextPage = current.page + 1;
    final (orders, hasMore, failure) = await _repository.getOrders(
      page: nextPage,
      search: current.query,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(current.copyWith(isLoadingMore: false));
    } else {
      emit(
        current.copyWith(
          orders: [...current.orders, ...orders!],
          page: nextPage,
          hasMore: hasMore,
          isLoadingMore: false,
        ),
      );
    }
  }

  Future<void> _onDetail(
      OrderDetailRequested event, Emitter<OrdersState> emit) async {
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
