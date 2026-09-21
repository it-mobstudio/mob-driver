import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/core/app_runtime/push_notification_service.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/core/utils/polyline_codec.dart';
import 'package:m_o_b_demand_side/features/driver/data/location/driver_location_service.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/invoice_actions.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip_extras.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/item_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/invoice_card.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/photo_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_map.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// Reasons offered when a driver cancels before pickup. The last is free text.
const kCancelReasons = [
  'Vehicle breakdown',
  'Customer not reachable',
  'Pickup not ready',
  'Unsafe or wrong location',
  'Other',
];

/// One trip, start to finish: the map with the route polyline and the leg to
/// the next stop, plus the action for whatever stage the trip is in.
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

class _TripPageState extends State<TripPage> {
  final _panelKey = GlobalKey();
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();

  Trip? _trip;
  String? _loadError;
  NavRoute? _leg;
  List<LatLng> _legPoints = const [];
  TripStatus? _legFor;
  Timer? _legTimer;
  StreamSubscription<DriverEvent>? _events;

  double _panelHeight = 340;
  bool _measureScheduled = false;
  String? _routeKey;
  List<LatLng> _routePoints = const [];

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
      _leg = null;
      _legPoints = const [];
      _legFor = null;
    } else if (_legFor != trip.status) {
      // The next stop changed (pickup → drop): the old leg is now wrong.
      _leg = null;
      _legPoints = const [];
      _legFor = trip.status;
      unawaited(_refreshLeg());
    }
  }

  Future<void> _refreshLeg() async {
    final trip = _trip;
    if (trip == null || !trip.status.isActive) return;
    final (route, _) = await _cubit.navigation(trip.id);
    if (!mounted || route == null || _trip?.status != trip.status) return;
    setState(() {
      _leg = route;
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

  // -- actions -------------------------------------------------------------

  Future<void> _run(
    Future<(Trip?, AppFailure?)> Function() action, {
    void Function(Trip trip)? onSuccess,
  }) async {
    final (trip, failure) = await action();
    if (!mounted) return;
    if (trip == null) {
      AppHaptics.error();
      TopSnackBar.show(context,
          message: failure?.message ?? 'Something went wrong.',
          type: TopSnackBarType.error);
      return;
    }
    AppHaptics.success();
    setState(() => _adopt(trip));
    onSuccess?.call(trip);
  }

  Future<void> _arrive() => _run(() => _cubit.arrive(widget.tripId));

  Future<void> _startDelivery() => _run(() => _cubit.startTrip(widget.tripId));

  Future<void> _completePrepaid() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete delivery?'),
        content: const Text(
            'Confirm the order has been handed over to the customer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not yet')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Complete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(
      () => _cubit.complete(widget.tripId),
      onSuccess: (trip) async {
        await PushNotificationService.instance.hideOngoingTrip();
        if (mounted) await showTripCompletedDialog(context, trip);
      },
    );
  }

  Future<void> _cancel() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CancelSheet(),
    );
    if (reason == null || !mounted) return;
    await _run(
      () => _cubit.cancel(widget.tripId, reason),
      onSuccess: (_) async {
        await PushNotificationService.instance.hideOngoingTrip();
        if (!mounted) return;
        TopSnackBar.show(context,
            message: 'Trip cancelled', type: TopSnackBarType.info);
        context.go(DriverRoutes.dashboard);
      },
    );
  }

  void _goBack() =>
      context.canPop() ? context.pop() : context.go(DriverRoutes.dashboard);

  // -- build ---------------------------------------------------------------

  TripMapData _mapData(Trip trip, GeoPoint? me) => TripMapData(
        status: trip.status,
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

  /// Tells the map how much of its bottom edge the panel covers, so Google's
  /// logo and the camera's centre stay in the visible part.
  void _measurePanel() {
    if (!mounted) return;
    final box = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null &&
        box.hasSize &&
        (box.size.height - _panelHeight).abs() > 1) {
      setState(() => _panelHeight = box.size.height);
    }
  }

  Widget _content(Trip trip) {
    final mapBuilder = widget.mapBuilder ?? defaultTripMapBuilder;
    if (!_measureScheduled) {
      _measureScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measurePanel());
    }

    return Stack(children: [
      Positioned.fill(
        child: ValueListenableBuilder<GeoPoint?>(
          valueListenable: _cubit.position,
          builder: (context, me, _) =>
              mapBuilder(context, _mapData(trip, me), _panelHeight),
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _RoundBackButton(onTap: _goBack),
            const Spacer(),
          ]),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        // The panel eases between stages (its height changes as rows appear);
        // each change nudges the map's bottom padding to follow.
        child: NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (_) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _measurePanel());
            return false;
          },
          child: SizeChangedLayoutNotifier(
            child: _SlideUpIn(
              child: _Panel(
                key: _panelKey,
                trip: trip,
                leg: _leg,
                busy: context
                    .select<DriverSessionCubit, bool>((c) => c.state.tripBusy),
                onArrive: _arrive,
                onStart: _startDelivery,
                invoiceActions: widget.invoiceActions,
                onVerifyItems: () => context.push(DriverRoutes.items(trip.id)),
                onCollectPayment: () =>
                    context.push(DriverRoutes.payment(trip.id)),
                onEnterOtp: () => context.push(DriverRoutes.otp(trip.id)),
                onCompletePrepaid: _completePrepaid,
                onCancel: _cancel,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
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

class _Stage {
  const _Stage(this.title, this.subtitle, this.color);
  final String title;
  final String subtitle;
  final Color color;
}

_Stage _stageOf(Trip trip, NavRoute? leg) {
  final away = leg == null
      ? null
      : '${formatDistance(leg.distanceMeters)} · ${formatDuration(leg.durationSeconds)} away';
  switch (trip.status) {
    case TripStatus.assigned:
      return _Stage('Head to pickup', away ?? 'Go to the pickup point',
          DriverColors.blue);
    case TripStatus.arrivedAtPickup:
      return const _Stage('At pickup',
          'Collect the parcel, then start the delivery', DriverColors.orange);
    case TripStatus.inProgress:
      if (trip.needsItemVerification) {
        return _Stage(
            'Check the items',
            '${trip.resolvedItemCount} of ${trip.items.length} checked with the customer',
            DriverColors.blue);
      }
      if (trip.needsPaymentCollection) {
        return _Stage('Deliver & collect payment',
            away ?? 'Take the customer’s payment by QR', DriverColors.blue);
      }
      if (trip.needsDeliveryOtp) {
        return const _Stage('Payment received',
            'Enter the customer’s OTP to finish', DriverColors.green);
      }
      return _Stage('Deliver to customer', away ?? 'On the way to the drop',
          DriverColors.blue);
    case TripStatus.completed:
      return _Stage('Delivery completed', formatDateTime(trip.completedAt),
          DriverColors.green);
    case TripStatus.cancelled:
      final who = trip.cancelledByCompany
          ? 'Cancelled by the company'
          : trip.cancelledBy == 'driver'
              ? 'You cancelled this trip'
              : 'Cancelled';
      return _Stage('Trip cancelled', who, DriverColors.red);
    default:
      return _Stage(trip.status.label, '', DriverColors.muted);
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.trip,
    required this.leg,
    required this.busy,
    required this.invoiceActions,
    required this.onVerifyItems,
    required this.onArrive,
    required this.onStart,
    required this.onCollectPayment,
    required this.onEnterOtp,
    required this.onCompletePrepaid,
    required this.onCancel,
  });

  final Trip trip;
  final NavRoute? leg;
  final bool busy;
  final InvoiceActions invoiceActions;
  final VoidCallback onVerifyItems;
  final VoidCallback onArrive;
  final VoidCallback onStart;
  final VoidCallback onCollectPayment;
  final VoidCallback onEnterOtp;
  final VoidCallback onCompletePrepaid;
  final VoidCallback onCancel;

  bool get _headingToPickup =>
      trip.status == TripStatus.assigned ||
      trip.status == TripStatus.arrivedAtPickup;

  @override
  Widget build(BuildContext context) {
    final stage = _stageOf(trip, leg);
    final target = _headingToPickup ? trip.pickup : trip.drop;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .66),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
              color: Color(0x28000000), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + bottom),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: DriverColors.line,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stage.title,
                          key: const Key('trip_stage_title'),
                          style: TextStyle(
                              color: stage.color,
                              fontSize: 19,
                              fontWeight: FontWeight.w800)),
                      if (stage.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(stage.subtitle,
                            style: const TextStyle(
                                color: DriverColors.muted, fontSize: 12.5)),
                      ],
                    ]),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatMoney(trip.totalFare, currency: trip.currency),
                    key: const Key('trip_fare'),
                    style: const TextStyle(
                        color: DriverColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text(
                    '${formatDistance(trip.distanceMeters)} · ${formatDuration(trip.durationSeconds)}',
                    style: const TextStyle(
                        color: DriverColors.muted, fontSize: 11.5)),
              ]),
            ]),
            const SizedBox(height: 14),
            _StopTile(
              label: 'PICKUP',
              stop: trip.pickup,
              color: DriverColors.green,
              emphasised: trip.status.isActive && _headingToPickup,
            ),
            Container(
              margin: const EdgeInsets.only(left: 6),
              height: 12,
              alignment: Alignment.centerLeft,
              child: Container(width: 2, color: DriverColors.line),
            ),
            _StopTile(
              label: 'DROP',
              stop: trip.drop,
              color: DriverColors.red,
              emphasised: trip.status.isActive && !_headingToPickup,
            ),
            const SizedBox(height: 12),
            _PaymentStrip(trip: trip),
            if (trip.hasItems) ...[
              const SizedBox(height: 10),
              _ItemsCard(trip: trip, onOpen: onVerifyItems),
            ],
            if (trip.hasInvoice) ...[
              const SizedBox(height: 10),
              InvoiceCard(trip: trip, actions: invoiceActions),
            ],
            const SizedBox(height: 14),
            if (trip.status.isActive) ...[
              // The main button changes with the stage; cross-fade rather than
              // swap so the panel doesn't flicker as the trip moves along.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(
                      '${trip.status.wire}|${trip.needsItemVerification}|${trip.needsPaymentCollection}|${trip.needsDeliveryOtp}'),
                  child: _primaryAction(),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: SecondaryButton(
                    label: _headingToPickup
                        ? 'Navigate to pickup'
                        : 'Navigate to drop',
                    icon: Icons.navigation_rounded,
                    color: DriverColors.blue,
                    onPressed: () => openNavigationTo(target),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: _headingToPickup ? 'Call pickup' : 'Call customer',
                    icon: Icons.call_rounded,
                    onPressed: target.contactPhone == null
                        ? null
                        : () => callPhone(target.contactPhone),
                  ),
                ),
              ]),
              if (trip.canCancel)
                TextButton(
                  key: const Key('trip_cancel'),
                  onPressed: busy ? null : onCancel,
                  child: const Text('Cancel trip',
                      style: TextStyle(
                          color: DriverColors.red,
                          fontWeight: FontWeight.w700)),
                ),
            ] else
              _FinishedSummary(trip: trip),
          ]),
        ),
      ),
    );
  }

  Widget _primaryAction() {
    switch (trip.status) {
      case TripStatus.assigned:
        return PrimaryButton(
          label: 'I’ve reached the pickup',
          icon: Icons.location_on_rounded,
          loading: busy,
          onPressed: onArrive,
        );
      case TripStatus.arrivedAtPickup:
        return PrimaryButton(
          label: 'Picked up — start delivery',
          icon: Icons.play_arrow_rounded,
          loading: busy,
          onPressed: onStart,
        );
      case TripStatus.inProgress:
        if (trip.needsItemVerification) {
          return PrimaryButton(
            key: const Key('verify_items'),
            label:
                'Check items (${trip.resolvedItemCount}/${trip.items.length})',
            icon: Icons.fact_check_outlined,
            onPressed: onVerifyItems,
          );
        }
        if (trip.needsPaymentCollection) {
          return PrimaryButton(
            label:
                'Collect ${formatMoney(trip.totalFare, currency: trip.currency)}',
            icon: Icons.qr_code_2_rounded,
            color: DriverColors.green,
            onPressed: onCollectPayment,
          );
        }
        if (trip.needsDeliveryOtp) {
          return PrimaryButton(
            label: 'Enter delivery OTP',
            icon: Icons.pin_outlined,
            color: DriverColors.green,
            onPressed: onEnterOtp,
          );
        }
        return PrimaryButton(
          label: 'Complete delivery',
          icon: Icons.check_circle_outline_rounded,
          color: DriverColors.green,
          loading: busy,
          onPressed: onCompletePrepaid,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.label,
    required this.stop,
    required this.color,
    required this.emphasised,
  });

  final String label;
  final TripStop stop;
  final Color color;
  final bool emphasised;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: emphasised ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8)),
              const SizedBox(height: 1),
              Text(stop.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: DriverColors.ink,
                      fontSize: 14,
                      fontWeight:
                          emphasised ? FontWeight.w800 : FontWeight.w600)),
              if ((stop.contactName ?? '').isNotEmpty ||
                  (stop.contactPhone ?? '').isNotEmpty)
                Text(
                  [
                    if ((stop.contactName ?? '').isNotEmpty) stop.contactName!,
                    if ((stop.contactPhone ?? '').isNotEmpty)
                      formatPhone(stop.contactPhone),
                  ].join(' · '),
                  style:
                      const TextStyle(color: DriverColors.muted, fontSize: 12),
                ),
            ]),
          ),
        ],
      );
}

/// The order's items at a glance, opening the full checklist. When the company
/// asked for verification it shows how far along the driver is — a segment per
/// item — and each item says in words where it stands.
class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.trip, required this.onOpen});
  final Trip trip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final items = trip.items;
    final shown = items.take(3).toList();
    final hidden = items.length - shown.length;
    final verifying = trip.verifyItems;
    final allDone = verifying && trip.pendingItemCount == 0;

    final (pill, color) = !verifying
        ? (
            '${items.length} item${items.length == 1 ? '' : 's'}',
            DriverColors.muted
          )
        : allDone
            ? ('ALL CHECKED', DriverColors.green)
            : (
                '${trip.resolvedItemCount}/${items.length} CHECKED',
                trip.status == TripStatus.inProgress
                    ? DriverColors.orange
                    : DriverColors.muted
              );
    final live = verifying && trip.status == TripStatus.inProgress;
    // Still answers to give: open it to work through them. All given but the
    // trip isn't over: it's there to review (or undo a mis-tap). Otherwise it's
    // a record.
    final actionLabel = !live
        ? 'View all items'
        : allDone
            ? 'Review items'
            : 'Check items';

    return DriverCard(
      key: const Key('items_card'),
      onTap: onOpen,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.inventory_2_outlined,
              size: 19, color: DriverColors.ink),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Items',
                style: TextStyle(
                    color: DriverColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ),
          StatusPill(pill, color: color),
        ]),
        if (verifying) ...[
          const SizedBox(height: 10),
          ItemProgressBar(items: items, height: 6),
        ],
        const SizedBox(height: 12),
        for (final item in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              NetworkThumb(item.imageUrl, size: 40, radius: 10),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: DriverColors.ink,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              QuantityChip(item.quantityLabel, compact: true),
              if (verifying) ...[
                const SizedBox(width: 6),
                ItemStatusChip(item.status),
              ],
            ]),
          ),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('+ $hidden more',
                style: const TextStyle(
                    color: DriverColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ),
        // A real button-shaped target, not a bare link: this is the way in.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: (live && !allDone ? DriverColors.blue : DriverColors.muted)
                .withValues(alpha: .09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(actionLabel,
                key: const Key('items_card_action'),
                style: TextStyle(
                    color: live && !allDone
                        ? DriverColors.blue
                        : DriverColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color:
                    live && !allDone ? DriverColors.blue : DriverColors.muted),
          ]),
        ),
      ]),
    );
  }
}

class _PaymentStrip extends StatelessWidget {
  const _PaymentStrip({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final amount = formatMoney(trip.totalFare, currency: trip.currency);
    final (text, color, icon) = !trip.isCod
        ? (
            'Prepaid — nothing to collect',
            DriverColors.green,
            Icons.verified_outlined
          )
        : trip.isPaid
            ? (
                'Cash on delivery · $amount received',
                DriverColors.green,
                Icons.check_circle_outline_rounded
              )
            : (
                trip.status.isFinished
                    ? 'Cash on delivery · not collected'
                    : 'Cash on delivery · collect $amount from the customer',
                DriverColors.orange,
                Icons.payments_outlined
              );
    return InfoBanner(text: text, color: color, icon: icon);
  }
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
        if (trip.referenceId != null) InfoRow('Reference', trip.referenceId!),
      ]);
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  String? _choice;
  final _other = TextEditingController();

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  String? get _reason {
    if (_choice == null) return null;
    if (_choice != 'Other') return _choice;
    final text = _other.text.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        // A Material (not a painted Container): the radio rows' ink ripples
        // render on the nearest Material, and an opaque box in between hides
        // them — and trips a debug assertion.
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 18, 20, 20 + MediaQuery.paddingOf(context).bottom),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Why are you cancelling?',
                      style: TextStyle(
                          color: DriverColors.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(
                      'The order goes back to the company. You can’t cancel once the delivery has started.',
                      style: TextStyle(
                          color: DriverColors.muted,
                          fontSize: 12.5,
                          height: 1.4)),
                  const SizedBox(height: 10),
                  RadioGroup<String>(
                    groupValue: _choice,
                    onChanged: (v) => setState(() => _choice = v),
                    child: Column(children: [
                      for (final reason in kCancelReasons)
                        RadioListTile<String>(
                          key: Key('cancel_reason_$reason'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: reason,
                          title: Text(reason),
                        ),
                    ]),
                  ),
                  if (_choice == 'Other')
                    TextField(
                      key: const Key('cancel_other_text'),
                      controller: _other,
                      maxLength: 255,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          hintText: 'Tell us what happened'),
                    ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Cancel trip',
                    color: DriverColors.red,
                    onPressed: _reason == null
                        ? null
                        : () => Navigator.pop(context, _reason),
                  ),
                ]),
          ),
        ),
      );
}
