import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/home/data/datasources/order_notification_socket_datasource.dart';

class HomeLiveOrdersTray extends StatefulWidget {
  const HomeLiveOrdersTray({super.key});

  @override
  State<HomeLiveOrdersTray> createState() => _HomeLiveOrdersTrayState();
}

class _HomeLiveOrdersTrayState extends State<HomeLiveOrdersTray>
    with WidgetsBindingObserver {
  final OrderNotificationSocketDatasource _datasource =
      const OrderNotificationSocketDatasource();
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
      _syncSocket(force: true);
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
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
      _dismissed = false;
      _expanded = false;
      _orders = const [];
    });
    if (_socketPaused || digitsPhone.isEmpty) return;
    _ordersSubscription = _datasource.watch(phoneNumber: digitsPhone).listen(
          _onOrders,
          onError: (_) {},
        );
  }

  void _onOrders(List<OrderNotificationPreview> nextOrders) {
    if (!mounted || nextOrders.isEmpty) return;
    setState(() {
      _dismissed = false;
      _orders = nextOrders.length > 1
          ? nextOrders
          : _upsertOrder(_orders, nextOrders.first);
    });
  }

  List<OrderNotificationPreview> _upsertOrder(
    List<OrderNotificationPreview> current,
    OrderNotificationPreview next,
  ) {
    final nextKey = _orderKey(next);
    if (nextKey.isEmpty) return [next, ...current];
    final updated = <OrderNotificationPreview>[next];
    for (final order in current) {
      if (_orderKey(order) != nextKey) updated.add(order);
    }
    return updated;
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
      onDismiss: () => setState(() => _dismissed = true),
      onTrack: _openOrders,
    );
  }

  void _openOrders() {
    context.push('/orders-tab');
  }
}

class _OrdersTrayOverlay extends StatelessWidget {
  const _OrdersTrayOverlay({
    required this.orders,
    required this.expanded,
    required this.onExpandChanged,
    required this.onDismiss,
    required this.onTrack,
  });

  final List<OrderNotificationPreview> orders;
  final bool expanded;
  final ValueChanged<bool> onExpandChanged;
  final VoidCallback onDismiss;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 72;
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
          Positioned(
            left: 16,
            right: 16,
            bottom: bottom,
            child: expanded
                ? _ExpandedOrdersTray(
                    orders: orders,
                    onTrack: onTrack,
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
  }
}

class _ExpandedOrdersTray extends StatelessWidget {
  const _ExpandedOrdersTray({
    required this.orders,
    required this.onTrack,
  });

  final List<OrderNotificationPreview> orders;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Your orders',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 24 / 18,
                ),
              ),
            ),
            TextButton(
              onPressed: onTrack,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                minimumSize: const Size(70, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const CircleAvatar(
              radius: 13,
              backgroundColor: Color(0xFFE5E5E5),
              child: Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6D7480),
                size: 20,
              ),
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
  final VoidCallback onTrack;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hiddenCount > 0)
          Transform.translate(
            offset: const Offset(0, 8),
            child: Material(
              color: Colors.white,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onExpand,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+ $hiddenCount more',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0A243F),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 18 / 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SvgPicture.asset(
                        'assets/images/upicon.svg',
                        width: 10,
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        _LiveOrderCard(
          order: order,
          onTrack: onTrack,
          trailing: IconButton(
            onPressed: onDismiss,
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFF9AA1AD),
              size: 20,
            ),
          ),
        ),
      ],
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
  final VoidCallback onTrack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 58,
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E6EE)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _accentColorFor(order),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SvgPicture.asset(
                'assets/images/vehicletracking.svg',
                width: 28,
                height: 28,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 18 / 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6C778A),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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
                onPressed: onTrack,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: Color(0xFF0BA326)),
                  foregroundColor: const Color(0xFF0BA326),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Track',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 18 / 13,
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
}
