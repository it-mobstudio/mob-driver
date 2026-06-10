import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/orders/order_detail_page.dart';
import 'package:m_o_b_demand_side/widgets/main_scaffold.dart';

class OrdersPage extends StatelessWidget {
  static const String routeName = 'OrdersPage';
  static const String routePath = '/orders';

  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 3,
      showLocationheader: false,
      showBackButton: true,
      headerBackgroundColor: const Color(0xFFE8F2EF),
      searchHintText: 'Search for product, category, brand..',
      child: _OrdersBody(),
    );
  }
}

class _OrdersBody extends StatelessWidget {
  // Sample data — replace with real data source
  static final List<_OrderData> _orders = [
    _OrderData(
      orderId: 'MOB9867855HJS6',
      amount: '₹ 31250',
      placedOn: 'Placed on: 30 Jan 2022',
      status: OrderStatus.arriving,
      statusText: 'Arriving between 31 Jan - 3 Feb',
      statusSubText: 'This order contains 3 shipments',
      ctaText: 'Track 2 shipments',
      points: '328 points',
      pointsSubText: '(It will be added)',
      projectBanner: null,
    ),
    _OrderData(
      orderId: 'MOB9867855HJS6',
      amount: '₹ 31250',
      placedOn: 'Placed on: 30 Jan 2022',
      status: OrderStatus.delivered,
      statusText: 'Delivered',
      statusSubText: 'on 1 Oct, 2022',
      ctaText: 'RATE ITEMS',
      points: '328 points',
      pointsSubText: '(It will be added)',
      projectBanner: 'Project: D-201 Apartment',
    ),
    _OrderData(
      orderId: 'MOB9867855HJS6',
      amount: '₹ 31250',
      placedOn: 'Placed on: 30 Jan 2022',
      status: OrderStatus.delivered,
      statusText: 'Delivered',
      statusSubText: 'on 1 Oct, 2022',
      ctaText: 'RATE ITEMS',
      points: '328 points',
      pointsSubText: '(It will be added)',
      projectBanner: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "My orders" title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'My orders',
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0A243F),
              height: 28 / 19,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Search all RFQ's
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search,
                  size: 18,
                  color: const Color(0xFF6C7C8C),
                ),
                const SizedBox(width: 8),
                Text(
                  "Search all RFQ's",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6C7C8C),
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _FilterChip(label: 'Sort by'),
              const SizedBox(width: 8),
              _FilterChip(label: 'Members'),
              const SizedBox(width: 8),
              _FilterChip(label: 'Order time'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Orders list
        Expanded(
          child: ColoredBox(
            color: const Color(0xFFF0F0F0),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.projectBanner != null) ...[
                      _ProjectBanner(label: order.projectBanner!),
                      const SizedBox(height: 8),
                    ],
                    _OrderCard(order: order),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Filter chip
// ──────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDEDEDE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A243F),
              height: 18 / 12,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: Color(0xFF0A243F),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Project banner
// ──────────────────────────────────────────────
class _ProjectBanner extends StatelessWidget {
  final String label;
  const _ProjectBanner({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF01A685),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 18 / 12,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Order data model
// ──────────────────────────────────────────────
enum OrderStatus { arriving, delivered }

class _OrderData {
  final String orderId;
  final String amount;
  final String placedOn;
  final OrderStatus status;
  final String statusText;
  final String statusSubText;
  final String ctaText;
  final String points;
  final String pointsSubText;
  final String? projectBanner;

  const _OrderData({
    required this.orderId,
    required this.amount,
    required this.placedOn,
    required this.status,
    required this.statusText,
    required this.statusSubText,
    required this.ctaText,
    required this.points,
    required this.pointsSubText,
    required this.projectBanner,
  });
}

// ──────────────────────────────────────────────
// Order card
// ──────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final _OrderData order;
  const _OrderCard({required this.order});

  static const _placeholderImages = [
    'https://via.placeholder.com/32',
    'https://via.placeholder.com/32',
    'https://via.placeholder.com/32',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0D4DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: order ID + amount ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderId,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                Text(
                  order.amount,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                  ),
                ),
              ],
            ),
          ),

          // ── Placed on ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            child: Text(
              order.placedOn,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF67696D),
              ),
            ),
          ),

          // ── Divider ──
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 0.5, color: Color(0xFFD0D4DC)),
          ),

          // ── Status ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.statusText,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A243F),
                          height: 22 / 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.statusSubText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF67696D),
                          height: 18 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF0A243F),
                  size: 18,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Product thumbnails ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ..._placeholderImages.map(
                  (url) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+3',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6C7C8C),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── CTA button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: order.status == OrderStatus.arriving
                ? _TrackButton(text: order.ctaText)
                : _RateItemsButton(),
          ),

          const SizedBox(height: 12),

          // ── Points row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFC107),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  order.points,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                    height: 18 / 12,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  order.pointsSubText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6C7C8C),
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Track shipments button ──
class _TrackButton extends StatelessWidget {
  final String text;
  const _TrackButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => context.push(OrderDetailPage.routePath),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0360E5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Rate Items button ──
class _RateItemsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDEDEDE), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFC107),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'RATE ITEMS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'get',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6C7C8C),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFC107),
                  size: 16,
                ),
                const SizedBox(width: 2),
                Text(
                  '5',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
