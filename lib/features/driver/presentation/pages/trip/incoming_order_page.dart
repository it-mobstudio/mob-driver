import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/services/haptics.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/formatters.dart';
import 'package:mob_driver/core/utils/polyline_codec.dart';
import 'package:mob_driver/core/widgets/profile_avatar.dart';
import 'package:mob_driver/core/widgets/swipe_button.dart';
import 'package:mob_driver/features/driver/data/media/order_alert.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:mob_driver/features/driver/domain/entities/trip_extras.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:mob_driver/features/driver/presentation/widgets/duty/duty_header.dart';
import 'package:mob_driver/features/driver/presentation/widgets/map/map_sheet.dart';
import 'package:mob_driver/features/driver/presentation/widgets/map/trip_map.dart';
import 'package:mob_driver/features/driver/presentation/widgets/order/earnings_summary.dart'
    show HeavyUnloadingBanner;
import 'package:mob_driver/features/driver/presentation/widgets/trip/fare_chips.dart';

/// An assigned order stays visible until the driver responds or the backend
/// withdraws it. The app never expires or cancels an offer on a local clock.
class IncomingOrderPage extends StatefulWidget {
  const IncomingOrderPage({
    super.key,
    required this.tripId,
    this.mapBuilder,
    this.alert,
  });

  final String tripId;

  /// Replaces the Google map — used by tests, which can't host a platform view.
  final TripMapBuilder? mapBuilder;

  /// The sound + vibration that announce the order; tests pass a fake.
  final OrderAlert? alert;

  @override
  State<IncomingOrderPage> createState() => _IncomingOrderPageState();
}

class _IncomingOrderPageState extends State<IncomingOrderPage> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();
  Trip? _trip;
  NavRoute? _leg;
  bool _busy = false;

  /// How much of the map's bottom edge the offer covers.
  double _sheetHeight = 420;

  /// Prevents repeated decisions while navigation or cancellation is pending.
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    final live = _cubit.state.activeTrip;
    _trip = (live != null && live.id == widget.tripId) ? live : null;
    if (_trip == null) unawaited(_fetch());
    unawaited(_loadLeg());
    // Ring and buzz until the driver answers (or the offer lapses).
    unawaited(_alert.start());
    AppHaptics.success();
  }

  late final OrderAlert _alert = widget.alert ?? DeviceOrderAlert();

  @override
  void dispose() {
    unawaited(_alert.stop());
    super.dispose();
  }

  Future<void> _fetch() async {
    final (trip, failure) = await _cubit.fetchTrip(widget.tripId);
    if (!mounted) return;
    if (trip != null && trip.status != TripStatus.assigned ||
        failure?.code == 'NOT_FOUND') {
      _resolved = true;
      unawaited(_alert.stop());
      context.go(AppRoutes.dashboard);
      return;
    }
    if (trip != null) setState(() => _trip = trip);
  }

  Future<void> _loadLeg() async {
    final (route, _) = await _cubit.navigation(widget.tripId);
    if (!mounted || route == null) return;
    setState(() => _leg = route);
  }

  Future<void> _respond(
      {required bool accept, String reason = 'Rejected by driver'}) async {
    if (_resolved || _busy) return;
    unawaited(_alert.stop());
    if (accept) {
      _resolved = true;
      AppHaptics.success();
      if (mounted) context.pushReplacement(AppRoutes.trip(widget.tripId));
      return;
    }

    setState(() => _busy = true);
    final (_, failure) = await _cubit.cancel(widget.tripId, reason);
    _resolved = true;
    if (!mounted) return;
    if (failure != null) {
      // Couldn't decline (e.g. it already moved on) — showing the trip as it
      // now stands beats leaving the driver stuck on a dead screen.
      context.pushReplacement(AppRoutes.trip(widget.tripId));
      return;
    }
    AppHaptics.lightTap();
    context.go(AppRoutes.dashboard);
  }

  /// The details page offers the same "Accept order" as this one, and
  /// answers here — so accepting works one way, from either screen.
  Future<void> _openDetails() async {
    final accepted =
        await context.push<bool>(AppRoutes.orderDetails(widget.tripId));
    if (accepted == true && mounted) await _respond(accept: true);
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    return BlocListener<DriverSessionCubit, DriverSessionState>(
      listenWhen: (previous, next) => previous.activeTrip != next.activeTrip,
      listener: (context, state) {
        if (_resolved) return;
        final current = state.activeTrip;
        if (current?.id != widget.tripId ||
            current?.status != TripStatus.assigned) {
          _resolved = true;
          unawaited(_alert.stop());
          if (current?.id == widget.tripId && current!.status.isActive) {
            context.pushReplacement(AppRoutes.trip(widget.tripId));
          } else {
            context.go(AppRoutes.dashboard);
          }
        } else {
          setState(() => _trip = current);
        }
      },
      child: PopScope(
        // Answer the offer first — no dismissing it with the back gesture.
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: trip == null
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  // The same white header as the dashboard.
                  DutyHeaderSurface(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      // Read-only: this isn't the place to go off duty or open
                      // the menu, only to answer.
                      child:
                          BlocBuilder<DriverSessionCubit, DriverSessionState>(
                        buildWhen: (a, b) =>
                            a.activeTrip != b.activeTrip ||
                            a.profile != b.profile ||
                            a.stats != b.stats,
                        builder: (context, state) =>
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          DutyStatusRow(
                            online: state.isOnline,
                            avatar: state.profile == null
                                ? null
                                : ProfileAvatar(state.profile!.fullName,
                                    size: 44,
                                    photoUrl: state.profile!.photoUrl),
                          ),
                          const SizedBox(height: 10),
                          WorkingTimeBanner(
                            online: state.isOnline,
                            dutyStartedAt: _cubit.dutyStartedAt,
                            todayEarnings: state.stats.today.earnings,
                          ),
                        ]),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(children: [
                      // The trip on the map — pickup, drop and the route
                      // between — to glance at while deciding.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: (widget.mapBuilder ?? defaultTripMapBuilder)(
                              context, _mapData(trip), _sheetHeight),
                        ),
                      ),
                      Positioned.fill(
                        // Rises in once, with a gentle ease — the moment a job
                        // arrives.
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1, end: 0),
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          builder: (_, t, child) => Transform.translate(
                            offset: Offset(0, 120 * t),
                            child: Opacity(opacity: 1 - t, child: child),
                          ),
                          child: MapSheet(
                            onRestingHeight: (height) {
                              if ((height - _sheetHeight).abs() > 1) {
                                setState(() => _sheetHeight = height);
                              }
                            },
                            peek: _OfferSummary(
                              trip: trip,
                              leg: _leg,
                              onViewDetails: _openDetails,
                            ),
                            // The answer stays put, whatever the sheet shows.
                            footer: _OfferActions(
                              trip: trip,
                              busy: _busy,
                              onAccept: () => _respond(accept: true),
                              onReject: () => _respond(accept: false),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ]),
        ),
      ),
    );
  }

  TripMapData _mapData(Trip trip) => TripMapData(
        status: trip.status,
        pickup: trip.pickup.hasCoordinates
            ? LatLng(trip.pickup.latitude!, trip.pickup.longitude!)
            : null,
        drop: trip.drop.hasCoordinates
            ? LatLng(trip.drop.latitude!, trip.drop.longitude!)
            : null,
        route: decodePolyline(trip.routePolyline ?? '',
                precision: trip.polylinePrecision)
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
        leg: _leg == null
            ? const []
            : _leg!.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
      );
}

/// What's on offer: what it pays, and where it goes.
class _OfferSummary extends StatelessWidget {
  const _OfferSummary({
    required this.trip,
    required this.leg,
    required this.onViewDetails,
  });

  final Trip trip;
  final NavRoute? leg;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final bonus = trip.bonusFare;
    final extra = trip.hasExtraBonus ? trip.extraBonusFare : null;
    final hasBonus = (bonus != null && bonus > 0) || extra != null;
    final total = (trip.totalFare ?? 0) + (bonus ?? 0) + (extra ?? 0);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(tr('New order'),
          style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: .2)),
      const SizedBox(height: 4),
      Text(formatMoneyShort(total, currency: trip.currency),
          key: const Key('offer_total'),
          style: TextStyle(
              color: AppColors.ink,
              fontSize: 34,
              letterSpacing: -.5,
              fontWeight: FontWeight.w800)),
      // The split only says something when there's a bonus in it.
      if (hasBonus) ...[
        const SizedBox(height: 14),
        FareChips(
            tripFare: trip.totalFare,
            bonus: bonus ?? 0,
            extraBonus: extra,
            currency: trip.currency),
        // Unloading is real work: say so before the driver accepts.
        const SizedBox(height: 12),
        const HeavyUnloadingBanner(),
      ],
      const SizedBox(height: 22),
      _StopRow(
        label: tr('PICKUP'),
        isPickup: true,
        dotColor: AppColors.green,
        filled: true,
        distanceChip: leg?.distanceMeters == null
            ? null
            : '${formatDistance(leg!.distanceMeters)} away',
        name: trip.pickup.contactName?.isNotEmpty == true
            ? trip.pickup.contactName!
            : tr('Pickup'),
        address: trip.pickup.address,
      ),
      Container(
        margin: const EdgeInsets.only(left: 6),
        height: 26,
        alignment: Alignment.centerLeft,
        child: Container(width: 2, color: AppColors.line),
      ),
      _StopRow(
        label: tr('DROP'),
        dotColor: AppColors.red,
        filled: false,
        distanceChip: trip.distanceMeters == null
            ? null
            : '${formatDistance(trip.distanceMeters)} trip',
        name: trip.drop.contactName?.isNotEmpty == true
            ? trip.drop.contactName!
            : tr('Drop'),
        address: trip.drop.address,
      ),
      const SizedBox(height: 18),
      Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const Key('offer_view_details'),
          borderRadius: BorderRadius.circular(14),
          onTap: onViewDetails,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Expanded(
                child: Text(tr('View order details'),
                    style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5)),
              ),
              Material(
                color: AppColors.card,
                shape: const CircleBorder(),
                elevation: 1,
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: Icon(Icons.chevron_right_rounded,
                      color: AppColors.ink, size: 18),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

/// Accept with the required unloading work made explicit, or reject.
class _OfferActions extends StatelessWidget {
  const _OfferActions({
    required this.trip,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final Trip trip;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        SwipeButton(
          key: const Key('offer_accept'),
          label: trip.acceptOrderLabel,
          loading: busy,
          onConfirmed: () async => onAccept(),
        ),
        const SizedBox(height: 4),
        TextButton(
          key: const Key('offer_reject'),
          onPressed: busy ? null : onReject,
          child: Text(tr('Reject order'),
              style:
                  TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
        ),
      ]);
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.label,
    this.isPickup = false,
    required this.dotColor,
    required this.filled,
    required this.distanceChip,
    required this.name,
    required this.address,
  });

  final String label;
  final bool isPickup;
  final Color dotColor;
  final bool filled;
  final String? distanceChip;
  final String name;
  final String address;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(label,
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: filled ? dotColor : AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: dotColor, width: 3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (distanceChip != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(distanceChip!,
                      style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
              ],
              // Just the address — area and pincode included, as the company
              // sent it — and no shop or customer name before the driver accepts.
              Text(address,
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.4)),
            ]),
          ),
        ],
      );
}
