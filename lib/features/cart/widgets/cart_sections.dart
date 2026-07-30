import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/cart/domain/entities/cart_entity.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/pages/cart_rfq_request_page.dart';
import 'package:m_o_b_demand_side/features/cart/widgets/cart_product_details.dart';
import 'package:m_o_b_demand_side/index.dart';
import 'package:m_o_b_demand_side/shared/widgets/address_picker.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

class CartTopBar extends StatelessWidget {
  const CartTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(HomepageWidget.routePath);
              }
            },
            child: const SizedBox(
              width: 40,
              height: 60,
              child: Align(
                alignment: Alignment.center,
                child: AppBackIcon(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cart',
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 22 / 15,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => GoRouter.of(context).push('/search'),
            child: SizedBox(
              width: 40,
              height: 60,
              child: Align(
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  'assets/images/Searchicon.svg',
                  width: 16,
                  height: 16,
                ),
                //  Icon(
                //   Icons.search,
                //   color: Color(0xFF0A243F),
                //   size: 22,
                // ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShippingTile extends StatelessWidget {
  const ShippingTile({
    super.key,
    this.title = 'Shipping to: Iris Society',
    this.subtitle = 'Legros Mission Suite 804 Plains Apt 613..',
    this.hasAddress = true,
    this.onAddressAction,
  });

  final String title;
  final String subtitle;
  final bool hasAddress;
  final VoidCallback? onAddressAction;

  @override
  Widget build(BuildContext context) {
    final recipient = title
        .replaceFirst('Shipping to: ', '')
        .replaceFirst('Shipping address', '')
        .trim();
    final displayRecipient = recipient.isNotEmpty ? recipient : 'Add address';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Shipping to:',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0A243F),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 16 / 11,
                        ),
                      ),
                      TextSpan(
                        text: ' $displayRecipient',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0A243F),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 16 / 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF7D8798),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 16 / 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAddressAction,
            child: SizedBox(
              width: 45,
              child: Text(
                hasAddress ? 'CHANGE' : 'ADD',
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0360E5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 16 / 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SameAddressRow extends StatelessWidget {
  const SameAddressRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: ShapeDecoration(
              color: value ? const Color(0xFF0360E5) : Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color:
                      value ? const Color(0xFF0360E5) : const Color(0xFF767C8F),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          const Text(
            'Use same address for delivery and billing',
            style: TextStyle(
              color: Color(0xFF0A243F),
              fontSize: 11,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class BillingAddressTile extends StatelessWidget {
  const BillingAddressTile({
    super.key,
    required this.hasBillingAddress,
    this.addressDetails = '',
    this.onTap,
  });

  final bool hasBillingAddress;
  final String addressDetails;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Billing address',
                    style: TextStyle(
                      color: Color(0xFF0A243F),
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      height: 1.43,
                    ),
                  ),
                  if (addressDetails.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      addressDetails.trim(),
                      style: const TextStyle(
                        color: Color(0xFF67696D),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 45,
              child: Text(
                hasBillingAddress ? 'Change' : 'Add',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF2973F0),
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartAddressBottomSheet extends StatefulWidget {
  const CartAddressBottomSheet({
    super.key,
    required this.addresses,
    required this.onSelectAddress,
    required this.onAddAddress,
    required this.onEditAddress,
    required this.onDeleteAddress,
    this.selectedAddressId,
  });

  final List<AddressEntity> addresses;
  final String? selectedAddressId;
  final ValueChanged<AddressEntity> onSelectAddress;
  final VoidCallback onAddAddress;
  final ValueChanged<AddressEntity> onEditAddress;
  final ValueChanged<AddressEntity> onDeleteAddress;

  @override
  State<CartAddressBottomSheet> createState() => _CartAddressBottomSheetState();
}

class _CartAddressBottomSheetState extends State<CartAddressBottomSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AddressEntity> get _filteredAddresses {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.addresses;
    return widget.addresses.where((address) {
      final searchable = [
        address.name,
        address.displayAddress,
        address.phoneNumber,
        address.addressTag,
        address.projectName,
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 656 / 812,
        widthFactor: 1,
        child: Material(
          color: const Color(0xFFF7F7F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select delivery address',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0A243F),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 22 / 15,
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            width: 28,
                            height: 28,
                            child: Icon(
                              Icons.close,
                              color: Color(0xFF0A243F),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: AddressPickerBody(
                    addresses: _filteredAddresses,
                    selectedAddressId: widget.selectedAddressId,
                    showSearch: true,
                    showQuickActions: false,
                    searchController: _searchController,
                    onSearchChanged: (value) => setState(() => _query = value),
                    onAddNewAddress: widget.onAddAddress,
                    onSelectAddress: widget.onSelectAddress,
                    onEditAddress: widget.onEditAddress,
                    onDeleteAddress: widget.onDeleteAddress,
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FAF3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF2BF),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/images/yoursavings.svg',
              width: 11.554,
              height: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Your total savings',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
              height: 16 / 12,
            ),
          ),
          const Spacer(),
          Text(
            '₹${savings.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF01A685),
              height: 16 / 12,
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
    required this.deliveryLabel,
    required this.onQtyChanged,
    required this.onQtyInputChanged,
    required this.onRemove,
    this.itemStartIndex = 0,
    this.isStoreOpen = true,
    this.isUpdatingCart = false,
    this.updatingItemKey,
  });

  final String sellerCode;
  final List<CartItem> sellerItems;
  final int itemStartIndex;
  final String deliveryLabel;
  final bool isStoreOpen;
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
                  'Delivery fee',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 18 / 12,
                    color: const Color(0xFF0A243F),
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF0A243F),
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationThickness: 1.44,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹400',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF767C8F),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'FREE',
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
                  'Routing ID $sellerCode',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF767C8F),
                  ),
                ),
                const SizedBox(height: 4),
                if (deliveryLabel.trim().isNotEmpty) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        isStoreOpen
                            ? 'assets/images/qwik.svg'
                            : 'assets/images/timer-delivery.svg',
                        height: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        deliveryLabel.trim(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A243F),
                          height: 20 / 13,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: DottedDivider(),
                  ),
                  const SizedBox(height: 10),
                ],
                for (var i = 0; i < sellerItems.length; i++) ...[
                  CartProductDetails(
                    index: itemStartIndex + i,
                    item: sellerItems[i],
                    onQtyChanged: (qty) => onQtyChanged(sellerItems[i], qty),
                    onQtyInputChanged: (value) =>
                        onQtyInputChanged(sellerItems[i], value),
                    onDelete: () => onRemove(sellerItems[i]),
                    isBusy: isUpdatingCart &&
                        updatingItemKey == sellerItems[i].itemKey,
                  ),
                  if (i < sellerItems.length - 1) ...[
                    const SizedBox(height: 8),
                    const _DashedDivider(),
                    const SizedBox(height: 8),
                  ],
                ],
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.discount_outlined,
            size: 16,
            color: Color(0xFF0A243F),
          ),
          SizedBox(width: 10),
          Text(
            'View all coupons',
            style: TextStyle(
              color: Color(0xFF0A243F),
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              height: 1.54,
            ),
          ),
          Spacer(),
          Icon(
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
    this.earningPoints = 0,
    this.mobstarApplied,
    this.walletApplied,
  });

  final double subtotal;
  final double shipping;
  final double tax;
  final double savings;
  final double total;
  final int earningPoints;
  final double? mobstarApplied;
  final double? walletApplied;

  @override
  Widget build(BuildContext context) {
    String money(double value) => '\u20B9 ${value.toStringAsFixed(2)}';

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
                _kvRow('Subtotal', money(subtotal)),
                _kvRow(
                  'Delivery fee',
                  shipping == 0 ? 'Free' : money(shipping),
                  valueColor: shipping == 0 ? const Color(0xFF01A685) : null,
                ),
                _kvRow(
                  'Total tax',
                  money(tax),
                  keyDecorated: true,
                ),
                _kvRow(
                  'Savings',
                  money(savings),
                  keyDecorated: true,
                ),
                if ((mobstarApplied ?? 0) > 0) ...[
                  const Divider(height: 20),
                  _redeemRow(
                    label: 'mobSTAR points',
                    icon: SvgPicture.asset(
                      'assets/images/points.svg',
                      width: 16,
                      height: 16,
                    ),
                    amount: '- ₹ ${mobstarApplied!.toStringAsFixed(2)}',
                  ),
                ],
                if ((walletApplied ?? 0) > 0) ...[
                  const Divider(height: 20),
                  _redeemRow(
                    label: 'mobWALLET',
                    icon: const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFFC9825E),
                      size: 16,
                    ),
                    amount: '- ₹ ${walletApplied!.toStringAsFixed(2)}',
                  ),
                ],
                const Divider(height: 20),
                _kvRow(
                  'Total to pay',
                  money(total),
                  isTotal: true,
                ),
              ],
            ),
          ),
          ClipPath(
            clipper: const _CartPointsStripClipper(),
            child: Container(
              height: 47,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
              decoration: const BoxDecoration(
                color: Color(0xFFDFF8F9),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'You will earn ',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 18 / 12,
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/images/points.svg',
                    width: 16,
                    height: 16,
                  ),
                  Text(
                    ' $earningPoints points',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 18 / 12,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      ' on this purchase',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _redeemRow({
    required String label,
    required Widget icon,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A243F),
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A7D83),
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
    Color? valueColor,
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
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              height: isTotal ? 1.43 : null,
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
              color: valueColor ?? const Color(0xFF0A243F),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartPointsStripClipper extends CustomClipper<Path> {
  const _CartPointsStripClipper();

  @override
  Path getClip(Size size) {
    const waveWidth = 16.0;
    const waveDepth = 5.0;
    final path = Path()..moveTo(0, waveDepth);

    var x = 0.0;
    while (x < size.width) {
      path.quadraticBezierTo(
        x + waveWidth / 4,
        0,
        x + waveWidth / 2,
        waveDepth,
      );
      path.quadraticBezierTo(
        x + waveWidth * 3 / 4,
        waveDepth * 2,
        x + waveWidth,
        waveDepth,
      );
      x += waveWidth;
    }

    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CartPointsStripClipper oldClipper) => false;
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0D4DC)
      ..strokeWidth = 1;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

class CartActionRow extends StatelessWidget {
  const CartActionRow({super.key, required this.summary});

  final CartSummaryEntity summary;

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
            onPressed: () => showCartRfqRequestSheet(context, summary),
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
    this.label = 'Save and continue',
    required this.onProceed,
    this.isDisabled = false,
    this.isLoading = false,
    this.total,
  });

  final String label;
  final VoidCallback onProceed;
  final bool isDisabled;
  final bool isLoading;
  final double? total;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final active = !isDisabled && !isLoading;

    if (total != null) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          height: 86 + bottomInset,
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: active
                ? () {
                    AppHaptics.lightTap();
                    onProceed();
                  }
                : null,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color:
                    active ? const Color(0xFF0360E5) : const Color(0xFFB0C4DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.72),
                          height: 14 / 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹ ${total!.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 20 / 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (isLoading)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 20 / 14,
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 68 + bottomInset,
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
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 4),
        child: ElevatedButton(
          onPressed: active ? onProceed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                active ? const Color(0xFF0360E5) : const Color(0xFFB0C4DE),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFB0C4DE),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 21 / 14,
                  ),
                ),
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
  });

  final Widget topBar;
  final Widget shippingTile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        topBar,
        Expanded(
          child: ColoredBox(
            color: const Color(0xFFF0F0F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                shippingTile,
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 130,
                            width: 130,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0A243F)
                                      .withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 58,
                              color: Color(0xFF0A243F),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Your cart is empty',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0A243F),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 28 / 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Looks like you haven\'t added\nanything to your cart yet.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF767C8F),
                              fontSize: 14,
                              height: 22 / 14,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () =>
                                  GoRouter.of(context).go('/homepage'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A243F),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Start Shopping',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DottedDivider extends StatelessWidget {
  final Color color;
  final double dashWidth;
  final double dashHeight;
  final double spacing;

  const DottedDivider({
    super.key,
    this.color = const Color(0xFFE5E8EE),
    this.dashWidth = 6,
    this.dashHeight = 1,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount =
            (constraints.maxWidth / (dashWidth + spacing)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            ),
          ),
        );
      },
    );
  }
}
