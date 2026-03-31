import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/google_fonts_compat.dart';
import 'package:m_o_b_demand_side/features/cart/models/cart_item.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_product_details.dart';

class CartTopBar extends StatelessWidget {
  const CartTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Text(
        'My cart',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0A243F),
          height: 22 / 15,
        ),
      ),
    );
  }
}

class ShippingTile extends StatelessWidget {
  const ShippingTile({
    super.key,
    this.title = 'Shipping to: Iris Society',
    this.subtitle = 'Legros Mission Suite 804 Plains Apt 613..',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF0A243F),
                    ),
                    children: [
                      TextSpan(
                        text: 'Shipping to:  ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0A243F),
                        ),
                      ),
                      TextSpan(
                        text: title.replaceFirst('Shipping to: ', ''),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A243F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6C7C8C),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'CHANGE',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2973F0),
            ),
          ),
        ],
      ),
    );
  }
}

class SavingsStrip extends StatelessWidget {
  const SavingsStrip({
    super.key,
    required this.savings,
  });

  final double savings;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 41,
      color: const Color(0xFFE9FAF2),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.local_offer,
            size: 14,
            color: Color(0xFFFFAB00),
          ),
          const SizedBox(width: 8),
          Text(
            'Your total savings',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A243F),
            ),
          ),
          const Spacer(),
          Text(
            '₹${savings.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF01A685),
            ),
          ),
        ],
      ),
    );
  }
}

class SellerSection extends StatelessWidget {
  const SellerSection({
    super.key,
    required this.sellerCode,
    required this.sellerItems,
    required this.onQtyChanged,
    required this.onQtyInputChanged,
    required this.onRemove,
    this.isUpdatingCart = false,
    this.updatingItemKey,
  });

  final String sellerCode;
  final List<CartItem> sellerItems;
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
        border: Border.all(color: const Color(0xFFE6ECF2)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.solid,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹ 400',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF767C8F),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹ 250',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sold by $sellerCode',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF67696D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Arrives by tomorrow evening',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                const SizedBox(height: 8),
                ...sellerItems
                    .map(
                      (item) => CartProductDetails(
                        item: item,
                        onQtyChanged: (qty) => onQtyChanged(item, qty),
                        onQtyInputChanged: (value) =>
                            onQtyInputChanged(item, value),
                        onDelete: () => onRemove(item),
                        isBusy:
                            isUpdatingCart && updatingItemKey == item.itemKey,
                      ),
                    )
                    .expand((widget) => [widget, const SizedBox(height: 12)])
                    .toList()
                  ..removeLast(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ViewCouponsTile extends StatelessWidget {
  const ViewCouponsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.discount_outlined,
            size: 16,
            color: Color(0xFF0A243F),
          ),
          const SizedBox(width: 10),
          Text(
            'View all coupons',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: Color(0xFF0A243F),
          ),
        ],
      ),
    );
  }
}

class OrderDetailsCard extends StatelessWidget {
  const OrderDetailsCard({
    super.key,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.savings,
    required this.total,
  });

  final double subtotal;
  final double shipping;
  final double tax;
  final double savings;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              children: [
                _kvRow('Order details', '', isHeading: true),
                const SizedBox(height: 4),
                _kvRow('Subtotal', '₹ ${subtotal.toStringAsFixed(2)}'),
                _kvRow('Shipping', '₹ ${shipping.toStringAsFixed(2)}'),
                _kvRow(
                  'Total tax',
                  '₹ ${tax.toStringAsFixed(2)}',
                  keyDecorated: true,
                ),
                _kvRow(
                  'Savings',
                  '₹ ${savings.toStringAsFixed(2)}',
                  keyDecorated: true,
                ),
                const Divider(height: 20),
                _kvRow(
                  'Total to pay',
                  '₹ ${total.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFDFF8F9),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You will earn  ',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                const Icon(
                  Icons.star,
                  size: 16,
                  color: Color(0xFFFFAB00),
                ),
                Text(
                  '  1150 points',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0A243F),
                  ),
                ),
                Text(
                  ' on this purchase',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF0A243F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(
    String key,
    String value, {
    bool isHeading = false,
    bool isTotal = false,
    bool keyDecorated = false,
  }) {
    if (isHeading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            key,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0A243F),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            key,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color:
                  isTotal ? const Color(0xFF0A243F) : const Color(0xFF67696D),
              decoration: keyDecorated ? TextDecoration.underline : null,
              decorationStyle: keyDecorated ? TextDecorationStyle.dotted : null,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF0A243F),
            ),
          ),
        ],
      ),
    );
  }
}

class CartActionRow extends StatelessWidget {
  const CartActionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            'Purchase later (or)\nRecheck prices',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A243F),
              height: 21 / 14,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(
                color: Color(0xFFFECB00),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(48),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 0,
              ),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'QUOTE REQUEST (RFQ)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0A243F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BottomCheckoutBar extends StatelessWidget {
  const BottomCheckoutBar({
    super.key,
    required this.total,
    required this.onProceed,
  });

  final double total;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: ElevatedButton(
            onPressed: onProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0360E5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: Row(
              children: [
                Text(
                  '₹ ${total.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 36 / 14,
                  ),
                ),
                const Spacer(),
                Text(
                  'Proceed to checkout',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AiMicPill extends StatelessWidget {
  const AiMicPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8EEF5)),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Talk to me about adding, editing, deleting,\nchanging variations in the cart',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF6F79FF), Color(0xFF8A3CFF)],
                ),
              ),
              child: const Icon(Icons.mic, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FloatingAiMic extends StatelessWidget {
  const FloatingAiMic({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF6F79FF), Color(0xFF8A3CFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 28),
      ),
    );
  }
}

class EmptyCartBody extends StatelessWidget {
  const EmptyCartBody({
    super.key,
    required this.topBar,
    required this.shippingTile,
    required this.micPill,
  });

  final Widget topBar;
  final Widget shippingTile;
  final Widget micPill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        topBar,
        shippingTile,
        const SizedBox(height: 24),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 160,
                width: 160,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF4FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_basket_outlined, size: 80),
              ),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty!',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Talk to me about adding, editing,\ndeleting, changing variations in the cart',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        micPill,
        const SizedBox(height: 16),
      ],
    );
  }
}
