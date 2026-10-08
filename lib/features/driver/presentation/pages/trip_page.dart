import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/core/utils/polyline_codec.dart';
import 'package:m_o_b_demand_side/features/driver/data/location/driver_location_service.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/invoice_actions.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/map_sheet.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/order_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/voice_note_player.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_map.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_stage_actions.dart';

/// One trip, start to finish: the map with the route polyline and the leg to
/// the next stop, a sheet with the stop the driver is heading to (pull it up
/// for the rest of the trip), and — pinned under it — the action for whatever
/// stage the trip is in.
///
/// Works for the driver's live trip (kept in sync with the session cubit) and
/// for a finished trip opened from history (loaded once, read-only).
class TripPage extends StatefulWidget {
  const TripPage({
    super.key,
    required this.tripId,
    this.mapBuilder,
    this.invoiceActions = const DeviceInvoiceActions(),
  });

  static const routeName = 'DriverTrip';

  final String tripId;

  /// Replaces the Google map — used by tests, which can't host a platform view.
  final TripMapBuilder? mapBuilder;

  /// Download / share / WhatsApp for the invoice; tests pass a fake.
  final InvoiceActions invoiceActions;

  static final Set<String> _showing = {};

  /// Whether this trip's screen is currently open, so a global listener can
  /// leave a trip-specific alert to the screen itself.
  static bool isShowing(String tripId) => _showing.contains(tripId);

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> with TripStageActions<TripPage> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();

  Trip? _trip;
  String? _loadError;
  List<LatLng> _legPoints = const [];

  /// Which leg [_legPoints] is: the trip's stage plus the in-between stop
  /// it leads to, if any.
  String? _legFor;
  Timer? _legTimer;
  StreamSubscription<DriverEvent>? _events;

  /// How much of the map's bottom edge the resting sheet and the action
  /// under it cover, so Google's logo and the camera's centre stay in the
  /// visible part.
  double _panelHeight = 300;
  String? _routeKey;
  List<LatLng> _routePoints = const [];

  @override
  DriverSessionCubit get stageCubit => _cubit;

  @override
  String get stageTripId => widget.tripId;

  @override
  Trip? get stageTrip => _trip;

  @override
  void onStageTrip(Trip trip) => setState(() => _adopt(trip));

  @override
  void initState() {
    super.initState();
    TripPage._showing.add(widget.tripId);

    final live = _cubit.state.activeTrip;
    if (live != null && live.id == widget.tripId) {
      _adopt(live);
    } else {
      _fetch();
    }
    _events = _cubit.events.listen(_onEvent);
    // The leg is a snapshot from where the driver was; refresh it as they
    // drive so the green line keeps starting under the marker.
    _legTimer =
        Timer.periodic(const Duration(seconds: 45), (_) => _refreshLeg());
  }

  @override
  void dispose() {
    TripPage._showing.remove(widget.tripId);
    _legTimer?.cancel();
    _events?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loadError = null);
    final (trip, failure) = await _cubit.fetchTrip(widget.tripId);
    if (!mounted) return;
    if (trip == null) {
      setState(
          () => _loadError = failure?.message ?? 'Could not load this trip.');
      return;
    }
    setState(() => _adopt(trip));
  }

  /// Takes a newer version of this trip and re-derives what depends on it.
  void _adopt(Trip trip) {
    _trip = trip;

    final polyline = trip.routePolyline ?? '';
    final key = '$polyline|${trip.polylinePrecision}';
    if (key != _routeKey) {
      _routeKey = key;
      _routePoints = decodePolyline(polyline, precision: trip.polylinePrecision)
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
    }

    if (!trip.status.isActive) {
      _legPoints = const [];
      _legFor = null;
    } else if (_legFor != _legKey(trip)) {
      // The next stop changed (pickup → a stop in between → drop): the old
      // leg is now wrong.
      _legPoints = const [];
      _legFor = _legKey(trip);
      unawaited(_refreshLeg());
    }
  }

  static String _legKey(Trip trip) =>
      '${trip.status.wire}|${trip.nextStop?.id ?? ''}';

  Future<void> _refreshLeg() async {
    final trip = _trip;
    if (trip == null || !trip.status.isActive) return;
    final (route, _) = await _cubit.navigation(trip.id);
    final now = _trip;
    if (!mounted || route == null || now == null) return;
    if (_legKey(now) != _legKey(trip)) return;
    setState(() {
      _legPoints =
          route.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    });
  }

  void _onEvent(DriverEvent event) {
    if (event is! TripEndedExternally || event.trip.id != widget.tripId) return;
    if (!mounted) return;
    setState(() => _adopt(event.trip));
    AppHaptics.error();
    unawaited(_showCancelledByCompany(event.trip));
  }

  Future<void> _showCancelledByCompany(Trip trip) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Trip cancelled'),
        content: Text(
          trip.cancellationReason == null
              ? 'This trip was cancelled.'
              : 'This trip was cancelled: ${trip.cancellationReason}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    if (mounted) context.go(DriverRoutes.dashboard);
  }

  void _goBack() =>
      context.canPop() ? context.pop() : context.go(DriverRoutes.dashboard);

  // -- build ---------------------------------------------------------------

  TripMapData _mapData(Trip trip, GeoPoint? me) => TripMapData(
        status: trip.status,
        stops: [
          for (final stop in trip.inBetweenStops)
            if (stop.latitude != null && stop.longitude != null)
              MapStop(
                id: stop.id,
                at: LatLng(stop.latitude!, stop.longitude!),
                isPickup: stop.isPickup,
                label: '${stop.label} · ${stop.kindLabel}',
              ),
        ],
        pickup: trip.pickup.hasCoordinates
            ? LatLng(trip.pickup.latitude!, trip.pickup.longitude!)
            : null,
        drop: trip.drop.hasCoordinates
            ? LatLng(trip.drop.latitude!, trip.drop.longitude!)
            : null,
        driver: trip.status.isActive && me != null
            ? LatLng(me.latitude, me.longitude)
            : null,
        route: _routePoints,
        leg: _legPoints,
      );

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverSessionCubit, DriverSessionState>(
      listenWhen: (before, after) => before.activeTrip != after.activeTrip,
      listener: (context, state) {
        final live = state.activeTrip;
        if (live != null && live.id == widget.tripId) {
          setState(() => _adopt(live));
        }
      },
      child: Scaffold(
        backgroundColor: DriverColors.surface,
        body: _trip == null ? _placeholder() : _content(_trip!),
      ),
    );
  }

  Widget _placeholder() => SafeArea(
        child: Stack(children: [
          Center(
            child: _loadError == null
                ? const CircularProgressIndicator()
                : CenteredMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load trip',
                    message: _loadError,
                    actionLabel: 'Retry',
                    onAction: _fetch,
                  ),
          ),
          Padding(
              padding: const EdgeInsets.all(12),
              child: _RoundBackButton(onTap: _goBack)),
        ]),
      );

  Widget _content(Trip trip) {
    final mapBuilder = widget.mapBuilder ?? defaultTripMapBuilder;
    final busy =
        context.select<DriverSessionCubit, bool>((c) => c.state.tripBusy);
    final active = trip.status.isActive;
    final stops = _timeline(trip);
    final current =
        stops.where((s) => s.progress == StopProgress.active).firstOrNull;
    // While the trip is on, only the stop being worked on shows at rest; the
    // ones still to come, then the ones done, are a pull of the sheet away.
    final upcoming = [
      for (final s in stops)
        if (s.progress == StopProgress.upcoming) s
    ];
    final done = [
      for (final s in stops)
        if (s.progress == StopProgress.done) s
    ];

    // Expanded: everything but the back button is positioned, so the stack
    // would otherwise shrink to that button's height.
    return Stack(fit: StackFit.expand, children: [
      Positioned.fill(
        child: ValueListenableBuilder<GeoPoint?>(
          valueListenable: _cubit.position,
          builder: (context, me, _) =>
              mapBuilder(context, _mapData(trip, me), _panelHeight),
        ),
      ),
      Align(
        alignment: Alignment.topLeft,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _RoundBackButton(onTap: _goBack),
          ),
        ),
      ),
      Positioned.fill(
        child: _SlideUpIn(
          child: MapSheet(
            onRestingHeight: (height) {
              if ((height - _panelHeight).abs() > 1) {
                setState(() => _panelHeight = height);
              }
            },
            // The sheet eases between stages (its height changes as stops
            // move from "next" to "done").
            peek: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (trip.hasVoiceNote && active) ...[
                  VoiceNotePlayer(
                      url: trip.voiceNoteUrl!,
                      seconds: trip.voiceNoteSeconds,
                      compact: true),
                  const SizedBox(height: 16),
                ],
                TripTimeline(
                    stops: active && current != null ? [current] : stops),
              ]),
            ),
            more: !active
                ? _FinishedSummary(trip: trip)
                : upcoming.isEmpty && done.isEmpty
                    ? null
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        if (upcoming.isNotEmpty) ...[
                          const _TimelineLabel('Up next'),
                          TripTimeline(stops: upcoming),
                        ],
                        if (upcoming.isNotEmpty && done.isNotEmpty)
                          const SizedBox(height: 22),
                        if (done.isNotEmpty) ...[
                          const _TimelineLabel('Done'),
                          TripTimeline(stops: done),
                        ],
                      ]),
            footer: !active
                ? null
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(height: 8),
                    stageSwipe(trip, busy: busy),
                    if (trip.canCancel)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TextButton(
                          key: const Key('trip_cancel'),
                          onPressed: busy ? null : cancelTrip,
                          child: const Text('Cancel trip',
                              style: TextStyle(
                                  color: DriverColors.muted,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ]),
          ),
        ),
      ),
    ]);
  }

  /// Every stop in visiting order, each knowing its place ([TimelineStop.index])
  /// whatever part of the sheet it ends up in.
  List<TimelineStop> _timeline(Trip trip) {
    final finished = trip.status == TripStatus.completed;
    final atPickup = trip.status == TripStatus.assigned ||
        trip.status == TripStatus.arrivedAtPickup;
    void viewDetails() =>
        context.push(DriverRoutes.orderDetails(trip.id, fromTrip: true));
    String name(TripStop stop, String fallback) =>
        (stop.contactName ?? '').isNotEmpty ? stop.contactName! : fallback;

    final between = trip.inBetweenStops;
    return [
      TimelineStop(
        index: 0,
        tag: 'Pickup',
        tagIcon: SvgPicture.asset('assets/images/pickup_dot.svg',
            width: 7, height: 7),
        name: name(trip.pickup, 'Pickup'),
        address: trip.pickup.address,
        progress: atPickup && trip.status.isActive
            ? StopProgress.active
            : StopProgress.done,
        onViewDetails: viewDetails,
        onMap: trip.pickup.hasCoordinates
            ? () => openNavigationTo(trip.pickup)
            : null,
      ),
      for (final (i, stop) in between.indexed)
        TimelineStop(
          index: i + 1,
          tag: '${stop.label} · ${stop.kindLabel}',
          tagIcon: stop.isPickup
              ? SvgPicture.asset('assets/images/pickup_dot.svg',
                  width: 7, height: 7)
              : const Icon(Icons.home_rounded),
          name: name(stop.asStop, stop.kindLabel),
          address: stop.address,
          progress: stop.isDone || finished
              ? StopProgress.done
              : trip.nextStop?.id == stop.id
                  ? StopProgress.active
                  : StopProgress.upcoming,
          onViewDetails: viewDetails,
          onMap: stop.latitude != null
              ? () => openNavigationTo(stop.asStop)
              : null,
        ),
      TimelineStop(
        index: between.length + 1,
        tag: 'Drop',
        tagIcon: const Icon(Icons.home_rounded),
        name: name(trip.drop, 'Drop'),
        address: trip.drop.address,
        progress: finished
            ? StopProgress.done
            : trip.status == TripStatus.inProgress && trip.nextStop == null
                ? StopProgress.active
                : StopProgress.upcoming,
        onViewDetails: viewDetails,
        onMap:
            trip.drop.hasCoordinates ? () => openNavigationTo(trip.drop) : null,
      ),
    ];
  }
}

/// `UP NEXT` / `DONE` over a group of stops in the pulled-up sheet.
class _TimelineLabel extends StatelessWidget {
  const _TimelineLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(text.toUpperCase(),
              style: const TextStyle(
                  color: DriverColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8)),
        ),
      );
}

/// The panel rises from the bottom edge (with a fade) the first time the trip
/// screen appears, instead of being simply there.
class _SlideUpIn extends StatefulWidget {
  const _SlideUpIn({required this.child});
  final Widget child;

  @override
  State<_SlideUpIn> createState() => _SlideUpInState();
}

class _SlideUpInState extends State<_SlideUpIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _curve,
        child: widget.child,
        builder: (context, child) => FractionalTranslation(
          translation: Offset(0, 1 - _curve.value),
          child: Opacity(opacity: _curve.value.clamp(0.0, 1.0), child: child),
        ),
      );
}

// ---------------------------------------------------------------------------

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        child: IconButton(
          key: const Key('trip_back'),
          icon: const Icon(Icons.arrow_back_rounded, color: DriverColors.ink),
          onPressed: onTap,
        ),
      );
}

class _FinishedSummary extends StatelessWidget {
  const _FinishedSummary({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) => Column(children: [
        const Divider(height: 22),
        InfoRow(
            'Base fare', formatMoney(trip.baseFare, currency: trip.currency)),
        InfoRow('Distance',
            formatMoney(trip.distanceFare, currency: trip.currency)),
        InfoRow('Time', formatMoney(trip.timeFare, currency: trip.currency)),
        InfoRow('Total', formatMoney(trip.totalFare, currency: trip.currency),
            bold: true),
        if (trip.driverEarning != null)
          InfoRow('You earned',
              formatMoney(trip.driverEarning, currency: trip.currency),
              bold: true, valueColor: DriverColors.green),
        if (trip.status == TripStatus.cancelled &&
            (trip.cancellationReason ?? '').isNotEmpty)
          InfoRow('Reason', trip.cancellationReason!),
        InfoRow('Order', trip.displayReference),
      ]);
}
