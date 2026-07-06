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
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_detail_page.dart';

class OrderPlacedPage extends StatefulWidget {
  static const routeName = 'OrderPlacedPage';
  static const routePath = '/checkout/success';

  const OrderPlacedPage({super.key, this.orderId = '', this.order});

  final String orderId;
  final PlacedOrderEntity? order;

  @override
  State<OrderPlacedPage> createState() => _OrderPlacedPageState();
}

class _OrderPlacedPageState extends State<OrderPlacedPage> {
  CheckoutBloc? _checkoutBloc;
  late final CartBloc _cartBloc;
  late GoRouter _router;
  Timer? _navTimer;

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
      _checkoutBloc = sl<CheckoutBloc>()
        ..add(CheckoutOrderConfirmationRequested(widget.orderId));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cartBloc.add(CartLoadRequested());
    });
    _navTimer = Timer(const Duration(seconds: 2), _navigateToOrderDetail);
  }

  void _navigateToOrderDetail() {
    if (!mounted) return;
    final orderId = widget.order?.orderId ?? widget.orderId;
    _router.go(
      OrderDetailPage.routePath,
      extra: orderId.isNotEmpty ? orderId : null,
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
                      repeat: false,
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
