import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:m_o_b_demand_side/features/checkout/domain/entities/checkout_entity.dart';
import 'package:m_o_b_demand_side/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_detail_page.dart';

class OrderPlacedPage extends StatefulWidget {
  static const routeName = 'OrderPlacedPage';
  static const routePath = '/checkout/success';

  const OrderPlacedPage({super.key, this.orderId = '', this.order});

  /// Platform order id (e.g. "OD20260618004988"). Used as a fallback to fetch
  /// the full order via [CheckoutOrderConfirmationRequested] when [order]
  /// hasn't already been loaded by the payment flow.
  final String orderId;

  /// Full order details, already fetched by the payment flow (Razorpay
  /// verify/status-check). When present, no extra API call is made.
  final PlacedOrderEntity? order;

  @override
  State<OrderPlacedPage> createState() => _OrderPlacedPageState();
}

class _OrderPlacedPageState extends State<OrderPlacedPage> {
  int _rating = 0;
  CheckoutBloc? _checkoutBloc;

  @override
  void initState() {
    super.initState();
    AppHaptics.success();
    if (widget.order == null && widget.orderId.isNotEmpty) {
      _checkoutBloc = sl<CheckoutBloc>()
        ..add(CheckoutOrderConfirmationRequested(widget.orderId));
    }
    // Reload cart so it's empty when user navigates back — runs for every
    // success path (Razorpay, zero-total, Rupifi, status-check).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartBloc>().add(CartLoadRequested());
    });
  }

  @override
  void dispose() {
    _checkoutBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.order != null) {
      return _scaffold(context, widget.order);
    }
    return BlocProvider.value(
      value: _checkoutBloc!,
      child: BlocBuilder<CheckoutBloc, CheckoutState>(
        builder: (context, state) {
          final order = state is CheckoutOrderPlaced ? state.order : null;
          return _scaffold(context, order);
        },
      ),
    );
  }

  Widget _scaffold(BuildContext context, PlacedOrderEntity? order) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _topGreenBanner(context),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order != null && (order.pointsSummary?.totalPoints ?? 0) > 0) ...[
                    _pointsCard(order.pointsSummary!),
                    const SizedBox(height: 20),
                  ],
                  _experienceSection(),
                  const SizedBox(height: 20),
                  _orderInfoSection(order),
                  const SizedBox(height: 16),
                  _viewOrderBtn(context, order),
                  if (order != null && order.suborders.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _deliveryBreakdownSection(order.suborders),
                  ],
                  if (order != null) ...[
                    const SizedBox(height: 24),
                    _billSummarySection(order),
                  ],
                  const SizedBox(height: 24),
                  _nextStepsSection(),
                  const SizedBox(height: 16),
                  _referCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Green header ──────────────────────────────────────────────────────────

  Widget _topGreenBanner(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF4FB589),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, topPad + 24, 16, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Thank you! Your order has been placed',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 20 / 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Points card ───────────────────────────────────────────────────────────

  Widget _pointsCard(PlacedOrderPointsEntity points) => Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8E6B6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFAB00),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${points.totalPoints} points',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0A243F),
                      height: 22 / 15,
                    ),
                  ),
                  if (points.message.isNotEmpty)
                    Text(
                      points.message,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0A243F).withValues(alpha: 0.8),
                        height: 18 / 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Star rating section ───────────────────────────────────────────────────

  Widget _experienceSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was your experience?',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFAB00),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  // ── Order info + product thumbnails ──────────────────────────────────────

  Widget _orderInfoSection(PlacedOrderEntity? order) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order != null && order.orderId.isNotEmpty
                ? 'Order ID: ${order.orderId}'
                : 'Order confirmed',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A243F).withValues(alpha: 0.6),
              height: 18 / 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order != null ? _deliveryEstimate(order) : 'Confirming your order…',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
              height: 22 / 15,
            ),
          ),
          if (order != null && order.status.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _formatStatus(order.status),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A243F),
                height: 20 / 14,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (order == null)
            const SizedBox(
              height: 64,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            _itemThumbnails(_displayItems(order)),
        ],
      );

  List<PlacedOrderProductEntity> _displayItems(PlacedOrderEntity order) {
    if (order.items.isNotEmpty) return order.items;
    return order.suborders.expand((s) => s.products).toList();
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return '';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  String _deliveryEstimate(PlacedOrderEntity order) {
    final dates = order.suborders
        .map((s) => DateTime.tryParse(s.deliveryDate))
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return 'Your items are on the way';
    dates.sort();
    final earliest = dates.first;
    final latest = dates.last;
    if (earliest.year == latest.year &&
        earliest.month == latest.month &&
        earliest.day == latest.day) {
      return 'Estimated delivery on ${_formatDate(earliest)}';
    }
    return 'Estimated delivery between ${_formatDate(earliest)} and ${_formatDate(latest)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _itemThumbnails(List<PlacedOrderProductEntity> items) {
    const maxVisible = 3;
    final visible = items.take(maxVisible).toList();
    final remaining = items.length - maxVisible;
    return Row(
      children: [
        ...visible.map((item) => _productThumb(item.imageUrl)),
        if (remaining > 0) _moreChip(remaining),
      ],
    );
  }

  Widget _productThumb(String imageUrl) => Container(
        width: 64,
        height: 64,
        margin: const EdgeInsets.only(right: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDEDEDE)),
        ),
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                fadeOutDuration: Duration.zero,
                errorWidget: (_, __, ___) => const Icon(
                  Icons.image_outlined,
                  color: Color(0xFFB0B8C1),
                  size: 28,
                ),
              )
            : const Icon(
                Icons.image_outlined,
                color: Color(0xFFB0B8C1),
                size: 28,
              ),
      );

  Widget _moreChip(int count) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDEDEDE)),
        ),
        child: Center(
          child: Text(
            '+$count\nmore',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A243F).withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ),
      );

  // ── View order details button ─────────────────────────────────────────────

  Widget _viewOrderBtn(BuildContext context, PlacedOrderEntity? order) => SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: order != null && order.numericId.isNotEmpty
              ? () => context.push(
                    OrderDetailPage.routePath,
                    extra: order.numericId,
                  )
              : null,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFDEDEDE)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(48),
            ),
          ),
          child: Text(
            'View order details',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
              height: 22 / 15,
            ),
          ),
        ),
      );

  // ── Delivery breakdown (per vendor / suborder) ────────────────────────────

  Widget _deliveryBreakdownSection(List<PlacedSubOrderEntity> suborders) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery details',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
              height: 21 / 14,
            ),
          ),
          const SizedBox(height: 12),
          ...suborders.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _suborderCard(s),
            ),
          ),
        ],
      );

  Widget _suborderCard(PlacedSubOrderEntity suborder) {
    final date = DateTime.tryParse(suborder.deliveryDate);
    final productNames = suborder.products.map((p) => p.productName).where((n) => n.isNotEmpty).join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  suborder.vendorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A243F),
                    height: 20 / 13,
                  ),
                ),
              ),
              if (suborder.status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatStatus(suborder.status),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0057A8),
                    ),
                  ),
                ),
            ],
          ),
          if (productNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              productNames,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF0A243F).withValues(alpha: 0.7),
                height: 18 / 12,
              ),
            ),
          ],
          if (date != null || suborder.deliverySlot.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (date != null) 'Delivery on ${_formatDate(date)}',
                if (suborder.deliverySlot.isNotEmpty) suborder.deliverySlot,
              ].join(' · '),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A243F),
                height: 18 / 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Bill summary ───────────────────────────────────────────────────────────

  Widget _billSummarySection(PlacedOrderEntity order) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill summary',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
              height: 21 / 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E8EE)),
            ),
            child: Column(
              children: [
                _billRow('Subtotal', order.subTotal),
                if (order.sgst > 0) _billRow('SGST', order.sgst),
                if (order.cgst > 0) _billRow('CGST', order.cgst),
                _billRow('Shipping fee', order.shippingFee),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFE5E8EE)),
                ),
                _billRow('Total paid', order.total, isTotal: true),
                if (order.deliveryAddress != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Delivering to ${order.deliveryAddress!.name.isNotEmpty ? order.deliveryAddress!.name : ''}'
                              '${order.deliveryAddress!.name.isNotEmpty ? ', ' : ''}'
                              '${order.deliveryAddress!.fullAddress}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0A243F).withValues(alpha: 0.7),
                        height: 18 / 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );

  Widget _billRow(String label, double amount, {bool isTotal = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
                color: const Color(0xFF0A243F),
                height: 20 / 13,
              ),
            ),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                color: const Color(0xFF0A243F),
                height: 20 / 13,
              ),
            ),
          ],
        ),
      );

  // ── Next steps ────────────────────────────────────────────────────────────

  Widget _nextStepsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next steps',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A243F),
              height: 21 / 14,
            ),
          ),
          const SizedBox(height: 16),
          _nextStep(
            '1',
            Icons.inventory_2_outlined,
            'Sorting your material to check assured quality requirement',
          ),
          const SizedBox(height: 12),
          _nextStep(
            '2',
            Icons.local_shipping_outlined,
            'Allocating vehicle for super fast delivery',
          ),
          const SizedBox(height: 12),
          _nextStep(
            '3',
            Icons.location_on_outlined,
            'Product delivered at your address',
          ),
        ],
      );

  Widget _nextStep(String num, IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(icon, size: 36, color: const Color(0xFF4FB589)),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF4FB589)),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        num,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4FB589),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0A243F),
                height: 18 / 12,
              ),
            ),
          ),
        ],
      );

  // ── Referral card ─────────────────────────────────────────────────────────

  Widget _referCard() => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F2FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Refer a friend and get ₹500 each',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A243F),
                      height: 22 / 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For every friend you refer, you get ₹500 and your friend gets ₹500 after their first order.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF0A243F).withValues(alpha: 0.7),
                      height: 20 / 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      side: const BorderSide(color: Color(0xFF0A243F)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Refer a friend',
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
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.groups_rounded,
              size: 90,
              color: const Color(0xFF0A243F).withValues(alpha: 0.25),
            ),
          ],
        ),
      );
}
