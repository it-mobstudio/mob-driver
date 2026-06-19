import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:m_o_b_demand_side/shared/main_scaffold.dart';
import 'package:m_o_b_demand_side/shared/image_shimmer.dart';
import 'order_detail_page.dart';

part 'orders_page_cards.dart';
part 'orders_page_controls.dart';

class OrdersPage extends StatefulWidget {
  static const String routeName = 'OrdersPage';
  static const String routePath = '/orders';

  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrdersBloc _ordersBloc;

  @override
  void initState() {
    super.initState();
    _ordersBloc = sl<OrdersBloc>()..add(OrdersLoadRequested());
  }

  @override
  void dispose() {
    _ordersBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersBloc>.value(
      value: _ordersBloc,
      child: MainScaffold(
        currentIndex: 2,
        showTopSearchBar: false,
        showLocationheader: false,
        headerBackgroundColor: Colors.white,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _OrdersHeader(onBack: () => _goBack(context)),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF1F1F2),
                    child: BlocBuilder<OrdersBloc, OrdersState>(
                      builder: (context, state) {
                        return switch (state) {
                          OrdersInitial() ||
                          OrdersLoading() =>
                            const Center(child: CircularProgressIndicator()),
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
                          OrdersLoaded(:final orders) when orders.isEmpty =>
                            Center(
                              child: Text(
                                'No orders yet.',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF596378),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          OrdersLoaded(:final orders) => ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              children: [
                                const _OrdersSearch(),
                                const SizedBox(height: 12),
                                const _FilterButton(),
                                const SizedBox(height: 16),
                                ...orders.map(
                                  (order) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _OrderCard(
                                      order: order,
                                      onTap: () => context.push(
                                        OrderDetailPage.routePath,
                                        extra: order.id,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          _ => const SizedBox.shrink(),
                        };
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/myaccount');
    }
  }
}
