import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/invoice_actions.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/order_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/invoice_card.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/swipe_button.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_photos.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/pages/trip_page.dart'
    show kCancelReasons;
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// Everything about one order: the photos the company asked for at the
/// pickup (none, one of the whole package, or one per item —
/// `Trip.pickupPhoto`), both stops with a way to call or navigate, the item
/// list, the invoice and what it pays. Photos come from the camera only,
/// carry a geo stamp, and go to the server as soon as they're taken.
///
/// Reached two ways: from the incoming-order offer ("View order details"),
/// where "Pickup order" commits the driver; and from the trip screen's
/// "View details" ([fromTrip]), where it's for reading — only the
/// before-pickup "Problem at pickup" stays.
class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({
    super.key,
    required this.tripId,
    this.fromTrip = false,
    this.capture = const DevicePhotoCapture(),
    this.invoiceActions = const DeviceInvoiceActions(),
  });

  static const routeName = 'OrderDetails';

  final String tripId;
  final bool fromTrip;
  final PhotoCapture capture;
  final InvoiceActions invoiceActions;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with TripPhotoSlots<OrderDetailsPage> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();
  Trip? _trip;
  bool _itemsExpanded = true;
  bool _busy = false;

  @override
  DriverSessionCubit get photoCubit => _cubit;

  @override
  PhotoCapture get photoCapture => widget.capture;

  @override
  void onTripUpdated(Trip trip) => setState(() => _trip = trip);

  @override
  void initState() {
    super.initState();
    final live = _cubit.state.activeTrip;
    _trip = (live != null && live.id == widget.tripId) ? live : null;
    if (_trip == null) unawaited(_fetch());
  }

  Future<void> _fetch() async {
    final (trip, _) = await _cubit.fetchTrip(widget.tripId);
    if (!mounted || trip == null) return;
    setState(() => _trip = trip);
  }

  /// Pickup photos can be (re)taken until the delivery starts.
  bool _pickupEditable(Trip trip) =>
      trip.status == TripStatus.assigned ||
      trip.status == TripStatus.arrivedAtPickup;

  /// There's no "accepted" step on the backend separate from "assigned" —
  /// this is the same commitment the offer screen's Accept makes, just from
  /// someone who checked the details first. The photos the order asks for are
  /// already on the server by now (each uploads as it's taken); the backend
  /// checks them again before the delivery can start.
  Future<void> _pickupOrder(Trip trip) async {
    final problem = missingPhotosMessage(trip, PhotoStage.pickup);
    if (problem != null) {
      AppHaptics.error();
      if (!_itemsExpanded) setState(() => _itemsExpanded = true);
      TopSnackBar.show(context, message: problem, type: TopSnackBarType.error);
      return;
    }
    context.pushReplacement(DriverRoutes.trip(widget.tripId));
  }

  Future<void> _problemAtPickup() async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProblemSheet(),
    );
    if (reason == null || !mounted) return;

    setState(() => _busy = true);
    final (_, failure) = await _cubit.cancel(widget.tripId, reason);
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      TopSnackBar.show(context,
          message: failure.message, type: TopSnackBarType.error);
      return;
    }
    AppHaptics.lightTap();
    context.go(DriverRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    return Scaffold(
      backgroundColor: DriverColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: .5,
        foregroundColor: DriverColors.ink,
        titleSpacing: 0,
        title: const Text('Order details',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          const Center(child: HelpChip(key: Key('order_details_help'))),
          const SizedBox(width: 14),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: trip == null
            ? const Center(child: CircularProgressIndicator())
            : _body(trip),
      ),
      bottomNavigationBar: trip == null ? null : _bottomBar(trip),
    );
  }

  Widget _body(Trip trip) {
    final editable = _pickupEditable(trip);
    final atDrop = trip.status == TripStatus.inProgress;

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        OrderSection(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            OrderHeader(
                reference: trip.displayReference, placedAt: trip.createdAt),
            if (trip.hasNotes) ...[
              const SizedBox(height: 16),
              OrderNoteCard(note: trip.notes!),
            ],
            if (trip.wantsPickupPhotos) ...[
              const SizedBox(height: 22),
              photoSection(trip, PhotoStage.pickup, enabled: editable),
            ],
          ]),
        ),
        const OrderSectionGap(),
        OrderSection(
          child: StopTimeline(
            pickup: StopInfo(
              name: trip.pickup.contactName?.isNotEmpty == true
                  ? trip.pickup.contactName!
                  : 'Pickup',
              address: trip.pickup.address,
              onCall: atDrop || trip.pickup.contactPhone == null
                  ? null
                  : () => callPhone(trip.pickup.contactPhone),
              onMap: !atDrop && trip.pickup.hasCoordinates
                  ? () => openNavigationTo(trip.pickup)
                  : null,
            ),
            drop: StopInfo(
              name: trip.drop.contactName?.isNotEmpty == true
                  ? trip.drop.contactName!
                  : 'Drop',
              address: trip.drop.address,
              // The customer's number matters once the goods are on the way.
              onCall: atDrop && trip.drop.contactPhone != null
                  ? () => callPhone(trip.drop.contactPhone)
                  : null,
              onMap: atDrop && trip.drop.hasCoordinates
                  ? () => openNavigationTo(trip.drop)
                  : null,
            ),
          ),
        ),
        if (trip.hasItems) ...[
          const OrderSectionGap(),
          ColoredBox(
            color: Colors.white,
            child: Column(children: [
              ShipmentHeader(
                count: trip.items.length,
                expanded: _itemsExpanded,
                onToggle: () =>
                    setState(() => _itemsExpanded = !_itemsExpanded),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _itemsExpanded
                    ? ShipmentItemList(
                        items: trip.items,
                        photoSlotFor: (item) => itemPhotoSlot(
                            trip, PhotoStage.pickup, item,
                            enabled: editable),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ]),
          ),
        ],
        if (trip.hasInvoice) ...[
          const OrderSectionGap(),
          OrderSection(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: InvoiceCard(trip: trip, actions: widget.invoiceActions),
          ),
        ],
        const OrderSectionGap(),
        OrderSection(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: EarningsSummary(
            tripFare: trip.totalFare,
            bonus: trip.bonusFare,
            currency: trip.currency,
          ),
        ),
      ]),
    );
  }

  Widget? _bottomBar(Trip trip) {
    final commit = !widget.fromTrip && trip.status == TripStatus.assigned;
    if (!commit && !trip.canCancel) return null;
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (trip.canCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('order_details_problem'),
                  onPressed: _busy ? null : _problemAtPickup,
                  icon: const Icon(Icons.warning_amber_rounded,
                      color: DriverColors.red),
                  label: const Text('Problem at pickup'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DriverColors.red,
                    side: BorderSide(
                        color: DriverColors.red.withValues(alpha: .35)),
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(48),
                    textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            if (commit) ...[
              const SizedBox(height: 10),
              SwipeButton(
                key: const Key('order_details_pickup'),
                label: 'Pickup order',
                loading: _busy,
                onConfirmed: () => _pickupOrder(trip),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _ProblemSheet extends StatefulWidget {
  const _ProblemSheet();

  @override
  State<_ProblemSheet> createState() => _ProblemSheetState();
}

class _ProblemSheetState extends State<_ProblemSheet> {
  String? _choice;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What’s the problem?',
                        style: TextStyle(
                            color: DriverColors.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('This sends the order back to the company.',
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
                            key: Key('problem_reason_$reason'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: reason,
                            title: Text(reason),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Report problem',
                      color: DriverColors.red,
                      onPressed: _choice == null
                          ? null
                          : () => Navigator.pop(context, _choice),
                    ),
                  ]),
            ),
          ),
        ),
      );
}
