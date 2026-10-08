import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/fare_chips.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/photo_widgets.dart';

/// The building blocks of an order screen — header, pickup photos, the two
/// stops, the shipment list and what it pays. Each is self-contained (data
/// in, callbacks out) so other order screens can reuse them as they are.

// -- layout ------------------------------------------------------------------

/// The 8 px grey band between an order screen's sections.
class OrderSectionGap extends StatelessWidget {
  const OrderSectionGap({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 8, color: DriverColors.surface);
}

/// A white section with the order screens' standard padding.
class OrderSection extends StatelessWidget {
  const OrderSection({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.white,
        child: Padding(padding: padding, child: child),
      );
}

/// `Upload photo *` — a field label, with a red star when it's required.
class OrderFieldLabel extends StatelessWidget {
  const OrderFieldLabel(this.text, {super.key, this.required = false, this.trailing});

  final String text;
  final bool required;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(text,
            style: const TextStyle(
                color: DriverColors.ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w800)),
        if (required)
          const Text(' *',
              style: TextStyle(
                  color: DriverColors.red,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800)),
        if (trailing != null) ...[const Spacer(), trailing!],
      ]);
}

/// The app bar's "Help" pill: headset icon and label, vertically centred.
/// With no [onTap] it explains where to turn for help.
class HelpChip extends StatelessWidget {
  const HelpChip({super.key, this.onTap});

  final VoidCallback? onTap;

  void _explain(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Need help?'),
          content: const Text(
              'Contact your operations team about this order — they can step in from their end.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: DriverColors.line),
        ),
        child: InkWell(
          key: const Key('help_chip'),
          borderRadius: BorderRadius.circular(10),
          onTap: onTap ?? () => _explain(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.headset_mic_outlined,
                  size: 16, color: DriverColors.ink),
              SizedBox(width: 6),
              Text('Help',
                  style: TextStyle(
                      color: DriverColors.ink,
                      fontSize: 13,
                      height: 1.2,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}

/// A quiet secondary action: soft grey fill, no outline — next to a dark
/// primary (Map) it reads as the lesser choice without shouting.
class TonalButton extends StatelessWidget {
  const TonalButton(
      {super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => PressScale(
        enabled: onPressed != null,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: DriverColors.surface,
            foregroundColor: DriverColors.ink,
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[
              Icon(icon, size: 17),
              const SizedBox(width: 6),
            ],
            Text(label),
          ]),
        ),
      );
}

// -- header ------------------------------------------------------------------

/// `#MOB9867855HJ` over `16 May 2026, 10:25 am`.
class OrderHeader extends StatelessWidget {
  const OrderHeader({super.key, required this.reference, this.placedAt});

  final String reference;
  final DateTime? placedAt;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reference,
              style: const TextStyle(
                  color: DriverColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800)),
          if (placedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMM yyyy, h:mm a')
                  .format(placedAt!.toLocal())
                  .replaceAll('AM', 'am')
                  .replaceAll('PM', 'pm'),
              style: const TextStyle(color: DriverColors.muted, fontSize: 13),
            ),
          ],
        ],
      );
}

// -- photos ------------------------------------------------------------------

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
        final side =
            (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
        return Wrap(spacing: _gap, runSpacing: _gap, children: [
          for (final photo in photos)
            _PhotoTile(
              photo: photo,
              side: side,
              onRemove: enabled && !photo.busy && (photo.id ?? '').isNotEmpty
                  ? onRemove
                  : null,
            ),
          if (enabled && canAdd) _AddTile(key: addKey, side: side, onTap: onAdd),
        ]);
      }),
      const SizedBox(height: 10),
      Row(children: [
        const Icon(Icons.check_circle_rounded,
            color: DriverColors.green, size: 15),
        const SizedBox(width: 5),
        Text('$count photo${count == 1 ? '' : 's'} added',
            style: const TextStyle(
                color: DriverColors.muted,
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
                    color: const Color(0xFFF7F9FC),
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
          const Icon(Icons.add_a_photo_rounded,
              size: 30, color: DriverColors.ink),
          const SizedBox(height: 10),
          Text(hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: DriverColors.ink,
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
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 18,
                          semanticLabel: 'Remove photo'),
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
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_a_photo_rounded,
                        size: 22, color: DriverColors.ink),
                    SizedBox(height: 6),
                    Text('Add photo',
                        style: TextStyle(
                            color: DriverColors.ink,
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
                    const Icon(Icons.check_circle_rounded,
                        color: DriverColors.green, size: 15),
                    const SizedBox(width: 4),
                    Text(enabled ? 'Photo added · Retake' : 'Photo added',
                        style: const TextStyle(
                            color: DriverColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              )
            : const DashedBorder(
                key: ValueKey('empty'),
                radius: 10,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 16, color: DriverColors.ink),
                    SizedBox(width: 6),
                    Text('Add photo',
                        style: TextStyle(
                            color: DriverColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    Text(' *',
                        style: TextStyle(
                            color: DriverColors.red,
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
            ? 'All $total item photos taken'
            : 'Take a photo of each item below · $done of $total done',
        style: TextStyle(
            color: complete ? DriverColors.green : DriverColors.muted,
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
            backgroundColor: DriverColors.line,
            valueColor: AlwaysStoppedAnimation(
                complete ? DriverColors.green : DriverColors.blue),
          ),
        ),
      ),
    ]);
  }
}

// -- stops -------------------------------------------------------------------

/// One end of the trip as [StopTimeline] shows it.
class StopInfo {
  const StopInfo({
    required this.name,
    required this.address,
    this.onCall,
    this.onMap,
  });

  final String name;
  final String address;
  final VoidCallback? onCall;
  final VoidCallback? onMap;
}

/// Pickup over drop, joined by a line: a filled green dot and a hollow red
/// one, each with the side label (`PICKUP` / `DROP`) running up the edge.
class StopTimeline extends StatelessWidget {
  const StopTimeline({super.key, required this.pickup, required this.drop});

  final StopInfo pickup;
  final StopInfo drop;

  @override
  Widget build(BuildContext context) => Column(children: [
          StopBlock(
            label: 'PICKUP',
            color: DriverColors.green,
            filled: true,
            stop: pickup,
            lineBelow: true,
            actionsKeyPrefix: 'order_details',
          ),
          StopBlock(
            label: 'DROP',
            color: DriverColors.red,
            filled: false,
            stop: drop,
            actionsKeyPrefix: 'order_details_drop',
          ),
        ]);
}

class StopBlock extends StatelessWidget {
  const StopBlock({
    super.key,
    required this.label,
    required this.color,
    required this.filled,
    required this.stop,
    this.lineBelow = false,
    this.actionsKeyPrefix = 'stop',
  });

  final String label;
  final Color color;
  final bool filled;
  final StopInfo stop;

  /// Continues the connecting line down to the next stop.
  final bool lineBelow;
  final String actionsKeyPrefix;

  @override
  // IntrinsicHeight lets the connecting line stretch to the block's height.
  Widget build(BuildContext context) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Align(
              alignment: Alignment.topCenter,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(label,
                    style: const TextStyle(
                        color: DriverColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 14,
            child: Column(children: [
              const SizedBox(height: 4),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: filled ? color : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                ),
              ),
              if (lineBelow)
                Expanded(
                  child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: DriverColors.line),
                ),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: lineBelow ? 26 : 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stop.name,
                        style: const TextStyle(
                            color: DriverColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(stop.address,
                        style: const TextStyle(
                            color: DriverColors.muted,
                            fontSize: 13,
                            height: 1.35)),
                    if (stop.onCall != null || stop.onMap != null) ...[
                      const SizedBox(height: 12),
                      _StopActions(stop: stop, keyPrefix: actionsKeyPrefix),
                    ],
                  ]),
            ),
          ),
        ],
      ));
}

class _StopActions extends StatelessWidget {
  const _StopActions({required this.stop, required this.keyPrefix});
  final StopInfo stop;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) => Row(children: [
        if (stop.onCall != null)
          Expanded(
            child: TonalButton(
              key: Key('${keyPrefix}_call'),
              label: 'Call',
              icon: Icons.call_rounded,
              onPressed: stop.onCall,
            ),
          ),
        if (stop.onCall != null && stop.onMap != null) const SizedBox(width: 10),
        if (stop.onMap != null)
          Expanded(
            child: ElevatedButton.icon(
              key: Key('${keyPrefix}_map'),
              onPressed: stop.onMap,
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: const Text('Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverColors.ink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(44),
                textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ]);
}

/// Where a stop stands on the trip screen's timeline.
enum StopProgress { done, active, upcoming }

/// One stop on [TripTimeline].
class TimelineStop {
  const TimelineStop({
    required this.tag,
    required this.tagIcon,
    required this.name,
    required this.address,
    required this.progress,
    this.index,
    this.onViewDetails,
    this.onMap,
  });

  /// The stop's place on the whole trip (0 = the main pickup), for when a
  /// [TripTimeline] shows only some of the stops. Defaults to its place in
  /// the list it's given in.
  final int? index;
  final String tag;

  /// Sits after the tag's label, ~13 px.
  final Widget tagIcon;
  final String name;
  final String address;
  final StopProgress progress;
  final VoidCallback? onViewDetails;

  /// Only shown on the active stop.
  final VoidCallback? onMap;
}

/// The trip screen's pickup → drop timeline: a tag per stop (green while it's
/// the one being worked on), a tick once it's done, and View details / Map.
class TripTimeline extends StatelessWidget {
  const TripTimeline({super.key, required this.stops});

  final List<TimelineStop> stops;

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < stops.length; i++)
          _TimelineRow(
            stop: stops[i],
            index: stops[i].index ?? i,
            // The line to the next stop turns green once this one's done.
            lineBelow: i == stops.length - 1
                ? null
                : stops[i].progress == StopProgress.done
                    ? DriverColors.green
                    : DriverColors.line,
          ),
      ]);
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow(
      {required this.stop, required this.index, required this.lineBelow});

  final TimelineStop stop;
  final int index;
  final Color? lineBelow;

  @override
  Widget build(BuildContext context) {
    final active = stop.progress == StopProgress.active;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 22,
          child: Column(children: [
            const SizedBox(height: 2),
            _TimelineNode(progress: stop.progress),
            if (lineBelow != null)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 2.5,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: lineBelow,
                ),
              ),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: lineBelow == null ? 0 : 22),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StopTag(label: stop.tag, icon: stop.tagIcon, active: active),
                  const SizedBox(height: 8),
                  Text(stop.name,
                      style: const TextStyle(
                          color: DriverColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(stop.address,
                      style: const TextStyle(
                          color: DriverColors.muted,
                          fontSize: 13,
                          height: 1.35)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TonalButton(
                        key: Key('timeline_view_details_$index'),
                        label: 'View details',
                        onPressed: stop.onViewDetails,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: active && stop.onMap != null
                          ? ElevatedButton.icon(
                              key: Key('timeline_map_$index'),
                              onPressed: stop.onMap,
                              icon: const Icon(Icons.navigation_rounded,
                                  size: 16),
                              label: const Text('Map'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DriverColors.ink,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                minimumSize: const Size.fromHeight(44),
                                textStyle: const TextStyle(fontFamily: 'Inter', 
                                    fontWeight: FontWeight.w700),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ]),
                ]),
          ),
        ),
      ]),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.progress});
  final StopProgress progress;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (progress) {
          StopProgress.done => Container(
              key: const ValueKey('done'),
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                  color: DriverColors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 15),
            ),
          StopProgress.active => Container(
              key: const ValueKey('active'),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: DriverColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: DriverColors.ink, width: 4.5),
              ),
            ),
          StopProgress.upcoming => Container(
              key: const ValueKey('upcoming'),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC5CED8), width: 3),
              ),
            ),
        },
      );
}

class _StopTag extends StatelessWidget {
  const _StopTag(
      {required this.label, required this.icon, required this.active});
  final String label;
  final Widget icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fg = active ? const Color(0xFF0E8A57) : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFD5F3E4) : const Color(0xFF9AA5B1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(width: 5),
        IconTheme.merge(
            data: IconThemeData(size: 13, color: fg), child: icon),
      ]),
    );
  }
}

// -- items -------------------------------------------------------------------

/// `6 items in shipment` with a chevron that folds the list away.
class ShipmentHeader extends StatelessWidget {
  const ShipmentHeader({
    super.key,
    required this.count,
    required this.expanded,
    required this.onToggle,
  });

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
          child: Row(children: [
            Expanded(
              child: Text('$count ${count == 1 ? 'item' : 'items'} in shipment',
                  style: const TextStyle(
                      color: DriverColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ),
            IconButton(
              key: const Key('order_details_items_toggle'),
              onPressed: onToggle,
              icon: AnimatedRotation(
                turns: expanded ? .5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ),
          ]),
        ),
      );
}

/// The items, separated by dashed rules. [photoSlotFor] adds a camera slot
/// under an item (orders wanting a photo per item); null leaves it plain.
class ShipmentItemList extends StatelessWidget {
  const ShipmentItemList({super.key, required this.items, this.photoSlotFor});

  final List<TripItem> items;
  final Widget? Function(TripItem item)? photoSlotFor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Column(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const DashedDivider(),
            ShipmentItemRow(item: items[i], photoSlot: photoSlotFor?.call(items[i])),
          ],
        ]),
      );
}

/// Picture, name (two lines), the variant line in grey and the `x 2` chip.
class ShipmentItemRow extends StatelessWidget {
  const ShipmentItemRow({super.key, required this.item, this.photoSlot});

  final TripItem item;
  final Widget? photoSlot;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          NetworkThumb(item.imageUrl, size: 52, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DriverColors.ink,
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w600)),
              if (item.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(item.notes!,
                    style: const TextStyle(
                        color: DriverColors.muted, fontSize: 12)),
              ],
              if ((item.driverNote ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                    key: Key('item_driver_note_${item.id}'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 13,
                          color: item.status == ItemStatus.notDelivered
                              ? DriverColors.red
                              : DriverColors.muted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                            item.status == ItemStatus.notDelivered
                                ? 'Not delivered · ${item.driverNote!.trim()}'
                                : item.driverNote!.trim(),
                            style: TextStyle(
                                color: item.status == ItemStatus.notDelivered
                                    ? DriverColors.red
                                    : DriverColors.muted,
                                fontSize: 12,
                                height: 1.3)),
                      ),
                    ]),
              ],
              if (photoSlot != null) ...[
                const SizedBox(height: 10),
                photoSlot!,
              ],
            ]),
          ),
          const SizedBox(width: 10),
          QuantityChip(quantity: item.quantity),
        ]),
      );
}

/// `x 13` in a soft grey pill.
class QuantityChip extends StatelessWidget {
  const QuantityChip({super.key, required this.quantity});
  final int quantity;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(10)),
        child: Text('x $quantity',
            style: const TextStyle(
                color: DriverColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
      );
}

// -- notes -------------------------------------------------------------------

/// The company's note for the driver, on a soft amber card.
class OrderNoteCard extends StatelessWidget {
  const OrderNoteCard({super.key, required this.note, this.title = 'Note'});

  final String note;
  final String title;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('order_note'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF6E2B3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.sticky_note_2_outlined,
                size: 18, color: DriverColors.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: DriverColors.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(note.trim(),
                  style: const TextStyle(
                      color: DriverColors.ink, fontSize: 13, height: 1.4)),
            ]),
          ),
        ]),
      );
}

// -- earnings ----------------------------------------------------------------

/// `You'll receive ₹420`, the trip-fare / bonus split, and the
/// heavy-unloading note when there's a bonus.
class EarningsSummary extends StatelessWidget {
  const EarningsSummary({
    super.key,
    required this.tripFare,
    this.bonus,
    this.currency = 'INR',
  });

  final double? tripFare;

  /// Null or zero: no bonus chip, no banner.
  final double? bonus;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final hasBonus = bonus != null && bonus! > 0;
    final total = (tripFare ?? 0) + (hasBonus ? bonus! : 0);
    return Column(children: [
      const Text('You’ll receive',
          style: TextStyle(
              color: DriverColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(formatMoneyShort(total, currency: currency),
          key: const Key('order_details_total'),
          style: const TextStyle(
              color: DriverColors.ink,
              fontSize: 30,
              fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      FareChips(
          tripFare: tripFare,
          bonus: hasBonus ? bonus : null,
          currency: currency),
      if (hasBonus) ...[
        const SizedBox(height: 12),
        const HeavyUnloadingBanner(),
      ],
    ]);
  }
}

class HeavyUnloadingBanner extends StatelessWidget {
  const HeavyUnloadingBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('heavy_unloading_banner'),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        decoration: BoxDecoration(
            color: const Color(0xFFFBE4E0),
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Heavy unloading',
                  style: TextStyle(
                      color: DriverColors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Additional unloading fee included for this delivery',
                  style: TextStyle(
                      color: DriverColors.muted, fontSize: 12, height: 1.35)),
            ]),
          ),
          const SizedBox(width: 10),
          Image.asset('assets/images/heavy_loading.png',
              width: 64, height: 64, fit: BoxFit.contain),
        ]),
      );
}

// -- dashes ------------------------------------------------------------------

/// A rounded rect drawn as short dashes rather than a solid line.
class DashedBorder extends StatelessWidget {
  const DashedBorder({super.key, required this.child, this.radius = 14});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
        foregroundPainter: _DashedRRectPainter(radius: radius),
        child: child,
      );
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = DriverColors.muted.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
            metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

/// A thin dashed rule between rows.
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashedLinePainter(), size: Size.infinite));
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DriverColors.line
      ..strokeWidth = 1;
    const dash = 5.0, gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
