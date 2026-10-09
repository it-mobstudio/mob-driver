import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mob_driver/core/constants/app_assets.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/widgets/tonal_button.dart';

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

/// The small dotted mark that sits at the right of a pickup's name.
class PickupMark extends StatelessWidget {
  const PickupMark({super.key});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        AppAssets.pickupMark,
        key: const Key('pickup_mark'),
        width: 13,
        height: 13,
        // The artwork is dark navy; tint it so it shows in dark mode too.
        colorFilter: ColorFilter.mode(AppColors.muted, BlendMode.srcIn),
      );
}

/// A stop's name with, for a pickup, [PickupMark] at the right end.
class _StopName extends StatelessWidget {
  const _StopName(this.name, {required this.pickup, required this.style});
  final String name;
  final bool pickup;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final text = Text(name, style: style);
    if (!pickup) return text;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: text),
      const SizedBox(width: 8),
      const Padding(padding: EdgeInsets.only(top: 4), child: PickupMark()),
    ]);
  }
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
          label: tr('PICKUP'),
          isPickup: true,
          color: AppColors.green,
          filled: true,
          stop: pickup,
          lineBelow: true,
          actionsKeyPrefix: 'order_details',
        ),
        StopBlock(
          label: tr('DROP'),
          color: AppColors.red,
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
    this.isPickup = false,
    this.lineBelow = false,
    this.actionsKeyPrefix = 'stop',
  });

  final String label;
  final Color color;
  final bool filled;
  final StopInfo stop;

  /// Shows [PickupMark] beside the name.
  final bool isPickup;

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
                    style: TextStyle(
                        color: AppColors.muted,
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
                  color: filled ? color : AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                ),
              ),
              if (lineBelow)
                Expanded(
                  child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.line),
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
                    _StopName(stop.name,
                        pickup: isPickup,
                        style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(stop.address,
                        style: TextStyle(
                            color: AppColors.muted,
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
              label: tr('Call'),
              icon: Icons.call_rounded,
              onPressed: stop.onCall,
            ),
          ),
        if (stop.onCall != null && stop.onMap != null)
          const SizedBox(width: 10),
        if (stop.onMap != null)
          Expanded(
            child: ElevatedButton.icon(
              key: Key('${keyPrefix}_map'),
              onPressed: stop.onMap,
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: Text(tr('Map')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(44),
                textStyle: const TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w700),
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
    this.isPickup = false,
  });

  /// Shows [PickupMark] beside the name.
  final bool isPickup;

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
                    ? AppColors.green
                    : AppColors.line,
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
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _StopTag(label: stop.tag, icon: stop.tagIcon, active: active),
              const SizedBox(height: 8),
              _StopName(stop.name,
                  pickup: stop.isPickup,
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(stop.address,
                  style: TextStyle(
                      color: AppColors.muted, fontSize: 13, height: 1.35)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TonalButton(
                    key: Key('timeline_view_details_$index'),
                    label: tr('View details'),
                    onPressed: stop.onViewDetails,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: active && stop.onMap != null
                      ? ElevatedButton.icon(
                          key: Key('timeline_map_$index'),
                          onPressed: stop.onMap,
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: Text(tr('Map')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.button,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size.fromHeight(44),
                            textStyle: const TextStyle(
                                fontFamily: 'Inter',
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
              decoration:
                  BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 15),
            ),
          StopProgress.active => Container(
              key: const ValueKey('active'),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 4.5),
              ),
            ),
          StopProgress.upcoming => Container(
              key: const ValueKey('upcoming'),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line, width: 3),
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
        color: active ? AppColors.greenSoft : const Color(0xFF9AA5B1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(width: 5),
        IconTheme.merge(data: IconThemeData(size: 13, color: fg), child: icon),
      ]),
    );
  }
}
