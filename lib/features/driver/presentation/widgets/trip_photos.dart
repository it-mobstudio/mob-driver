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
mixin TripPhotoSlots<T extends StatefulWidget> on State<T> {
  final Map<String, CapturedPhoto> _local = {};
  final Set<String> _uploading = {};

  DriverSessionCubit get photoCubit;
  PhotoCapture get photoCapture;

  /// The server's answer after a photo went in.
  void onTripUpdated(Trip trip);

  static String _slot(PhotoStage stage, TripItem? item) =>
      '${stage.wire}:${item?.id ?? 'order'}';

  bool get photoUploading => _uploading.isNotEmpty;

  CapturedPhoto? localPhoto(PhotoStage stage, [TripItem? item]) =>
      _local[_slot(stage, item)];

  bool isUploading(PhotoStage stage, [TripItem? item]) =>
      _uploading.contains(_slot(stage, item));

  Future<void> takeTripPhoto(Trip trip, PhotoStage stage,
      [TripItem? item]) async {
    final slot = _slot(stage, item);
    final photo = await takeGeoPhoto(
      context,
      photoCapture,
      caption: trip.photoCaption(stage.label, item),
      locate: photoCubit.currentFix,
    );
    if (photo == null || !mounted) return;
    setState(() {
      _local[slot] = photo;
      _uploading.add(slot);
    });
    final (updated, failure) = await photoCubit.addTripPhoto(trip.id,
        stage: stage, photo: photo, itemId: item?.id);
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
  Widget photoSection(Trip trip, PhotoStage stage, {required bool enabled}) {
    final perItem = trip.photoMode(stage) == PickupPhotoMode.perItem;
    final total = trip.items.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      OrderFieldLabel(perItem ? 'Item photos' : 'Upload photo', required: true),
      const SizedBox(height: 10),
      if (perItem)
        PhotoProgress(done: total - trip.missingPhotos(stage), total: total)
      else
        CameraPhotoBox(
          key: Key('${stage.wire}_photo_box'),
          photo: localPhoto(stage),
          photoUrl: trip.orderPhotoUrl(stage),
          uploading: isUploading(stage),
          enabled: enabled,
          hint: stage == PhotoStage.pickup
              ? 'Tap to add photo of the package'
              : 'Tap to add photo of the delivered package',
          onTap: () => takeTripPhoto(trip, stage),
        ),
    ]);
  }

  /// The camera slot under one item, for orders wanting a photo per item.
  Widget? itemPhotoSlot(Trip trip, PhotoStage stage, TripItem item,
          {required bool enabled}) =>
      trip.photoMode(stage) != PickupPhotoMode.perItem
          ? null
          : ItemPhotoSlot(
              key: Key('${stage.wire}_item_photo_${item.id}'),
              photo: localPhoto(stage, item),
              photoUrl: item.photoUrl(stage),
              uploading: isUploading(stage, item),
              enabled: enabled,
              onTap: () => takeTripPhoto(trip, stage, item),
            );

  /// Why the driver can't move on yet, or null when every photo is in.
  String? missingPhotosMessage(Trip trip, PhotoStage stage) {
    if (photoUploading) return 'Wait a moment — the photo is still uploading.';
    final missing = trip.missingPhotos(stage);
    if (missing == 0) return null;
    return trip.photoMode(stage) == PickupPhotoMode.perItem
        ? 'Take a photo of every item first ($missing left).'
        : stage == PhotoStage.pickup
            ? 'Add a photo of the package first.'
            : 'Add a photo of the delivered package first.';
  }
}
