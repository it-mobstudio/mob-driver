// lib/pages/checkout_order_review_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/main_scaffold.dart';
import 'checkout_payment_page.dart';

class CheckoutOrderReviewPage extends StatelessWidget {
  static const routeName = 'CheckoutOrderReviewPage';
  static const routePath = '/checkout/review';

  const CheckoutOrderReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _topBar(context, 'Order review'),
                  const SizedBox(height: 8),
                  _summaryChip(),
                  const SizedBox(height: 12),
                  _sellerBlock('BENG-098', [
                    _itemTile(
                        1,
                        'Hindware 121 mm Round Brass Silver Wall Mount Overhead Rain Shower F1…',
                        4250),
                    _itemTile(
                        1,
                        'Hindware 4 inch Round Brass Silver Wall Mount Overhead Shower, F160119',
                        1533),
                  ]),
                  const SizedBox(height: 12),
                  _sellerBlock('BENG-004', [
                    _itemTile(
                        1,
                        'Hindware Overhead Shower 150 mm White ABS Round, F160216',
                        2325),
                    _itemTile(
                        1,
                        'Hindware Single Flow Overhead Round Shower Single Flow, Rain Flow, 23…',
                        3175),
                  ]),
                  const SizedBox(height: 12),
                  _viewCouponsTile(),
                  const SizedBox(height: 12),
                  _orderDetailsCard(
                      subtotal: 26567, shipping: 500, tax: 433, savings: 1055),
                  const SizedBox(height: 12),
                  _earnPointsStrip(),
                ],
              ),
              _bottomCTA(
                'Continue',
                () => GoRouter.of(context).go(CheckoutPaymentPage.routePath),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext c, String title) => Row(
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(c)),
          Text(title,
              style:
                  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _summaryChip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Text('🧺  4 items  from 2 verified stores',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
    );
  }

  Widget _sellerBlock(String seller, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6ECF2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFE1F4FF), Color(0xFFD6F2FF)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text('Store delivery',
                    style: GoogleFonts.inter(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('₹ 250',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sold by $seller',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF6C7C8C))),
                const SizedBox(height: 4),
                Text('Arrives by tomorrow evening',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...items,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemTile(int qty, String title, double price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Container(
            height: 26,
            width: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(6)),
            child: Text('$qty',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8EEF5)),
            ),
            child: const Icon(Icons.shower_outlined),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          const SizedBox(width: 10),
          Text('₹${price.toStringAsFixed(0)}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _viewCouponsTile() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EEF5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer_outlined),
            const SizedBox(width: 10),
            Text('View all coupons', style: GoogleFonts.inter(fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right),
          ],
        ),
      );

  Widget _orderDetailsCard(
          {required double subtotal,
          required double shipping,
          required double tax,
          required double savings}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EEF5)),
        ),
        child: Column(
          children: [
            _kv('Subtotal', subtotal),
            _kv('Shipping', shipping),
            _kv('Total tax', tax),
            _kv('Savings', savings, saving: true),
            const Divider(height: 20),
            _kv('Total to pay', subtotal + shipping + tax - savings,
                bold: true),
          ],
        ),
      );

  Widget _earnPointsStrip() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF8EE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('You will earn 🪙 1150 points on this purchase',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      );

  Widget _kv(String k, double v, {bool saving = false, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(k,
                style: GoogleFonts.inter(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
            const Spacer(),
            Text('₹ ${v.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: saving ? Colors.green : null,
                )),
          ],
        ),
      );

  Widget _bottomCTA(String label, VoidCallback onPressed) => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.white,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      );
}
