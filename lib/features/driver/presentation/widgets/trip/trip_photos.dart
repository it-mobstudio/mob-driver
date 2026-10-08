import 'package:flutter/material.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/services/haptics.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/driver/data/media/photo_capture.dart';
import 'package:mob_driver/features/driver/domain/driver_limits.dart';
import 'package:mob_driver/features/driver/domain/entities/captured_photo.dart';
import 'package:mob_driver/features/driver/domain/entities/trip.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:mob_driver/features/driver/presentation/widgets/order/order_photo_grid.dart';
import 'package:mob_driver/features/driver/presentation/widgets/order/order_section.dart';
import 'package:mob_driver/features/driver/presentation/widgets/photo_widgets.dart';

/// Taking and sending a trip's proof photos (pickup or delivery), shared by
/// every screen that shows a photo slot. Each photo is geo-stamped, shown at
/// once from memory, and uploaded straight away; a failed upload drops it.
///
/// The whole order can have several photos — each one taken is added, and a
/// wrong one can be removed — while an item has one, which a retake replaces.
///
/// Every helper is about the main pickup / final drop, or — given `stop` —
/// one in-between stop (whose kind decides the stage).
mixin TripPhotoSlots<T extends StatefulWidget> on State<T> {
  final Map<String, CapturedPhoto> _local = {};
  final Set<String> _uploading = {};

  /// Order photos on their way up, by slot — shown after the ones already on
  /// the server until the upload answers.
  final Map<String, List<CapturedPhoto>> _pending = {};

  /// Order photos taken on this screen, by their server id: shown from memory
  /// rather than fetched back.
  final Map<String, CapturedPhoto> _taken = {};
  final Set<String> _removing = {};

  DriverSessionCubit get photoCubit;
  PhotoCapture get photoCapture;

  /// The server's answer after a photo went in.
  void onTripUpdated(Trip trip);

  static String _slot(PhotoStage stage, TripItem? item, TripWaypoint? stop) =>
      '${stop?.id ?? 'main'}:${stage.wire}:${item?.id ?? 'order'}';

  bool get photoUploading => _uploading.isNotEmpty || _pending.isNotEmpty;

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
    final ofOrder = item == null;
    final before = {for (final p in trip.orderPhotos(stage, stop: stop)) p.id};
    setState(() {
      if (ofOrder) {
        (_pending[slot] ??= []).add(photo);
      } else {
        _local[slot] = photo;
        _uploading.add(slot);
      }
    });
    final (updated, failure) = stop == null
        ? await photoCubit.addTripPhoto(trip.id,
            stage: stage, photo: photo, itemId: item?.id)
        : await photoCubit.addStopPhoto(trip.id, stop.id,
            photo: photo, itemId: item?.id);
    if (!mounted) return;
    setState(() {
      if (ofOrder) {
        _pending[slot]?.remove(photo);
        if (_pending[slot]?.isEmpty ?? false) _pending.remove(slot);
        // The one the server just added is this picture.
        final added = updated
            ?.orderPhotos(stage,
                stop: stop == null
                    ? null
                    : updated.stops.where((s) => s.id == stop.id).firstOrNull)
            .where((p) => p.canRemove && !before.contains(p.id))
            .lastOrNull;
        if (added != null) _taken[added.id] = photo;
      } else {
        _uploading.remove(slot);
        if (updated == null) _local.remove(slot);
      }
    });
    if (updated == null) {
      AppHaptics.error();
      TopSnackBar.show(context,
          message:
              failure?.message ?? tr('Couldn’t save the photo. Try again.'),
          type: TopSnackBarType.error);
      return;
    }
    AppHaptics.lightTap();
    onTripUpdated(updated);
  }

  /// Takes back one photo of the whole order, once the driver confirms.
  Future<void> removeTripPhoto(Trip trip, String photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Remove this photo?')),
        content: Text(tr('You can take another one in its place.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Keep'))),
          TextButton(
              key: const Key('photo_remove_confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Remove'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _removing.add(photoId));
    final (updated, failure) =
        await photoCubit.removeTripPhoto(trip.id, photoId);
    if (!mounted) return;
    setState(() {
      _removing.remove(photoId);
      if (updated != null) _taken.remove(photoId);
    });
    if (updated == null) {
      AppHaptics.error();
      TopSnackBar.show(context,
          message:
              failure?.message ?? tr('Couldn’t remove the photo. Try again.'),
          type: TopSnackBarType.error);
      return;
    }
    AppHaptics.lightTap();
    onTripUpdated(updated);
  }

  /// The label plus either the order's photos or the per-item progress
  /// (the item slots themselves go in the item list — see [itemPhotoSlot]).
  Widget photoSection(Trip trip, PhotoStage stage,
      {required bool enabled, TripWaypoint? stop}) {
    final mode = trip.photoMode(stage);
    final total = trip.itemsAt(stage, stop: stop).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      OrderFieldLabel(
          mode == PickupPhotoMode.both
              ? tr('Order & item photos')
              : mode.wantsItemPhotos
                  ? tr('Item photos')
                  : tr('Upload photos'),
          required: true),
      const SizedBox(height: 10),
      if (mode.wantsItemPhotos && total > 0) ...[
        PhotoProgress(
            done: total - trip.missingItemPhotos(stage, stop: stop),
            total: total),
        if (mode.wantsOrderPhoto) const SizedBox(height: 14),
      ],
      if (mode.wantsOrderPhoto) _orderPhotos(trip, stage, enabled, stop),
    ]);
  }

  Widget _orderPhotos(
      Trip trip, PhotoStage stage, bool enabled, TripWaypoint? stop) {
    final saved = trip.orderPhotos(stage, stop: stop);
    final pending = _pending[_slot(stage, null, stop)] ?? const [];
    return OrderPhotoGrid(
      addKey: Key('${stop?.id ?? stage.wire}_photo_box'),
      photos: [
        for (final photo in saved)
          OrderPhotoEntry(
            id: photo.canRemove ? photo.id : null,
            bytes: _taken[photo.id]?.bytes,
            url: photo.url,
            busy: _removing.contains(photo.id),
          ),
        for (final photo in pending)
          OrderPhotoEntry(bytes: photo.bytes, busy: true),
      ],
      enabled: enabled,
      canAdd: saved.length + pending.length < DriverLimits.maxOrderPhotos,
      hint: stage == PhotoStage.pickup
          ? tr('Tap to add photo of the package')
          : tr('Tap to add photo of the delivered package'),
      onAdd: () => takeTripPhoto(trip, stage, null, stop),
      onRemove: (id) => removeTripPhoto(trip, id),
    );
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
    if (photoUploading) {
      return tr('Wait a moment — the photo is still uploading.');
    }
    if (trip.orderPhotoMissing(stage, stop: stop)) {
      return stage == PhotoStage.pickup
          ? tr('Add a photo of the package first.')
          : tr('Add a photo of the delivered package first.');
    }
    final items = trip.missingItemPhotos(stage, stop: stop);
    if (items > 0) {
      return tr(
          'Take a photo of every item first ({items} left).', {'items': items});
    }
    return null;
  }
}
