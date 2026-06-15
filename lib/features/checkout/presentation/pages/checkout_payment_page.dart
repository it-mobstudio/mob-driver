import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/entities/checkout_entity.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/order_placed_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/payment_failed_page.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
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
  bool _redeemInitialized = false;
  // -1 = none selected, 0 = mobCredit, 1 = Razorpay
  int _paymentOption = -1;
  RazorpayOrderEntity? _razorpayEntity; // populated when radio is selected

  late final CheckoutBloc _checkoutBloc;
  late final Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _checkoutBloc = sl<CheckoutBloc>();
    _razorpay = Razorpay();
    if (!kIsWeb) {
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) _razorpay.clear();
    // Reset redeem state on navigate away (mirrors web handleGetCartData reset)
    final cartBloc = context.read<CartBloc>();
    final cartState = cartBloc.state;
    if (cartState is CartLoaded) {
      cartBloc.add(CartRedeemUpdateRequested(
        cartId: cartState.summary.cartId,
        useWallet: false,
        walletAmount: 0,
        usePoints: false,
        points: 0,
      ));
    }
    _checkoutBloc.close();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _checkoutBloc.add(
      CheckoutRazorpayStatusCheckRequested(
        platformOrderId: _razorpayEntity?.platformOrderId ?? '',
        merchantPaymentRefId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        transactionId: response.signature ?? '',
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _checkoutBloc.add(
      CheckoutRazorpayPaymentFailed(
        response.message ?? 'Payment failed. Please try again.',
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  // Replace with your Razorpay key (rzp_test_xxx or rzp_live_xxx)
  static const _razorpayKey = 'rzp_test_fjQ8CCi7188hME';

  // Called when Razorpay radio is tapped — triggers order creation immediately
  void _onRazorpaySelected(String cartId) {
    setState(() {
      _paymentOption = 1;
      _razorpayEntity = null; // clear stale entity while new one loads
    });
    _checkoutBloc.add(
      CheckoutRazorpayOrderRequested(cartId: int.tryParse(cartId) ?? 0),
    );
  }

  void _openRazorpayGateway(RazorpayOrderEntity entity) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Razorpay is only available on the mobile app.')),
      );
      return;
    }
    final options = <String, dynamic>{
      'key': _razorpayKey,
      'amount': entity.amount,
      'currency': entity.currency,
      'name': entity.name.isNotEmpty ? entity.name : 'MOB',
      'order_id': entity.razorpayOrderId,
      'description': 'Order payment',
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      _checkoutBloc.add(CheckoutRazorpayPaymentFailed(
          'Could not open payment gateway. Please try again.'));
    }
  }

  void _onProceed(BuildContext context, String cartId, double total, CartSummaryEntity summary) {
    if (_paymentOption == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method to continue.')),
      );
      return;
    }
    if (_paymentOption == 1) {
      final entity = _razorpayEntity;
      if (entity != null) {
        _openRazorpayGateway(entity);
      }
    } else {
      _checkoutBloc.add(
        CheckoutOrderPlaceRequested(
          payload: {
            'payment_method': 'mob_credit',
            'use_mob_star': _useMobstar,
            'use_mob_wallet': _useMobwallet,
            if (_useMobstar && summary.rewardPoints > 0) 'points': summary.rewardPoints,
            if (_useMobwallet && summary.walletBalance > 0) 'wallet_amount': summary.walletBalance,
            'total': total,
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _checkoutBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, cartState) {
              return switch (cartState) {
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
                CartLoaded(:final summary, :final isRedeemUpdating) =>
                  Builder(builder: (_) {
                    // Seed checkboxes from API flags on first load
                    if (!_redeemInitialized) {
                      _redeemInitialized = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _useMobwallet = summary.useWallet;
                            _useMobstar = summary.usePoints;
                          });
                        }
                      });
                    }
                    return BlocConsumer<CheckoutBloc, CheckoutState>(
                    listener: (context, checkoutState) {
                      if (checkoutState is CheckoutRazorpayOrderCreated) {
                        // Store the entity — gateway opens when user taps "Place order"
                        setState(() => _razorpayEntity = checkoutState.entity);
                      } else if (checkoutState is CheckoutOrderPlaced) {
                        GoRouter.of(context).go(
                          OrderPlacedPage.routePath,
                          extra: checkoutState.order.orderId,
                        );
                      } else if (checkoutState is CheckoutPaymentFailed) {
                        GoRouter.of(context).go(
                          PaymentFailedPage.routePath,
                          extra: checkoutState.message,
                        );
                      } else if (checkoutState is CheckoutError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(checkoutState.message),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    },
                    builder: (context, checkoutState) {
                      final isLoading = checkoutState is CheckoutLoading;
                      return Column(
                        children: [
                          _PaymentHeader(onBack: () => _goBack(context)),
                          Expanded(
                            child: Container(
                              color: const Color(0xFFF0F0F0),
                              child: Stack(
                                children: [
                                  ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 20, 16, 118),
                                    children: [
                                      const _SectionTitle(
                                          'Select redeem option'),
                                      const SizedBox(height: 16),
                                      _RedeemOptionsCard(
                                        useMobstar: _useMobstar,
                                        useMobwallet: _useMobwallet,
                                        mobstarPoints: summary.rewardPoints,
                                        mobstarAmount: summary.mobstarAmount,
                                        walletBalance: summary.walletBalance,
                                        applicableWalletAmount: summary.applicableWalletAmount,
                                        isUpdating: isRedeemUpdating,
                                        onMobstarChanged: summary.rewardPoints > 0
                                            ? () {
                                                final next = !_useMobstar;
                                                setState(() => _useMobstar = next);
                                                context.read<CartBloc>().add(
                                                  CartRedeemUpdateRequested(
                                                    cartId: summary.cartId,
                                                    useWallet: _useMobwallet,
                                                    walletAmount: summary.applicableWalletAmount,
                                                    usePoints: next,
                                                    points: next ? summary.rewardPoints : 0,
                                                  ),
                                                );
                                              }
                                            : null,
                                        onMobwalletChanged: summary.walletBalance > 0
                                            ? () {
                                                final next = !_useMobwallet;
                                                setState(() => _useMobwallet = next);
                                                context.read<CartBloc>().add(
                                                  CartRedeemUpdateRequested(
                                                    cartId: summary.cartId,
                                                    useWallet: next,
                                                    walletAmount: next ? summary.applicableWalletAmount : 0,
                                                    usePoints: _useMobstar,
                                                    points: _useMobstar ? summary.rewardPoints : 0,
                                                  ),
                                                );
                                              }
                                            : null,
                                      ),
                                      const SizedBox(height: 20),
                                      const _SectionTitle(
                                          'Please select payment option'),
                                      const SizedBox(height: 12),
                                      _MobCreditPaymentCard(
                                        selected: _paymentOption == 0,
                                        total: summary.total,
                                        onTap: () => setState(() {
                                          _paymentOption = 0;
                                          _razorpayEntity = null;
                                        }),
                                      ),
                                      const SizedBox(height: 20),
                                      _RazorpayTile(
                                        selected: _paymentOption == 1,
                                        onTap: () => _onRazorpaySelected(
                                            summary.cartId),
                                      ),
                                      const SizedBox(height: 20),
                                      OrderDetailsCard(
                                        subtotal: summary.subtotal,
                                        shipping: summary.shipping,
                                        tax: summary.tax,
                                        savings: summary.savings,
                                        total: summary.total,
                                        earningPoints: summary.earningPoints,
                                        mobstarApplied: _useMobstar ? summary.mobstarAmount : null,
                                        walletApplied: _useMobwallet ? summary.applicableWalletAmount : null,
                                      ),
                                    ],
                                  ),
                                  BottomCheckoutBar(
                                    label: 'Place your order and pay',
                                    isLoading: isLoading,
                                    onProceed: () => _onProceed(
                                        context, summary.cartId, summary.total, summary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  }),
              };
            },
          ),
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
    required this.mobstarPoints,
    required this.mobstarAmount,
    required this.walletBalance,
    required this.applicableWalletAmount,
    required this.onMobstarChanged,
    required this.onMobwalletChanged,
    this.isUpdating = false,
  });

  final bool useMobstar;
  final bool useMobwallet;
  final int mobstarPoints;
  final double mobstarAmount;
  final double walletBalance;
  final double applicableWalletAmount;
  final bool isUpdating;
  final VoidCallback? onMobstarChanged;
  final VoidCallback? onMobwalletChanged;

  @override
  Widget build(BuildContext context) {
    final hasMobstar = mobstarPoints > 0;
    final hasWallet = walletBalance > 0;
    final mobstarLabel = hasMobstar
        ? '$mobstarPoints (₹${mobstarAmount.toStringAsFixed(2)}) mobstar points'
        : 'No mobstar points available';
    final walletLabel = hasWallet
        ? '₹${walletBalance.toStringAsFixed(2)} mobwallet balance'
        : 'No mobwallet balance';

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _RedeemRow(
                checked: useMobstar,
                enabled: hasMobstar && !isUpdating,
                amount: '₹${mobstarAmount.toStringAsFixed(2)}',
                icon: SvgPicture.asset(
                  'assets/images/points.svg',
                  width: 16,
                  height: 16,
                ),
                label: mobstarLabel,
                onTap: isUpdating ? null : onMobstarChanged,
              ),
              const Divider(height: 1, color: Color(0xFFE5E8EE)),
              _RedeemRow(
                checked: useMobwallet,
                enabled: hasWallet && !isUpdating,
                amount: '₹${applicableWalletAmount.toStringAsFixed(2)}',
                icon: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFFC9825E),
                  size: 16,
                ),
                label: walletLabel,
                onTap: isUpdating ? null : onMobwalletChanged,
              ),
            ],
          ),
        ),
        if (isUpdating)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RedeemRow extends StatelessWidget {
  const _RedeemRow({
    required this.checked,
    required this.enabled,
    required this.amount,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool checked;
  final bool enabled;
  final String amount;
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const SizedBox(width: 12),
            _CheckboxMark(checked: checked, enabled: enabled),
            const SizedBox(width: 12),
            Text(
              amount,
              style: GoogleFonts.inter(
                color: enabled ? const Color(0xFF0A243F) : const Color(0xFFB0B4BB),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 20 / 13,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 18, color: const Color(0xFFD9D9D9)),
            const SizedBox(width: 12),
            Opacity(opacity: enabled ? 1.0 : 0.4, child: icon),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: enabled ? const Color(0xFF0A243F) : const Color(0xFFB0B4BB),
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
    required this.total,
    required this.onTap,
  });

  final bool selected;
  final double total;
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
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Pay '),
                        TextSpan(
                          text: '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: ' using mobCREDIT'),
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
  const _CheckboxMark({required this.checked, this.enabled = true});

  final bool checked;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final activeColor = enabled ? const Color(0xFF0360E5) : const Color(0xFFB0B4BB);
    final borderColor = checked ? activeColor : const Color(0xFF767C8F);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? activeColor : Colors.white,
        border: Border.all(color: borderColor),
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
