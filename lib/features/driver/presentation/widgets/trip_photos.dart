import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/app_haptics.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/order_widgets.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/photo_widgets.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// Taking and sending a trip's proof photos (pickup or delivery), shared by
/// every screen that shows a photo slot. Each photo is geo-stamped, shown at
/// once from memory, and uploaded straight away; a failed upload drops it.
///
/// Every helper is about the main pickup / final drop, or — given `stop` —
/// one in-between stop (whose kind decides the stage).
mixin TripPhotoSlots<T extends StatefulWidget> on State<T> {
  final Map<String, CapturedPhoto> _local = {};
  final Set<String> _uploading = {};

  DriverSessionCubit get photoCubit;
  PhotoCapture get photoCapture;

  /// The server's answer after a photo went in.
  void onTripUpdated(Trip trip);

  static String _slot(PhotoStage stage, TripItem? item, TripWaypoint? stop) =>
      '${stop?.id ?? 'main'}:${stage.wire}:${item?.id ?? 'order'}';

  bool get photoUploading => _uploading.isNotEmpty;

  CapturedPhoto? localPhoto(PhotoStage stage,
          [TripItem? item, TripWaypoint? stop]) =>
      _local[_slot(stage, item, stop)];

  bool isUploading(PhotoStage stage, [TripItem? item, TripWaypoint? stop]) =>
      _uploading.contains(_slot(stage, item, stop));

  Future<void> takeTripPhoto(Trip trip, PhotoStage stage,
      [TripItem? item, TripWaypoint? stop]) async {
    final slot = _slot(stage, item, stop);
    final photo = await takeGeoPhoto(
      context,
      photoCapture,
      caption: trip.photoCaption(
          stop == null ? stage.label : '${stop.label} · ${stop.kindLabel}',
          item),
      locate: photoCubit.currentFix,
    );
    if (photo == null || !mounted) return;
    setState(() {
      _local[slot] = photo;
      _uploading.add(slot);
    });
    final (updated, failure) = stop == null
        ? await photoCubit.addTripPhoto(trip.id,
            stage: stage, photo: photo, itemId: item?.id)
        : await photoCubit.addStopPhoto(trip.id, stop.id,
            photo: photo, itemId: item?.id);
    if (!mounted) return;
    setState(() {
      _uploading.remove(slot);
      if (updated == null) _local.remove(slot);
    });
    if (updated == null) {
      AppHaptics.error();
      TopSnackBar.show(context,
          message: failure?.message ?? 'Couldn’t save the photo. Try again.',
          type: TopSnackBarType.error);
      return;
    }
    AppHaptics.lightTap();
    onTripUpdated(updated);
  }

  /// The label plus either the big order-photo box or the per-item progress
  /// (the item slots themselves go in the item list — see [itemPhotoSlot]).
  Widget photoSection(Trip trip, PhotoStage stage,
      {required bool enabled, TripWaypoint? stop}) {
    final mode = trip.photoMode(stage);
    final total = trip.itemsAt(stage, stop: stop).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      OrderFieldLabel(
          mode == PickupPhotoMode.both
              ? 'Order & item photos'
              : mode.wantsItemPhotos
                  ? 'Item photos'
                  : 'Upload photo',
          required: true),
      const SizedBox(height: 10),
      if (mode.wantsItemPhotos && total > 0) ...[
        PhotoProgress(
            done: total - trip.missingItemPhotos(stage, stop: stop),
            total: total),
        if (mode.wantsOrderPhoto) const SizedBox(height: 14),
      ],
      if (mode.wantsOrderPhoto)
        CameraPhotoBox(
          key: Key('${stop?.id ?? stage.wire}_photo_box'),
          photo: localPhoto(stage, null, stop),
          photoUrl: trip.orderPhotoUrl(stage, stop: stop),
          uploading: isUploading(stage, null, stop),
          enabled: enabled,
          hint: stage == PhotoStage.pickup
              ? 'Tap to add photo of the package'
              : 'Tap to add photo of the delivered package',
          onTap: () => takeTripPhoto(trip, stage, null, stop),
        ),
    ]);
  }

  /// The camera slot under one item, for orders wanting a photo per item.
  Widget? itemPhotoSlot(Trip trip, PhotoStage stage, TripItem item,
          {required bool enabled, TripWaypoint? stop}) =>
      !trip.photoMode(stage).wantsItemPhotos
          ? null
          : ItemPhotoSlot(
              key: Key('${stage.wire}_item_photo_${item.id}'),
              photo: localPhoto(stage, item, stop),
              photoUrl: item.photoUrl(stage),
              uploading: isUploading(stage, item, stop),
              enabled: enabled,
              onTap: () => takeTripPhoto(trip, stage, item, stop),
            );

  /// Why the driver can't move on yet, or null when every photo is in.
  String? missingPhotosMessage(Trip trip, PhotoStage stage,
      {TripWaypoint? stop}) {
    if (photoUploading) return 'Wait a moment — the photo is still uploading.';
    if (trip.orderPhotoMissing(stage, stop: stop)) {
      return stage == PhotoStage.pickup
          ? 'Add a photo of the package first.'
          : 'Add a photo of the delivered package first.';
    }
    final items = trip.missingItemPhotos(stage, stop: stop);
    if (items > 0) return 'Take a photo of every item first ($items left).';
    return null;
  }
}
