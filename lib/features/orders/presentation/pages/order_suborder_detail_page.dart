import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextDirection;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:m_o_b_demand_side/shared/image_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class SuborderDetailPage extends StatelessWidget {
  static const String routeName = 'SuborderDetailPage';
  static const String routePath = '/suborder-detail';

  const SuborderDetailPage({super.key, this.order, this.shipment});

  final OrderEntity? order;
  final OrderShipmentEntity? shipment;

  @override
  Widget build(BuildContext context) {
    if (order == null || shipment == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: Color(0xFF0A243F)),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Suborder details',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(child: Text('No suborder data')),
      );
    }

    final ord = order!;
    final ship = shipment!;

    final isDelivered = _isDeliveredStatus(ship.status);
    final isOutForDelivery = _isOutForDeliveryStatus(ship.status);

    final statusColor = isDelivered
        ? const Color(0xFF0BCB60)
        : isOutForDelivery
            ? const Color(0xFF0360E5)
            : const Color(0xFF0A243F);

    final statusIcon = isDelivered
        ? Icons.check_circle_rounded
        : isOutForDelivery
            ? Icons.local_shipping_outlined
            : Icons.inventory_2_rounded;

    final deliveryLabel = _buildDeliveryLabel(ord, ship);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _SuborderHeader(
              orderNumber: ord.orderNumber,
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 24),
                child: Column(
                  children: [
                    // Status + Items section
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status tile — taps to tracking
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => context.push(
                              OrderTrackingPage.routePath,
                              extra: {'order': ord, 'shipment': ship},
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDelivered
                                        ? const Color(0xFFCEFBE3)
                                        : isOutForDelivery
                                            ? const Color(0xFFDFF8F9)
                                            : const Color(0xFFFFF2C3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(statusIcon,
                                      size: 22, color: statusColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatStatus(ship.status),
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF0A243F),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          height: 26 / 18,
                                        ),
                                      ),
                                      if (deliveryLabel.isNotEmpty)
                                        Text(
                                          deliveryLabel,
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF596378),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            height: 18 / 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    size: 24, color: Color(0xFF0A243F)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(
                              height: 0,
                              thickness: 1,
                              color: Color(0xFFE0E0E0)),
                          const SizedBox(height: 14),
                          Text(
                            '${ship.items.length} ${ship.items.length == 1 ? 'item' : 'items'} in shipment',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0A243F),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 20 / 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (var i = 0; i < ship.items.length; i++) ...[
                            _SuborderItemTile(item: ship.items[i]),
                            if (i < ship.items.length - 1)
                              const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                    _gap(),
                    // Bill details
                    _SuborderBillSection(shipment: ship),
                    _gap(),
                    // Order details
                    _SuborderInfoSection(order: ord, shipment: ship),
                    _gap(),
                    // Help tile
                    _HelpTile(),
                    _gap(),
                    // Promo footer
                    _PromoFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gap() => Container(height: 12, color: const Color(0xFFF1F1F2));

  String _formatStatus(String status) {
    if (status.trim().isEmpty) return 'Processing';
    return '${status[0].toUpperCase()}${status.substring(1).replaceAll('_', ' ')}';
  }

  bool _isDeliveredStatus(String status) {
    final s = status.trim().toLowerCase().replaceAll('_', ' ');
    if (_isOutForDeliveryStatus(status)) return false;
    return s.contains('delivered') ||
        s.contains('completed') ||
        s.contains('fulfilled');
  }

  bool _isOutForDeliveryStatus(String status) {
    final s = status.trim().toLowerCase().replaceAll('_', ' ');
    return s.contains('out for delivery') || s.contains('on the way');
  }

  String _buildDeliveryLabel(OrderEntity order, OrderShipmentEntity ship) {
    if (ship.deliverySlot.isNotEmpty) return ship.deliverySlot;
    if (order.status.trim() == 'Order Delivered') {
      final date = _formatDate(order.createdAt);
      return date.isNotEmpty ? 'Delivered $date' : 'Delivered';
    }
    final date = _formatDate(ship.deliveryDate);
    return date.isNotEmpty ? 'Arriving by $date' : '';
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return '';
    }
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _SuborderHeader extends StatelessWidget {
  const _SuborderHeader({required this.orderNumber, required this.onBack});

  final String orderNumber;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: 48,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.expand(),
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Color(0xFF0A243F)),
              ),
            ),
          ),
          Positioned.fill(
            left: 56,
            right: 56,
            child: Center(
              child: Text(
                orderNumber.isNotEmpty ? 'Order #$orderNumber' : 'Suborder',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 22 / 15,
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F1F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded,
                  size: 18, color: Color(0xFF0A243F)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item tile ────────────────────────────────────────────────────────────────

class _SuborderItemTile extends StatelessWidget {
  const _SuborderItemTile({required this.item});

  final OrderItemEntity item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 44,
              height: 44,
              color: const Color(0xFFF1F1F2),
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.contain,
                      memCacheWidth: 88,
                      placeholder: (_, __) => const ImageShimmer(),
                      errorWidget: (_, __, ___) =>
                          const ProductImagePlaceholder(),
                    )
                  : const ProductImagePlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 18 / 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.unitPrice.toStringAsFixed(0)} /unit  •  ${item.qty} units',
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
            '₹${item.lineTotal.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bill section ─────────────────────────────────────────────────────────────

class _SuborderBillSection extends StatelessWidget {
  const _SuborderBillSection({required this.shipment});

  final OrderShipmentEntity shipment;

  @override
  Widget build(BuildContext context) {
    final subTotal = shipment.subTotal;
    final total = shipment.total;
    final savedAmount = subTotal > total ? subTotal - total : 0.0;
    final points = shipment.rewardPoints;
    final rewardMessage = shipment.rewardMessage;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill details',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 24 / 17,
            ),
          ),
          const SizedBox(height: 12),
          _BillRow(label: 'Subtotal', value: '₹${subTotal.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
          _BillRow(
            label: 'Total',
            value: '₹${total.toStringAsFixed(2)}',
            bold: true,
          ),
          if (savedAmount > 0) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFCEFBE3)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'SAVED ₹${savedAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF329537),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 16 / 11,
                  ),
                ),
              ),
            ),
          ],
          if (points > 0 || rewardMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDFF8F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    'You will earn',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A243F),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset('assets/images/points.svg',
                      width: 16, height: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      rewardMessage.isNotEmpty
                          ? rewardMessage
                          : '$points points on this purchase',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (shipment.proformaInvoiceUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(shipment.proformaInvoiceUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.file_download_outlined,
                    size: 20, color: Color(0xFF0360E5)),
                label: Text(
                  'Download invoice',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0360E5),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0360E5),
                  side: const BorderSide(color: Color(0xFF0360E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final fs = bold ? 14.0 : 13.0;
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: bold ? const Color(0xFF0A243F) : const Color(0xFF67696D),
            fontSize: fs,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            height: 20 / fs,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            color: const Color(0xFF0A243F),
            fontSize: fs,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            height: 20 / fs,
          ),
        ),
      ],
    );
  }
}

// ── Order info section ────────────────────────────────────────────────────────

class _SuborderInfoSection extends StatelessWidget {
  const _SuborderInfoSection({required this.order, required this.shipment});

  final OrderEntity order;
  final OrderShipmentEntity shipment;

  String _fmt(String iso) {
    if (iso.isEmpty) return '—';
    try {
      return DateFormat("dd MMM yyyy 'at' hh:mm a")
          .format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  String _fmtPhone(String p) =>
      p.isEmpty ? '' : (p.startsWith('+') ? p : '+91 $p');

  String _fmtPayment(String m) {
    const map = {
      'mobWALLET': 'MOB Wallet',
      'mobCREDIT': 'MOB Credit',
      'RAZORPAY': 'Razorpay',
      'COD': 'Cash on delivery',
    };
    return map[m] ?? m;
  }

  @override
  Widget build(BuildContext context) {
    final payment = order.paymentMethods.isEmpty
        ? '—'
        : order.paymentMethods.map(_fmtPayment).join(', ');
    final deliveryPhone = _fmtPhone(order.deliveryPhone);
    final deliveryAddr = [
      order.shippingAddress,
      if (deliveryPhone.isNotEmpty) deliveryPhone,
    ].where((p) => p.isNotEmpty).join('\n');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order details',
            style: GoogleFonts.inter(
              color: const Color(0xFF0A243F),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 24 / 17,
            ),
          ),
          const SizedBox(height: 8),
          _InfoLabel('Order ID'),
          GestureDetector(
            onTap: () =>
                Clipboard.setData(ClipboardData(text: order.orderNumber)),
            child: Row(
              children: [
                _InfoValue(order.orderNumber),
                const SizedBox(width: 8),
                Icon(Icons.copy_rounded, size: 16, color: Colors.grey.shade600),
              ],
            ),
          ),
          if (shipment.id.isNotEmpty && shipment.id != order.orderNumber) ...[
            const SizedBox(height: 10),
            _InfoLabel('Suborder ID'),
            GestureDetector(
              onTap: () => Clipboard.setData(ClipboardData(text: shipment.id)),
              child: Row(
                children: [
                  _InfoValue(shipment.id),
                  const SizedBox(width: 8),
                  Icon(Icons.copy_rounded,
                      size: 16, color: Colors.grey.shade600),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          _InfoLabel('Order placed'),
          _InfoValue(_fmt(order.createdAt)),
          const SizedBox(height: 10),
          _InfoLabel('Payment method'),
          _InfoValue(payment),
          if (order.deliveryName.isNotEmpty || deliveryAddr.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoLabel('Delivery address'),
            if (order.deliveryName.isNotEmpty) _InfoValue(order.deliveryName),
            if (deliveryAddr.isNotEmpty) _InfoValue(deliveryAddr),
          ],
        ],
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  const _InfoLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          color: const Color(0xFF67696D),
          fontSize: 11,
          fontWeight: FontWeight.w400,
          height: 16 / 11,
        ),
      );
}

class _InfoValue extends StatelessWidget {
  const _InfoValue(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          color: const Color(0xFF0A243F),
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 20 / 13,
        ),
      );
}

// ── Help tile ─────────────────────────────────────────────────────────────────

class _HelpTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFDFF8F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Color(0xFF0A7D83), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help with your order?',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0A243F),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                  ),
                ),
                Text(
                  'Contact us about any issues',
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
          const Icon(Icons.chevron_right_rounded,
              size: 24, color: Color(0xFF0A243F)),
        ],
      ),
    );
  }
}

// ── Promo footer ──────────────────────────────────────────────────────────────

class _PromoFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFCBEFF9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Text(
            'Making\nconstruction\nreliable',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 40 / 32,
            ).copyWith(
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Color(0xFF3991E2), Color(0xFF81D9C3)],
                ).createShader(const Rect.fromLTWH(0, 0, 260, 130)),
            ),
          ),
          Positioned(
            left: 0,
            top: 130,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              alignment: Alignment.center,
              child: Text(
                'mob',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0A243F),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.construction_rounded,
              size: 120,
              color: const Color(0xFF0A243F).withValues(alpha: 0.20),
            ),
          ),
        ],
      ),
    );
  }
}
