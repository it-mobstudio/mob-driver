import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/utils/image_decode.dart';
import 'package:mob_driver/core/widgets/dashed_border.dart';
import 'package:mob_driver/features/driver/domain/entities/captured_photo.dart';
import 'package:mob_driver/features/driver/presentation/widgets/photo_widgets.dart';

/// One picture in [OrderPhotoGrid]: just taken on this phone ([bytes]) or
/// already on the server ([url]). [id] is what removes it; [busy] while it's
/// uploading or being removed.
class OrderPhotoEntry {
  const OrderPhotoEntry({this.id, this.bytes, this.url, this.busy = false});

  final String? id;
  final Uint8List? bytes;
  final String? url;
  final bool busy;
}

/// The photos of the whole order at one stop. Empty, it's the big dashed
/// "Tap to add photo of the package" box; after that a grid of what was
/// taken — each with a bin to take a wrong shot back — and a tile to add
/// another. Camera only: the caller opens the camera on [onAdd].
class OrderPhotoGrid extends StatelessWidget {
  const OrderPhotoGrid({
    super.key,
    required this.photos,
    required this.onAdd,
    this.onRemove,
    this.addKey,
    this.enabled = true,
    this.canAdd = true,
    this.hint = 'Tap to add photo of the package',
  });

  final List<OrderPhotoEntry> photos;
  final VoidCallback onAdd;

  /// Called with the photo's id. Null hides the bins.
  final ValueChanged<String>? onRemove;

  /// Goes on whatever opens the camera: the empty box, then the "Add" tile.
  final Key? addKey;
  final bool enabled;

  /// False once the stop has as many photos as it can take.
  final bool canAdd;
  final String hint;

  static const _columns = 3;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return _emptyBox();
    final count = photos.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (context, constraints) {
        final side = (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
        return Wrap(spacing: _gap, runSpacing: _gap, children: [
          for (final photo in photos)
            _PhotoTile(
              photo: photo,
              side: side,
              onRemove: enabled && !photo.busy && (photo.id ?? '').isNotEmpty
                  ? onRemove
                  : null,
            ),
          if (enabled && canAdd)
            _AddTile(key: addKey, side: side, onTap: onAdd),
        ]);
      }),
      const SizedBox(height: 10),
      Row(children: [
        Icon(Icons.check_circle_rounded, color: AppColors.green, size: 15),
        const SizedBox(width: 5),
        Text(
            tr('{count} photo{p0} added',
                {'count': count, 'p0': count == 1 ? '' : 's'}),
            style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ]),
    ]);
  }

  Widget _emptyBox() => Material(
        color: Colors.transparent,
        child: InkWell(
          key: addKey,
          onTap: enabled ? onAdd : null,
          borderRadius: BorderRadius.circular(14),
          child: DashedBorder(
            radius: 14,
            child: SizedBox(
              height: 132,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(14)),
                child: _Empty(hint: hint),
              ),
            ),
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add_a_photo_rounded, size: 30, color: AppColors.ink),
          const SizedBox(height: 10),
          Text(tr(hint),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ]),
      );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile(
      {required this.photo, required this.side, required this.onRemove});

  final OrderPhotoEntry photo;
  final double side;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: side,
        height: side,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(fit: StackFit.expand, children: [
            if (photo.bytes != null)
              Image.memory(photo.bytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  // A 1600 px photo decoded whole is ~10 MB; at tile size
                  // it's a few hundred KB.
                  cacheWidth: thumbPixels(context, side))
            else
              NetworkThumb(photo.url,
                  size: side,
                  radius: 12,
                  fallbackIcon: Icons.image_not_supported_outlined),
            if (photo.busy)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white)),
                  ),
                ),
              ),
            if (onRemove != null)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.black.withValues(alpha: .62),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: Key('photo_remove_${photo.id}'),
                    onTap: () => onRemove!(photo.id!),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 18,
                          semanticLabel: tr('Remove photo')),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      );
}

class _AddTile extends StatelessWidget {
  const _AddTile({super.key, required this.side, required this.onTap});

  final double side;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: side,
        height: side,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: DashedBorder(
              radius: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_a_photo_rounded,
                        size: 22, color: AppColors.ink),
                    const SizedBox(height: 6),
                    Text(tr('Add photo'),
                        style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

/// A small camera slot for one item's photo, sitting under its name: dashed
/// "Add photo" until taken, then the thumbnail with a green tick.
class ItemPhotoSlot extends StatelessWidget {
  const ItemPhotoSlot({
    super.key,
    required this.onTap,
    this.photo,
    this.photoUrl,
    this.uploading = false,
    this.enabled = true,
  });

  final VoidCallback onTap;
  final CapturedPhoto? photo;
  final String? photoUrl;
  final bool uploading;
  final bool enabled;

  bool get _filled => photo != null || (photoUrl ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final thumb = SizedBox(
      width: 36,
      height: 36,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(fit: StackFit.expand, children: [
          if (photo != null)
            Image.memory(photo!.bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: thumbPixels(context, 36))
          else
            NetworkThumb(photoUrl, size: 36, radius: 8),
          if (uploading)
            const ColoredBox(
              color: Color(0x66000000),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white)),
              ),
            ),
        ]),
      ),
    );

    return InkWell(
      onTap: enabled && !uploading ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerLeft,
          children: [...previous, if (current != null) current],
        ),
        child: _filled
            ? Row(
                key: const ValueKey('filled'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  thumb,
                  const SizedBox(width: 8),
                  if (!uploading) ...[
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.green, size: 15),
                    const SizedBox(width: 4),
                    Text(
                        enabled
                            ? tr('Photo added · Retake')
                            : tr('Photo added'),
                        style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              )
            : DashedBorder(
                key: const ValueKey('empty'),
                radius: 10,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 16, color: AppColors.ink),
                    const SizedBox(width: 6),
                    Text(tr('Add photo'),
                        style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    Text(' *',
                        style: TextStyle(
                            color: AppColors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
      ),
    );
  }
}

/// `2 of 6 photos taken` with a thin bar — for orders wanting a photo of
/// every item.
class PhotoProgress extends StatelessWidget {
  const PhotoProgress({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final complete = total > 0 && done >= total;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        complete
            ? tr('All {total} item photos taken', {'total': total})
            : tr('Take a photo of each item below · {done} of {total} done',
                {'done': done, 'total': total}),
        style: TextStyle(
            color: complete ? AppColors.green : AppColors.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: total == 0 ? 0 : done / total),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => LinearProgressIndicator(
            value: value,
            minHeight: 5,
            backgroundColor: AppColors.line,
            valueColor: AlwaysStoppedAnimation(
                complete ? AppColors.green : AppColors.blue),
          ),
        ),
      ),
    ]);
  }
}
