import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/core/utils/polyline_codec.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/order_alert.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip_extras.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/duty_top_bar.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/fare_chips.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/swipe_button.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_map.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';

/// The full-screen offer shown the moment a trip is assigned: what it pays,
/// how far the pickup is, and a countdown to answer before it's declined for
/// them. There's no separate "offered" state on the backend yet — Accept
/// opens the trip as normal; Reject (or letting the countdown run out)
/// simply cancels it, the same way declining from the trip screen would.
class IncomingOrderPage extends StatefulWidget {
  const IncomingOrderPage({
    super.key,
    required this.tripId,
    this.countdownSeconds = 30,
    this.mapBuilder,
    this.alert,
  });

  static const routeName = 'IncomingOrder';

  final String tripId;
  final int countdownSeconds;

  /// Replaces the Google map — used by tests, which can't host a platform view.
  final TripMapBuilder? mapBuilder;

  /// The sound + vibration that announce the order; tests pass a fake.
  final OrderAlert? alert;

  @override
  State<IncomingOrderPage> createState() => _IncomingOrderPageState();
}

class _IncomingOrderPageState extends State<IncomingOrderPage> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();
  late int _secondsLeft = widget.countdownSeconds;
  Timer? _timer;
  Trip? _trip;
  NavRoute? _leg;
  bool _busy = false;

  /// Set the moment a decision is made (accept, reject, or the clock running
  /// out), so a race between the countdown and a tap can't fire twice.
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    final live = _cubit.state.activeTrip;
    _trip = (live != null && live.id == widget.tripId) ? live : null;
    if (_trip == null) unawaited(_fetch());
    unawaited(_loadLeg());
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    // Ring and buzz until the driver answers (or the offer lapses).
    unawaited(_alert.start());
    AppHaptics.success();
  }

  late final OrderAlert _alert = widget.alert ?? DeviceOrderAlert();

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_alert.stop());
    super.dispose();
  }

  Future<void> _fetch() async {
    final (trip, _) = await _cubit.fetchTrip(widget.tripId);
    if (!mounted || trip == null) return;
    setState(() => _trip = trip);
  }

  Future<void> _loadLeg() async {
    final (route, _) = await _cubit.navigation(widget.tripId);
    if (!mounted || route == null) return;
    setState(() => _leg = route);
  }

  void _tick(Timer timer) {
    if (_resolved) {
      timer.cancel();
      return;
    }
    if (_secondsLeft <= 1) {
      timer.cancel();
      if (mounted) setState(() => _secondsLeft = 0);
      unawaited(_respond(accept: false, reason: 'No response from driver'));
      return;
    }
    if (mounted) setState(() => _secondsLeft -= 1);
  }

  Future<void> _respond(
      {required bool accept, String reason = 'Rejected by driver'}) async {
    if (_resolved || _busy) return;
    unawaited(_alert.stop());
    if (accept) {
      _resolved = true;
      _timer?.cancel();
      AppHaptics.success();
      if (mounted) context.pushReplacement(DriverRoutes.trip(widget.tripId));
      return;
    }

    setState(() => _busy = true);
    final (_, failure) = await _cubit.cancel(widget.tripId, reason);
    _resolved = true;
    _timer?.cancel();
    if (!mounted) return;
    if (failure != null) {
      // Couldn't decline (e.g. it already moved on) — showing the trip as it
      // now stands beats leaving the driver stuck on a dead screen.
      context.pushReplacement(DriverRoutes.trip(widget.tripId));
      return;
    }
    AppHaptics.lightTap();
    context.go(DriverRoutes.dashboard);
  }

  void _openDetails() => context.push(DriverRoutes.orderDetails(widget.tripId));

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    return PopScope(
      // Answer the offer first — no dismissing it with the back gesture.
      canPop: false,
      // Light status-bar icons over the dark, dimmed map.
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B1B2E),
          body: Stack(children: [
            // The trip on the map — pickup, drop and the route between — dimmed
            // so the offer reads first, but still there to glance at.
            if (trip != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: (widget.mapBuilder ?? defaultTripMapBuilder)(
                    context,
                    _mapData(trip),
                    MediaQuery.sizeOf(context).height * .5,
                  ),
                ),
              ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x8C0B1B2E), Color(0x590B1B2E)],
                    ),
                  ),
                ),
              ),
            ),
            if (trip == null)
              const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white)))
            else ...[
              SafeArea(
                bottom: false,
                child: BlocBuilder<DriverSessionCubit, DriverSessionState>(
                  builder: (context, state) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        // Read-only: this isn't the place to go off duty or open
                        // the menu, only to answer.
                        child: DutyStatusRow(online: state.isOnline),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: WorkingTimeBanner(
                          online: state.isOnline,
                          dutyStartedAt: _cubit.dutyStartedAt,
                          todayEarnings: state.stats.today.earnings,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                // Rises in once, with a gentle ease — the moment a job arrives.
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1, end: 0),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, child) => Transform.translate(
                    offset: Offset(0, 120 * t),
                    child: Opacity(opacity: 1 - t, child: child),
                  ),
                  child: _OfferSheet(
                    trip: trip,
                    leg: _leg,
                    secondsLeft: _secondsLeft,
                    totalSeconds: widget.countdownSeconds,
                    busy: _busy,
                    onAccept: () => _respond(accept: true),
                    onReject: () => _respond(accept: false),
                    onViewDetails: _openDetails,
                  ),
                ),
              ),
            ],
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

class _OfferSheet extends StatelessWidget {
  const _OfferSheet({
    required this.trip,
    required this.leg,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.busy,
    required this.onAccept,
    required this.onReject,
    required this.onViewDetails,
  });

  final Trip trip;
  final NavRoute? leg;
  final int secondsLeft;
  final int totalSeconds;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final bonus = trip.bonusFare;
    final hasBonus = bonus != null && bonus > 0;
    final total = (trip.totalFare ?? 0) + (bonus ?? 0);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .82),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 30, offset: Offset(0, -6)),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 18 + bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: DriverColors.line,
                borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 16),
          const Text('New order',
              style: TextStyle(
                  color: DriverColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .2)),
          const SizedBox(height: 4),
          Text(formatMoneyShort(total, currency: trip.currency),
              key: const Key('offer_total'),
              style: const TextStyle(
                  color: DriverColors.ink,
                  fontSize: 34,
                  letterSpacing: -.5,
                  fontWeight: FontWeight.w800)),
          // The split only says something when there's a bonus in it.
          if (hasBonus) ...[
            const SizedBox(height: 14),
            FareChips(
                tripFare: trip.totalFare,
                bonus: bonus,
                currency: trip.currency),
          ],
          const SizedBox(height: 22),
          _StopRow(
            label: 'PICKUP',
            dotColor: DriverColors.green,
            filled: true,
            distanceChip: leg?.distanceMeters == null
                ? null
                : '${formatDistance(leg!.distanceMeters)} away',
            name: trip.pickup.contactName?.isNotEmpty == true
                ? trip.pickup.contactName!
                : 'Pickup',
            address: trip.pickup.address,
          ),
          Container(
            margin: const EdgeInsets.only(left: 6),
            height: 26,
            alignment: Alignment.centerLeft,
            child: Container(width: 2, color: DriverColors.line),
          ),
          _StopRow(
            label: 'DROP',
            dotColor: DriverColors.red,
            filled: false,
            distanceChip: trip.distanceMeters == null
                ? null
                : '${formatDistance(trip.distanceMeters)} trip',
            name: trip.drop.contactName?.isNotEmpty == true
                ? trip.drop.contactName!
                : 'Drop',
            address: trip.drop.address,
          ),
          const SizedBox(height: 18),
          Material(
            color: const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              key: const Key('offer_view_details'),
              borderRadius: BorderRadius.circular(14),
              onTap: onViewDetails,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  const Expanded(
                    child: Text('View order details',
                        style: TextStyle(
                            color: DriverColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5)),
                  ),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: const SizedBox(
                      width: 26,
                      height: 26,
                      child: Icon(Icons.chevron_right_rounded,
                          color: DriverColors.ink, size: 18),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SwipeButton(
            key: const Key('offer_accept'),
            label: 'Accept order',
            trailing: '${secondsLeft}s',
            remaining: totalSeconds == 0 ? 0 : secondsLeft / totalSeconds,
            color: secondsLeft <= 10 ? DriverColors.orange : DriverColors.blue,
            loading: busy,
            onConfirmed: () async => onAccept(),
          ),
          const SizedBox(height: 10),
          TextButton(
            key: const Key('offer_reject'),
            onPressed: busy ? null : onReject,
            child: const Text('Reject order',
                style: TextStyle(
                    color: DriverColors.red, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.label,
    required this.dotColor,
    required this.filled,
    required this.distanceChip,
    required this.name,
    required this.address,
  });

  final String label;
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
                  style: const TextStyle(
                      color: DriverColors.muted,
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
              color: filled ? dotColor : Colors.white,
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
                      color: const Color(0xFFF1F4F8),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(distanceChip!,
                      style: const TextStyle(
                          color: DriverColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
              ],
              // One wrapping sentence — the name in bold, the address
              // trailing it in grey — not two stacked lines.
              Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: name,
                        style: const TextStyle(
                            color: DriverColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    TextSpan(text: ' - $address'),
                  ]),
                  style: const TextStyle(
                      color: DriverColors.muted, fontSize: 12.5, height: 1.35)),
            ]),
          ),
        ],
      );
}
