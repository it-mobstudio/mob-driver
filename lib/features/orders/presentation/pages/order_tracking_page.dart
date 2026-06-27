import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/shared/image_shimmer.dart';

class OrderTrackingPage extends StatelessWidget {
  static const String routeName = 'OrderTrackingPage';
  static const String routePath = '/order-tracking';

  const OrderTrackingPage({
    super.key,
    this.order,
    this.shipment,
  });

  final OrderEntity? order;
  final OrderShipmentEntity? shipment;

  @override
  Widget build(BuildContext context) {
    final items = shipment?.items.isNotEmpty == true
        ? shipment!.items
        : order?.items ?? const <OrderItemEntity>[];
    final orderNumber = shipment?.id.isNotEmpty == true
        ? shipment!.id
        : order?.orderNumber ?? 'OD20260106004961';
    final address = order?.shippingAddress.isNotEmpty == true
        ? order!.shippingAddress
        : '10 Downing Street, 4th floor, Infront of westend mall, Chennai, 600005';
    final shipmentStatus = shipment?.status.trim() ?? '';
    final orderStatus = order?.status.trim() ?? '';
    final trackingStatus =
        shipmentStatus.isNotEmpty ? shipmentStatus : orderStatus;
    final trackingState = _TrackingState.fromStatus(trackingStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F2),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _TrackingHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F1F2),
                  ),
                  child: Column(
                    children: [
                      _TrackingHeroSection(state: trackingState),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                        child: Column(
                          children: [
                            const _DeliveryPartnerCard(),
                            const SizedBox(height: 12),
                            _DeliveryAddressCard(address: address),
                            const SizedBox(height: 12),
                            _TrackingItemsCard(
                              items: items,
                              orderNumber: orderNumber,
                            ),
                            const SizedBox(height: 12),
                            if (trackingState.isOutForDelivery) ...[
                              const _DownloadInvoiceButton(),
                              const SizedBox(height: 12),
                            ],
                            const _TrackingHelpCard(),
                            const SizedBox(height: 32),
                          ],
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
    );
  }
}

class _TrackingHeader extends StatelessWidget {
  const _TrackingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: double.infinity,
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
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: _TrackingColors.navy,
                ),
              ),
            ),
          ),
          Positioned.fill(
            left: 56,
            right: 56,
            child: Center(
              child: Text(
                'Track order',
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
        ],
      ),
    );
  }
}

class _TrackingHeroSection extends StatelessWidget {
  const _TrackingHeroSection({required this.state});

  final _TrackingState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width / 375;
        final sectionHeight = 390 * scale;
        final etaTop = 300 * scale;

        return SizedBox(
          height: sectionHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: _TrackingHero(
                  state: state,
                  height: 404 * scale,
                  gradientHeight: 120 * scale,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: etaTop,
                child: _EtaCard(state: state),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrackingHero extends StatelessWidget {
  const _TrackingHero({
    required this.state,
    required this.height,
    required this.gradientHeight,
  });

  final _TrackingState state;
  final double height;
  final double gradientHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.white),
              ),
            ),
            Positioned.fill(
              child: Image.asset(
                state.heroAsset,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                height: gradientHeight,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.5, 0),
                    end: Alignment(0.5, 1),
                    colors: [
                      Color(0x00F1F1F2),
                      Color(0xFF828282),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtaCard extends StatelessWidget {
  const _EtaCard({required this.state});

  final _TrackingState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDEDEDE)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 16,
            width: 188,
            height: 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/thunder.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF329537),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '3h 30mins',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF010101),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 30 / 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 188,
                  child: Text(
                    state.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _TrackingColors.navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 19,
            right: 16,
            child: Container(
              height: 26,
              width: 86,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E6),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/images/qwik.svg',
                width: 54,
                height: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryPartnerCard extends StatelessWidget {
  const _DeliveryPartnerCard();

  @override
  Widget build(BuildContext context) {
    return _TrackingCard(
      height: 80,
      child: Row(
        children: [
          const _RoundIcon(
            background: Color(0xFFDFF8F9),
            icon: Icons.delivery_dining_rounded,
            iconColor: Color(0xFF0360E5),
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aakash Iyer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _TrackingColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 20 / 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Delivery partner',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _TrackingColors.greyText,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F1F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call_rounded,
              color: Colors.black,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDEDEDE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssetRoundIcon(
            assetPath: 'assets/images/vehicletracking.svg',
            size: 48,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 204,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 204,
                  height: 20,
                  child: Text(
                    'Delivery to Carlos Sainz ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _TrackingColors.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 20 / 13,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: 204,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 54),
                    child: Text(
                      '$address\n+91 9876554324',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF67696D),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                      ),
                    ),
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

class _TrackingItemsCard extends StatelessWidget {
  const _TrackingItemsCard({
    required this.items,
    required this.orderNumber,
  });

  final List<OrderItemEntity> items;
  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(3).toList();

    return _TrackingCard(
      height: 182,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _RoundIcon(
                    background: Color(0xFFDFF8F9),
                    icon: Icons.inventory_2_rounded,
                    iconColor: Color(0xFFD97745),
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${items.isEmpty ? 3 : items.length} items',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _TrackingColors.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 20 / 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Sub order ID: #$orderNumber',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: _TrackingColors.greyText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 18 / 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: Color(0xFF8A8A8A),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < 3; i++)
                              _ProductThumb(
                                item: i < visibleItems.length
                                    ? visibleItems[i]
                                    : null,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDEDEDE)),
          SizedBox(
            height: 41,
            child: Center(
              child: Text(
                'View order summary',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0360E5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 18 / 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadInvoiceButton extends StatelessWidget {
  const _DownloadInvoiceButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(
          Icons.file_download_outlined,
          size: 20,
          color: Color(0xFF0360E5),
        ),
        label: Text(
          'Download invoice',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: const Color(0xFF0360E5),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 21 / 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0360E5),
          side: const BorderSide(color: Color(0xFF0360E5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
          minimumSize: const Size.fromHeight(48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _TrackingHelpCard extends StatelessWidget {
  const _TrackingHelpCard();

  @override
  Widget build(BuildContext context) {
    return _TrackingCard(
      height: 80,
      child: Row(
        children: [
          const _RoundIcon(
            background: Color(0xFFDFF8F9),
            icon: Icons.support_agent_rounded,
            iconColor: Color(0xFF0A243F),
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help with your order?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _TrackingColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Contact us about any issues',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _TrackingColors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F1F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: _TrackingColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.height,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final double height;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDEDEDE)),
      ),
      child: child,
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.size,
  });

  final Color background;
  final IconData icon;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: size * 0.58),
    );
  }
}

class _AssetRoundIcon extends StatelessWidget {
  const _AssetRoundIcon({
    required this.assetPath,
    required this.size,
  });

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({this.item});

  final OrderItemEntity? item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        color: const Color(0xFFF1F1F2),
        child: item?.imageUrl.isNotEmpty == true
            ? CachedNetworkImage(
                imageUrl: item!.imageUrl,
                fit: BoxFit.contain,
                memCacheWidth: 88,
                placeholder: (_, __) => const ImageShimmer(),
                errorWidget: (_, __, ___) => Image.asset(
                  'assets/images/Image-coming-soon.png',
                  fit: BoxFit.contain,
                ),
              )
            : Image.asset(
                'assets/images/Image-coming-soon.png',
                fit: BoxFit.contain,
              ),
      ),
    );
  }
}

enum _TrackingState {
  packing,
  packed,
  outForDelivery;

  factory _TrackingState.fromStatus(String status) {
    final value =
        status.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    final compactValue = value.replaceAll(' ', '');
    if (value.contains('out for delivery') ||
        compactValue.contains('outfordelivery') ||
        value.contains('out for shipment') ||
        value.contains('on the way')) {
      return _TrackingState.outForDelivery;
    }
    if (value.contains('order is packed') ||
        value.contains('your order is packed') ||
        value.contains('packed') ||
        value.contains('ready for pickup') ||
        value.contains('ready to ship')) {
      return _TrackingState.packed;
    }
    return _TrackingState.packing;
  }

  String get subtitle {
    return switch (this) {
      _TrackingState.outForDelivery => 'Out for delivery',
      _TrackingState.packed => 'Your order is packed',
      _TrackingState.packing => 'Packing your order',
    };
  }

  String get heroAsset {
    return switch (this) {
      _TrackingState.outForDelivery => 'assets/images/Deliveredintacking.webp',
      _TrackingState.packed => 'assets/images/Your order is packed.webp',
      _TrackingState.packing => 'assets/images/Packing your order.webp',
    };
  }

  bool get isOutForDelivery => this == _TrackingState.outForDelivery;
}

class _TrackingColors {
  const _TrackingColors._();

  static const navy = Color(0xFF0A243F);
  static const greyText = Color(0xFF67696D);
  static const grey = Color(0xFF8A8A8A);
}
