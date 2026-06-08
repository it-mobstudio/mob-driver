import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/checkout/checkout_payment_page.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/features/cart/controllers/cart_controller.dart';
import 'package:m_o_b_demand_side/features/cart/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_sections.dart';
import 'package:m_o_b_demand_side/widgets/error_state_view.dart';
import 'package:m_o_b_demand_side/widgets/quantity_stepper.dart';

class CheckoutOrderReviewPage extends StatefulWidget {
  static const routeName = 'CheckoutOrderReviewPage';
  static const routePath = '/checkout/review';

  const CheckoutOrderReviewPage({super.key});

  @override
  State<CheckoutOrderReviewPage> createState() =>
      _CheckoutOrderReviewPageState();
}

class _CheckoutOrderReviewPageState extends State<CheckoutOrderReviewPage> {
  late final CartController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CartController();
    _controller.loadCart();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_controller.errorMessage != null &&
                _controller.errorMessage!.isNotEmpty &&
                _controller.items.isEmpty) {
              return ErrorStateView(
                title: 'Unable to load order review',
                message: _controller.errorMessage!,
                onRetry: () => _controller.loadCart(),
              );
            }

            return Column(
              children: [
                _ReviewHeader(onBack: () => _goBack(context)),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF0F0F0),
                    child: Stack(
                      children: [
                        ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 118),
                          children: [
                            _CartSummaryCard(
                              itemCount: _controller.itemCount,
                              storeCount: _controller.itemsBySeller.length,
                            ),
                            const SizedBox(height: 20),
                            ..._sellerSections(),
                            const ViewCouponsTile(),
                            const SizedBox(height: 20),
                            OrderDetailsCard(
                              subtotal: _controller.subtotal,
                              shipping: _controller.shipping,
                              tax: _controller.tax,
                              savings: _controller.savings,
                              total: _controller.total,
                              rewardPoints: _controller.rewardPoints,
                            ),
                          ],
                        ),
                        BottomCheckoutBar(
                          label: 'Continue',
                          onProceed: () => GoRouter.of(context)
                              .go(CheckoutPaymentPage.routePath),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sellerSections() {
    final sections = <Widget>[];
    final entries = _controller.itemsBySeller.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      sections.add(
        _ReviewSellerCard(
          sellerCode: entry.key,
          items: entry.value,
          itemStartIndex:
              entries.take(i).fold<int>(0, (sum, e) => sum + e.value.length),
          onQtyChanged: _controller.updateQuantity,
          onQtyInputChanged: _controller.onQuantityInputChanged,
          onRemove: _controller.removeItem,
          isUpdatingCart: _controller.isUpdatingCart,
          updatingItemKey: _controller.updatingItemKey,
        ),
      );
      sections.add(const SizedBox(height: 20));
    }

    return sections;
  }

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/checkout/address');
    }
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'Order review',
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

class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard({
    required this.itemCount,
    required this.storeCount,
  });

  final int itemCount;
  final int storeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/cart.svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              Color(0xFF0A243F),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 20 / 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'from $storeCount verified ${storeCount == 1 ? 'store' : 'stores'}',
            style: GoogleFonts.inter(
              color: const Color(0xFF767C8F),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSellerCard extends StatelessWidget {
  const _ReviewSellerCard({
    required this.sellerCode,
    required this.items,
    required this.itemStartIndex,
    required this.onQtyChanged,
    required this.onQtyInputChanged,
    required this.onRemove,
    required this.isUpdatingCart,
    required this.updatingItemKey,
  });

  final String sellerCode;
  final List<CartItem> items;
  final int itemStartIndex;
  final void Function(CartItem item, int quantity) onQtyChanged;
  final void Function(CartItem item, String quantityText) onQtyInputChanged;
  final void Function(CartItem item) onRemove;
  final bool isUpdatingCart;
  final String? updatingItemKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD3F6F5), Color(0xFFBADEFF)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  'Store delivery',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 18 / 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const Spacer(),
                Text(
                  '\u20B9 400',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF767C8F),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  'FREE',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sold by $sellerCode',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF67696D),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 16 / 11,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/qwik.svg',
                      width: 54,
                      height: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '1-4 hrs delivery',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 20 / 13,
                      ),
                    ),
                  ],
                ),
                const Divider(
                  height: 24,
                  color: Color(0xFFE5E8EE),
                ),
                ...items.asMap().entries.map(
                      (entry) => _ReviewItemTile(
                        index: itemStartIndex + entry.key + 1,
                        item: entry.value,
                        onQtyChanged: (qty) => onQtyChanged(entry.value, qty),
                        onQtyInputChanged: (value) =>
                            onQtyInputChanged(entry.value, value),
                        onRemove: () => onRemove(entry.value),
                        isBusy: isUpdatingCart &&
                            updatingItemKey == entry.value.itemKey,
                        showDivider: entry.key != items.length - 1,
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

class _ReviewItemTile extends StatelessWidget {
  const _ReviewItemTile({
    required this.index,
    required this.item,
    required this.onQtyChanged,
    required this.onQtyInputChanged,
    required this.onRemove,
    required this.isBusy,
    required this.showDivider,
  });

  final int index;
  final CartItem item;
  final ValueChanged<int> onQtyChanged;
  final ValueChanged<String> onQtyInputChanged;
  final VoidCallback onRemove;
  final bool isBusy;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, showDivider ? 16 : 0),
      margin: EdgeInsets.only(bottom: showDivider ? 16 : 0),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE5E8EE)),
              )
            : null,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 18,
                child: Text(
                  '$index',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.isNetworkImage
                      ? Image.network(
                          item.imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/Image-coming-soon.png',
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(item.imageAsset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 18 / 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\u20B9 ${item.unitPrice.toStringAsFixed(0)} /unit',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8A8A8A),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\u20B9${item.lineTotal.toStringAsFixed(0)}',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isBusy ? null : onRemove,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: isBusy
                          ? const Color(0xFFC5CAD3)
                          : const Color(0xFF67696D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Remove',
                      style: GoogleFonts.inter(
                        color: isBusy
                            ? const Color(0xFFC5CAD3)
                            : const Color(0xFF67696D),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 148,
                height: 40,
                child: QuantityStepper(
                  value: item.qty,
                  onDecrement: () => onQtyChanged(item.qty - 1),
                  onIncrement: () => onQtyChanged(item.qty + 1),
                  onInputChanged: onQtyInputChanged,
                  isBusy: isBusy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
