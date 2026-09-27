import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/order_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_photos.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// One in-between stop of a multi-stop trip, once the driver is there: who to
/// meet, the items collected (pickup) or handed over (drop) here, the photos
/// the order asks for at this kind of stop and — at a drop of an order with
/// item verification — the checklist. "Done" finishes the stop and pops
/// `true`, so the trip screen moves on to the next one.
class StopPage extends StatefulWidget {
  const StopPage({
    super.key,
    required this.tripId,
    required this.stopId,
    this.capture = const DevicePhotoCapture(),
  });

  static const routeName = 'DriverTripStop';

  final String tripId;
  final String stopId;
  final PhotoCapture capture;

  @override
  State<StopPage> createState() => _StopPageState();
}

class _StopPageState extends State<StopPage> with TripPhotoSlots<StopPage> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();

  /// Only when this isn't the live trip (it normally is).
  Trip? _fetched;

  @override
  DriverSessionCubit get photoCubit => _cubit;

  @override
  PhotoCapture get photoCapture => widget.capture;

  @override
  void onTripUpdated(Trip trip) => setState(() {});

  @override
  void initState() {
    super.initState();
    if (_cubit.state.activeTrip?.id != widget.tripId) unawaited(_fetch());
  }

  Future<void> _fetch() async {
    final (trip, _) = await _cubit.fetchTrip(widget.tripId);
    if (mounted && trip != null) setState(() => _fetched = trip);
  }

  Trip? _trip(DriverSessionState state) =>
      state.activeTrip?.id == widget.tripId ? state.activeTrip : _fetched;

  TripWaypoint? _stop(Trip trip) =>
      trip.stops.where((s) => s.id == widget.stopId).firstOrNull;

  void _error(String message) {
    AppHaptics.error();
    TopSnackBar.show(context, message: message, type: TopSnackBarType.error);
  }

  /// The photos, then the item checks, then the backend's word.
  Future<void> _finish(Trip trip, TripWaypoint stop) async {
    final photos = missingPhotosMessage(trip, stop.stage, stop: stop);
    if (photos != null) return _error(photos);
    if (trip.pendingItemsAt(stop) > 0) {
      await context.push(DriverRoutes.items(trip.id, stopId: stop.id));
      if (!mounted) return;
      // Carry on only once the checklist came back complete.
      final latest = _trip(_cubit.state);
      final latestStop = latest == null ? null : _stop(latest);
      if (latestStop == null || latest!.pendingItemsAt(latestStop) > 0) return;
    }
    final (updated, failure) = await _cubit.finishStop(trip.id, stop.id);
    if (!mounted) return;
    if (updated == null) {
      return _error(failure?.message ?? 'Couldn’t finish this stop. Try again.');
    }
    AppHaptics.success();
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DriverSessionCubit, DriverSessionState>(
        builder: (context, state) {
          final trip = _trip(state);
          final stop = trip == null ? null : _stop(trip);
          return Scaffold(
            backgroundColor: DriverColors.surface,
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              foregroundColor: DriverColors.ink,
              titleSpacing: 0,
              title: Text(
                  stop == null ? 'Stop' : '${stop.label} · ${stop.kindLabel}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 17)),
            ),
            body: trip == null || stop == null
                ? const Center(child: CircularProgressIndicator())
                : _content(trip, stop),
            bottomNavigationBar: trip == null || stop == null || stop.isDone
                ? null
                : _footer(trip, stop, state.tripBusy),
          );
        },
      );

  Widget _content(Trip trip, TripWaypoint stop) {
    final stage = stop.stage;
    final items = trip.itemsAt(stage, stop: stop);
    final live = trip.status == TripStatus.inProgress && !stop.isDone;
    final notes = (stop.notes ?? '').trim();
    final checks = trip.verifyItems && !stop.isPickup && items.isNotEmpty;
    return ListView(children: [
      OrderSection(
        child: StopBlock(
          label: stop.isPickup ? 'PICKUP' : 'DROP',
          color: stop.isPickup ? DriverColors.green : DriverColors.red,
          filled: stop.isPickup,
          stop: StopInfo(
            name: (stop.contactName ?? '').isNotEmpty
                ? stop.contactName!
                : stop.kindLabel,
            address: stop.address,
            onCall: (stop.contactPhone ?? '').isNotEmpty
                ? () => callPhone(stop.contactPhone)
                : null,
            onMap: stop.latitude != null
                ? () => openNavigationTo(stop.asStop)
                : null,
          ),
          actionsKeyPrefix: 'stop_${stop.position}',
        ),
      ),
      if (notes.isNotEmpty) ...[
        const OrderSectionGap(),
        OrderSection(child: OrderNoteCard(note: notes)),
      ],
      if (trip.wantsPhotos(stage, stop: stop)) ...[
        const OrderSectionGap(),
        OrderSection(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              stop.isPickup
                  ? 'Take photos with the camera before you leave with the items. Each is stamped with your location and time.'
                  : 'Take photos with the camera after handing the items over. Each is stamped with your location and time.',
              style: const TextStyle(
                  color: DriverColors.muted, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 16),
            photoSection(trip, stage, enabled: live, stop: stop),
          ]),
        ),
      ],
      const OrderSectionGap(),
      OrderSection(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
        child: OrderFieldLabel(
          stop.isPickup
              ? 'Collect here · ${items.length}'
              : 'Hand over here · ${items.length}',
          trailing: checks
              ? TextButton(
                  key: const Key('stop_check_items'),
                  onPressed: () => context
                      .push(DriverRoutes.items(trip.id, stopId: stop.id)),
                  child: Text(trip.pendingItemsAt(stop) > 0
                      ? 'Check items (${trip.pendingItemsAt(stop)} left)'
                      : 'Items checked'),
                )
              : null,
        ),
      ),
      ColoredBox(
        color: Colors.white,
        child: items.isEmpty
            ? const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Text('No items at this stop.',
                    style: TextStyle(color: DriverColors.muted)),
              )
            : ShipmentItemList(
                items: items,
                photoSlotFor: (item) =>
                    itemPhotoSlot(trip, stage, item, enabled: live, stop: stop),
              ),
      ),
    ]);
  }

  Widget _footer(Trip trip, TripWaypoint stop, bool busy) {
    final ready = trip.hasPhotos(stop.stage, stop: stop) &&
        trip.pendingItemsAt(stop) == 0 &&
        !photoUploading;
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: PrimaryButton(
            key: const Key('stop_done'),
            label: stop.isPickup ? 'Items collected' : 'Items delivered',
            icon: Icons.check_rounded,
            loading: busy,
            color: ready ? DriverColors.green : DriverColors.muted,
            onPressed: () => _finish(trip, stop),
          ),
        ),
      ),
    );
  }
}
