import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/order_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_photos.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// The proof photos an order asks for at one stop — the package before
/// pickup, or the delivered package at the drop — when the driver swipes
/// "Pickup order" / "Deliver order" without them. Pops `true` once every
/// photo is on the server, so the swipe can carry on.
class OrderPhotosPage extends StatefulWidget {
  const OrderPhotosPage({
    super.key,
    required this.tripId,
    required this.stage,
    this.capture = const DevicePhotoCapture(),
  });

  static const routeName = 'OrderPhotos';

  final String tripId;
  final PhotoStage stage;
  final PhotoCapture capture;

  @override
  State<OrderPhotosPage> createState() => _OrderPhotosPageState();
}

class _OrderPhotosPageState extends State<OrderPhotosPage>
    with TripPhotoSlots<OrderPhotosPage> {
  late final DriverSessionCubit _cubit = context.read<DriverSessionCubit>();
  Trip? _trip;

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
    if (mounted && trip != null) setState(() => _trip = trip);
  }

  void _done(Trip trip) {
    final problem = missingPhotosMessage(trip, widget.stage);
    if (problem != null) {
      TopSnackBar.show(context, message: problem, type: TopSnackBarType.error);
      return;
    }
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    final pickup = widget.stage == PhotoStage.pickup;
    return Scaffold(
      backgroundColor: DriverColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: DriverColors.ink,
        titleSpacing: 0,
        title: Text(pickup ? 'Pickup photos' : 'Delivery photos',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: trip == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [
              OrderSection(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OrderHeader(
                          reference: trip.displayReference,
                          placedAt: trip.createdAt),
                      const SizedBox(height: 6),
                      Text(
                        pickup
                            ? 'Take photos with the camera before you pick up the order. Each is stamped with your location and time.'
                            : 'Take photos with the camera after handing the order over. Each is stamped with your location and time.',
                        style: const TextStyle(
                            color: DriverColors.muted,
                            fontSize: 12.5,
                            height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      photoSection(trip, widget.stage, enabled: true),
                    ]),
              ),
              if (trip.photoMode(widget.stage) == PickupPhotoMode.perItem) ...[
                const OrderSectionGap(),
                ColoredBox(
                  color: Colors.white,
                  child: ShipmentItemList(
                    items: trip.items,
                    photoSlotFor: (item) => itemPhotoSlot(
                        trip, widget.stage, item,
                        enabled: true),
                  ),
                ),
              ],
            ]),
      bottomNavigationBar: trip == null
          ? null
          : Material(
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: PrimaryButton(
                    key: const Key('order_photos_done'),
                    label: 'Continue',
                    color: trip.hasPhotos(widget.stage) && !photoUploading
                        ? DriverColors.blue
                        : DriverColors.muted,
                    onPressed: () => _done(trip),
                  ),
                ),
              ),
            ),
    );
  }
}
