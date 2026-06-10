import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/bloc/orders_bloc.dart';

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
    return BlocProvider<OrdersBloc>.value(
      value: _ordersBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<OrdersBloc, OrdersState>(
            builder: (context, state) {
              final order = switch (state) {
                OrderDetailLoaded(:final order) => order,
                _ => null,
              };

              return Column(
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
                              if (order != null && order.items.isNotEmpty)
                                _ShipmentSection(
                                  index: 1,
                                  title: _formatStatus(order.status),
                                  icon: Icons.local_shipping_outlined,
                                  iconBackground: const Color(0xFFDFF8F9),
                                  items: order.items,
                                )
                              else
                                const SizedBox(height: 8),
                              const _SectionGap(),
                              const _RateItemsStrip(),
                              const _SectionGap(),
                              const _BillDetailsSection(),
                              const _SectionGap(),
                              const _OrderInfoSection(),
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
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionGap extends StatelessWidget {
  const _SectionGap();

  @override
  Widget build(BuildContext context) {
    return Container(height: 12, color: const Color(0xFFF1F1F2));
  }
}
