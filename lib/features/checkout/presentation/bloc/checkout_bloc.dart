import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/entities/checkout_entity.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/repositories/checkout_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────

sealed class CheckoutEvent {}

final class CheckoutLoadRequested extends CheckoutEvent {}

final class CheckoutAddressUpdateRequested extends CheckoutEvent {
  CheckoutAddressUpdateRequested({required this.payload});
  final Map<String, dynamic> payload;
}

final class CheckoutOrderPlaceRequested extends CheckoutEvent {
  CheckoutOrderPlaceRequested({required this.payload});
  final Map<String, dynamic> payload;
}

final class CheckoutRazorpayOrderRequested extends CheckoutEvent {
  CheckoutRazorpayOrderRequested({required this.cartId, this.paymentOrigin});
  final int cartId;
  final String? paymentOrigin;
}

final class CheckoutRazorpayPaymentFailed extends CheckoutEvent {
  CheckoutRazorpayPaymentFailed(this.message);
  final String message;
}

final class CheckoutRazorpayVerifyRequested extends CheckoutEvent {
  CheckoutRazorpayVerifyRequested({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
  final String paymentId;
  final String orderId;
  final String signature;
}

final class CheckoutRazorpayStatusCheckRequested extends CheckoutEvent {
  CheckoutRazorpayStatusCheckRequested({
    required this.platformOrderId,
    required this.merchantPaymentRefId,
    required this.paymentId,
    required this.transactionId,
  });
  final String platformOrderId;
  final String merchantPaymentRefId;
  final String paymentId;
  final String transactionId;
}

final class CheckoutRupifiOrderRequested extends CheckoutEvent {
  CheckoutRupifiOrderRequested({
    required this.cartId,
    this.paymentOrigin,
  });
  final String cartId;
  final String? paymentOrigin;
}

final class CheckoutRupifiStatusCheckRequested extends CheckoutEvent {
  CheckoutRupifiStatusCheckRequested({
    required this.platformOrderId,
    required this.merchantPaymentRefId,
    required this.paymentId,
    required this.transactionId,
    this.currency = '',
  });
  final String platformOrderId;
  final String merchantPaymentRefId;
  final String paymentId;
  final String transactionId;
  final String currency;
}

final class CheckoutOrderConfirmationRequested extends CheckoutEvent {
  CheckoutOrderConfirmationRequested(this.orderId);
  final String orderId;
}

// ── States ───────────────────────────────────────────────────────────────────

sealed class CheckoutState {}

final class CheckoutInitial extends CheckoutState {}

final class CheckoutLoading extends CheckoutState {}

final class CheckoutSummaryLoaded extends CheckoutState {
  CheckoutSummaryLoaded(this.summary);
  final CheckoutSummaryEntity summary;
}

final class CheckoutAddressUpdated extends CheckoutState {}

final class CheckoutRazorpayOrderCreated extends CheckoutState {
  CheckoutRazorpayOrderCreated(this.entity);
  final RazorpayOrderEntity entity;
}

final class CheckoutOrderPlaced extends CheckoutState {
  CheckoutOrderPlaced(this.order);
  final PlacedOrderEntity order;
}

final class CheckoutError extends CheckoutState {
  CheckoutError(this.message);
  final String message;
}

final class CheckoutPaymentFailed extends CheckoutState {
  CheckoutPaymentFailed(this.message);
  final String message;
}

final class CheckoutRupifiOrderCreated extends CheckoutState {
  CheckoutRupifiOrderCreated(this.entity);
  final RupifiOrderEntity entity;
}

// ── BLoC (factory) ───────────────────────────────────────────────────────────

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc(this._repository) : super(CheckoutInitial()) {
    on<CheckoutLoadRequested>(_onLoad);
    on<CheckoutAddressUpdateRequested>(_onUpdateAddress);
    on<CheckoutOrderPlaceRequested>(_onPlaceOrder);
    on<CheckoutRazorpayOrderRequested>(_onCreateRazorpayOrder);
    on<CheckoutRazorpayPaymentFailed>(_onRazorpayPaymentFailed);
    on<CheckoutRazorpayVerifyRequested>(_onVerifyRazorpayPayment);
    on<CheckoutRazorpayStatusCheckRequested>(_onRazorpayStatusCheck);
    on<CheckoutRupifiOrderRequested>(_onCreateRupifiOrder);
    on<CheckoutRupifiStatusCheckRequested>(_onRupifiStatusCheck);
    on<CheckoutOrderConfirmationRequested>(_onOrderConfirmation);
  }

  final CheckoutRepository _repository;

  // flutter_bloc processes events of the same type concurrently by default,
  // and the UI only disables the "Place order" button once CheckoutLoading
  // has actually rebuilt the widget — a rapid double-tap can fire two
  // CheckoutOrderPlaceRequested events before that happens, which would
  // otherwise place the order twice. This flag makes the handler a no-op for
  // any event that arrives while one is already in flight.
  bool _isPlacingOrder = false;

  Future<void> _onUpdateAddress(
    CheckoutAddressUpdateRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    final failure = await _repository.updateAddressToOrder(event.payload);
    if (failure != null) {
      AppHaptics.error();
      emit(CheckoutError(failure.message));
    } else {
      emit(CheckoutAddressUpdated());
    }
  }

  Future<void> _onLoad(
      CheckoutLoadRequested event, Emitter<CheckoutState> emit) async {
    emit(CheckoutLoading());
    final (summary, failure) = await _repository.getCheckoutSummary();
    if (failure != null) {
      AppHaptics.error();
      emit(CheckoutError(failure.message));
    } else {
      emit(CheckoutSummaryLoaded(summary!));
    }
  }

  Future<void> _onPlaceOrder(
    CheckoutOrderPlaceRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_isPlacingOrder) return;
    _isPlacingOrder = true;
    try {
      emit(CheckoutLoading());
      final (order, failure) = await _repository.placeOrder(event.payload);
      if (failure != null) {
        AppHaptics.error();
        emit(CheckoutError(failure.message));
        return;
      }

      // Order is already placed at this point — a failure fetching the
      // richer suborder details below must not surface as a checkout error.
      // Fall back to the lighter confirmation entity from
      // place_direct_order instead.
      final placedOrder = order!;
      if (placedOrder.orderId.isEmpty) {
        emit(CheckoutOrderPlaced(placedOrder));
        return;
      }
      final (detailedOrder, detailFailure) =
          await _repository.getSuborderDetails(
        platformOrderId: placedOrder.orderId,
      );
      emit(CheckoutOrderPlaced(
          detailFailure != null ? placedOrder : detailedOrder!));
    } finally {
      _isPlacingOrder = false;
    }
  }

  Future<void> _onCreateRazorpayOrder(
    CheckoutRazorpayOrderRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    final (entity, failure) = await _repository.createRazorpayOrder(
      event.cartId,
      paymentOrigin: event.paymentOrigin,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(CheckoutError(failure.message));
    } else {
      emit(CheckoutRazorpayOrderCreated(entity!));
    }
  }

  Future<void> _onRazorpayPaymentFailed(
    CheckoutRazorpayPaymentFailed event,
    Emitter<CheckoutState> emit,
  ) async {
    AppHaptics.error();
    emit(CheckoutError(event.message));
  }

  Future<void> _onVerifyRazorpayPayment(
    CheckoutRazorpayVerifyRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());

    // Step 1: Verify payment with Razorpay → returns platform order ID
    final (verifiedOrder, verifyFailure) =
        await _repository.verifyRazorpayPayment(
      paymentId: event.paymentId,
      orderId: event.orderId,
      signature: event.signature,
    );
    if (verifyFailure != null) {
      AppHaptics.error();
      emit(CheckoutPaymentFailed(verifyFailure.message));
      return;
    }

    // Step 2: Fetch suborder details using the platform order ID from step 1
    final platformOrderId = verifiedOrder!.orderId;
    final (order, failure) = await _repository.getSuborderDetails(
      platformOrderId: platformOrderId,
      paymentGateway: 'RAZORPAY',
      merchantPaymentRefId: event.orderId,
      paymentId: event.paymentId,
      transactionId: event.signature,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(CheckoutPaymentFailed(failure.message));
      return;
    }

    emit(CheckoutOrderPlaced(order!));
  }

  Future<void> _onCreateRupifiOrder(
    CheckoutRupifiOrderRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    final (entity, failure) = await _repository.createRupifiOrder(
      event.cartId,
      paymentOrigin: event.paymentOrigin,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(CheckoutError(failure.message));
    } else {
      emit(CheckoutRupifiOrderCreated(entity!));
    }
  }

  Future<void> _onOrderConfirmation(
    CheckoutOrderConfirmationRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    final (order, failure) = await _repository.getSuborderDetails(
      platformOrderId: event.orderId,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(CheckoutError(failure.message));
    } else {
      emit(CheckoutOrderPlaced(order!));
    }
  }

  Future<void> _onRazorpayStatusCheck(
    CheckoutRazorpayStatusCheckRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());
    final (order, failure) = await _repository.getSuborderDetails(
      platformOrderId: event.platformOrderId,
      paymentGateway: 'RAZORPAY',
      merchantPaymentRefId: event.merchantPaymentRefId,
      paymentId: event.paymentId,
      transactionId: event.transactionId,
    );
    if (failure != null) {
      AppHaptics.error();
      emit(CheckoutPaymentFailed(failure.message));
    } else {
      emit(CheckoutOrderPlaced(order!));
    }
  }

  Future<void> _onRupifiStatusCheck(
    CheckoutRupifiStatusCheckRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    if (kDebugMode) {
      debugPrint(
          '[Rupifi] _onRupifiStatusCheck platformOrderId=${event.platformOrderId}');
      debugPrint('[Rupifi] merchantPaymentRefId=${event.merchantPaymentRefId}');
      debugPrint('[Rupifi] paymentId=${event.paymentId}');
      debugPrint('[Rupifi] transactionId=${event.transactionId}');
      debugPrint('[Rupifi] currency=${event.currency}');
    }
    emit(CheckoutLoading());
    final (order, failure) = await _repository.getSuborderDetails(
      platformOrderId: event.platformOrderId,
      paymentGateway: 'RUPIFI',
      merchantPaymentRefId: event.merchantPaymentRefId,
      paymentId: event.paymentId,
      transactionId: event.transactionId,
    );
    if (failure != null) {
      if (kDebugMode) {
        debugPrint('[Rupifi] getSuborderDetails FAILED: ${failure.message}');
      }
      AppHaptics.error();
      emit(CheckoutPaymentFailed(failure.message));
    } else {
      final placedOrder = order!;
      if (kDebugMode) {
        debugPrint(
            '[Rupifi] getSuborderDetails SUCCESS orderId=${placedOrder.orderId}');
      }
      emit(CheckoutOrderPlaced(placedOrder));
    }
  }
}
