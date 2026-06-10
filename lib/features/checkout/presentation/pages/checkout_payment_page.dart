import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/order_placed_page.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_sections.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';

class CheckoutPaymentPage extends StatefulWidget {
  static const routeName = 'CheckoutPaymentPage';
  static const routePath = '/checkout/payment';

  const CheckoutPaymentPage({super.key});

  @override
  State<CheckoutPaymentPage> createState() => _CheckoutPaymentPageState();
}

class _CheckoutPaymentPageState extends State<CheckoutPaymentPage> {
  bool _useMobstar = false;
  bool _useMobwallet = false;
  int _paymentOption = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            return switch (state) {
              CartInitial() || CartLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
              CartError(:final message) => ErrorStateView(
                  title: 'Unable to load payment details',
                  message: message,
                  onRetry: () =>
                      context.read<CartBloc>().add(CartLoadRequested()),
                ),
              CartRequiresLogin() => const Center(
                  child: Text('Please login to continue.'),
                ),
              CartLoaded(:final summary) => Column(
                  children: [
                    _PaymentHeader(onBack: () => _goBack(context)),
                    Expanded(
                      child: Container(
                        color: const Color(0xFFF0F0F0),
                        child: Stack(
                          children: [
                            ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 20, 16, 118),
                              children: [
                                const _SectionTitle('Select redeem option'),
                                const SizedBox(height: 16),
                                _RedeemOptionsCard(
                                  useMobstar: _useMobstar,
                                  useMobwallet: _useMobwallet,
                                  onMobstarChanged: () => setState(
                                      () => _useMobstar = !_useMobstar),
                                  onMobwalletChanged: () => setState(
                                      () => _useMobwallet = !_useMobwallet),
                                ),
                                const SizedBox(height: 20),
                                const _SectionTitle(
                                    'Please select payment option'),
                                const SizedBox(height: 12),
                                _MobCreditPaymentCard(
                                  selected: _paymentOption == 0,
                                  onTap: () =>
                                      setState(() => _paymentOption = 0),
                                ),
                                const SizedBox(height: 20),
                                _RazorpayTile(
                                  selected: _paymentOption == 1,
                                  onTap: () =>
                                      setState(() => _paymentOption = 1),
                                ),
                                const SizedBox(height: 20),
                                const ViewCouponsTile(),
                                const SizedBox(height: 20),
                                OrderDetailsCard(
                                  subtotal: summary.subtotal,
                                  shipping: summary.shipping,
                                  tax: summary.tax,
                                  savings: summary.savings,
                                  total: summary.total,
                                  rewardPoints: summary.rewardPoints,
                                ),
                              ],
                            ),
                            BottomCheckoutBar(
                              label: 'Place your order and pay',
                              onProceed: () => GoRouter.of(context)
                                  .go(OrderPlacedPage.routePath),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            };
          },
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/checkout/review');
    }
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Payment details',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 22 / 15,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: const SizedBox(
                width: 48,
                height: 50,
                child: Icon(
                  Icons.arrow_back,
                  color: Color(0xFF0A243F),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: const Color(0xFF0A243F),
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 20 / 14,
      ),
    );
  }
}

class _RedeemOptionsCard extends StatelessWidget {
  const _RedeemOptionsCard({
    required this.useMobstar,
    required this.useMobwallet,
    required this.onMobstarChanged,
    required this.onMobwalletChanged,
  });

  final bool useMobstar;
  final bool useMobwallet;
  final VoidCallback onMobstarChanged;
  final VoidCallback onMobwalletChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _RedeemRow(
            checked: useMobstar,
            amount: '₹1125',
            icon: SvgPicture.asset(
              'assets/images/points.svg',
              width: 16,
              height: 16,
            ),
            label: '4500 mobstar points',
            onTap: onMobstarChanged,
          ),
          const Divider(height: 1, color: Color(0xFFE5E8EE)),
          _RedeemRow(
            checked: useMobwallet,
            amount: '₹100',
            icon: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFFC9825E),
              size: 16,
            ),
            label: 'mobwallet balance',
            onTap: onMobwalletChanged,
          ),
        ],
      ),
    );
  }
}

class _RedeemRow extends StatelessWidget {
  const _RedeemRow({
    required this.checked,
    required this.amount,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool checked;
  final String amount;
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const SizedBox(width: 12),
            _CheckboxMark(checked: checked),
            const SizedBox(width: 12),
            Text(
              amount,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 20 / 13,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 18, color: const Color(0xFFD9D9D9)),
            const SizedBox(width: 12),
            icon,
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 20 / 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _MobCreditPaymentCard extends StatelessWidget {
  const _MobCreditPaymentCard({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _RadioMark(selected: selected),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    const TextSpan(
                      children: [
                        TextSpan(text: 'Pay '),
                        TextSpan(
                          text: '₹26092.00',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' out of '),
                        TextSpan(
                          text: '₹90000.00',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' mobCREDIT available'),
                      ],
                    ),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 20 / 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MobCreditInfo(),
          ],
        ),
      ),
    );
  }
}

class _MobCreditInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F6C6), Color(0xFFD4F4F3)],
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 104),
                  child: Text(
                    'Zero% interest for 21 days',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 18 / 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '21.9% per year after 21 days of transaction confirmation',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF67696D),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 16 / 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Late fee of ₹150 + 36.5% per year on loan amount if repayment is not made within 90 days of transaction confirmation.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF67696D),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 16 / 11,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              height: 24,
              width: 96,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E20),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/images/mobcreditlogo.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RazorpayTile extends StatelessWidget {
  const _RazorpayTile({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _RadioMark(selected: selected),
            const SizedBox(width: 12),
            Text(
              'Pay using Razorpay',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 20 / 13,
              ),
            ),
            const Spacer(),
            Text(
              'Razorpay',
              style: GoogleFonts.inter(
                color: const Color(0xFF0057A8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxMark extends StatelessWidget {
  const _CheckboxMark({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? const Color(0xFF0360E5) : Colors.white,
        border: Border.all(
          color:
              checked ? const Color(0xFF0360E5) : const Color(0xFF767C8F),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: checked
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: selected ? const Color(0xFF0360E5) : const Color(0xFF767C8F),
        ),
      ),
      child: selected
          ? const Center(
              child: SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF0360E5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
