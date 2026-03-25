import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/models/cart_item.dart';

class CartTopBar extends StatelessWidget {
  const CartTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            'My cart',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
    );
  }
}

class ShippingTile extends StatelessWidget {
  const ShippingTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shipping to: Iris Society',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Legros Mission Suite 804 Plains Apt 613..',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6C7C8C),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'CHANGE',
            style: GoogleFonts.inter(
              color: const Color(0xFF2B7FFF),
              fontWeight: FontWeight.w700,
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('Your total savings'),
          const Spacer(),
          Text(
            '₹${savings.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              color: const Color(0xFF179F4B),
              fontWeight: FontWeight.w700,
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
    required this.onRemove,
  });

  final String sellerCode;
  final List<CartItem> sellerItems;
  final void Function(CartItem item, int quantity) onQtyChanged;
  final void Function(CartItem item) onRemove;

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
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  'Store delivery',
                  style: GoogleFonts.inter(
                    decoration: TextDecoration.underline,
                    color: const Color(0xFF1575D6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹ 250',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
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
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Arrives by tomorrow evening',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...sellerItems
                    .map(
                      (item) => CartLineItem(
                        item: item,
                        onQtyChanged: (qty) => onQtyChanged(item, qty),
                        onRemove: () => onRemove(item),
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

class CartLineItem extends StatelessWidget {
  const CartLineItem({
    super.key,
    required this.item,
    required this.onQtyChanged,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            height: 26,
            width: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.qty}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
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
            child: Image.asset(item.imageAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹ ${item.unitPrice.toStringAsFixed(0)} /unit',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6C7C8C),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onRemove,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Remove',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.lineTotal.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              QuantityControl(qty: item.qty, onChanged: onQtyChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class QuantityControl extends StatelessWidget {
  const QuantityControl({
    super.key,
    required this.qty,
    required this.onChanged,
  });

  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1E6ED)),
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoundIconButton(
            icon: Icons.remove,
            onTap: () {
              if (qty > 1) {
                onChanged(qty - 1);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$qty',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          RoundIconButton(icon: Icons.add, onTap: () => onChanged(qty + 1)),
        ],
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class ViewCouponsTile extends StatelessWidget {
  const ViewCouponsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEF5)),
      ),
      child: Column(
        children: [
          _kvRow('Subtotal', '₹ ${subtotal.toStringAsFixed(2)}'),
          _kvRow('Shipping', '₹ ${shipping.toStringAsFixed(2)}'),
          _kvRow('Total tax', '₹ ${tax.toStringAsFixed(2)}'),
          _kvRow(
            'Savings',
            '₹ ${savings.toStringAsFixed(2)}',
            valueStyle: GoogleFonts.inter(
              color: Colors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Divider(height: 20),
          _kvRow(
            'Total to pay',
            '₹ ${total.toStringAsFixed(2)}',
            keyStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
            valueStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text('You will earn '),
              Text('1150', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(' points on this purchase'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kvRow(
    String key,
    String value, {
    TextStyle? keyStyle,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(key, style: keyStyle ?? GoogleFonts.inter(fontSize: 14)),
          const Spacer(),
          Text(value, style: valueStyle ?? GoogleFonts.inter(fontSize: 14)),
        ],
      ),
    );
  }
}

class CartActionRow extends StatelessWidget {
  const CartActionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Purchase later (or)\nRecheck prices',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'QUOTE REQUEST (RFQ)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF3FF),
                    foregroundColor: const Color(0xFF0A243F),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '₹ ${total.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Proceed to checkout',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
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
