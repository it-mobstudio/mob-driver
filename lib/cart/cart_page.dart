// lib/pages/cart_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/main_scaffold.dart';
import '../../checkout/checkout_address_page.dart';

class CartItem {
  final String title;
  final String imageAsset;
  final int qty;
  final double unitPrice;
  final String sellerCode;
  final bool storeDelivery;

  CartItem({
    required this.title,
    required this.imageAsset,
    required this.qty,
    required this.unitPrice,
    required this.sellerCode,
    this.storeDelivery = true,
  });
}

class CartPage extends StatefulWidget {
  static const String routeName = 'CartPage';
  static const String routePath = '/cart';

  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // ---- Mock: replace with your provider/bloc data
  List<CartItem> items = [
    // Leave this list empty to see App_160 (empty cart) design.
    CartItem(
      title:
          'Hindware 121 mm Round Brass Silver Wall Mount Overhead Rain Shower F1…',
      imageAsset: 'assets/sample_product.png',
      qty: 1,
      unitPrice: 4250,
      sellerCode: 'BENG-098',
    ),
    CartItem(
      title:
          'Hindware 4 inch Round Brass Silver Wall Mount Overhead Shower, F160119',
      imageAsset: 'assets/sample_product.png',
      qty: 2,
      unitPrice: 1533,
      sellerCode: 'BENG-098',
    ),
    CartItem(
      title: 'Hindware Overhead Shower 150 mm White ABS Round, F160216',
      imageAsset: 'assets/sample_product.png',
      qty: 3,
      unitPrice: 2325,
      sellerCode: 'BENG-004',
    ),
    CartItem(
      title:
          'Hindware Single Flow Overhead Round Shower Single Flow, Rain Flow, 23…',
      imageAsset: 'assets/sample_product.png',
      qty: 4,
      unitPrice: 3175,
      sellerCode: 'BENG-004',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = items.isEmpty;

    return MainScaffold(
      // keep your bottom nav persistent
      currentIndex: 4, // assuming index 4 is Cart tab
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: isEmpty ? _buildEmptyCart(context) : _buildCartWithItems(),
        ),
      ),
    );
  }

  // ------------------ EMPTY CART (App_160_Mob_cart_AI) ------------------
  Widget _buildEmptyCart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(context),
        _shippingTile(),
        const SizedBox(height: 24),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration placeholder
              Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
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
        _aiMicPill(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ---------------- CART WITH ITEMS (App_158 + App_159) ----------------
  // App_158: smaller list + fixed bottom bar visible
  // App_159: full UI long scroll; bottom bar stays fixed
  Widget _buildCartWithItems() {
    final double savings = 7200; // mock
    final double subtotal =
        items.fold(0, (sum, i) => sum + (i.unitPrice * i.qty.toDouble()));
    final double shipping = 500;
    final double tax = 433;
    final double total =
        subtotal + shipping + tax - 1055; // savings row example

    return Stack(
      children: [
        // Scroll content
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
          children: [
            _topBar(context),
            _shippingTile(),
            _savingsStrip(savings),
            const SizedBox(height: 8),
            ..._groupedSellerSections(),
            const SizedBox(height: 12),
            _viewCouponsTile(),
            const SizedBox(height: 12),
            _orderDetailsCard(subtotal, shipping, tax),
            const SizedBox(height: 12),
            _actionRow(),
            const SizedBox(height: 12),
          ],
        ),

        // Fixed bottom checkout bar
        _bottomCheckoutBar(total),
      ],
    );
  }

  // ----------------------- Components -----------------------

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text('My cart',
              style:
                  GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _shippingTile() {
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
              Text('Shipping to:  Iris Society',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Legros Mission Suite 804 Plains Apt 613..',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF6C7C8C))),
            ],
          ),
          const Spacer(),
          Text('CHANGE',
              style: GoogleFonts.inter(
                  color: const Color(0xFF2B7FFF), fontWeight: FontWeight.w700))
        ],
      ),
    );
  }

  Widget _savingsStrip(double savings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('💰  Your total savings'),
          const Spacer(),
          Text('₹${savings.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                  color: const Color(0xFF179F4B), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  List<Widget> _groupedSellerSections() {
    // Group by seller
    final Map<String, List<CartItem>> bySeller = {};
    for (final item in items) {
      bySeller.putIfAbsent(item.sellerCode, () => []).add(item);
    }

    final List<Widget> sections = [];
    for (final entry in bySeller.entries) {
      sections.add(_sellerSection(entry.key, entry.value));
      sections.add(const SizedBox(height: 12));
    }
    return sections;
  }

  Widget _sellerSection(String sellerCode, List<CartItem> sellerItems) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6ECF2)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          // header stripe
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5FF),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text('Store delivery',
                    style: GoogleFonts.inter(
                        decoration: TextDecoration.underline,
                        color: const Color(0xFF1575D6),
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('₹ 250',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, color: Colors.black87)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sold by $sellerCode',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text('Arrives by tomorrow evening',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...sellerItems
                    .map((i) => _cartLineItem(i))
                    .expand((w) => [w, const SizedBox(height: 12)])
                    .toList()
                  ..removeLast(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _cartLineItem(CartItem it) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // qty bubble
          Container(
            height: 26,
            width: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('${it.qty}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),

          // image
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8EEF5)),
            ),
            child: Image.asset(it.imageAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),

          // title + per unit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('₹ ${it.unitPrice.toStringAsFixed(0)} /unit',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF6C7C8C))),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline,
                          size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Text('Remove',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // qty stepper + price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${(it.unitPrice * it.qty).toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 8),
              _qtyControl(
                qty: it.qty,
                onChanged: (newQty) {
                  setState(() {
                    final idx = items.indexOf(it);
                    items[idx] = CartItem(
                      title: it.title,
                      imageAsset: it.imageAsset,
                      qty: newQty,
                      unitPrice: it.unitPrice,
                      sellerCode: it.sellerCode,
                    );
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyControl({required int qty, required ValueChanged<int> onChanged}) {
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
          _roundIconButton(Icons.remove, onTap: () {
            if (qty > 1) onChanged(qty - 1);
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('$qty',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          _roundIconButton(Icons.add, onTap: () => onChanged(qty + 1)),
        ],
      ),
    );
  }

  Widget _roundIconButton(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _viewCouponsTile() {
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

  Widget _orderDetailsCard(double subtotal, double shipping, double tax) {
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
          _kvRow('Savings', '₹ 1055.00',
              valueStyle: GoogleFonts.inter(
                  color: Colors.green, fontWeight: FontWeight.w700)),
          const Divider(height: 20),
          _kvRow('Total to pay',
              '₹ ${(subtotal + shipping + tax - 1055).toStringAsFixed(2)}',
              keyStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
              valueStyle: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('You will earn '),
              const Text('🪙 1150',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Text(' points on this purchase'),
            ],
          )
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v,
      {TextStyle? keyStyle, TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(k, style: keyStyle ?? GoogleFonts.inter(fontSize: 14)),
          const Spacer(),
          Text(v, style: valueStyle ?? GoogleFonts.inter(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _actionRow() {
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
              child: Text('Purchase later (or)\nRecheck prices',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
              child: Text('QUOTE REQUEST (RFQ)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomCheckoutBar(double total) {
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
                color: Colors.black12.withOpacity(0.08),
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
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('₹ ${total.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    GoRouter.of(context).go(CheckoutAddressPage.routePath);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Proceed to checkout',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aiMicPill() {
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
              color: Colors.black12.withOpacity(0.05),
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
