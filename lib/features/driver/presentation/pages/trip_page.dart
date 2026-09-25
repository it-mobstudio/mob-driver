import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/order_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/swipe_button.dart';
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
      _legPoints = const [];
      _legFor = null;
    } else if (_legFor != trip.status) {
      // The next stop changed (pickup → drop): the old leg is now wrong.
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

  Trip? get _latest {
    final live = _cubit.state.activeTrip;
    return live != null && live.id == widget.tripId ? live : _trip;
  }

  /// Opens the photo screen for [stage]; true once every photo is in.
  Future<bool> _takePhotos(PhotoStage stage) async {
    await context.push<bool>(DriverRoutes.photos(widget.tripId, stage));
    return mounted && (_latest?.hasPhotos(stage) ?? false);
  }

  /// "Pickup order": the pickup photos the order asks for, then the start.
  Future<void> _pickupOrder() async {
    final trip = _latest;
    if (trip == null) return;
    if (!trip.hasPhotos(PhotoStage.pickup) &&
        !await _takePhotos(PhotoStage.pickup)) {
      return;
    }
    await _run(() => _cubit.startTrip(widget.tripId));
  }

  /// "Deliver order": walks the driver through whatever the drop still
  /// needs, in order — the item check, the delivery photos, the payment, the
  /// customer's OTP — or confirms a prepaid handover when nothing's left.
  Future<void> _deliver() async {
    var trip = _latest;
    if (trip == null) return;
    if (trip.needsItemVerification) {
      await context.push(DriverRoutes.items(trip.id));
      trip = _latest;
      if (!mounted || trip == null || trip.needsItemVerification) return;
    }
    if (trip.needsDeliveryPhotos) {
      if (!await _takePhotos(PhotoStage.delivery)) return;
      trip = _latest!;
    }
    if (!mounted) return;
    if (trip.needsPaymentCollection) {
      await context.push(DriverRoutes.payment(trip.id));
    } else if (trip.needsDeliveryOtp) {
      await _openDeliveryOtp(trip);
    } else {
      await _completePrepaid();
    }
  }

  /// A COD trip's OTP went out with the payment; a prepaid one is texted to
  /// the customer now, as the driver reaches this step.
  Future<void> _openDeliveryOtp(Trip trip) async {
    if (trip.isCod) {
      await context.push(DriverRoutes.otp(trip.id));
      return;
    }
    final (sent, failure) = await _cubit.resendDeliveryOtp(trip.id);
    if (!mounted) return;
    // Sent moments ago (429) is fine — the customer already has a code.
    if (sent == null && failure?.code != 'OTP_ALREADY_REQUESTED') {
      AppHaptics.error();
      TopSnackBar.show(context,
          message: failure?.message ?? 'Couldn’t send the OTP.',
          type: TopSnackBarType.error);
      return;
    }
    await context.push(DriverRoutes.otp(trip.id), extra: {
      'debugOtp': sent?.debugOtp,
      'freshlySent': true,
    });
  }

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
                busy: context
                    .select<DriverSessionCubit, bool>((c) => c.state.tripBusy),
                onViewDetails: () => context.push(
                    DriverRoutes.orderDetails(trip.id, fromTrip: true)),
                onArrive: _arrive,
                onPickup: _pickupOrder,
                onDeliver: _deliver,
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

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.trip,
    required this.busy,
    required this.onViewDetails,
    required this.onArrive,
    required this.onPickup,
    required this.onDeliver,
    required this.onCancel,
  });

  final Trip trip;
  final bool busy;
  final VoidCallback onViewDetails;
  final Future<void> Function() onArrive;
  final Future<void> Function() onPickup;
  final Future<void> Function() onDeliver;
  final VoidCallback onCancel;

  bool get _atPickup =>
      trip.status == TripStatus.assigned ||
      trip.status == TripStatus.arrivedAtPickup;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final done = trip.status == TripStatus.completed;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .7),
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
            const SizedBox(height: 18),
            TripTimeline(stops: [
              TimelineStop(
                tag: 'Pickup',
                tagIcon: SvgPicture.asset('assets/images/pickup_dot.svg',
                    width: 7, height: 7),
                name: _name(trip.pickup, 'Pickup'),
                address: trip.pickup.address,
                progress: _atPickup && trip.status.isActive
                    ? StopProgress.active
                    : StopProgress.done,
                onViewDetails: onViewDetails,
                onMap: trip.pickup.hasCoordinates
                    ? () => openNavigationTo(trip.pickup)
                    : null,
              ),
              TimelineStop(
                tag: 'Drop',
                tagIcon: const Icon(Icons.home_rounded),
                name: _name(trip.drop, 'Drop'),
                address: trip.drop.address,
                progress: done
                    ? StopProgress.done
                    : trip.status == TripStatus.inProgress
                        ? StopProgress.active
                        : StopProgress.upcoming,
                onViewDetails: onViewDetails,
                onMap: trip.drop.hasCoordinates
                    ? () => openNavigationTo(trip.drop)
                    : null,
              ),
            ]),
            const SizedBox(height: 20),
            if (trip.status.isActive) ...[
              // The swipe changes with the stage; cross-fade rather than swap
              // so the panel doesn't flicker as the trip moves along.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(trip.status.wire),
                  child: _primaryAction(),
                ),
              ),
              if (trip.canCancel)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton(
                    key: const Key('trip_cancel'),
                    onPressed: busy ? null : onCancel,
                    child: const Text('Cancel trip',
                        style: TextStyle(
                            color: DriverColors.muted,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ] else
              _FinishedSummary(trip: trip),
          ]),
        ),
      ),
    );
  }

  static String _name(TripStop stop, String fallback) =>
      (stop.contactName ?? '').isNotEmpty ? stop.contactName! : fallback;

  Widget _primaryAction() => switch (trip.status) {
        TripStatus.assigned => SwipeButton(
            key: const Key('trip_swipe'),
            label: 'Reached pickup',
            loading: busy,
            onConfirmed: onArrive,
          ),
        TripStatus.arrivedAtPickup => SwipeButton(
            key: const Key('trip_swipe'),
            label: 'Pickup order',
            loading: busy,
            onConfirmed: onPickup,
          ),
        TripStatus.inProgress => SwipeButton(
            key: const Key('trip_swipe'),
            label: 'Deliver order',
            loading: busy,
            onConfirmed: onDeliver,
          ),
        _ => const SizedBox.shrink(),
      };
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
