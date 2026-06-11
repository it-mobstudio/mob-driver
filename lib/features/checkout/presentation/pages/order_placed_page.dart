// lib/checkout/order_placed_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';

class OrderPlacedPage extends StatefulWidget {
  static const routeName = 'OrderPlacedPage';
  static const routePath = '/checkout/success';

  const OrderPlacedPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderPlacedPage> createState() => _OrderPlacedPageState();
}

class _OrderPlacedPageState extends State<OrderPlacedPage> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _topGreenBanner(context),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pointsCard(),
                  const SizedBox(height: 20),
                  _experienceSection(),
                  const SizedBox(height: 20),
                  _orderInfoSection(),
                  const SizedBox(height: 16),
                  _viewOrderBtn(context),
                  const SizedBox(height: 24),
                  _nextStepsSection(),
                  const SizedBox(height: 16),
                  _referCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Green header ──────────────────────────────────────────────────────────

  Widget _topGreenBanner(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF4FB589),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, topPad + 24, 16, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Thank you! Your order has been placed',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 20 / 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Points card ───────────────────────────────────────────────────────────

  Widget _pointsCard() => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8E6B6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFAB00),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1150 points',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                    height: 22 / 15,
                  ),
                ),
                Text(
                  'on the way!',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A243F).withOpacity(0.8),
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // ── Star rating section ───────────────────────────────────────────────────

  Widget _experienceSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was your experience?',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFAB00),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  // ── Order info + product thumbnails ──────────────────────────────────────

  Widget _orderInfoSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.orderId.isNotEmpty
                ? 'Order ID: ${widget.orderId}'
                : 'Order confirmed',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A243F).withOpacity(0.6),
              height: 18 / 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Estimated delivery in 1–4 working days',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
              height: 22 / 15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your items are on the way',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A243F),
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(3, (_) => _productThumb()),
              _moreChip(),
            ],
          ),
        ],
      );

  Widget _productThumb() => Container(
        width: 64,
        height: 64,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDEDEDE)),
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Color(0xFFB0B8C1),
          size: 28,
        ),
      );

  Widget _moreChip() => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDEDEDE)),
        ),
        child: Center(
          child: Text(
            '+5\nmore',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A243F).withOpacity(0.6),
              height: 1.4,
            ),
          ),
        ),
      );

  // ── View order details button ─────────────────────────────────────────────

  Widget _viewOrderBtn(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFDEDEDE)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(48),
            ),
          ),
          child: Text(
            'View order details',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
              height: 22 / 15,
            ),
          ),
        ),
      );

  // ── Next steps ────────────────────────────────────────────────────────────

  Widget _nextStepsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next steps',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
              height: 21 / 14,
            ),
          ),
          const SizedBox(height: 16),
          _nextStep(
            '1',
            Icons.inventory_2_outlined,
            'Sorting your material to check assured quality requirement',
          ),
          const SizedBox(height: 12),
          _nextStep(
            '2',
            Icons.local_shipping_outlined,
            'Allocating vehicle for super fast delivery',
          ),
          const SizedBox(height: 12),
          _nextStep(
            '3',
            Icons.location_on_outlined,
            'Product delivered at your address',
          ),
        ],
      );

  Widget _nextStep(String num, IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(icon, size: 36, color: const Color(0xFF4FB589)),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF4FB589)),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        num,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4FB589),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A243F),
                height: 18 / 12,
              ),
            ),
          ),
        ],
      );

  // ── Referral card ─────────────────────────────────────────────────────────

  Widget _referCard() => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F2FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Refer a friend and get ₹500 each',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A243F),
                      height: 22 / 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For every friend you refer, you get ₹500 and your friend gets ₹500 after their first order.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF0A243F).withOpacity(0.7),
                      height: 20 / 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      side: const BorderSide(color: Color(0xFF0A243F)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Refer a friend',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0A243F),
                        height: 18 / 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.groups_rounded,
              size: 90,
              color: const Color(0xFF0A243F).withOpacity(0.25),
            ),
          ],
        ),
      );
}
