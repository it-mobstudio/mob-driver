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
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/driver/data/media/photo_capture.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:mob_driver/features/driver/presentation/widgets/order/order_section.dart';
import 'package:mob_driver/features/driver/presentation/widgets/order/shipment_list.dart';
import 'package:mob_driver/features/driver/presentation/widgets/order/stop_timeline.dart';
import 'package:mob_driver/features/driver/presentation/widgets/trip/trip_photos.dart';

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
      await context.push(AppRoutes.items(trip.id, stopId: stop.id));
      if (!mounted) return;
      // Carry on only once the checklist came back complete.
      final latest = _trip(_cubit.state);
      final latestStop = latest == null ? null : _stop(latest);
      if (latestStop == null || latest!.pendingItemsAt(latestStop) > 0) return;
    }
    final (updated, failure) = await _cubit.finishStop(trip.id, stop.id);
    if (!mounted) return;
    if (updated == null) {
      return _error(
          failure?.message ?? tr('Couldn’t finish this stop. Try again.'));
    }
    AppHaptics.success();
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DriverSessionCubit, DriverSessionState>(
        buildWhen: (a, b) =>
            a.activeTrip != b.activeTrip || a.tripBusy != b.tripBusy,
        builder: (context, state) {
          final trip = _trip(state);
          final stop = trip == null ? null : _stop(trip);
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              backgroundColor: AppColors.card,
              surfaceTintColor: AppColors.card,
              elevation: 0,
              foregroundColor: AppColors.ink,
              titleSpacing: 0,
              title: Text(
                  stop == null
                      ? tr('Stop')
                      : '${stop.label} · ${stop.kindLabel}',
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
          label: stop.isPickup ? tr('PICKUP') : tr('DROP'),
          isPickup: stop.isPickup,
          color: stop.isPickup ? AppColors.green : AppColors.red,
          filled: stop.isPickup,
          stop: StopInfo(
            name: (stop.contactName ?? '').isNotEmpty
                ? stop.contactName!
                : stop.kindLabel,
            address: stop.address,
            onCall: (stop.contactPhone ?? '').isNotEmpty
                ? () => Launchers.call(stop.contactPhone)
                : null,
            onMap: stop.latitude != null
                ? () => Launchers.navigateTo(stop.asStop)
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              stop.isPickup
                  ? tr(
                      'Take photos with the camera before you leave with the items. Each is stamped with your location and time.')
                  : tr(
                      'Take photos with the camera after handing the items over. Each is stamped with your location and time.'),
              style: TextStyle(
                  color: AppColors.muted, fontSize: 12.5, height: 1.4),
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
              ? tr('Collect here · {count}', {'count': items.length})
              : tr('Hand over here · {count}', {'count': items.length}),
          trailing: checks
              ? TextButton(
                  key: const Key('stop_check_items'),
                  onPressed: () =>
                      context.push(AppRoutes.items(trip.id, stopId: stop.id)),
                  child: Text(trip.pendingItemsAt(stop) > 0
                      ? tr('Check items ({p0} left)',
                          {'p0': trip.pendingItemsAt(stop)})
                      : tr('Items checked')),
                )
              : null,
        ),
      ),
      ColoredBox(
        color: AppColors.card,
        child: items.isEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Text(tr('No items at this stop.'),
                    style: TextStyle(color: AppColors.muted)),
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
      color: AppColors.card,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: PrimaryButton(
            key: const Key('stop_done'),
            label:
                stop.isPickup ? tr('Items collected') : tr('Items delivered'),
            icon: Icons.check_rounded,
            loading: busy,
            color: ready ? AppColors.green : AppColors.muted,
            onPressed: () => _finish(trip, stop),
          ),
        ),
      ),
    );
  }
}
