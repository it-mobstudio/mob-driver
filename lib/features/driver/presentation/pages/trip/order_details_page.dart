import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/app/routes.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/services/haptics.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/launchers.dart';
import 'package:mob_driver/core/widgets/buttons.dart';
import 'package:mob_driver/core/widgets/swipe_button.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/driver/data/media/invoice_actions.dart';
import 'package:mob_driver/features/driver/data/media/photo_capture.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:mob_driver/features/driver/domain/trip_reasons.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:mob_driver/features/driver/presentation/widgets/order/earnings_summary.dart';
import 'package:mob_driver/features/driver/presentation/widgets/order/order_section.dart';
import 'package:mob_driver/features/driver/presentation/widgets/order/shipment_list.dart';
import 'package:mob_driver/features/driver/presentation/widgets/order/stop_timeline.dart';
import 'package:mob_driver/features/driver/presentation/widgets/trip/invoice_card.dart';
import 'package:mob_driver/features/driver/presentation/widgets/trip/trip_photos.dart';
import 'package:mob_driver/features/driver/presentation/widgets/trip/trip_stage_actions.dart';
import 'package:mob_driver/features/driver/presentation/widgets/trip/voice_note_player.dart';

/// Everything about one order: the photos the company asked for at the
/// pickup (none, one of the whole package, or one per item —
/// `Trip.pickupPhoto`), both stops with a way to call or navigate, the item
/// list, the invoice and what it pays. Photos come from the camera only,
/// carry a geo stamp, and go to the server as soon as they're taken.
///
/// Reached two ways: from the incoming-order offer ("View order details"),
/// where "Pickup order" commits the driver; and from the trip screen's
/// "View details" ([fromTrip]), where the bar pinned to the bottom carries
/// the same next step as the trip screen (reached pickup → pickup order →
/// deliver order), so the trip can be moved along from here too. Everything
/// above that bar scrolls.
class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({
    super.key,
    required this.tripId,
    this.fromTrip = false,
    this.capture = const DevicePhotoCapture(),
    this.invoiceActions = const DeviceInvoiceActions(),
  });

  final String tripId;
  final bool fromTrip;
  final PhotoCapture capture;
  final InvoiceActions invoiceActions;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage>
    with TripPhotoSlots<OrderDetailsPage>, TripStageActions<OrderDetailsPage> {
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
  DriverSessionCubit get stageCubit => _cubit;

  @override
  String get stageTripId => widget.tripId;

  @override
  Trip? get stageTrip => _trip;

  @override
  void onStageTrip(Trip trip) => setState(() => _trip = trip);

  /// The pickup photos are taken right here, so a swipe without them points
  /// at the slots above instead of opening the photo screen.
  @override
  Future<bool> ensurePhotos(PhotoStage stage) async {
    final trip = latestTrip;
    if (stage != PhotoStage.pickup || trip == null) {
      return super.ensurePhotos(stage);
    }
    final problem = missingPhotosMessage(trip, stage);
    if (problem == null) return true;
    AppHaptics.error();
    if (!_itemsExpanded) setState(() => _itemsExpanded = true);
    TopSnackBar.show(context, message: problem, type: TopSnackBarType.error);
    return false;
  }

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

  /// Before pickup: the driver can't take the order (it goes back to the
  /// company with their reason).
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
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    final tripBusy =
        context.select<DriverSessionCubit, bool>((c) => c.state.tripBusy);
    // Keeps up with the live trip: a step taken on a screen opened from here
    // (the photos, the item check, the payment) moves this one along too.
    return BlocListener<DriverSessionCubit, DriverSessionState>(
      listenWhen: (before, after) => before.activeTrip != after.activeTrip,
      listener: (context, state) {
        final live = state.activeTrip;
        if (live != null && live.id == widget.tripId) {
          setState(() => _trip = live);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          surfaceTintColor: AppColors.card,
          elevation: 0,
          scrolledUnderElevation: .5,
          foregroundColor: AppColors.ink,
          titleSpacing: 0,
          title: Text(tr('Order details'),
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          actions: const [
            Center(child: HelpChip(key: Key('order_details_help'))),
            SizedBox(width: 14),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: trip == null
              ? const Center(child: CircularProgressIndicator())
              : _body(trip, tripBusy),
        ),
        bottomNavigationBar: trip == null ? null : _bottomBar(trip, tripBusy),
      ),
    );
  }

  Widget _body(Trip trip, bool tripBusy) {
    final editable = _pickupEditable(trip);
    final atDrop = trip.status == TripStatus.inProgress;

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        OrderSection(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            OrderHeader(
                reference: trip.displayReference, placedAt: trip.createdAt),
            if (trip.hasNotes) ...[
              const SizedBox(height: 16),
              OrderNoteCard(note: trip.notes!),
            ],
            if (trip.hasVoiceNote) ...[
              const SizedBox(height: 12),
              VoiceNotePlayer(
                  url: trip.voiceNoteUrl!, seconds: trip.voiceNoteSeconds),
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
                  : tr('Pickup'),
              address: trip.pickup.address,
              onCall: atDrop || trip.pickup.contactPhone == null
                  ? null
                  : () => Launchers.call(trip.pickup.contactPhone),
              onMap: !atDrop && trip.pickup.hasCoordinates
                  ? () => Launchers.navigateTo(trip.pickup)
                  : null,
            ),
            drop: StopInfo(
              name: trip.drop.contactName?.isNotEmpty == true
                  ? trip.drop.contactName!
                  : tr('Drop'),
              address: trip.drop.address,
              // The customer's number matters once the goods are on the way.
              onCall: atDrop && trip.drop.contactPhone != null
                  ? () => Launchers.call(trip.drop.contactPhone)
                  : null,
              onMap: atDrop && trip.drop.hasCoordinates
                  ? () => Launchers.navigateTo(trip.drop)
                  : null,
            ),
          ),
        ),
        if (trip.hasItems) ...[
          const OrderSectionGap(),
          ColoredBox(
            color: AppColors.card,
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
        // Part of the page, not pinned: reporting a problem is the exception,
        // and shouldn't sit next to the main action all the time.
        if (trip.canCancel)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: OutlinedButton.icon(
              key: const Key('order_details_problem'),
              onPressed: _busy || tripBusy ? null : _problemAtPickup,
              icon: Icon(Icons.warning_amber_rounded, color: AppColors.red),
              label: Text(tr('Problem at pickup')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                backgroundColor: AppColors.card,
                side: BorderSide(color: AppColors.red.withValues(alpha: .35)),
                shape: const StadiumBorder(),
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ]),
    );
  }

  /// Pinned under the scrolling details: the trip's next step.
  Widget? _bottomBar(Trip trip, bool tripBusy) {
    final commit = !widget.fromTrip && trip.status == TripStatus.assigned;
    final advance = widget.fromTrip && trip.status.isActive;
    if (!commit && !advance) return null;
    return Material(
      color: AppColors.card,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (commit) ...[
              // Opened from the offer: the same answer as there, given
              // back to the offer screen, which owns accepting.
              SwipeButton(
                key: const Key('order_details_accept'),
                label: tr('Accept order'),
                loading: _busy,
                onConfirmed: () async => context.pop(true),
              ),
            ] else if (advance) ...[
              stageSwipe(trip,
                  busy: tripBusy || _busy,
                  swipeKey: const Key('order_details_swipe')),
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
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Material(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('What’s the problem?'),
                        style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(tr('This sends the order back to the company.'),
                        style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12.5,
                            height: 1.4)),
                    const SizedBox(height: 10),
                    RadioGroup<String>(
                      groupValue: _choice,
                      onChanged: (v) => setState(() => _choice = v),
                      child: Column(children: [
                        for (final reason in TripReasons.cancel)
                          RadioListTile<String>(
                            key: Key('problem_reason_$reason'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            value: reason,
                            title: Text(tr(reason)),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: tr('Report problem'),
                      color: AppColors.red,
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
