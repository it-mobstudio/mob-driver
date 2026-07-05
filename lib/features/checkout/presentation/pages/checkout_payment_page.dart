import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/entities/checkout_entity.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/order_placed_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/payment_failed_page.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/pages/rupifi_payment_webview_page.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_sections.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

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
  bool _isRupifiHandoffInProgress = false;
  double _lastMobstarApplicableAmount = 0;
  // -1 = none selected, 0 = mobCredit, 1 = Razorpay
  int _paymentOption = -1;
  RazorpayOrderEntity? _razorpayEntity; // populated when radio is selected
  RupifiOrderEntity?
      _rupifiEntity; // populated when mobCREDIT radio is selected
  int? _requestedPaymentOption;
  String? _requestedPaymentCartId;
  double? _requestedPaymentTotal;
  bool _isPaymentOrderRequestInFlight = false;

  late final CheckoutBloc _checkoutBloc;
  late final CartBloc _cartBloc;
  late final Razorpay _razorpay;
  late GoRouter _router;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router = GoRouter.of(context);
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    _checkoutBloc = sl<CheckoutBloc>();
    _cartBloc = context.read<CartBloc>();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    // Reset redeem state on navigate away (mirrors web handleGetCartData reset)
    final cartState = _cartBloc.state;
    if (cartState is CartLoaded) {
      _cartBloc.add(CartRedeemUpdateRequested(
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
    final paymentId = _razorpayValue(
      response.paymentId,
      response.data?['razorpay_payment_id'],
      response.data?['payment_id'],
    );
    final orderId = _razorpayValue(
      response.orderId,
      response.data?['razorpay_order_id'],
      response.data?['order_id'],
      _razorpayEntity?.razorpayOrderId,
    );
    final signature = _razorpayValue(
      response.signature,
      response.data?['razorpay_signature'],
      response.data?['signature'],
    );

    if (paymentId.isEmpty || orderId.isEmpty || signature.isEmpty) {
      final platformOrderId = _razorpayEntity?.platformOrderId ?? '';
      if (platformOrderId.isNotEmpty && orderId.isNotEmpty) {
        _checkoutBloc.add(
          CheckoutRazorpayStatusCheckRequested(
            platformOrderId: platformOrderId,
            merchantPaymentRefId: orderId,
            paymentId: paymentId,
            transactionId: signature,
          ),
        );
        return;
      }

      _checkoutBloc.add(
        CheckoutRazorpayPaymentFailed(
          'Payment completed, but confirmation details were missing. Please contact support.',
        ),
      );
      return;
    }

    _checkoutBloc.add(
      CheckoutRazorpayVerifyRequested(
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
      ),
    );
  }

  String _razorpayValue(
    Object? primary, [
    Object? fallback1,
    Object? fallback2,
    Object? fallback3,
  ]) {
    for (final value in [primary, fallback1, fallback2, fallback3]) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
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

  // Called when mobCREDIT radio is tapped — triggers Rupifi order creation immediately
  void _onMobCreditSelected(String cartId, double total) {
    if (_isRupifiHandoffInProgress) return;
    setState(() {
      _paymentOption = 0;
      _rupifiEntity = null;
      _razorpayEntity = null;
    });
    _requestRupifiOrder(cartId: cartId, total: total);
  }

  Future<void> _openRupifiGateway(RupifiOrderEntity entity) async {
    if (kIsWeb) {
      setState(() => _isRupifiHandoffInProgress = true);
      final uri = Uri.tryParse(entity.paymentUrl);
      if (uri == null) {
        setState(() => _isRupifiHandoffInProgress = false);
        _router.go(
          PaymentFailedPage.routePath,
          extra: 'Invalid mobCREDIT payment URL. Please try again.',
        );
        return;
      }
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!mounted) return;
      if (!opened) {
        setState(() => _isRupifiHandoffInProgress = false);
        _router.go(
          PaymentFailedPage.routePath,
          extra: 'Unable to open mobCREDIT payment. Please try again.',
        );
      }
      return;
    }
    final result = await Navigator.of(context).push<RupifiPaymentResult>(
      MaterialPageRoute(
        builder: (_) => RupifiPaymentWebviewPage(paymentUrl: entity.paymentUrl),
      ),
    );
    if (!mounted) return;
    if (result == null || result.isCancelled) return;
    if (!result.isCompleted) {
      _router.go(
        PaymentFailedPage.routePath,
        extra: 'mobCREDIT payment was not completed. Please try again.',
      );
      return;
    }
    _router.go(
      OrderPlacedPage.routePath,
      extra: result.merchantPaymentRefId ?? '',
    );
  }

  // Called when Razorpay radio is tapped — triggers order creation immediately
  void _onRazorpaySelected(String cartId, double total) {
    if (_isRupifiHandoffInProgress) return;
    setState(() {
      _paymentOption = 1;
      _razorpayEntity = null; // clear stale entity while new one loads
    });
    _requestRazorpayOrder(cartId: cartId, total: total);
  }

  void _requestRazorpayOrder({
    required String cartId,
    required double? total,
  }) {
    _requestedPaymentOption = 1;
    _requestedPaymentCartId = cartId;
    _requestedPaymentTotal = total;
    _isPaymentOrderRequestInFlight = true;
    _checkoutBloc.add(
      CheckoutRazorpayOrderRequested(cartId: int.tryParse(cartId) ?? 0),
    );
  }

  void _requestRupifiOrder({
    required String cartId,
    required double? total,
  }) {
    _requestedPaymentOption = 0;
    _requestedPaymentCartId = cartId;
    _requestedPaymentTotal = total;
    _isPaymentOrderRequestInFlight = true;
    _checkoutBloc.add(CheckoutRupifiOrderRequested(cartId: cartId));
  }

  void _syncPaymentDetailsForSummary(CartSummaryEntity summary) {
    if (!mounted || _isRupifiHandoffInProgress) return;
    if (_isPaymentOrderRequestInFlight) return;

    if (summary.total <= 0) {
      if (_paymentOption != -1 ||
          _razorpayEntity != null ||
          _rupifiEntity != null) {
        setState(() {
          _paymentOption = -1;
          _razorpayEntity = null;
          _rupifiEntity = null;
          _requestedPaymentOption = null;
          _requestedPaymentCartId = null;
          _requestedPaymentTotal = null;
          _isPaymentOrderRequestInFlight = false;
        });
      }
      return;
    }

    final requestMatches = _requestedPaymentCartId == summary.cartId &&
        _requestedPaymentTotal == summary.total &&
        _requestedPaymentOption == _paymentOption;

    if (_paymentOption == 1) {
      final hasFreshOrder = _razorpayEntity != null && requestMatches;
      if (hasFreshOrder) return;
      setState(() => _razorpayEntity = null);
      _requestRazorpayOrder(cartId: summary.cartId, total: summary.total);
    } else if (_paymentOption == 0) {
      final hasFreshOrder = _rupifiEntity != null && requestMatches;
      if (hasFreshOrder) return;
      setState(() => _rupifiEntity = null);
      _requestRupifiOrder(cartId: summary.cartId, total: summary.total);
    }
  }

  void _openRazorpayGateway(RazorpayOrderEntity entity) {
    final options = <String, dynamic>{
      'key': entity.key.isNotEmpty ? entity.key : _razorpayKey,
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

  void _onProceed(BuildContext context, String cartId, double total,
      CartSummaryEntity summary) {
    if (_isRupifiHandoffInProgress) return;
    // Zero total — wallet/points covered the full amount, place order directly
    if (total == 0) {
      _checkoutBloc.add(
        CheckoutOrderPlaceRequested(payload: {
          'cart_id': int.tryParse(cartId) ?? 0,
          'use_wallet': _useMobwallet,
          'wallet_amount': _useMobwallet ? summary.applicableWalletAmount : 0,
          'use_points': _useMobstar,
          'points': _useMobstar ? summary.rewardPoints : 0,
        }),
      );
      return;
    }

    if (_paymentOption == -1) {
      _scaffoldMessenger?.showSnackBar(
        const SnackBar(
            content: Text('Please select a payment method to continue.')),
      );
      return;
    }
    if (_paymentOption == 0) {
      final entity = _rupifiEntity;
      if (entity != null) {
        _openRupifiGateway(entity);
      } else {
        _scaffoldMessenger?.showSnackBar(
          const SnackBar(
              content: Text('Loading payment details, please try again.')),
        );
      }
    } else if (_paymentOption == 1) {
      final entity = _razorpayEntity;
      if (entity != null) {
        _openRazorpayGateway(entity);
      }
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
          child: BlocConsumer<CartBloc, CartState>(
            listener: (context, cartState) {
              if (cartState is CartLoaded && !cartState.isRedeemUpdating) {
                _syncPaymentDetailsForSummary(cartState.summary);
              }
            },
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
                    final mobstarApplicableAmount =
                        _mobstarApplicableAmount(summary);
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
                        // The bloc's async work (Razorpay verify, place_direct_order
                        // + suborder-details fetch, etc.) can still be in flight
                        // when the user navigates away (e.g. back button). If this
                        // page's element is no longer in the tree by the time the
                        // state arrives, bail out instead of looking up an
                        // ancestor on a deactivated context (causes "Duplicate
                        // GlobalKey" / element-lifecycle crashes).
                        if (!mounted) return;
                        if (checkoutState is CheckoutRupifiOrderCreated) {
                          setState(() {
                            _isPaymentOrderRequestInFlight = false;
                            _rupifiEntity = checkoutState.entity;
                          });
                        } else if (checkoutState
                            is CheckoutRazorpayOrderCreated) {
                          // Store the entity — gateway opens when user taps "Place order"
                          setState(() {
                            _isPaymentOrderRequestInFlight = false;
                            _razorpayEntity = checkoutState.entity;
                          });
                        } else if (checkoutState is CheckoutOrderPlaced) {
                          _router.go(
                            OrderPlacedPage.routePath,
                            extra: checkoutState.order,
                          );
                        } else if (checkoutState is CheckoutPaymentFailed) {
                          _router.go(
                            PaymentFailedPage.routePath,
                            extra: checkoutState.message,
                          );
                        } else if (checkoutState is CheckoutError) {
                          _isPaymentOrderRequestInFlight = false;
                          _scaffoldMessenger?.showSnackBar(
                            SnackBar(
                              content: Text(checkoutState.message),
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      },
                      builder: (context, checkoutState) {
                        final isLoading = checkoutState is CheckoutLoading;
                        final isPaymentBlocked =
                            isLoading || _isRupifiHandoffInProgress;
                        final isPaymentMethodReady = summary.total <= 0 ||
                            (_paymentOption == 1 && _razorpayEntity != null) ||
                            (_paymentOption == 0 && _rupifiEntity != null);
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
                                          mobstarAmount:
                                              mobstarApplicableAmount,
                                          mobstarBalanceAmount:
                                              summary.mobstarAmount,
                                          walletBalance: summary.walletBalance,
                                          applicableWalletAmount:
                                              summary.applicableWalletAmount,
                                          isReferralOnlyWallet:
                                              summary.isReferralOnlyWallet,
                                          isWalletUsageLimited:
                                              summary.isWalletUsageLimited,
                                          walletNote: summary.walletNote,
                                          isUpdating: isRedeemUpdating ||
                                              isPaymentBlocked,
                                          onMobstarChanged: summary
                                                      .rewardPoints >
                                                  0
                                              ? () {
                                                  final next = !_useMobstar;
                                                  setState(
                                                      () => _useMobstar = next);
                                                  context.read<CartBloc>().add(
                                                        CartRedeemUpdateRequested(
                                                          cartId:
                                                              summary.cartId,
                                                          useWallet:
                                                              _useMobwallet,
                                                          walletAmount: summary
                                                              .applicableWalletAmount,
                                                          usePoints: next,
                                                          points: next
                                                              ? summary
                                                                  .rewardPoints
                                                              : 0,
                                                        ),
                                                      );
                                                }
                                              : null,
                                          onMobwalletChanged: summary
                                                      .walletBalance >
                                                  0
                                              ? () {
                                                  final next = !_useMobwallet;
                                                  setState(() =>
                                                      _useMobwallet = next);
                                                  context.read<CartBloc>().add(
                                                        CartRedeemUpdateRequested(
                                                          cartId:
                                                              summary.cartId,
                                                          useWallet: next,
                                                          walletAmount: next
                                                              ? summary
                                                                  .applicableWalletAmount
                                                              : 0,
                                                          usePoints:
                                                              _useMobstar,
                                                          points: _useMobstar
                                                              ? summary
                                                                  .rewardPoints
                                                              : 0,
                                                        ),
                                                      );
                                                }
                                              : null,
                                        ),
                                        const SizedBox(height: 20),
                                        const _SectionTitle(
                                            'Please select payment option'),
                                        const SizedBox(height: 12),
                                        if (summary.mobCreditAccountStatus !=
                                            null) ...[
                                          if (summary.mobCreditAccountStatus ==
                                              'AMOUNT_DUE')
                                            const _MobCreditOverlimitBanner(),
                                          _MobCreditPaymentCard(
                                            selected: summary.total > 0 &&
                                                summary.mobCreditAccountStatus ==
                                                    'ACTIVE' &&
                                                summary.total <=
                                                    summary.mobCreditBalance &&
                                                _paymentOption == 0,
                                            total: summary.total,
                                            mobCreditBalance:
                                                summary.mobCreditBalance,
                                            status:
                                                summary.mobCreditAccountStatus,
                                            isDisabled: summary.total <= 0 ||
                                                isPaymentBlocked ||
                                                summary.mobCreditAccountStatus !=
                                                    'ACTIVE' ||
                                                summary.total >
                                                    summary.mobCreditBalance,
                                            onTap: () => _onMobCreditSelected(
                                              summary.cartId,
                                              summary.total,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        _RazorpayTile(
                                          selected: summary.total > 0 &&
                                              _paymentOption == 1,
                                          isDisabled: summary.total <= 0 ||
                                              isPaymentBlocked,
                                          onTap: () => _onRazorpaySelected(
                                            summary.cartId,
                                            summary.total,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        OrderDetailsCard(
                                          subtotal: summary.subtotal,
                                          shipping: summary.shipping,
                                          tax: summary.tax,
                                          savings: summary.savings,
                                          total: summary.total,
                                          earningPoints: summary.earningPoints,
                                          mobstarApplied: _useMobstar
                                              ? mobstarApplicableAmount
                                              : null,
                                          walletApplied: _useMobwallet
                                              ? summary.applicableWalletAmount
                                              : null,
                                        ),
                                      ],
                                    ),
                                    BottomCheckoutBar(
                                      label: summary.total == 0
                                          ? 'Place order'
                                          : 'Place your order and pay',
                                      isLoading: isPaymentBlocked,
                                      isDisabled: _isRupifiHandoffInProgress ||
                                          !isPaymentMethodReady,
                                      onProceed: () => _onProceed(
                                          context,
                                          summary.cartId,
                                          summary.total,
                                          summary),
                                    ),
                                    if (_isRupifiHandoffInProgress)
                                      _RupifiHandoffOverlay(
                                        onClose: () => setState(
                                          () => _isRupifiHandoffInProgress =
                                              false,
                                        ),
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
      _router.go('/checkout/review');
    }
  }

  double _mobstarApplicableAmount(CartSummaryEntity summary) {
    if (summary.mobstarAmount <= 0) return 0;

    final preRedeemPayable = summary.subtotal > 0
        ? summary.subtotal
        : summary.total + summary.savings - summary.shipping - summary.tax;
    final payableCap = summary.total > 0 ? summary.total : preRedeemPayable;
    final applicable =
        summary.mobstarAmount > payableCap ? payableCap : summary.mobstarAmount;

    if (applicable > 0) {
      _lastMobstarApplicableAmount = applicable;
      return applicable;
    }

    return summary.usePoints ? _lastMobstarApplicableAmount : 0;
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
                child: Center(child: AppBackIcon()),
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
    required this.mobstarBalanceAmount,
    required this.walletBalance,
    required this.applicableWalletAmount,
    required this.isReferralOnlyWallet,
    required this.isWalletUsageLimited,
    required this.onMobstarChanged,
    required this.onMobwalletChanged,
    this.walletNote = '',
    this.isUpdating = false,
  });

  final bool useMobstar;
  final bool useMobwallet;
  final int mobstarPoints;
  final double mobstarAmount;
  final double mobstarBalanceAmount;
  final double walletBalance;
  final double applicableWalletAmount;
  final bool isReferralOnlyWallet;
  final bool isWalletUsageLimited;
  final String walletNote;
  final bool isUpdating;
  final VoidCallback? onMobstarChanged;
  final VoidCallback? onMobwalletChanged;

  String get _walletNoteText {
    if (!isReferralOnlyWallet || !isWalletUsageLimited) return '';
    if (walletNote.isNotEmpty) return walletNote;
    if (applicableWalletAmount > 0 && applicableWalletAmount < walletBalance) {
      return 'Only a portion of your wallet balance can be used for this order. You can apply ₹${applicableWalletAmount.toStringAsFixed(2)}.';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final hasMobstar = mobstarPoints > 0;
    final hasWallet = walletBalance > 0;
    final mobstarLabel = hasMobstar
        ? '$mobstarPoints (₹${mobstarBalanceAmount.toStringAsFixed(2)}) mobstar points'
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
              if (hasWallet && _walletNoteText.isNotEmpty) ...[
                const Divider(height: 1, color: Color(0xFFE5E8EE)),
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F5F5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    _walletNoteText,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF67696D),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      height: 16 / 11,
                    ),
                  ),
                ),
              ],
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
                color:
                    enabled ? const Color(0xFF0A243F) : const Color(0xFFB0B4BB),
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
                  color: enabled
                      ? const Color(0xFF0A243F)
                      : const Color(0xFFB0B4BB),
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
    required this.mobCreditBalance,
    required this.onTap,
    this.status,
    this.isDisabled = false,
  });

  final bool selected;
  final double total;
  final double mobCreditBalance;
  final VoidCallback onTap;
  final String? status;
  final bool isDisabled;

  String get _disabledMessage {
    if (total <= 0) return 'No payable amount for mobCREDIT.';
    if (status == 'AMOUNT_DUE')
      return 'Clear your outstanding due to use mobCREDIT.';
    if (status != 'ACTIVE') return 'mobCREDIT is not active for this account.';
    if (total > mobCreditBalance) {
      return 'Order amount exceeds your mobCREDIT balance.';
    }
    return 'mobCREDIT is not active for this account.';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.58 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
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
                        child: _RadioMark(
                            selected: selected, enabled: !isDisabled),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Pay '),
                              TextSpan(
                                text: '₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              if (mobCreditBalance > 0) ...[
                                const TextSpan(text: ' out of '),
                                TextSpan(
                                  text:
                                      '₹${mobCreditBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                const TextSpan(text: ' mobCREDIT available'),
                              ] else
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
            if (isDisabled) ...[
              const SizedBox(height: 8),
              Text(
                _disabledMessage,
                style: GoogleFonts.inter(
                  color: const Color(0xFF67696D),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 16 / 11,
                ),
              ),
            ],
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F6C6), Color(0xFFD4F4F3)],
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 92),
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
                  topRight: Radius.circular(12),
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
    this.isDisabled = false,
  });

  final bool selected;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.58 : 1,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _RadioMark(selected: selected, enabled: !isDisabled),
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
    final activeColor =
        enabled ? const Color(0xFF0360E5) : const Color(0xFFB0B4BB);
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
  const _RadioMark({required this.selected, this.enabled = true});

  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        enabled ? const Color(0xFF0360E5) : const Color(0xFFB0B4BB);
    final borderColor = selected ? activeColor : const Color(0xFF767C8F);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: selected
          ? Center(
              child: SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _RupifiHandoffOverlay extends StatefulWidget {
  const _RupifiHandoffOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_RupifiHandoffOverlay> createState() => _RupifiHandoffOverlayState();
}

class _RupifiHandoffOverlayState extends State<_RupifiHandoffOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = Tween<double>(
    begin: 0.94,
    end: 1.06,
  ).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.38),
        child: Center(
          child: Container(
            width: 320,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.lock_clock_outlined,
                      color: Color(0xFF0360E5),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Complete mobCREDIT OTP',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 22 / 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rupifi opened in a new tab. Finish OTP verification there. '
                  'Do not refresh or place another order from this page.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 18 / 12,
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        final phase = (_controller.value + index * 0.22) % 1;
                        final opacity = 0.35 + (phase * 0.65);
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0360E5)
                                .withValues(alpha: opacity.clamp(0.35, 1)),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: widget.onClose,
                  child: const Text('Cancel and retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobCreditOverlimitBanner extends StatelessWidget {
  const _MobCreditOverlimitBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFEE2C00).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFEE2C00), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your mobCREDIT has an outstanding due amount. Please clear it to continue.',
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
    );
  }
}
