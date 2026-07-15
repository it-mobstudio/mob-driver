import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/entities/checkout_entity.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_tracking_page.dart';

class OrderPlacedPage extends StatefulWidget {
  static const routeName = 'OrderPlacedPage';
  static const routePath = '/checkout/success';

  const OrderPlacedPage({
    super.key,
    this.orderId = '',
    this.order,
    this.paymentGateway,
    this.merchantPaymentRefId,
    this.paymentId,
    this.transactionId,
    this.currency,
  });

  final String orderId;
  final PlacedOrderEntity? order;

  /// When non-null and equals 'RUPIFI', the page fires
  /// [CheckoutRupifiStatusCheckRequested] to confirm the payment via the
  /// proper Rupifi status-check API (e.g. when reached via an OS deep link).
  final String? paymentGateway;
  final String? merchantPaymentRefId;
  final String? paymentId;
  final String? transactionId;
  final String? currency;

  @override
  State<OrderPlacedPage> createState() => _OrderPlacedPageState();
}

class _OrderPlacedPageState extends State<OrderPlacedPage> {
  CheckoutBloc? _checkoutBloc;
  late final CartBloc _cartBloc;
  late GoRouter _router;
  Timer? _navTimer;
  PlacedOrderEntity? _resolvedOrder;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router = GoRouter.of(context);
  }

  @override
  void initState() {
    super.initState();
    AppHaptics.success();
    _cartBloc = context.read<CartBloc>();
    if (widget.order == null && widget.orderId.isNotEmpty) {
      final isRupifiDeepLink = widget.paymentGateway == 'RUPIFI' &&
          (widget.merchantPaymentRefId?.isNotEmpty ?? false);
      if (isRupifiDeepLink) {
        _checkoutBloc = sl<CheckoutBloc>()
          ..add(CheckoutRupifiStatusCheckRequested(
            platformOrderId: widget.orderId,
            merchantPaymentRefId: widget.merchantPaymentRefId!,
            paymentId: widget.paymentId ?? '',
            transactionId: widget.transactionId ?? '',
            currency: widget.currency ?? '',
          ));
      } else {
        _checkoutBloc = sl<CheckoutBloc>()
          ..add(CheckoutOrderConfirmationRequested(widget.orderId));
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cartBloc.add(CartLoadRequested());
    });
    _navTimer = Timer(const Duration(seconds: 3), _navigateToOrderTracking);
  }

  void _navigateToOrderTracking() {
    if (!mounted) return;
    final placedOrder = widget.order ?? _resolvedOrder;
    final order = placedOrder != null
        ? _orderEntityFromPlaced(placedOrder)
        : _fallbackOrderEntity(widget.orderId);
    final shipment = _firstShipmentBySuborderId(order.shipments);

    _router.go(
      OrderTrackingPage.routePath,
      extra: {
        'order': order,
        if (shipment != null) 'shipment': shipment,
        'autoOpenRating': true,
      },
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _checkoutBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _checkoutBloc;
    if (widget.order != null || bloc == null) {
      return _scaffold(context, widget.order);
    }

    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<CheckoutBloc, CheckoutState>(
        builder: (context, state) {
          final order = state is CheckoutOrderPlaced ? state.order : null;
          if (order != null) _resolvedOrder = order;
          return _scaffold(context, order);
        },
      ),
    );
  }

  Widget _scaffold(BuildContext context, PlacedOrderEntity? order) {
    final points = order?.pointsSummary?.totalPoints ?? 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Transform.translate(
                offset: const Offset(0, -78),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/lottiejson/paymentsuccess.json',
                      width: 230,
                      height: 230,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Order placed',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 30 / 24,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (points > 0)
                      _PointsPill(points: points)
                    else if (order == null)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

OrderShipmentEntity? _firstShipmentBySuborderId(
  List<OrderShipmentEntity> shipments,
) {
  if (shipments.isEmpty) return null;
  final sorted = [...shipments];
  sorted.sort((a, b) {
    final suffixCompare =
        _suborderSuffixNumber(a.id).compareTo(_suborderSuffixNumber(b.id));
    if (suffixCompare != 0) return suffixCompare;
    return a.id.compareTo(b.id);
  });
  return sorted.first;
}

int _suborderSuffixNumber(String id) {
  final match = RegExp(r'_(\d+)$').firstMatch(id.trim());
  if (match == null) return 999999;
  return int.tryParse(match.group(1) ?? '') ?? 999999;
}

OrderEntity _orderEntityFromPlaced(PlacedOrderEntity order) {
  final shipments = order.suborders.map(_shipmentEntityFromPlaced).toList();
  return OrderEntity(
    id: order.orderId,
    orderNumber:
        order.orderNumber.isNotEmpty ? order.orderNumber : order.orderId,
    status: order.status,
    createdAt: order.createdAt,
    total: order.total,
    items: order.items.map(_itemEntityFromPlaced).toList(),
    shippingAddress: order.deliveryAddress?.fullAddress ?? '',
    projectName: '',
    rewardMessage: order.pointsSummary?.message ?? '',
    isQuickCommerceOrder: false,
    shipments: shipments.isNotEmpty
        ? shipments
        : [
            OrderShipmentEntity(
              id: '${order.orderId}_01',
              status: order.status,
              deliveryDate: '',
              createdAt: order.createdAt,
              items: order.items.map(_itemEntityFromPlaced).toList(),
            ),
          ],
    subTotal: order.subTotal,
    sgst: order.sgst,
    cgst: order.cgst,
    shippingFee: order.shippingFee,
    deliveryName: order.deliveryAddress?.name ?? '',
    deliveryPhone: order.deliveryAddress?.phoneNumber ?? '',
    paymentMethods: order.payments
        .map((payment) => payment.gateway)
        .where((gateway) => gateway.isNotEmpty)
        .toList(),
    rewardPoints: order.pointsSummary?.totalPoints ?? 0,
  );
}

OrderEntity _fallbackOrderEntity(String orderId) {
  final id = orderId.trim();
  return OrderEntity(
    id: id,
    orderNumber: id,
    status: '',
    createdAt: '',
    total: 0,
    items: const [],
    shippingAddress: '',
    projectName: '',
    rewardMessage: '',
    isQuickCommerceOrder: false,
    shipments: id.isEmpty
        ? const []
        : [
            OrderShipmentEntity(
              id: '${id}_01',
              status: '',
              deliveryDate: '',
              items: const [],
            ),
          ],
  );
}

OrderShipmentEntity _shipmentEntityFromPlaced(PlacedSubOrderEntity suborder) {
  return OrderShipmentEntity(
    id: suborder.suborderId,
    status: suborder.status,
    deliveryDate: suborder.deliveryDate,
    deliverySlot: suborder.deliverySlot,
    createdAt: '',
    vendorName: suborder.vendorName,
    subTotal: suborder.subTotal,
    total: suborder.total,
    items: suborder.products.map(_itemEntityFromPlaced).toList(),
  );
}

OrderItemEntity _itemEntityFromPlaced(PlacedOrderProductEntity product) {
  return OrderItemEntity(
    title: product.productName,
    imageUrl: product.imageUrl,
    qty: product.quantity,
    unitPrice: product.price,
    mobSku: product.mobSku,
    slug: '',
  );
}

class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7A7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFFFBF18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$points points',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: ' on the way!'),
              ],
            ),
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}
