import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/domain/repositories/cart_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class CartEvent {}

final class CartLoadRequested extends CartEvent {}

final class CartQuantityUpdateRequested extends CartEvent {
  CartQuantityUpdateRequested({required this.item, required this.newQty});
  final CartItem item;
  final int newQty;
}

final class CartItemRemoveRequested extends CartEvent {
  CartItemRemoveRequested({required this.item});
  final CartItem item;
}

final class CartActionErrorCleared extends CartEvent {}

// ── States ───────────────────────────────────────────────────────────────────

sealed class CartState {}

final class CartInitial extends CartState {}

final class CartLoading extends CartState {}

final class CartLoaded extends CartState {
  CartLoaded({
    required this.summary,
    this.actionError,
    this.updatingItemKey,
    this.successMessage,
  });
  final CartSummaryEntity summary;
  final String? actionError;
  final String? updatingItemKey;

  /// Transient — shown once via BlocListener then gone on next state.
  final String? successMessage;

  bool get isUpdating => updatingItemKey != null;

  /// Comes directly from API `item_count` field — no calculation.
  int get totalItemCount => summary.itemCount;

  /// vendorProductId → quantity map (computed once per state instance).
  Map<String, int> get quantityMap => {
        for (final item in summary.items)
          if (item.vendorProductId.isNotEmpty) item.vendorProductId: item.qty,
      };

  int quantityFor(String vendorProductId) =>
      quantityMap[vendorProductId] ?? 0;

  bool isUpdatingFor(String vendorProductId) =>
      updatingItemKey != null && updatingItemKey == vendorProductId;

  CartLoaded copyWith({
    CartSummaryEntity? summary,
    String? actionError,
    String? updatingItemKey,
    String? successMessage,
    bool clearActionError = false,
    bool clearUpdatingKey = false,
    bool clearSuccessMessage = false,
  }) {
    return CartLoaded(
      summary: summary ?? this.summary,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      updatingItemKey:
          clearUpdatingKey ? null : (updatingItemKey ?? this.updatingItemKey),
      successMessage: clearSuccessMessage
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}

final class CartError extends CartState {
  CartError(this.message);
  final String message;
}

final class CartRequiresLogin extends CartState {}

// ── BLoC ─────────────────────────────────────────────────────────────────────

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._repository) : super(CartInitial()) {
    on<CartLoadRequested>(_onLoad);
    on<CartQuantityUpdateRequested>(_onQuantityUpdate);
    on<CartItemRemoveRequested>(_onRemove);
    on<CartActionErrorCleared>(_onClearError);
  }

  final CartRepository _repository;

  Future<void> _onLoad(CartLoadRequested event, Emitter<CartState> emit) async {
    if (!AuthSession.instance.isAuthenticated) {
      emit(CartRequiresLogin());
      return;
    }
    emit(CartLoading());
    final (summary, failure) = await _repository.getCart();
    if (failure != null) {
      emit(CartError(failure.message));
    } else {
      emit(CartLoaded(summary: summary!));
    }
  }

  Future<void> _onQuantityUpdate(
    CartQuantityUpdateRequested event,
    Emitter<CartState> emit,
  ) async {
    if (!AuthSession.instance.isAuthenticated) {
      emit(CartRequiresLogin());
      return;
    }
    final current = state;
    if (current is! CartLoaded || current.isUpdating) return;

    final itemKey =
        event.item.itemKey.isNotEmpty ? event.item.itemKey : event.item.title;
    emit(current.copyWith(updatingItemKey: itemKey, clearActionError: true));

    final isAdding = event.newQty > 0;

    // When removing, the CartItem from the UI may not carry a cart_item_id
    // (it is built from ProductModel, not from cart state). Resolve it from
    // the current cart summary so the API always receives the real integer id.
    String resolvedCartItemId = event.item.cartItemId;
    if (!isAdding && resolvedCartItemId.isEmpty) {
      final match = current.summary.items.where(
        (ci) => ci.vendorProductId == event.item.vendorProductId,
      );
      if (match.isNotEmpty) resolvedCartItemId = match.first.cartItemId;
    }

    final (_, failure) = isAdding
        ? await _repository.addToCart(
            vendorProductId: event.item.vendorProductId,
            quantity: event.newQty,
          )
        : await _repository.removeFromCart(
            cartItemId: resolvedCartItemId,
            vendorProductId: event.item.vendorProductId,
          );

    if (failure != null) {
      emit(current.copyWith(
        clearUpdatingKey: true,
        actionError: failure.message,
      ));
      return;
    }

    // Add/remove endpoints don't return the full cart — fetch fresh state.
    final (freshSummary, freshFailure) = await _repository.getCart();
    if (freshFailure != null) {
      emit(current.copyWith(clearUpdatingKey: true));
    } else {
      emit(CartLoaded(
        summary: freshSummary!,
        successMessage: isAdding ? 'Added to cart' : null,
      ));
    }
  }

  Future<void> _onRemove(
    CartItemRemoveRequested event,
    Emitter<CartState> emit,
  ) async {
    if (!AuthSession.instance.isAuthenticated) {
      emit(CartRequiresLogin());
      return;
    }
    final current = state;
    if (current is! CartLoaded || current.isUpdating) return;

    final itemKey =
        event.item.itemKey.isNotEmpty ? event.item.itemKey : event.item.title;
    emit(current.copyWith(updatingItemKey: itemKey, clearActionError: true));

    final (_, failure) = await _repository.removeFromCart(
      cartItemId: event.item.cartItemId,
      vendorProductId: event.item.vendorProductId,
    );

    if (failure != null) {
      emit(current.copyWith(
          clearUpdatingKey: true, actionError: failure.message));
      return;
    }

    final (freshSummary, freshFailure) = await _repository.getCart();
    if (freshFailure != null) {
      emit(current.copyWith(clearUpdatingKey: true));
    } else {
      emit(CartLoaded(summary: freshSummary!));
    }
  }

  void _onClearError(CartActionErrorCleared event, Emitter<CartState> emit) {
    final current = state;
    if (current is CartLoaded) {
      emit(current.copyWith(clearActionError: true));
    }
  }
}
