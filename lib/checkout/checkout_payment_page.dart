// lib/pages/checkout_payment_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/main_scaffold.dart';
import '../../checkout/order_placed_page.dart';

class CheckoutPaymentPage extends StatefulWidget {
  static const routeName = 'CheckoutPaymentPage';
  static const routePath = '/checkout/payment';

  const CheckoutPaymentPage({super.key});

  @override
  State<CheckoutPaymentPage> createState() => _CheckoutPaymentPageState();
}

class _CheckoutPaymentPageState extends State<CheckoutPaymentPage> {
  bool useMobstar = true;
  bool useMobwallet = true;
  int option = 0; // 0 = mobCREDIT, 1 = Razorpay

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
                  _topBar(context, 'Payment details'),
                  const SizedBox(height: 8),
                  _redeemSection(),
                  const SizedBox(height: 12),
                  RadioGroup<int>(
                    groupValue: option,
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => option = v);
                      }
                    },
                    child: Column(
                      children: [
                        _paymentOptionCard(),
                        const SizedBox(height: 10),
                        _razorpayTile(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _viewCouponsTile(),
                  const SizedBox(height: 12),
                  _orderDetailsCard(),
                ],
              ),
              _bottomCTA('Place your order and pay',
                  () => GoRouter.of(context).go(OrderPlacedPage.routePath)),
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

  Widget _redeemSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select redeem option',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _redeemTile(
          checked: useMobstar,
          onChanged: (v) => setState(() => useMobstar = v ?? false),
          label: '₹1125      🪙 4500 mobstar points',
        ),
        const SizedBox(height: 8),
        _redeemTile(
          checked: useMobwallet,
          onChanged: (v) => setState(() => useMobwallet = v ?? false),
          label: '₹100      🧾 mobwallet balance',
        ),
      ],
    );
  }

  Widget _redeemTile(
      {required bool checked,
      required ValueChanged<bool?> onChanged,
      required String label}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Row(
        children: [
          Checkbox(value: checked, onChanged: onChanged),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _paymentOptionCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2B7FFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Radio<int>(value: 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pay ₹26092.00 out of ₹90000.00 mobCREDIT available',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _mobCreditBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobCreditBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFFE1F4FF), Color(0xFFD6F2FF)]),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Zero% interest for 21 days',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.black, borderRadius: BorderRadius.circular(6)),
              child: Text('mobCREDIT',
                  style: GoogleFonts.inter(color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            '21.9% per year after 21 days of transaction confirmation\nLate fee of ₹150 + 36.5% per year on loan amount if repayment is not made within 90 days of transaction confirmation.',
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _razorpayTile() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Row(
        children: [
          const Radio<int>(value: 1),
          const SizedBox(width: 8),
          Text('Pay using Razorpay',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          const Spacer(),
          const Icon(Icons.payments_outlined),
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

  Widget _orderDetailsCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EEF5)),
        ),
        child: Column(
          children: [
            _kv('Subtotal', 26567),
            _kv('Shipping', 500),
            _kv('Total tax', 433),
            _kv('Savings', 1055, saving: true),
            const Divider(height: 20),
            _kv('mobSTAR points', -1125, saving: true),
            _kv('mobWALLET', -100, saving: true),
            const Divider(height: 20),
            _kv('Total to pay', 26567, bold: true),
            const SizedBox(height: 8),
            Text('You will earn 🪙 1150 points on this purchase',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
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
            Text(
              '${saving && v < 0 ? '- ' : ''}₹ ${v.abs().toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: saving ? Colors.green : null,
              ),
            ),
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
