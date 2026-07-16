import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/home/data/datasources/order_notification_socket_datasource.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';

class HomeLiveOrdersTray extends StatefulWidget {
  const HomeLiveOrdersTray({super.key});

  @override
  State<HomeLiveOrdersTray> createState() => _HomeLiveOrdersTrayState();
}

class _HomeLiveOrdersTrayState extends State<HomeLiveOrdersTray>
    with WidgetsBindingObserver {
  final OrderNotificationSocketDatasource _datasource =
      const OrderNotificationSocketDatasource();
  static List<OrderNotificationPreview> _cachedOrders = const [];
  static String _cachedPhoneNumber = '';
  static String _dismissedPhoneNumber = '';
  bool _expanded = false;
  bool _dismissed = false;
  bool _socketPaused = false;
  StreamSubscription<List<OrderNotificationPreview>>? _ordersSubscription;
  List<OrderNotificationPreview> _orders = const [];
  String _phoneNumber = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthSession.instance.addListener(_syncSocket);
    _syncSocket();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthSession.instance.removeListener(_syncSocket);
    _ordersSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _socketPaused = false;
      if (_ordersSubscription == null) {
        _syncSocket(force: true);
      }
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _socketPaused = true;
      _ordersSubscription?.cancel();
      _ordersSubscription = null;
    }
  }

  void _syncSocket({bool force = false}) {
    final phone = AuthSession.instance.phoneNumber ?? '';
    final digitsPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (!force && digitsPhone == _phoneNumber) return;
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    setState(() {
      _phoneNumber = digitsPhone;
      _dismissed = digitsPhone.isNotEmpty &&
          digitsPhone == _dismissedPhoneNumber &&
          digitsPhone == _cachedPhoneNumber &&
          _cachedOrders.isNotEmpty;
      _expanded = false;
      _orders = digitsPhone.isNotEmpty && digitsPhone == _cachedPhoneNumber
          ? _cachedOrders
          : const [];
    });
    if (_socketPaused || digitsPhone.isEmpty) return;
    _ordersSubscription = _datasource.watch(phoneNumber: digitsPhone).listen(
          _onOrders,
          onError: (_) {},
        );
  }

  void _onOrders(List<OrderNotificationPreview> nextOrders) {
    if (!mounted || nextOrders.isEmpty) return;
    final mergedOrders = _mergeOrders(_orders, nextOrders);
    setState(() {
      _dismissed = false;
      _dismissedPhoneNumber = '';
      _orders = mergedOrders;
      _cachedPhoneNumber = _phoneNumber;
      _cachedOrders = _orders;
    });
  }

  List<OrderNotificationPreview> _mergeOrders(
    List<OrderNotificationPreview> current,
    List<OrderNotificationPreview> nextOrders,
  ) {
    final updated = <OrderNotificationPreview>[];
    final seenKeys = <String>{};

    for (final order in nextOrders) {
      final key = _orderKey(order);
      if (key.isNotEmpty && !seenKeys.add(key)) continue;
      updated.add(order);
    }

    for (final order in current) {
      final key = _orderKey(order);
      if (key.isNotEmpty && !seenKeys.add(key)) continue;
      updated.add(order);
    }
    return updated.take(5).toList(growable: false);
  }

  String _orderKey(OrderNotificationPreview order) {
    if (order.suborderId.isNotEmpty) return order.suborderId;
    if (order.orderId.isNotEmpty) return order.orderId;
    return '${order.title}|${order.subtitle}';
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _orders.isEmpty) return const SizedBox.shrink();

    return _OrdersTrayOverlay(
      orders: _orders,
      expanded: _expanded,
      onExpandChanged: (value) => setState(() => _expanded = value),
      onDismiss: _dismissTray,
      onTrack: _openTracking,
      onViewAll: _openOrders,
    );
  }

  void _dismissTray() {
    setState(() {
      _dismissed = true;
      _expanded = false;
      _dismissedPhoneNumber = _phoneNumber;
    });
  }

  void _openOrders() {
    context.push('/orders-tab');
  }

  void _openTracking(OrderNotificationPreview order) {
    final suborderId = order.trackingSuborderId;
    if (suborderId.isEmpty) {
      context.push('/orders-tab');
      return;
    }
    final parentOrderId = _parentOrderId(suborderId);
    final shipment = OrderShipmentEntity(
      id: suborderId,
      status: order.status,
      deliveryDate: '',
      items: const [],
    );
    context.push(
      OrderTrackingPage.routePath,
      extra: {
        'order': OrderEntity(
          id: parentOrderId,
          orderNumber: parentOrderId,
          status: order.status,
          createdAt: '',
          total: 0,
          items: const [],
          shippingAddress: '',
          projectName: '',
          rewardMessage: '',
          isQuickCommerceOrder: false,
          shipments: [shipment],
        ),
        'shipment': shipment,
      },
    );
  }

  String _parentOrderId(String suborderId) {
    return suborderId.replaceFirst(RegExp(r'_\d+$'), '');
  }
}

class _OrdersTrayOverlay extends StatelessWidget {
  const _OrdersTrayOverlay({
    required this.orders,
    required this.expanded,
    required this.onExpandChanged,
    required this.onDismiss,
    required this.onTrack,
    required this.onViewAll,
  });

  final List<OrderNotificationPreview> orders;
  final bool expanded;
  final ValueChanged<bool> onExpandChanged;
  final VoidCallback onDismiss;
  final ValueChanged<OrderNotificationPreview> onTrack;
  final VoidCallback onViewAll;

  static const double _stackedGap = 12;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartBloc, CartState, bool>(
      selector: (state) => state is CartLoaded && state.summary.itemCount > 0,
      builder: (context, hasCart) {
        return ValueListenableBuilder<bool>(
          valueListenable: navBarVisible,
          builder: (context, isNavBarVisible, _) {
            final bottomInset = MediaQuery.paddingOf(context).bottom;
            final navOffset =
                hasCart && !isNavBarVisible ? -kBottomNavBarHeight : 0.0;
            final collapsedBottom = bottomInset +
                kViewCartBarGap +
                navOffset +
                (hasCart ? kViewCartBarHeight + _stackedGap : 0);

            return Positioned.fill(
              child: Stack(
                children: [
                  if (expanded)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => onExpandChanged(false),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                          child: Container(
                            color: Colors.black.withValues(alpha: .62),
                          ),
                        ),
                      ),
                    ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    left: 16,
                    right: 16,
                    bottom: collapsedBottom,
                    child: expanded
                        ? _ExpandedOrdersTray(
                            orders: orders,
                            onTrack: onTrack,
                            onViewAll: onViewAll,
                            onClose: () => onExpandChanged(false),
                          )
                        : _CollapsedOrdersTray(
                            order: orders.first,
                            hiddenCount: orders.length - 1,
                            onExpand: () => onExpandChanged(true),
                            onTrack: onTrack,
                            onDismiss: onDismiss,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ExpandedOrdersTray extends StatelessWidget {
  const _ExpandedOrdersTray({
    required this.orders,
    required this.onTrack,
    required this.onViewAll,
    required this.onClose,
  });

  final List<OrderNotificationPreview> orders;
  final ValueChanged<OrderNotificationPreview> onTrack;
  final VoidCallback onViewAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClose,
          child: SvgPicture.asset(
            'assets/images/closeicon-bg.svg',
            width: 44,
            height: 44,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                'Your orders',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 24 / 17,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                minimumSize: const Size(70, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 20 / 13,
                ),
              ),
            ),
            const SizedBox(width: 2),
            SvgPicture.asset(
              'assets/images/Notification-rightarrow.svg',
              width: 24,
              height: 24,
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final order in orders) ...[
          _LiveOrderCard(order: order, onTrack: onTrack),
          if (order != orders.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CollapsedOrdersTray extends StatelessWidget {
  const _CollapsedOrdersTray({
    required this.order,
    required this.hiddenCount,
    required this.onExpand,
    required this.onTrack,
    required this.onDismiss,
  });

  final OrderNotificationPreview order;
  final int hiddenCount;
  final VoidCallback onExpand;
  final ValueChanged<OrderNotificationPreview> onTrack;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final orderCard = _LiveOrderCard(
      order: order,
      onTrack: onTrack,
      trailing: IconButton(
        onPressed: onDismiss,
        padding: EdgeInsets.zero,
        icon: SvgPicture.asset(
          'assets/images/close-light.svg',
          width: 16,
          height: 16,
        ),
      ),
    );

    if (hiddenCount <= 0) return orderCard;

    return SizedBox(
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          if (hiddenCount > 1)
            Positioned(
              left: 28,
              right: 28,
              top: 2,
              child: const _StackedOrderCardLayer(),
            ),
          Positioned(
            left: 12,
            right: 12,
            top: 10,
            child: const _StackedOrderCardLayer(),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 18,
            child: orderCard,
          ),
          Positioned(
            top: 0,
            child: _MoreOrdersPill(
              hiddenCount: hiddenCount,
              onTap: onExpand,
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedOrderCardLayer extends StatelessWidget {
  const _StackedOrderCardLayer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _MoreOrdersPill extends StatelessWidget {
  const _MoreOrdersPill({
    required this.hiddenCount,
    required this.onTap,
  });

  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD6D6D6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+ $hiddenCount more',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 16 / 11,
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/images/moreicon.svg',
                width: 8,
                height: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveOrderCard extends StatelessWidget {
  const _LiveOrderCard({
    required this.order,
    required this.onTrack,
    this.trailing,
  });

  final OrderNotificationPreview order;
  final ValueChanged<OrderNotificationPreview> onTrack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 54,
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _accentColorFor(order),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SvgPicture.asset(
                _iconAssetFor(order),
                width: 38,
                height: 38,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 18 / 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF596378),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 15 / 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 68,
              height: 34,
              child: OutlinedButton(
                onPressed: () => onTrack(order),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: Color(0xFF008800)),
                  foregroundColor: const Color(0xFF008800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Track',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 18 / 12,
                  ),
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 2),
              SizedBox(width: 34, height: 42, child: trailing),
            ],
          ],
        ),
      ),
    );
  }

  Color _accentColorFor(OrderNotificationPreview order) {
    final value = '${order.title} ${order.status}'.toLowerCase();
    if (value.contains('pack')) return const Color(0xFFFFEFAF);
    return const Color(0xFFDDFBFF);
  }

  String _iconAssetFor(OrderNotificationPreview order) {
    final statusText = order.status.isNotEmpty
        ? order.status
        : '${order.title} ${order.subtitle}';
    return orderStatusIconAsset(
      statusText,
    );
  }
}
