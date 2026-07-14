import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextDirection;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/orders/domain/entities/order_entity.dart';
import 'package:m_o_b_demand_side/features/orders/domain/repositories/orders_repository.dart';
import 'package:m_o_b_demand_side/shared/image_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

/// Resolves to true once the user has actually submitted a rating during
/// this sheet's lifetime (whenever they close it, at any point after).
Future<bool> showOrderRatingSheet(
  BuildContext context, {
  required String suborderId,
}) async {
  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => _OrderRatingSheet(suborderId: suborderId),
  );
  return submitted ?? false;
}

Future<void> _showOrderStatusSheet(
  BuildContext context,
  List<_TrackingTimelineItem> items,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => _OrderStatusSheet(items: items),
  );
}

String _mapString(
  Map<String, dynamic>? map,
  List<String> keys,
) {
  if (map == null) return '';
  for (final key in keys) {
    final value = map[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

Map<String, dynamic>? _trackOrderPayload(Map<String, dynamic>? map) {
  if (map == null) return null;
  for (final key in const ['data', 'result', 'tracking', 'track_order']) {
    final value = map[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return map;
}

bool _isQuickOrderResponse(Map<String, dynamic>? map) {
  final value = _mapString(
    _trackOrderPayload(map),
    const ['is_quick_order', 'isQuickOrder'],
  ).toLowerCase();
  if (value.isEmpty) return false;
  return value != 'normal_order' &&
      value != 'normal' &&
      value != 'false' &&
      value != '0';
}

String _formatTrackingDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = date.day;
  final suffix = switch (day) {
    11 || 12 || 13 => 'th',
    _ when day % 10 == 1 => 'st',
    _ when day % 10 == 2 => 'nd',
    _ when day % 10 == 3 => 'rd',
    _ => 'th',
  };
  return '$day$suffix ${months[date.month - 1]}';
}

String _formatTrackingDateTime(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  try {
    final date = DateTime.parse(value).toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'pm' : 'am';
    return 'on ${_formatTrackingDate(date)} at $hour:$minute$period';
  } catch (_) {
    return value;
  }
}

enum _TrackingTimelineStage {
  placed,
  packing,
  packed,
  outForDelivery,
  delivered;

  String get label {
    return switch (this) {
      _TrackingTimelineStage.placed => 'Order placed',
      _TrackingTimelineStage.packing => 'Packing your order',
      _TrackingTimelineStage.packed => 'Your order is packed',
      _TrackingTimelineStage.outForDelivery => 'Out for delivery',
      _TrackingTimelineStage.delivered => 'Delivered',
    };
  }
}

class _TrackingTimelineItem {
  const _TrackingTimelineItem({
    required this.stage,
    required this.timeText,
    required this.completed,
  });

  final _TrackingTimelineStage stage;
  final String timeText;
  final bool completed;
}

_TrackingTimelineStage _timelineStageFromState(_TrackingState state) {
  return switch (state) {
    _TrackingState.packing => _TrackingTimelineStage.packing,
    _TrackingState.packed => _TrackingTimelineStage.packed,
    _TrackingState.outForDelivery => _TrackingTimelineStage.outForDelivery,
    _TrackingState.delivered => _TrackingTimelineStage.delivered,
  };
}

_TrackingTimelineStage? _timelineStageFromStatus(String status) {
  final value =
      status.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
  final compactValue = value.replaceAll(' ', '');
  if (value.isEmpty) return null;
  if (value.contains('waiting') ||
      value.contains('order placed') ||
      compactValue == 'orderplaced') {
    return _TrackingTimelineStage.placed;
  }
  if (value.contains('out of delivery') ||
      value.contains('out for delivery') ||
      compactValue.contains('outfordelivery') ||
      compactValue.contains('outofdelivery') ||
      value.contains('out for shipment') ||
      value.contains('on the way')) {
    return _TrackingTimelineStage.outForDelivery;
  }
  if (value.contains('delivered') ||
      value.contains('completed') ||
      value.contains('received') ||
      value.contains('fulfilled') ||
      compactValue == 'deliver') {
    return _TrackingTimelineStage.delivered;
  }
  if (value.contains('order is packed') ||
      value.contains('ready for pickup') ||
      compactValue == 'readyforpickup' ||
      value.contains('ready to ship') ||
      value.contains('packed')) {
    return _TrackingTimelineStage.packed;
  }
  if (value.contains('packing') ||
      value.contains('processing') ||
      value.contains('created')) {
    return _TrackingTimelineStage.packing;
  }
  return null;
}

List<_TrackingTimelineItem> _buildTrackingTimeline({
  required OrderEntity? order,
  required OrderShipmentEntity? shipment,
  required _TrackingState trackingState,
}) {
  final stageTimes = <_TrackingTimelineStage, String>{};
  final orderCreatedAt = _formatTrackingDateTime(order?.createdAt ?? '');
  if (orderCreatedAt.isNotEmpty) {
    stageTimes[_TrackingTimelineStage.placed] = orderCreatedAt;
  }

  final shipmentCreatedAt = _formatTrackingDateTime(shipment?.createdAt ?? '');
  final shipmentStage = _timelineStageFromStatus(shipment?.status ?? '');
  if (shipmentStage != null && shipmentCreatedAt.isNotEmpty) {
    stageTimes[shipmentStage] = shipmentCreatedAt;
  }

  for (final suborder in order?.shipments ?? const <OrderShipmentEntity>[]) {
    final stage = _timelineStageFromStatus(suborder.status);
    final timeText = _formatTrackingDateTime(suborder.createdAt);
    if (stage != null && timeText.isNotEmpty) {
      stageTimes[stage] = timeText;
    }
  }

  final currentStage =
      shipmentStage ?? _timelineStageFromStatus(order?.status ?? '') ??
          _timelineStageFromState(trackingState);
  final completedIndex =
      currentStage.index < _TrackingTimelineStage.packing.index
          ? _TrackingTimelineStage.placed.index
          : currentStage.index;

  return _TrackingTimelineStage.values
      .map(
        (stage) => _TrackingTimelineItem(
          stage: stage,
          timeText: stageTimes[stage] ?? '',
          completed: stage.index <= completedIndex,
        ),
      )
      .toList();
}

String _currentTrackingTimelineTime(
  List<_TrackingTimelineItem> items,
  _TrackingState state,
) {
  final stage = _timelineStageFromState(state);
  for (final item in items) {
    if (item.stage == stage && item.timeText.isNotEmpty) return item.timeText;
  }
  for (final item in items.reversed) {
    if (item.completed && item.timeText.isNotEmpty) return item.timeText;
  }
  return '';
}

class OrderTrackingPage extends StatefulWidget {
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
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  late bool _hasReview = widget.shipment?.hasReview ?? false;
  Map<String, dynamic>? _trackOrderBody;

  @override
  void initState() {
    super.initState();
    _loadTrackOrder();
  }

  Future<void> _loadTrackOrder() async {
    final suborderId = widget.shipment?.id.trim() ?? '';
    if (suborderId.isEmpty) return;

    final (body, failure) = await sl<OrdersRepository>().trackOrder(suborderId);
    if (!mounted) return;
    if (failure != null) {
      debugPrint('track_order failed: ${failure.message}');
      return;
    }
    setState(() => _trackOrderBody = body);
    debugPrint('track_order response: $_trackOrderBody');
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shipment = widget.shipment;
    final items = shipment?.items.isNotEmpty == true
        ? shipment!.items
        : order?.items ?? const <OrderItemEntity>[];
    final orderNumber = shipment?.id.isNotEmpty == true
        ? shipment!.id
        : order?.orderNumber ?? '';
    final address =
        order?.shippingAddress.isNotEmpty == true ? order!.shippingAddress : '';
    final deliveryName = order?.deliveryName ?? '';
    final rawPhone = order?.deliveryPhone ?? '';
    final deliveryPhone = rawPhone.isNotEmpty
        ? (rawPhone.startsWith('+') ? rawPhone : '+91 $rawPhone')
        : '';
    final shipmentStatus = shipment?.status.trim() ?? '';
    final orderStatus = order?.status.trim() ?? '';
    final trackingStatus =
        shipmentStatus.isNotEmpty ? shipmentStatus : orderStatus;
    final trackingState = _TrackingState.fromStatus(trackingStatus);
    final deliverySlot = shipment?.deliverySlot ?? '';
    // final vendorName = shipment?.vendorName ?? '';
    // final vehicleAssigned = shipment?.vehicleAssigned ?? false;
    final invoiceUrl = shipment?.proformaInvoiceUrl ?? '';
    final formattedDeliveryDate = () {
      final raw = shipment?.deliveryDate.trim() ?? '';
      if (raw.isEmpty) return '';
      try {
        return _formatTrackingDate(DateTime.parse(raw).toLocal());
      } catch (_) {
        return raw;
      }
    }();
    final deliveryDate =
        formattedDeliveryDate.isNotEmpty ? formattedDeliveryDate : '';
    final isQuickOrder = _trackOrderBody == null
        ? order?.isQuickCommerceOrder ?? false
        : _isQuickOrderResponse(_trackOrderBody);
    final arrivingIn = _mapString(
      _trackOrderPayload(_trackOrderBody),
      const ['arriving_in', 'arrivingIn', 'eta'],
    );
    final timelineItems = _buildTrackingTimeline(
      order: order,
      shipment: shipment,
      trackingState: trackingState,
    );
    final normalStatusTime =
        _currentTrackingTimelineTime(timelineItems, trackingState);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F2),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TrackingHeader(title: trackingState.headerTitle),
            Expanded(
              child: SingleChildScrollView(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F1F2),
                  ),
                  child: Column(
                    children: [
                      _TrackingHeroSection(
                        state: trackingState,
                        deliveryDate: deliveryDate,
                        deliverySlot: deliverySlot,
                        isQuickOrder: isQuickOrder,
                        arrivingIn: arrivingIn,
                        normalStatusTime: normalStatusTime,
                        onNormalStatusTap: isQuickOrder
                            ? null
                            : () => _showOrderStatusSheet(
                                  context,
                                  timelineItems,
                                ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                        child: Column(
                          children: [
                            if (!trackingState.isDelivered) ...[
                              // if (vehicleAssigned) ...[
                              //   _DeliveryPartnerCard(vendorName: vendorName),
                              //   const SizedBox(height: 12),
                              // ],
                              _DeliveryAddressCard(
                                address: address,
                                deliveryName: deliveryName,
                                deliveryPhone: deliveryPhone,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (trackingState.canDownloadInvoice &&
                                invoiceUrl.isNotEmpty) ...[
                              _DownloadInvoiceButton(invoiceUrl: invoiceUrl),
                              const SizedBox(height: 12),
                            ],
                            _TrackingItemsCard(
                              items: items,
                              orderNumber: orderNumber,
                              onViewSummary: order == null || shipment == null
                                  ? null
                                  : () => context.push(
                                        '/order-detail',
                                        extra: order.id,
                                      ),
                            ),
                            const SizedBox(height: 12),
                            const _TrackingHelpCard(),
                            if (!_hasReview) ...[
                              const SizedBox(height: 12),
                              _TrackingRatingCard(
                                suborderId: orderNumber,
                                onReviewSubmitted: () =>
                                    setState(() => _hasReview = true),
                              ),
                            ],
                            const SizedBox(height: 20),
                            ReferralEarnCard(
                              onTap: () {
                                context.push('/refer-a-friend');
                              },
                              backgroundSvg: 'assets/images/giftbox.webp',
                            ),
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
  const _TrackingHeader({required this.title});

  final String title;

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
                icon: const AppBackIcon(),
              ),
            ),
          ),
          Positioned.fill(
            left: 56,
            right: 56,
            child: Center(
              child: Text(
                title,
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
  const _TrackingHeroSection({
    required this.state,
    required this.deliveryDate,
    required this.deliverySlot,
    required this.isQuickOrder,
    required this.arrivingIn,
    required this.normalStatusTime,
    required this.onNormalStatusTap,
  });

  final _TrackingState state;
  final String deliveryDate;
  final String deliverySlot;
  final bool isQuickOrder;
  final String arrivingIn;
  final String normalStatusTime;
  final VoidCallback? onNormalStatusTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = width / 375;
        final sectionHeight = state.isDelivered ? 430 * scale : 390 * scale;
        final etaTop = state.isDelivered ? 344 * scale : 300 * scale;

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
                  height: state.isDelivered ? 448 * scale : 404 * scale,
                  gradientHeight: 120 * scale,
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: etaTop,
                child: _EtaCard(
                  state: state,
                  deliveryDate: deliveryDate,
                  deliverySlot: deliverySlot,
                  isQuickOrder: isQuickOrder,
                  arrivingIn: arrivingIn,
                  normalStatusTime: normalStatusTime,
                  onTap: onNormalStatusTap,
                ),
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
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: state.isDelivered
                      ? const Color(0xFF05060A)
                      : Colors.white,
                  gradient: state.isDelivered
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF05060A), Color(0xFF373E52)],
                        )
                      : null,
                ),
              ),
            ),
            if (state.isOutForDelivery)
              Positioned(
                left: 0,
                right: 0,
                top: height * 0.077,
                height: height * 0.696,
                child: _heroAsset(
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              )
            else if (state.isDelivered)
              Positioned(
                left: 0,
                right: 0,
                top: height * 0.02,
                bottom: height * 0.17,
                child: _heroAsset(
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              )
            else
              Positioned.fill(
                child: _heroAsset(
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            if (!state.isDelivered)
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

  Widget _heroAsset({
    required BoxFit fit,
    required AlignmentGeometry alignment,
  }) {
    final asset = state.heroAsset;
    if (asset.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        asset,
        fit: fit,
        alignment: alignment,
      );
    }
    return Image.asset(
      asset,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
    );
  }
}

class _EtaCard extends StatelessWidget {
  const _EtaCard({
    required this.state,
    required this.deliveryDate,
    required this.deliverySlot,
    required this.isQuickOrder,
    required this.arrivingIn,
    required this.normalStatusTime,
    required this.onTap,
  });

  final _TrackingState state;
  final String deliveryDate;
  final String deliverySlot;
  final bool isQuickOrder;
  final String arrivingIn;
  final String normalStatusTime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (isQuickOrder) return _quickOrderCard();

    final title = state.subtitle;
    final scheduleText = _scheduleText();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDEDEDE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF010101),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 30 / 24,
                    ),
                  ),
                  if (scheduleText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      scheduleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0A243F),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            SvgPicture.asset(
              'assets/images/Track-Arrow.svg',
              width: 24,
              height: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickOrderCard() {
    final etaText = arrivingIn.trim().isNotEmpty ? arrivingIn.trim() : '--';

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
                    state.isDelivered
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF10B320),
                            size: 24,
                          )
                        : SvgPicture.asset(
                            'assets/images/thunder.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF329537),
                              BlendMode.srcIn,
                            ),
                          ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        state.isDelivered ? 'Delivered' : etaText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF010101),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 30 / 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 188,
                  child: Text(
                    state.isDelivered ? deliveryDate : state.subtitle,
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

  String _scheduleText() {
    final statusTime = normalStatusTime.trim();
    if (statusTime.isNotEmpty) return statusTime;
    final date = deliveryDate.trim();
    final slot = deliverySlot.trim();
    if (date.isNotEmpty && slot.isNotEmpty) return 'on $date at $slot';
    if (date.isNotEmpty) return 'on $date';
    if (slot.isNotEmpty) return 'at $slot';
    return '';
  }
}

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({
    required this.address,
    required this.deliveryName,
    required this.deliveryPhone,
  });

  final String address;
  final String deliveryName;
  final String deliveryPhone;

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
          const _RoundIcon(
            background: Color(0xFFDFF8F9),
            svgAsset: 'assets/images/vehicletracking.svg',
            size: 48,
            imageWidth: 48,
            imageHeight: 48,
            svgAlignment: Alignment.centerLeft,
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
                    deliveryName.isNotEmpty
                        ? 'Delivery to $deliveryName'
                        : 'Delivery address',
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
                      '$address${deliveryPhone.isNotEmpty ? '\n$deliveryPhone' : ''}',
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
    required this.onViewSummary,
  });

  final List<OrderItemEntity> items;
  final String orderNumber;
  final VoidCallback? onViewSummary;

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
                    svgAsset: 'assets/images/Mobitem.svg',
                    size: 48,
                    imageWidth: 48,
                    imageHeight: 48,
                    svgAlignment: Alignment.bottomCenter,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${items.length} items',
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
                            GestureDetector(
                                onTap: () => Clipboard.setData(
                                    ClipboardData(text: orderNumber)),
                                child: SvgPicture.asset(
                                  'assets/images/copy.svg',
                                )),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          children: [
                            for (final item in visibleItems)
                              _ProductThumb(item: item),
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
          InkWell(
            onTap: onViewSummary,
            child: SizedBox(
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
          ),
        ],
      ),
    );
  }
}

class _DownloadInvoiceButton extends StatelessWidget {
  const _DownloadInvoiceButton({required this.invoiceUrl});

  final String invoiceUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final uri = Uri.tryParse(invoiceUrl);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
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

  static const _whatsappNumber = '918970415365';

  Future<void> _openWhatsapp(BuildContext context) async {
    AppHaptics.lightTap();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(
      Uri.parse('https://wa.me/$_whatsappNumber'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Unable to open WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openWhatsapp(context),
      child: _TrackingCard(
        height: 80,
        child: Row(
          children: [
            const _RoundIcon(
              background: Color(0xFFDFF8F9),
              svgAsset: 'assets/images/supportagent.svg',
              size: 40,
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
      ),
    );
  }
}

class _TrackingRatingCard extends StatelessWidget {
  const _TrackingRatingCard({
    required this.suborderId,
    required this.onReviewSubmitted,
  });

  final String suborderId;
  final VoidCallback onReviewSubmitted;

  @override
  Widget build(BuildContext context) {
    return _TrackingCard(
      height: 80,
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Lottie.asset(
              'assets/lottiejson/rating_6_slight_smile.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'How likely are you to recommend us?',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _TrackingColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () async {
              final submitted = await showOrderRatingSheet(
                context,
                suborderId: suborderId,
              );
              if (submitted) onReviewSubmitted();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0360E5),
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Rate',
              style: GoogleFonts.inter(
                color: const Color(0xFF0360E5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 18 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusSheet extends StatelessWidget {
  const _OrderStatusSheet({required this.items});

  final List<_TrackingTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = 492.0 + bottomInset;
    final completedCount = items.where((item) => item.completed).length;

    return SizedBox(
      height: sheetHeight + 72,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/close-dark.svg',
                    width: 44,
                    height: 44,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: sheetHeight,
              padding: EdgeInsets.fromLTRB(16, 26, 16, 24 + bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order status',
                    style: GoogleFonts.inter(
                      color: _TrackingColors.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 28 / 20,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (var i = 0; i < items.length; i++)
                    _OrderStatusTimelineRow(
                      item: items[i],
                      isLast: i == items.length - 1,
                      showCompletedConnector: completedCount > 1 &&
                          items[i].completed &&
                          i < items.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusTimelineRow extends StatelessWidget {
  const _OrderStatusTimelineRow({
    required this.item,
    required this.isLast,
    required this.showCompletedConnector,
  });

  final _TrackingTimelineItem item;
  final bool isLast;
  final bool showCompletedConnector;

  @override
  Widget build(BuildContext context) {
    final completed = item.completed;
    final circleColor =
        completed ? const Color(0xFF35B971) : const Color(0xFFE1E1E1);
    final textColor =
        completed ? _TrackingColors.navy : const Color(0xFF67696D);

    return SizedBox(
      height: isLast ? 50 : 68,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: isLast ? 50 : 68,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 22,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      color: const Color(0xFFDEDEDE),
                    ),
                  ),
                if (showCompletedConnector)
                  Positioned(
                    top: 22,
                    bottom: 0,
                    child: Container(
                      width: 4,
                      color: const Color(0xFF35B971),
                    ),
                  ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: completed
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.stage.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 20 / 14,
                    ),
                  ),
                  if (completed && item.timeText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.timeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7D8492),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRatingSheet extends StatefulWidget {
  const _OrderRatingSheet({required this.suborderId});

  final String suborderId;

  @override
  State<_OrderRatingSheet> createState() => _OrderRatingSheetState();
}

class _OrderRatingSheetState extends State<_OrderRatingSheet> {
  double _rating = 9;
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final failure = await sl<OrdersRepository>().submitReview(
      suborderId: widget.suborderId,
      rating: _rating.round(),
    );
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (failure != null) {
        _errorMessage = failure.message;
      } else {
        _isSubmitted = true;
      }
    });
  }

  String get _emoji {
    final value = _rating.round();
    return switch (value) {
      0 => '😡',
      1 => '😠',
      2 => '😞',
      3 => '🙁',
      4 => '😕',
      5 => '😐',
      6 => '🙂',
      7 => '😊',
      8 => '😃',
      9 => '😁',
      _ => '🤩',
    };
  }

  String? get _emojiLottieAsset {
    return switch (_rating.round()) {
      0 => 'assets/lottiejson/rating_0_1_symbols_angry.json',
      1 => 'assets/lottiejson/rating_0_1_symbols_angry.json',
      2 => 'assets/lottiejson/rating_2_3_angry.json',
      3 => 'assets/lottiejson/rating_2_3_angry.json',
      4 => 'assets/lottiejson/rating_4_frown.json',
      5 => 'assets/lottiejson/rating_5_neutral.json',
      6 => 'assets/lottiejson/rating_6_slight_smile.json',
      7 => 'assets/lottiejson/rating_7_8_smiley.json',
      8 => 'assets/lottiejson/rating_7_8_smiley.json',
      9 => 'assets/lottiejson/rating_10_heart_eyes.json',
      10 => 'assets/lottiejson/rating_10_heart_eyes.json',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = 456.0 + bottomInset;

    return SizedBox(
      height: sheetHeight + 60,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(_isSubmitted),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.close_rounded,
                    color: _TrackingColors.navy,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: sheetHeight,
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isSubmitted) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: SizedBox(
                        width: 144,
                        height: 144,
                        child: Image.asset(
                          'assets/images/Thank you.webp',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Thank you for the feedback!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: _TrackingColors.navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 26 / 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ] else ...[
                    Text(
                      'How likely are you to recommend Mad over buildings to family & friends?',
                      style: GoogleFonts.inter(
                        color: _TrackingColors.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 26 / 18,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                              scale: animation, child: child);
                        },
                        child: _emojiLottieAsset == null
                            ? Text(
                                _emoji,
                                key: ValueKey('emoji-$_emoji'),
                                style: const TextStyle(fontSize: 78, height: 1),
                              )
                            : Lottie.asset(
                                _emojiLottieAsset!,
                                key: ValueKey(_emojiLottieAsset),
                                width: 88,
                                height: 88,
                                repeat: true,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 31),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Not likely',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF767C8F),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 20 / 14,
                            ),
                          ),
                          Text(
                            'Extremely likely',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF767C8F),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 20 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 12,
                          activeTrackColor: const Color(0xFF20C677),
                          inactiveTrackColor: const Color(0xFFDADADA),
                          tickMarkShape: const RoundSliderTickMarkShape(
                            tickMarkRadius: 4,
                          ),
                          activeTickMarkColor:
                              Colors.white.withValues(alpha: 0.4),
                          inactiveTickMarkColor:
                              Colors.white.withValues(alpha: 0.4),
                          thumbShape: const _RatingSliderThumbShape(),
                          overlayShape: SliderComponentShape.noOverlay,
                          trackShape: const RoundedRectSliderTrackShape(),
                        ),
                        child: Slider(
                          min: 0,
                          max: 10,
                          divisions: 10,
                          value: _rating,
                          onChanged: (value) => setState(() => _rating = value),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 31),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i <= 10; i++)
                            SizedBox(
                              width: 20,
                              child: Text(
                                '$i',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: i == _rating.round()
                                      ? _TrackingColors.navy
                                      : const Color(0xFF767C8F),
                                  fontSize: 14,
                                  fontWeight: i == _rating.round()
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  height: 20 / 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD32F2F),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 18 / 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF0360E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Submit',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 21 / 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSliderThumbShape extends SliderComponentShape {
  const _RatingSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(40, 40);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final fillPaint = Paint()..color = Colors.white;
    final iconPaint = Paint()
      ..color = const Color(0xFFB8B8B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(center.translate(0, 2), 20, shadowPaint);
    canvas.drawCircle(center, 20, fillPaint);

    final leftPath = Path()
      ..moveTo(center.dx - 5, center.dy - 5)
      ..lineTo(center.dx - 10, center.dy)
      ..lineTo(center.dx - 5, center.dy + 5);
    final rightPath = Path()
      ..moveTo(center.dx + 5, center.dy - 5)
      ..lineTo(center.dx + 10, center.dy)
      ..lineTo(center.dx + 5, center.dy + 5);
    canvas.drawPath(leftPath, iconPaint);
    canvas.drawPath(rightPath, iconPaint);
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
    super.key,
    required this.background,
    required this.size,
    this.icon,
    this.svgAsset,
    this.iconColor,
    this.iconScale = 0.52,
    this.imageWidth,
    this.imageHeight,
    this.svgAlignment = Alignment.center,
  }) : assert(
          icon != null || svgAsset != null,
          'Provide either icon or svgAsset.',
        );

  final Color background;
  final IconData? icon;
  final String? svgAsset;
  final Color? iconColor;
  final double size;
  final double iconScale;

  /// Optional custom image size
  final double? imageWidth;
  final double? imageHeight;

  final Alignment svgAlignment;

  @override
  Widget build(BuildContext context) {
    final innerSize = size * iconScale;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: imageWidth ?? innerSize,
          height: imageHeight ?? innerSize,
          child: svgAsset != null
              ? SvgPicture.asset(
                  svgAsset!,
                  width: imageWidth ?? innerSize,
                  height: imageHeight ?? innerSize,
                  fit: BoxFit.contain,
                  alignment: svgAlignment,
                  colorFilter: iconColor == null
                      ? null
                      : ColorFilter.mode(
                          iconColor!,
                          BlendMode.srcIn,
                        ),
                )
              : Icon(
                  icon,
                  color: iconColor,
                  size: imageWidth ?? innerSize,
                ),
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.item});

  final OrderItemEntity item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
                errorWidget: (_, __, ___) => const ProductImagePlaceholder(),
              )
            : const ProductImagePlaceholder(),
      ),
    );
  }
}

class ReferralEarnCard extends StatelessWidget {
  const ReferralEarnCard({
    super.key,
    required this.onTap,
    required this.backgroundSvg,
  });

  final VoidCallback onTap;
  final String backgroundSvg;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 343 / 160,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF020202),
                      Color(0xFF372114),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned(
                        left: width * 0.047,
                        top: height * 0.10,
                        right: width * 0.34,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Refer a friend & earn ',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.44,
                                ),
                              ),
                              TextSpan(
                                text: '₹1000',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFFACF5B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.44,
                                ),
                              ),
                              TextSpan(
                                text: ' each',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  height: 1.44,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Positioned(
                        left: width * 0.047,
                        bottom: height * 0.10,
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [
                                Color(0xFFFBCF5C),
                                Color(0xFFEEA830),
                              ],
                            ),
                          ),
                          child: Text(
                            'Refer & earn',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0A243F),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.50,
                            ),
                          ),
                        ),
                      ),

                      // Background SVG
                      Positioned(
                        right: 0,
                        bottom: 0,
                        width: width * 0.45,
                        height: height,
                        child: Image.asset(
                          backgroundSvg,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomRight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _TrackingState {
  packing,
  packed,
  outForDelivery,
  delivered;

  factory _TrackingState.fromStatus(String status) {
    final value =
        status.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    final compactValue = value.replaceAll(' ', '');
    if (value.contains('waiting') ||
        value.contains('order placed') ||
        compactValue == 'orderplaced') {
      return _TrackingState.packing;
    }
    if (value.contains('out for delivery') ||
        value.contains('out of delivery') ||
        compactValue.contains('outfordelivery') ||
        compactValue.contains('outofdelivery') ||
        value.contains('out for shipment') ||
        value.contains('on the way')) {
      return _TrackingState.outForDelivery;
    }
    if (value.contains('delivered') ||
        value.contains('completed') ||
        value.contains('received') ||
        value.contains('fulfilled') ||
        compactValue == 'deliver') {
      return _TrackingState.delivered;
    }
    if (value.contains('order is packed') ||
        value.contains('Ready for Pickup') ||
        value.contains('ready for pickup') ||
        compactValue == 'readyforpickup' ||
        value.contains('ready to ship')) {
      return _TrackingState.packed;
    }
    return _TrackingState.packing;
  }

  String get subtitle {
    return switch (this) {
      _TrackingState.delivered => 'Delivered',
      _TrackingState.outForDelivery => 'Out for delivery',
      _TrackingState.packed => 'Your order is packed',
      _TrackingState.packing => 'Packing your order',
    };
  }

  String get heroAsset {
    return switch (this) {
      _TrackingState.delivered => 'assets/images/Delivered.webp',
      _TrackingState.outForDelivery => 'assets/images/Out_for_delivery.webp',
      _TrackingState.packed => 'assets/images/Your_order_is_packed.webp',
      _TrackingState.packing => 'assets/images/Packing_your_order.webp',
    };
  }

  String get headerTitle {
    return switch (this) {
      _TrackingState.delivered => 'Shipment 1',
      _ => 'Track order',
    };
  }

  bool get isDelivered => this == _TrackingState.delivered;

  bool get isOutForDelivery => this == _TrackingState.outForDelivery;

  bool get canDownloadInvoice =>
      this == _TrackingState.outForDelivery || this == _TrackingState.delivered;
}

class _TrackingColors {
  const _TrackingColors._();

  static const navy = Color(0xFF0A243F);
  static const greyText = Color(0xFF67696D);
  static const grey = Color(0xFF8A8A8A);
}
