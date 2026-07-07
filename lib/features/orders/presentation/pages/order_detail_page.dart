import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:m_o_b_demand_side/shared/image_shimmer.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

part 'order_detail_bill_section.dart';
part 'order_detail_footer_section.dart';
part 'order_detail_header.dart';
part 'order_detail_info_section.dart';
part 'order_detail_shipments.dart';

class OrderDetailPage extends StatefulWidget {
  static const String routeName = 'OrderDetailPage';
  static const String routePath = '/order-detail';

  const OrderDetailPage({super.key});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrdersBloc _ordersBloc;
  bool _initialized = false;
  bool _navigatingBack = false;

  @override
  void initState() {
    super.initState();
    _ordersBloc = sl<OrdersBloc>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final orderId = GoRouterState.of(context).extra as String?;
      if (orderId != null && orderId.isNotEmpty) {
        _ordersBloc.add(OrderDetailRequested(orderId));
      }
    }
  }

  @override
  void dispose() {
    _ordersBloc.close();
    super.dispose();
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'Processing';
    return '${status[0].toUpperCase()}${status.substring(1).toLowerCase().replaceAll('_', ' ')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _navigatingBack) return;
        _navigatingBack = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/homepage');
          }
        });
      },
      child: BlocProvider<OrdersBloc>.value(
        value: _ordersBloc,
        child: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            final order = switch (state) {
              OrderDetailLoaded(:final order) => order,
              _ => null,
            };
            final shipments = _shipmentsFor(order);

            return Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _OrderDetailHeader(order: order),
                    Expanded(
                      child: switch (state) {
                        OrdersInitial() || OrdersLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        OrdersError(:final message) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                message,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF596378),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        _ => SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (order != null && shipments.isNotEmpty)
                                  for (var i = 0;
                                      i < shipments.length;
                                      i++) ...[
                                    _ShipmentSection(
                                      order: order,
                                      shipment: shipments[i],
                                      index: i + 1,
                                      title: _shipmentTitle(
                                          order, shipments[i], i),
                                      iconAsset: _shipmentIconAsset(
                                          order, shipments[i]),
                                      items: shipments[i].items,
                                    ),
                                    if (i < shipments.length - 1)
                                      const _SectionGap(),
                                  ]
                                else
                                  const SizedBox(height: 8),
                                const _SectionGap(),
                                // const _RateItemsStrip(),
                                // const _SectionGap(),
                                _BillDetailsSection(order: order),
                                const _SectionGap(),
                                _OrderInfoSection(order: order),
                                const _SectionGap(),
                                const _HelpTile(),
                                const _SectionGap(),
                                const _PromoFooter(),
                              ],
                            ),
                          ),
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<OrderShipmentEntity> _shipmentsFor(OrderEntity? order) {
    if (order == null) return const [];
    if (order.shipments.isNotEmpty) return order.shipments;
    if (order.items.isEmpty) return const [];
    return [
      OrderShipmentEntity(
        id: order.id,
        status: order.status,
        deliveryDate: order.createdAt,
        items: order.items,
      ),
    ];
  }

  String _resolvedShipmentStatus(
      OrderEntity order, OrderShipmentEntity shipment) {
    // Use order-level status (order_status from API) to match website display.
    // Fall back to suborder status only when the order status is empty.
    return order.status.trim().isNotEmpty
        ? order.status.trim()
        : shipment.status.trim();
  }

  String _shipmentTitle(
      OrderEntity order, OrderShipmentEntity shipment, int index) {
    final status = _resolvedShipmentStatus(order, shipment);
    if (status.isEmpty) {
      return index == 0 ? 'Processing' : 'Packing your order';
    }
    if (_isDeliveredStatus(status)) return 'Delivered';
    if (_isOutForDeliveryStatus(status)) return 'Out for delivery';
    return _formatStatus(status);
  }

  String _shipmentIconAsset(OrderEntity order, OrderShipmentEntity shipment) {
    return orderStatusIconAsset(_resolvedShipmentStatus(order, shipment));
  }

  bool _isOutForDeliveryStatus(String status) {
    final normalized =
        status.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    final compact = normalized.replaceAll(' ', '');
    return normalized.contains('out for delivery') ||
        compact.contains('outfordelivery') ||
        normalized.contains('out for shipment') ||
        normalized.contains('on the way');
  }

  bool _isDeliveredStatus(String status) {
    final normalized =
        status.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    if (_isOutForDeliveryStatus(status)) {
      return false;
    }
    return normalized.contains('deliver') ||
        normalized.contains('completed') ||
        normalized.contains('received') ||
        normalized.contains('fulfilled');
  }
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) {
    return Container(height: 12, color: const Color(0xFFF1F1F2));
  }
}
