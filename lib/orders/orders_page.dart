import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/orders/order_detail_page.dart';

part 'orders_page_cards.dart';
part 'orders_page_controls.dart';

class OrdersPage extends StatelessWidget {
  static const String routeName = 'OrdersPage';
  static const String routePath = '/orders';

  const OrdersPage({super.key});

  static const List<_OrderData> _orders = [
    _OrderData(
      amount: '₹1000',
      dateTime: '16 May, 10:25 am',
      points: 100,
      productImages: [
        'assets/images/Brands/Fevicol.webp',
        'assets/images/Brands/Drfixit.webp',
        'assets/images/Brands/Roff.webp',
        'assets/images/Brands/greenply.webp',
        'assets/images/Brands/century.webp',
      ],
    ),
    _OrderData(
      amount: '₹1000',
      dateTime: '16 May, 10:25 am',
      points: 100,
      productImages: [
        'assets/images/Brands/Drfixit.webp',
        'assets/images/Brands/greenply.webp',
        'assets/images/Brands/Fevicol.webp',
        'assets/images/Brands/Roff.webp',
      ],
    ),
    _OrderData(
      amount: '₹1000',
      dateTime: '16 May, 10:25 am',
      points: 100,
      productImages: [
        'assets/images/Brands/Roff.webp',
        'assets/images/Brands/Ultratech.webp',
        'assets/images/Brands/greenply.webp',
      ],
    ),
    _OrderData(
      amount: '₹1000',
      dateTime: '16 May, 10:25 am',
      points: 100,
      project: 'Project: Hotel California',
      productImages: [
        'assets/images/Brands/Fevicol.webp',
        'assets/images/Brands/century.webp',
        'assets/images/Brands/Drfixit.webp',
        'assets/images/Brands/Ultratech.webp',
        'assets/images/Brands/Roff.webp',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _OrdersHeader(onBack: () => _goBack(context)),
            Expanded(
              child: Container(
                color: const Color(0xFFF0F0F0),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    const _OrdersSearch(),
                    const SizedBox(height: 12),
                    const _FilterButton(),
                    const SizedBox(height: 16),
                    ..._orders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _OrderCard(
                          order: order,
                          onTap: () => context.push(OrderDetailPage.routePath),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

class _OrderData {
  const _OrderData({
    required this.amount,
    required this.dateTime,
    required this.productImages,
    required this.points,
    this.project,
  });

  final String amount;
  final String dateTime;
  final List<String> productImages;
  final int points;
  final String? project;
}
