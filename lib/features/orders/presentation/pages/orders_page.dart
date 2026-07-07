import 'dart:async';

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
import 'package:m_o_b_demand_side/shared/image_shimmer.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'order_detail_page.dart';
import 'order_tracking_page.dart';

part 'orders_page_cards.dart';
part 'orders_page_controls.dart';

const List<({String label, String key})> kOrderFilterOptions = [
  (label: 'Active', key: 'Order Created'),
  (label: 'Delivered', key: 'Order Delivered'),
  (label: 'Cancelled', key: 'cancelled'),
  (label: "RFQ's", key: 'rfq'),
];

class OrdersPage extends StatefulWidget {
  static const String routeName = 'OrdersPage';
  static const String routePath = '/orders';

  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrdersBloc _ordersBloc;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  String? _activeFilterLabel;

  @override
  void initState() {
    super.initState();
    _ordersBloc = sl<OrdersBloc>()..add(OrdersLoadRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _ordersBloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _ordersBloc.add(OrdersNextPageRequested());
    }
  }

  void _onSearchChanged(String value) {
    if (_activeFilterLabel != null) {
      setState(() => _activeFilterLabel = null);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _ordersBloc.add(OrdersQueryChanged(value.trim()));
    });
  }

  void _onSearchCleared() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _activeFilterLabel = null);
    _ordersBloc.add(OrdersLoadRequested());
  }

  void _onFilterSelected(String key, String label) {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _activeFilterLabel = label);
    _ordersBloc.add(OrdersQueryChanged(key));
  }

  void _onFilterCleared() {
    setState(() => _activeFilterLabel = null);
    _ordersBloc.add(OrdersLoadRequested());
  }

  Future<void> _openFilterSheet() async {
    final selected = await showModalBottomSheet<({String label, String key})?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _OrderFilterSheet(activeLabel: _activeFilterLabel),
    );
    if (selected == null) return;
    if (selected.key.isEmpty) {
      _onFilterCleared();
    } else {
      _onFilterSelected(selected.key, selected.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersBloc>.value(
      value: _ordersBloc,
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
                        OrdersLoaded(:final orders, :final isLoadingMore) =>
                          ListView(
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                              16,
                              12,
                              16,
                              24 +
                                  kBottomNavBarHeight +
                                  MediaQuery.paddingOf(context).bottom,
                            ),
                            children: [
                              _OrdersSearch(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                onCleared: _onSearchCleared,
                              ),
                              const SizedBox(height: 12),
                              _FilterButton(
                                activeLabel: _activeFilterLabel,
                                onTap: _openFilterSheet,
                              ),
                              const SizedBox(height: 16),
                              if (orders.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 48,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No orders yet.',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF596378),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              else ...[
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
                                if (isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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
    );
  }

  void _goBack(BuildContext context) {
    // The header only shows this when canPop() is true, but guard here too
    // in case it's ever wired up elsewhere. Falls back to My account for
    // direct visits where there is no stack entry to pop.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/myaccount');
    }
  }
}
