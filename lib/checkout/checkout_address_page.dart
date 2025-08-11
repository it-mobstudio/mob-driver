// lib/pages/checkout_address_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m_o_b_demand_side/checkout/checkout_payment_page.dart';
import '../widgets/main_scaffold.dart';

class CheckoutAddressPage extends StatelessWidget {
  static const routeName = 'CheckoutAddressPage';
  static const routePath = '/checkout/address';

  const CheckoutAddressPage({super.key});

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
                  _topBar(context, 'Add address detail'),
                  const SizedBox(height: 8),
                  _addressCard(
                      title: 'Deliver to: Carlos Sainz', onChange: () {}),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(value: false, onChanged: (_) {}),
                      Text('Use same address for delivery and billing',
                          style: GoogleFonts.inter(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _addressCard(
                      title: 'Billing to: Carlos Sainz',
                      onChange: () {},
                      showGst: true),
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
                label: 'Save and continue',
                onPressed: () {
                  GoRouter.of(context).go(CheckoutPaymentPage.routePath);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, String title) {
    return Row(
      children: [
        IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        Text(title,
            style:
                GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _addressCard(
      {required String title,
      required VoidCallback onChange,
      bool showGst = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text(title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
            TextButton(onPressed: onChange, child: const Text('Change')),
          ]),
          if (showGst)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('GST NO: 18AABCU9603R1ZM',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          Text(
              '10 Downing Street, 4th floor, Infront of westend mall, Chennai, 600005',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF6C7C8C))),
          const SizedBox(height: 6),
          Text('+91 9876554324',
              style: GoogleFonts.inter(
                  fontSize: 13, color: const Color(0xFF6C7C8C))),
        ],
      ),
    );
  }

  Widget _viewCouponsTile() {
    return Container(
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
  }

  Widget _orderDetailsCard(
      {required double subtotal,
      required double shipping,
      required double tax,
      required double savings}) {
    return Container(
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
          _kv('Savings', savings, isSaving: true),
          const Divider(height: 20),
          _kv('Total to pay', subtotal + shipping + tax - savings,
              isBold: true),
        ],
      ),
    );
  }

  Widget _earnPointsStrip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('You will earn 🪙 1150 points on this purchase',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
    );
  }

  Widget _kv(String k, double v, {bool isSaving = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(k,
              style: GoogleFonts.inter(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
          const Spacer(),
          Text('₹ ${v.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: isSaving ? Colors.green : null,
              )),
        ],
      ),
    );
  }

  Widget _bottomCTA({required String label, required VoidCallback onPressed}) {
    return Positioned(
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
}
